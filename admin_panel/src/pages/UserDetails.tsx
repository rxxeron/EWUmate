import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabaseAdmin as supabase } from '../lib/supabase';
import { ArrowLeft, RefreshCw, Users, CheckCircle2, Clipboard, CalendarClock, AlertTriangle, Clock, Edit, Save, X, Plus, Trash2 } from 'lucide-react';
import toast from 'react-hot-toast';
import type { Profile, Enrollment, CompletedCourse, Task, CourseMark, UserSemesterState } from '../types';

export function UserDetails() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('overview');
  
  const [user, setUser] = useState<Profile | null>(null);
  const [completedCourses, setCompletedCourses] = useState<CompletedCourse[]>([]);
  const [currentEnrollments, setCurrentEnrollments] = useState<Enrollment[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [marks, setMarks] = useState<CourseMark[]>([]);
  const [semesterState, setSemesterState] = useState<UserSemesterState | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [rebuilding, setRebuilding] = useState(false);
  const [saving, setSaving] = useState(false);
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [editForm, setEditForm] = useState<Partial<Profile>>({});
  
  const [isAddingCourse, setIsAddingCourse] = useState(false);
  const [courseForm, setCourseForm] = useState<Partial<CompletedCourse>>({});
  const [availablePrograms, setAvailablePrograms] = useState<any[]>([]);

  useEffect(() => {
    if (id) {
      fetchUser(id);
      fetchPrograms();
    }
  }, [id]);

  async function fetchPrograms() {
    try {
      const { data } = await supabase.from('programs').select('program_code, name, department_name, track');
      if (data) setAvailablePrograms(data);
    } catch (e) {
      console.error('Failed to fetch programs:', e);
    }
  }

  const startAddingCourse = () => {
    setCourseForm({
      semester_code: '',
      course_code: '',
      grade: 'A',
      credits: 3.0,
      user_id: id
    });
    setIsAddingCourse(true);
  };

  const handleAddCourse = async () => {
    if (!id || !courseForm.course_code || !courseForm.semester_code) return;
    setSaving(true);
    try {
      const { error } = await supabase
        .from('completed_courses')
        .insert([{ ...courseForm, user_id: id }]);
      
      if (error) throw error;
      toast.success('Course added');
      setIsAddingCourse(false);
      fetchUser(id);
    } catch (err: any) {
      toast.error('Failed to add course: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteCourse = async (courseId: string) => {
    if (!confirm('Are you sure you want to delete this course history record?')) return;
    try {
      const { error } = await supabase
        .from('completed_courses')
        .delete()
        .eq('id', courseId);
      
      if (error) throw error;
      toast.success('Course record deleted');
      fetchUser(id!);
    } catch (err: any) {
      toast.error('Delete failed: ' + err.message);
    }
  };

  const handleDeleteEnrollment = async (enrollmentId: string) => {
    if (!confirm('Are you sure you want to remove this course from current enrollments? This will affect the user\'s schedule.')) return;
    try {
      const { error } = await supabase
        .from('enrollments')
        .delete()
        .eq('id', enrollmentId);
      
      if (error) throw error;
      toast.success('Enrollment removed');
      fetchUser(id!);
    } catch (err: any) {
      toast.error('Removal failed: ' + err.message);
    }
  };

  const startEditing = () => {
    if (user) {
      setEditForm({
        full_name: user.full_name,
        student_id: user.student_id,
        program_code: user.program_code,
        program_name: user.program_name,
        department_name: user.department_name,
        cgpa: user.cgpa,
        total_credits_earned: user.total_credits_earned,
        track: user.track
      });
      setIsEditingProfile(true);
    }
  };

  const handleUpdateProfile = async () => {
    if (!id) return;
    setSaving(true);
    try {
      const { error } = await supabase
        .from('profiles')
        .update(editForm)
        .eq('id', id);
      
      if (error) throw error;
      toast.success('Profile updated successfully');
      setIsEditingProfile(false);
      fetchUser(id);
    } catch (err: any) {
      toast.error('Update failed: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  async function fetchUser(userId: string) {
    setLoading(true);
    
    try {
      const { data: userData, error: userError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (userError) throw userError;
      if (userData) setUser(userData as Profile);

      const track = userData.track || 'tri_semester';
      const { data: activeSem } = await supabase
        .from('active_semester')
        .select('current_semester_code')
        .eq('track', track)
        .maybeSingle();

      const semesterCode = activeSem?.current_semester_code;

      // 3. Fetch Semester State (Schedule Cache)
      if (semesterCode) {
        try {
          const { data: stateData } = await supabase
            .from('user_semester_states')
            .select('*')
            .eq('user_id', userId)
            .eq('semester_code', semesterCode)
            .maybeSingle();
          
          if (stateData) setSemesterState(stateData as UserSemesterState);
        } catch (e) {
          console.error('Failed to fetch semester state:', e);
        }
      }

      // 4. Fetch Enrollments
      try {
        let enrollmentsQuery = supabase
          .from('enrollments')
          .select('*')
          .eq('user_id', userId);
          
        if (semesterCode) {
          enrollmentsQuery = enrollmentsQuery.eq('semester_code', semesterCode);
        }
        
        const { data: enrollmentsData } = await enrollmentsQuery;

        if (enrollmentsData) {
          const sectionIds = enrollmentsData.map((e: Enrollment) => e.section_id).filter(Boolean);
          if (sectionIds.length > 0 && semesterCode) {
            const cleanSem = semesterCode.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
            const courseTable = `courses_${cleanSem}`;
            
            const sectionsMap: Record<string, { id: string; section_number: number | null; course_name: string | null }> = {};
            const { data: semCourses } = await supabase.from(courseTable).select('id, section_number, course_name').in('id', sectionIds);
            
            if (semCourses) semCourses.forEach((s: any) => sectionsMap[s.id] = s);

            enrollmentsData.forEach((e: any) => {
               if (e.section_id && sectionsMap[e.section_id]) { 
                 e._sectionDetails = sectionsMap[e.section_id]; 
               }
            });
          }
          setCurrentEnrollments(enrollmentsData as Enrollment[]);
        }
      } catch (e) {
        console.error('Failed to fetch enrollments:', e);
      }

      // 5. Fetch Other Data
      try {
        const { data: coursesData } = await supabase.from('completed_courses').select('*').eq('user_id', userId).order('semester_code', { ascending: false });
        if (coursesData) setCompletedCourses(coursesData as CompletedCourse[]);
      } catch (e) {
        console.error('Failed to fetch completed courses:', e);
      }

      try {
        const { data: tasksData } = await supabase.from('tasks').select('*').eq('user_id', userId).order('due_date', { ascending: false }).limit(50);
        if (tasksData) setTasks(tasksData as Task[]);
      } catch (e) {
        console.error('Failed to fetch tasks:', e);
      }

      try {
        const { data: marksData } = await supabase.from('semester_course_marks').select('*').eq('user_id', userId);
        if (marksData && semesterCode) {
          const cleanSem = semesterCode.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
          const courseTable = `courses_${cleanSem}`;
          const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
          const uuidCodes = marksData.map((m: CourseMark) => m.course_code).filter(c => c && uuidRegex.test(c));
          
          if (uuidCodes.length > 0) {
            const { data: semCourses } = await supabase.from(courseTable).select('id, course_code').in('id', uuidCodes);
            if (semCourses) {
              const courseMap: Record<string, string> = {};
              semCourses.forEach((s: any) => courseMap[s.id] = s.course_code);
              marksData.forEach((m: CourseMark) => {
                if (courseMap[m.course_code]) {
                  m.course_code = courseMap[m.course_code];
                }
              });
            }
          }
          
          const filteredMarks = marksData.filter((m: CourseMark) => m.course_code && m.course_code.length <= 15 && !m.course_code.includes('-'));
          setMarks(filteredMarks as CourseMark[]);
        }
      } catch (e) {
        console.error('Failed to fetch marks:', e);
      }
    } catch (err: any) {
      console.error('Critical fetch error:', err);
    }
    setLoading(false);
  }

  const handleSyncData = async () => {
    if (!id) return;
    setSyncing(true);
    try {
      const { data, error } = await supabase.functions.invoke('sync-academic-stats', {
        body: { user_id: id }
      });
      if (error) throw error;
      toast.success(`Sync complete: CGPA ${data?.cgpa ?? '?'}`, { duration: 4000 });
      fetchUser(id);
    } catch (err: any) {
      toast.error('Sync failed: ' + err.message);
    } finally {
      setSyncing(false);
    }
  };

  const handleRebuildSchedule = async () => {
    if (!id) return;
    setRebuilding(true);
    const toastId = toast.loading('Rebuilding schedule cache...');
    try {
      const { error } = await supabase.functions.invoke('sync-schedule', {
        body: { user_id: id }
      });
      if (error) throw error;
      toast.success('Schedule rebuilt successfully!', { id: toastId });
      fetchUser(id);
    } catch (err: any) {
      toast.error('Rebuild failed: ' + err.message, { id: toastId });
    } finally {
      setRebuilding(false);
    }
  };

  if (loading) return <div className='flex justify-center items-center h-64'><div className='animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600'></div></div>;
  if (!user) return <div className='text-center py-12'><h3 className='text-lg font-medium text-gray-900'>User not found</h3></div>;

  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  return (
    <div className='space-y-6'>
      <div className='flex items-center justify-between flex-wrap gap-4'>
        <div className='flex items-center gap-4'>
          <button onClick={() => navigate('/users')} className='p-2 hover:bg-gray-100 rounded-full transition-colors'><ArrowLeft className='h-5 w-5 text-gray-600' /></button>
          <div>
            <h1 className='text-2xl font-bold text-gray-900'>{user.full_name || 'Unknown User'}</h1>
            <p className='text-sm text-gray-500'>ID: {user.student_id || 'N/A'} • {user.track?.replace('_', ' ') || 'Tri-Semester'}</p>
          </div>
        </div>
        <div className='flex gap-2'>
          <button onClick={startEditing} className='flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 text-sm font-medium'>
            <Edit className='h-4 w-4' />
            Edit Profile
          </button>
          <button onClick={handleSyncData} disabled={syncing} className='flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 disabled:opacity-50 text-sm font-medium'>
            <RefreshCw className={`h-4 w-4 ${syncing ? 'animate-spin' : ''}`} />
            {syncing ? 'Syncing...' : 'Sync Academic Data'}
          </button>
          <button onClick={handleRebuildSchedule} disabled={rebuilding} className='flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-md hover:bg-emerald-700 disabled:opacity-50 text-sm font-medium'>
            <CalendarClock className={`h-4 w-4 ${rebuilding ? 'animate-spin' : ''}`} />
            {rebuilding ? 'Rebuilding...' : 'Rebuild Schedule'}
          </button>
        </div>
      </div>

      <div className='border-b border-gray-200'>
        <nav className='-mb-px flex space-x-8 overflow-x-auto no-scrollbar'>
          {['overview', 'enrollments', 'schedule', 'history', 'tasks', 'marks'].map(tab => (
            <button key={tab} onClick={() => setActiveTab(tab)} className={`whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm ${activeTab === tab ? 'border-indigo-500 text-indigo-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}`}>
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </nav>
      </div>

      <div className='mt-6'>
        {activeTab === 'overview' && (
          <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
            <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
              <h3 className='text-lg font-medium mb-4 flex items-center gap-2'><Users className='h-5 w-5 text-indigo-500' /> Academic Standing</h3>
              <dl className='space-y-4'>
                <div><dt className='text-sm text-gray-500'>Program</dt><dd className='mt-1 text-sm font-medium'>{user.program_name || user.program_code || 'N/A'}</dd></div>
                <div className='grid grid-cols-2 gap-4'>
                  <div><dt className='text-sm text-gray-500'>CGPA</dt><dd className='mt-1 text-2xl font-bold text-indigo-600'>{user.cgpa?.toFixed(2) || '0.00'}</dd></div>
                  <div><dt className='text-sm text-gray-500'>Credits</dt><dd className='mt-1 text-2xl font-bold text-gray-900'>{user.total_credits_earned || 0}</dd></div>
                </div>
              </dl>
            </div>
            
            <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
              <h3 className='text-lg font-medium mb-4 flex items-center gap-2'><Clock className='h-5 w-5 text-indigo-500' /> Systems Status</h3>
              <div className='space-y-4'>
                <div className='flex items-center justify-between'>
                  <span className='text-sm text-gray-500'>App Opens</span>
                  <span className='font-bold text-gray-900'>{user.app_open_count || 0}</span>
                </div>
                <div className='flex items-center justify-between'>
                  <span className='text-sm text-gray-500'>Last Active</span>
                  <span className='text-sm font-medium'>{user.last_active_at ? new Date(user.last_active_at).toLocaleString() : 'Never'}</span>
                </div>
                <div className='text-xs text-gray-400'>
                  Account Created: {new Date(user.created_at).toLocaleString()}
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'schedule' && (
          <div className='space-y-4'>
            {!semesterState?.weekly_grid_cache ? (
              <div className='bg-amber-50 border border-amber-200 p-8 rounded-xl text-center'>
                <AlertTriangle className='h-12 w-12 text-amber-500 mx-auto mb-4' />
                <h3 className='text-lg font-bold text-amber-800'>No Schedule Cache Found</h3>
                <p className='text-amber-700 mt-2 max-w-md mx-auto'>
                  The mobile app won't show any classes because the schedule hasn't been generated for this user in the current semester.
                </p>
                <button onClick={handleRebuildSchedule} className='mt-6 px-6 py-2 bg-amber-600 text-white rounded-lg font-bold hover:bg-amber-700 transition-colors'>
                  Generate Schedule Now
                </button>
              </div>
            ) : (
              <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4'>
                {days.map(day => {
                  const dailyClasses = semesterState.weekly_grid_cache![day] || [];
                  return (
                    <div key={day} className='bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden'>
                      <div className='px-4 py-2 bg-gray-50 border-b border-gray-200 font-bold text-sm text-gray-700'>{day}</div>
                      <div className='p-4 space-y-3 min-h-[150px]'>
                        {dailyClasses.length === 0 ? (
                          <div className='h-full flex items-center justify-center text-xs text-gray-400 italic'>No classes scheduled</div>
                        ) : (
                          dailyClasses.map((cls, idx) => (
                            <div key={idx} className='p-3 bg-indigo-50 border border-indigo-100 rounded-lg'>
                              <div className='flex justify-between items-start'>
                                <span className='text-xs font-black text-indigo-700'>{cls.courseCode}</span>
                                <span className='text-[10px] bg-white px-1.5 py-0.5 rounded border border-indigo-200 text-indigo-600 font-bold uppercase'>{cls.type}</span>
                              </div>
                              <p className='text-xs font-medium text-gray-900 mt-1 line-clamp-1'>{cls.courseName}</p>
                              <div className='flex items-center gap-2 mt-2 text-[10px] text-gray-500 font-medium'>
                                <Clock className='w-3 h-3' />
                                {cls.startTime} - {cls.endTime}
                              </div>
                              <div className='flex items-center justify-between mt-2'>
                                <span className='text-[10px] bg-indigo-600 text-white px-2 py-0.5 rounded-full font-bold'>{cls.room}</span>
                                <span className='text-[10px] text-indigo-400 font-bold'>{cls.faculty}</span>
                              </div>
                            </div>
                          ))
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {activeTab === 'enrollments' && (
          <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
            <h3 className='text-lg font-medium mb-4'>Current Enrollments</h3>
            <div className='space-y-4'>
              {currentEnrollments.length > 0 ? currentEnrollments.map((enr, i) => (
                <div key={i} className='border rounded-xl p-4 flex justify-between items-center bg-white hover:border-indigo-200 transition-colors'>
                  <div>
                    <h4 className='font-bold text-gray-900'>{enr.course_code} - Section {enr._sectionDetails?.section_number || (enr as any).section || 'N/A'}</h4>
                    <p className='text-sm text-gray-500'>{enr._sectionDetails?.course_name || 'Course details stored in schedule'}</p>
                  </div>
                  <div className='flex items-center gap-3'>
                    <span className='px-3 py-1 bg-green-100 text-green-800 rounded-full text-xs font-bold'>Active</span>
                    <button 
                      onClick={() => handleDeleteEnrollment(enr.id)}
                      className='p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors'
                      title='Remove enrollment'
                    >
                      <Trash2 className='w-4 h-4' />
                    </button>
                  </div>
                </div>
              )) : <p className='text-gray-500 italic'>No current enrollments.</p>}
            </div>
          </div>
        )}

        {activeTab === 'history' && (
          <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
            <div className='flex items-center justify-between mb-4'>
              <h3 className='text-lg font-medium'>Past Courses</h3>
              <button 
                onClick={startAddingCourse}
                className='flex items-center gap-2 px-3 py-1.5 bg-indigo-50 text-indigo-700 rounded-lg hover:bg-indigo-100 text-sm font-bold transition-colors'
              >
                <Plus className='w-4 h-4' />
                Add Record
              </button>
            </div>
            <div className='overflow-x-auto'>
              <table className='min-w-full divide-y divide-gray-200'>
                <thead>
                  <tr>
                    <th className='text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider'>Semester</th>
                    <th className='text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider'>Course</th>
                    <th className='text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider'>Grade</th>
                    <th className='text-left py-3 text-xs font-medium text-gray-500 uppercase tracking-wider'>Credits</th>
                    <th className='text-right py-3 text-xs font-medium text-gray-500 uppercase tracking-wider'>Actions</th>
                  </tr>
                </thead>
                <tbody className='divide-y divide-gray-200'>
                  {completedCourses.map((c, i) => (
                    <tr key={i} className='hover:bg-gray-50'>
                      <td className='py-4 text-sm'>{c.semester_code}</td>
                      <td className='py-4 text-sm font-medium'>{c.course_code}</td>
                      <td className='py-4 text-sm'>
                        <span className='px-2 py-1 bg-gray-100 rounded text-gray-800 font-medium'>{c.grade}</span>
                      </td>
                      <td className='py-4 text-sm'>{c.credits}</td>
                      <td className='py-4 text-right'>
                        <button 
                          onClick={() => handleDeleteCourse(c.id)}
                          className='p-1.5 text-red-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors'
                          title='Delete record'
                        >
                          <Trash2 className='w-4 h-4' />
                        </button>
                      </td>
                    </tr>
                  ))}
                  {completedCourses.length === 0 && (
                    <tr>
                      <td colSpan={5} className='py-8 text-center text-sm text-gray-500 italic'>No course history found.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {activeTab === 'tasks' && (
          <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
            <h3 className='text-lg font-medium mb-4'>Task History</h3>
            <div className='space-y-3'>
              {tasks.length > 0 ? tasks.map((t, i) => (
                <div key={i} className='flex items-center justify-between p-3 border rounded-lg'>
                  <div className='flex items-center gap-3'>
                    {t.is_completed ? <CheckCircle2 className='h-5 w-5 text-green-500' /> : t.is_missed ? <CheckCircle2 className='h-5 w-5 text-red-500' /> : <Clipboard className='h-5 w-5 text-yellow-500' />}
                    <div>
                      <p className='font-medium text-sm'>{t.title}</p>
                      <p className='text-xs text-gray-500'>{t.course_code}</p>
                    </div>
                  </div>
                  <span className='text-xs text-gray-400'>{new Date(t.due_date).toLocaleDateString()}</span>
                </div>
              )) : <p className='text-gray-500'>No tasks found.</p>}
            </div>
          </div>
        )}

        {activeTab === 'marks' && (
          <div className='bg-white p-6 rounded-lg shadow-sm border border-gray-200'>
            <h3 className='text-lg font-medium mb-4'>Course Marks & Breakdown</h3>
            <div className='grid grid-cols-1 xl:grid-cols-2 gap-6'>
              {marks.length > 0 ? marks.map((m: any, i) => {
                const components = [
                  { key: 'mid', label: 'Midterm', obt: m.obt_mid, dist: m.dist_mid },
                  { key: 'final', label: 'Final', obt: m.obt_final, dist: m.dist_final },
                  { key: 'assignment', label: 'Assignment', obt: m.obt_assignment, dist: m.dist_assignment },
                  { key: 'attendance', label: 'Attendance', obt: m.obt_attendance, dist: m.dist_attendance },
                  { key: 'lab', label: 'Lab', obt: m.obt_lab, dist: m.dist_lab },
                  { key: 'presentation', label: 'Presentation', obt: m.obt_presentation, dist: m.dist_presentation },
                  { key: 'viva', label: 'Viva', obt: m.obt_viva, dist: m.dist_viva },
                  { key: 'project', label: 'Project', obt: m.obt_project, dist: m.dist_project },
                  { key: 'term_paper', label: 'Term Paper', obt: m.obt_term_paper, dist: m.dist_term_paper },
                  { key: 'class_performance', label: 'Class Performance', obt: m.obt_class_performance, dist: m.dist_class_performance },
                ];

                const activeComponents = components.filter(c => c.dist && c.dist > 0);

                return (
                  <div key={i} className='border border-gray-200 rounded-xl p-5 bg-slate-50 shadow-sm'>
                    <div className='flex items-center justify-between border-b pb-3 mb-3'>
                      <h4 className='font-bold text-gray-800 text-lg'>{m.course_code}</h4>
                      <span className='text-xs font-semibold px-2 py-1 bg-indigo-100 text-indigo-700 rounded-full'>{m.semester_code}</span>
                    </div>
                    
                    <div className='space-y-2 text-sm text-gray-700'>
                      {/* Quizzes breakdown */}
                      {m.dist_quiz && m.dist_quiz > 0 && (
                        <div className='bg-white p-3 rounded-lg border border-gray-100 flex flex-col gap-1'>
                          <div className='flex justify-between font-medium'>
                            <span>Quizzes ({m.quiz_strategy === 'best_n' ? `Best ${m.quiz_n}` : m.quiz_strategy === 'average_n' ? `Avg of ${m.quiz_n}` : 'All'})</span>
                            <span className='text-indigo-600 font-semibold'>{m.obt_quizzes?.length ? m.obt_quizzes.join(', ') : '-'} / {m.dist_quiz}</span>
                          </div>
                        </div>
                      )}

                      {/* Short Quizzes breakdown */}
                      {m.dist_short_quiz && m.dist_short_quiz > 0 && (
                        <div className='bg-white p-3 rounded-lg border border-gray-100 flex flex-col gap-1'>
                          <div className='flex justify-between font-medium'>
                            <span>Short Quizzes ({m.marks_data?.short_quiz_strategy === 'best_one' ? 'Best 1' : 'Sum all'})</span>
                            <span className='text-indigo-600 font-semibold'>{m.obt_short_quizzes?.length ? m.obt_short_quizzes.join(', ') : '-'} / {m.dist_short_quiz}</span>
                          </div>
                        </div>
                      )}

                      {/* Other dynamic components */}
                      {activeComponents.map((comp, idx) => (
                        <div key={idx} className='bg-white p-3 rounded-lg border border-gray-100 flex justify-between items-center'>
                          <span className='font-medium text-gray-600'>{comp.label}</span>
                          <span className='text-indigo-600 font-semibold'>{comp.obt ?? '-'} / {comp.dist}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                );
              }) : <p className='text-gray-500'>No detailed marks available.</p>}
            </div>
          </div>
        )}
      </div>

      {isEditingProfile && (
        <div className='fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4'>
          <div className='bg-white rounded-2xl shadow-xl w-full max-w-2xl overflow-hidden'>
            <div className='px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-gray-50'>
              <h3 className='text-lg font-bold text-gray-900'>Edit Student Profile</h3>
              <button onClick={() => setIsEditingProfile(false)} className='p-2 hover:bg-gray-200 rounded-full transition-colors'>
                <X className='h-5 w-5 text-gray-500' />
              </button>
            </div>
            <div className='p-6 space-y-4 max-h-[70vh] overflow-y-auto'>
              <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Full Name</label>
                  <input 
                    type='text' 
                    value={editForm.full_name || ''} 
                    onChange={e => setEditForm({...editForm, full_name: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Student ID</label>
                  <input 
                    type='text' 
                    value={editForm.student_id || ''} 
                    onChange={e => setEditForm({...editForm, student_id: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
                <div className='space-y-1 md:col-span-2'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Select Program</label>
                  <select 
                    value={editForm.program_code || ''} 
                    onChange={e => {
                      const prog = availablePrograms.find(p => p.program_code === e.target.value);
                      if (prog) {
                        setEditForm({
                          ...editForm, 
                          program_code: prog.program_code,
                          program_name: prog.name,
                          department_name: prog.department_name,
                          track: prog.track
                        });
                      } else {
                        setEditForm({...editForm, program_code: e.target.value});
                      }
                    }}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  >
                    <option value=''>-- Choose a Program --</option>
                    {availablePrograms.map(p => (
                      <option key={p.program_code} value={p.program_code}>{p.program_code} - {p.name}</option>
                    ))}
                  </select>
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Program Name (Display)</label>
                  <input 
                    type='text' 
                    value={editForm.program_name || ''} 
                    onChange={e => setEditForm({...editForm, program_name: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none bg-gray-50'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Department Name (Display)</label>
                  <input 
                    type='text' 
                    value={editForm.department_name || ''} 
                    onChange={e => setEditForm({...editForm, department_name: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none bg-gray-50'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>CGPA</label>
                  <input 
                    type='number' 
                    step='0.01'
                    value={editForm.cgpa || 0} 
                    onChange={e => setEditForm({...editForm, cgpa: parseFloat(e.target.value)})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Total Credits</label>
                  <input 
                    type='number' 
                    value={editForm.total_credits_earned || 0} 
                    onChange={e => setEditForm({...editForm, total_credits_earned: parseInt(e.target.value)})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Track</label>
                  <select 
                    value={editForm.track || 'tri_semester'} 
                    onChange={e => setEditForm({...editForm, track: e.target.value as any})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  >
                    <option value='tri_semester'>Tri-Semester</option>
                    <option value='bi_semester'>Bi-Semester</option>
                  </select>
                </div>
              </div>
            </div>
            <div className='px-6 py-4 border-t border-gray-100 flex items-center justify-end gap-3 bg-gray-50'>
              <button 
                onClick={() => setIsEditingProfile(false)}
                className='px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors'
              >
                Cancel
              </button>
              <button 
                onClick={handleUpdateProfile}
                disabled={saving}
                className='flex items-center gap-2 px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 text-sm font-bold shadow-md shadow-indigo-200 transition-all'
              >
                {saving ? <RefreshCw className='h-4 w-4 animate-spin' /> : <Save className='h-4 w-4' />}
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </div>
        </div>
      )}

      {isAddingCourse && (
        <div className='fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4'>
          <div className='bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden'>
            <div className='px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-gray-50'>
              <h3 className='text-lg font-bold text-gray-900'>Add Course Record</h3>
              <button onClick={() => setIsAddingCourse(false)} className='p-2 hover:bg-gray-200 rounded-full transition-colors'>
                <X className='h-5 w-5 text-gray-500' />
              </button>
            </div>
            <div className='p-6 space-y-4'>
              <div className='space-y-1'>
                <label className='text-xs font-bold text-gray-500 uppercase'>Semester Code</label>
                <input 
                  type='text' 
                  placeholder='e.g. Summer 2026'
                  value={courseForm.semester_code || ''} 
                  onChange={e => setCourseForm({...courseForm, semester_code: e.target.value})}
                  className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                />
              </div>
              <div className='space-y-1'>
                <label className='text-xs font-bold text-gray-500 uppercase'>Course Code</label>
                <input 
                  type='text' 
                  placeholder='e.g. CSE103'
                  value={courseForm.course_code || ''} 
                  onChange={e => setCourseForm({...courseForm, course_code: e.target.value.toUpperCase()})}
                  className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                />
              </div>
              <div className='grid grid-cols-2 gap-4'>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Grade</label>
                  <select 
                    value={courseForm.grade || 'A'} 
                    onChange={e => setCourseForm({...courseForm, grade: e.target.value})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  >
                    {['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'I', 'W'].map(g => (
                      <option key={g} value={g}>{g}</option>
                    ))}
                  </select>
                </div>
                <div className='space-y-1'>
                  <label className='text-xs font-bold text-gray-500 uppercase'>Credits</label>
                  <input 
                    type='number' 
                    step='0.5'
                    value={courseForm.credits || 3.0} 
                    onChange={e => setCourseForm({...courseForm, credits: parseFloat(e.target.value)})}
                    className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                  />
                </div>
              </div>
            </div>
            <div className='px-6 py-4 border-t border-gray-100 flex items-center justify-end gap-3 bg-gray-50'>
              <button 
                onClick={() => setIsAddingCourse(false)}
                className='px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors'
              >
                Cancel
              </button>
              <button 
                onClick={handleAddCourse}
                disabled={saving || !courseForm.course_code || !courseForm.semester_code}
                className='flex items-center gap-2 px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 text-sm font-bold shadow-md'
              >
                {saving ? <RefreshCw className='h-4 w-4 animate-spin' /> : <Plus className='h-4 w-4' />}
                {saving ? 'Adding...' : 'Add Record'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
