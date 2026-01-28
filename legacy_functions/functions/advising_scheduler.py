
import itertools
import json
import uuid
from datetime import datetime

from firebase_admin import firestore
from firebase_functions import https_fn, options
from google.cloud import tasks_v2

# --- CONFIGURATION ---
# Make sure this queue exists in your Google Cloud project
TASKS_QUEUE = "schedule-generator-queue"
TASKS_LOCATION = "us-central1" # e.g., "us-central1"

# --- HELPERS (Unchanged from original) ---

def parse_time_to_minutes(time_str):
    """Parses 'HH:mm AM/PM' to minutes from midnight."""
    try:
        dt = datetime.strptime(time_str.upper(), "%I:%M %p")
        return dt.hour * 60 + dt.minute
    except (ValueError, TypeError):
        return 0

def do_sessions_overlap(s1, s2):
    """Checks if two sessions overlap."""
    if not s1 or not s2 or s1.get('day') != s2.get('day'):
        return False
    
    start1 = parse_time_to_minutes(s1.get('startTime'))
    end1 = parse_time_to_minutes(s1.get('endTime'))
    start2 = parse_time_to_minutes(s2.get('startTime'))
    end2 = parse_time_to_minutes(s2.get('endTime'))
    
    return max(start1, start2) < min(end1, end2)

def is_valid_combination(sections):
    """Checks if a list of sections has any timing conflict."""
    all_sessions = []
    for sec in sections:
        # Ensure section is a dict and has sessions
        if isinstance(sec, dict):
            all_sessions.extend(sec.get('sessions', []))
        
    for i in range(len(all_sessions)):
        for j in range(i + 1, len(all_sessions)):
            if do_sessions_overlap(all_sessions[i], all_sessions[j]):
                return False
    return True

# --- NEW ASYNCHRONOUS IMPLEMENTATION ---

@https_fn.on_call(max_instances=10)
def generate_schedules_kickoff(req: https_fn.CallableRequest) -> https_fn.Response:
    """
    Initiates an asynchronous schedule generation process.
    """
    db = firestore.client()
    project_id = db.project
    # The public URL of the HTTP function that processes the tasks
    processor_function_url = f"https://{TASKS_LOCATION}-{project_id}.cloudfunctions.net/processCombinationTask"

    data = req.data
    semester = data.get('semester')
    course_codes = data.get('courses', [])
    
    if not semester or not course_codes:
        raise https_fn.HttpsError("invalid-argument", "Missing semester or courses.")

    # --- Validate User History (Same as before) ---
    if req.auth and req.auth.uid:
        user_ref = db.collection('users').document(req.auth.uid)
        user_doc = user_ref.get()
        if user_doc.exists:
            passed_courses = {
                r.get('courseCode') for r in user_doc.to_dict().get('academicResults', [])
                if r.get('grade') != 'F'
            }
            conflicts = set(course_codes) & passed_courses
            if conflicts:
                raise https_fn.HttpsError(
                    "failed-precondition",
                    f"You have already passed: { ', '.join(sorted(conflicts))}. Please remove them."
                )

    # 1. Fetch all available sections for the requested courses
    collection_name = f"courses_{semester.replace(' ', '')}"
    sections_by_course = {code: [] for code in course_codes}
    
    docs = db.collection(collection_name).where('code', 'in', course_codes).stream()
    
    for doc in docs:
        d = doc.to_dict()
        cap_str = d.get('capacity', '0/0')
        if isinstance(cap_str, str) and '/' in cap_str:
            try:
                enrolled, total = map(int, cap_str.split('/'))
                if total > 0 and enrolled < total:
                    d['id'] = doc.id
                    sections_by_course[d.get('code')].append(d)
            except ValueError:
                continue

    # Filter out courses that have no available sections
    courses_to_process = [c for c in course_codes if sections_by_course[c]]
    if not courses_to_process:
        return {"generationId": None, "message": "No sections available for the selected courses."}
    
    # 2. Create a state document in Firestore
    generation_id = str(uuid.uuid4())
    state_ref = db.collection('schedule_generations').document(generation_id)
    state_ref.set({
        'status': 'PENDING',
        'createdAt': firestore.SERVER_TIMESTAMP,
        'combinations': [],
        'request': {'semester': semester, 'courses': course_codes},
        'userId': req.auth.uid if req.auth else None
    })

    # 3. Create the initial Cloud Task
    tasks_client = tasks_v2.CloudTasksClient()
    
    initial_payload = {
        'generation_id': generation_id,
        'courses_to_process': courses_to_process,
        'all_sections': sections_by_course,
        'current_combination': []
    }
    
    # 4. Schedule the task
    try:
        _schedule_combination_task(tasks_client, project_id, processor_function_url, initial_payload)
        state_ref.update({'status': 'PROCESSING'})
    except Exception as e:
        state_ref.update({'status': 'FAILED', 'error': str(e)})
        raise https_fn.HttpsError("internal", f"Failed to create initial task: {e}")

    # 5. Return the generation ID to the client
    return {"generationId": generation_id}


@https_fn.on_request(max_instances=100)
def process_combination_task(req: https_fn.Request) -> https_fn.Response:
    """
    Recursively processes course combinations. Triggered by Cloud Tasks.
    """
    payload = req.get_json(silent=True)
    if not payload:
        return https_fn.Response("Invalid payload", status=400)

    generation_id = payload['generation_id']
    courses_to_process = payload['courses_to_process']
    all_sections = payload['all_sections']
    current_combination = payload['current_combination']
    
    db = firestore.client()
    project_id = db.project
    state_ref = db.collection('schedule_generations').document(generation_id)
    processor_function_url = f"https://{TASKS_LOCATION}-{project_id}.cloudfunctions.net/processCombinationTask"

    # Take the next course to process
    course_code = courses_to_process[0]
    remaining_courses = courses_to_process[1:]
    
    tasks_client = tasks_v2.CloudTasksClient()
    tasks_created = 0

    for section in all_sections[course_code]:
        new_combination = current_combination + [section]
        
        if is_valid_combination(new_combination):
            if not remaining_courses:
                # This is the last course, a valid combination is found
                final_set = [
                    {
                        'courseCode': s['code'], 'courseName': s['courseName'],
                        'section': s['section'], 'faculty': s['faculty'],
                        'id': s['id'], 'sessions': s.get('sessions', []),
                        'capacity': s.get('capacity', '0/0'),
                    } for s in new_combination
                ]
                state_ref.update({
                    'combinations': firestore.ArrayUnion([final_set])
                })
            else:
                # There are more courses, schedule a new task
                next_payload = {
                    'generation_id': generation_id,
                    'courses_to_process': remaining_courses,
                    'all_sections': all_sections,
                    'current_combination': new_combination
                }
                try:
                    _schedule_combination_task(tasks_client, project_id, processor_function_url, next_payload)
                    tasks_created += 1
                except Exception as e:
                    # Log error but continue
                    print(f"Error scheduling task for {generation_id}: {e}")

    return https_fn.Response(f"Tasks scheduled: {tasks_created}", status=200)


def _schedule_combination_task(client: tasks_v2.CloudTasksClient, project_id: str, processor_url: str, payload: dict):
    """Helper to create and queue a new task."""
    queue_path = client.queue_path(project_id, TASKS_LOCATION, TASKS_QUEUE)
    
    task = {
        "http_request": {
            "http_method": tasks_v2.HttpMethod.POST,
            "url": processor_url,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(payload).encode(),
        }
    }
    
    client.create_task(parent=queue_path, task=task)

# IMPORTANT: The old synchronous function `generate_schedule_combinations` is now removed.
# The new flow is initiated by `generate_schedules_kickoff` and processed by `process_combination_task`.
