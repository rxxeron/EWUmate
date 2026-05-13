import logging
import os
import uuid
import tempfile
from datetime import datetime, timedelta
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from supabase import create_client

def generate_admin_style_pdf(output_path, semester, courses):
    """
    Generates a PDF matching the Admin Portal (PortalAutomation.tsx) style.
    """
    doc = SimpleDocTemplate(output_path, pagesize=A4, 
                           rightMargin=30, leftMargin=30, 
                           topMargin=30, bottomMargin=30)
    
    elements = []
    styles = getSampleStyleSheet()
    
    # 1. Title Style
    title_style = ParagraphStyle(
        'AdminTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=16,
        textColor=colors.HexColor("#1E293B"),
        alignment=1, # Center
        spaceAfter=5
    )
    
    sub_style = ParagraphStyle(
        'AdminSub',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        textColor=colors.HexColor("#1E293B"),
        alignment=1,
        spaceAfter=10
    )

    # 2. Add Header
    elements.append(Paragraph("East West University — Course List", title_style))
    
    now = datetime.now()
    timestamp = now.strftime('%d/%m/%Y @ %I:%M %p')
    
    sub_text = f"Semester: {semester}  |  Total: {len(courses)}  |  Generated from EWUmate  |  Issued: {timestamp}"
    elements.append(Paragraph(sub_text, sub_style))
    elements.append(Spacer(1, 10))
    
    # 3. Table Data
    header = ['PROG', 'DESCRIPTION', 'SEC', 'FAC', 'CAP', 'SCHEDULE', 'ROOM', 'TYPE']
    data = [header]
    
    # Sort courses: CSE first, then ICE, then others
    sorted_courses = sorted(courses, key=lambda x: (
        0 if str(x.get('code', x.get('course_code', ''))).upper().startswith('CSE') else 
        1 if str(x.get('code', x.get('course_code', ''))).upper().startswith('ICE') else 2,
        str(x.get('code', x.get('course_code', ''))).upper()
    ))

    # Define a style for the table cells to handle wrapping
    cell_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontSize=6.5,
        leading=8,
        alignment=1 # Center
    )

    for c in sorted_courses:
        sessions = c.get('sessions', []) or c.get('schedule_data', [])
        
        # Use Paragraphs for wrapping in columns
        schedule_para = Paragraph("<br/>".join([f"{s.get('day', '')} {s.get('startTime', '')}-{s.get('endTime', '')}" for s in sessions]), cell_style)
        room_para = Paragraph("<br/>".join([str(s.get('room', '')) for s in sessions]), cell_style)
        
        # Align TYPE line-by-line with the sessions
        type_para = Paragraph("<br/>".join([s.get('type', 'Theory') for s in sessions]), cell_style)
        
        # Admin Portal description style: Just Course Code (Name removed as per request)
        desc_para = Paragraph(f"<b>{c.get('code', c.get('course_code', ''))}</b>", cell_style)
        
        data.append([
            c.get('dedicated_department', '—'),
            desc_para,
            c.get('section', c.get('section_number', '—')),
            c.get('faculty', c.get('faculty_initials', 'TBA')),
            c.get('capacity', '0/0'),
            schedule_para,
            room_para,
            type_para
        ])

    # 4. Create and Style Table (Matching PortalAutomation.tsx with stretched Room)
    # Stretched Room: DESC reduced, ROOM increased
    table = Table(data, colWidths=[35, 60, 25, 35, 45, 110, 140, 50], repeatRows=1)
    
    style = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#DBEAFE")), 
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor("#1E293B")), 
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 6.5),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")), 
        ('TEXTCOLOR', (7, 1), (7, -1), colors.HexColor("#4F46E5")), 
        ('FONTNAME', (7, 1), (7, -1), 'Helvetica-Bold'),
    ])
    table.setStyle(style)
    elements.append(table)
    
    doc.build(elements)

def run_automated_snapshot(semester_name):
    """
    Called after sync to capture a PDF snapshot of the current course list.
    """
    logging.info(f"Triggering Automated Snapshot for {semester_name}...")
    
    SUPABASE_URL = os.environ.get("SUPABASE_URL")
    SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_SERVICE_KEY")
    
    if not SUPABASE_URL or not SUPABASE_KEY:
        logging.error("Snapshot failed: Missing Supabase credentials")
        return

    try:
        sb = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # 1. Fetch current data from DB (with pagination to bypass 1000 limit)
        table_name = f"courses_{semester_name.lower().replace(' ', '')}"
        courses = []
        offset = 0
        limit = 1000
        
        while True:
            res = sb.table(table_name).select("*").range(offset, offset + limit - 1).execute()
            if not res.data:
                break
            courses.extend(res.data)
            if len(res.data) < limit:
                break
            offset += limit

        if not courses:
            logging.warning(f"No courses found in {table_name} for snapshot.")
            return
        
        # 2. Generate PDF
        with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp:
            pdf_path = tmp.name
        
        try:
            generate_admin_style_pdf(pdf_path, semester_name, courses)
            
            # 3. Upload to Storage
            with open(pdf_path, "rb") as f:
                pdf_bytes = f.read()
            os.remove(pdf_path)
            
            bucket_name = "temporary_pdfs"
            file_name = f"faculty_snapshot_{semester_name.lower().replace(' ', '')}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
            
            sb.storage.from_(bucket_name).upload(file_name, pdf_bytes, {"content-type": "application/pdf"})
            public_url = sb.storage.from_(bucket_name).get_public_url(file_name)
            
            # 4. Update app_config metadata
            config_res = sb.table("app_config").select("value").eq("key", "faculty_snapshots").execute()
            snapshots = []
            if config_res.data:
                snapshots = config_res.data[0].get("value", {}).get("snapshots", [])
            
            new_snapshot = {
                "id": str(uuid.uuid4()),
                "semester": semester_name,
                "url": public_url,
                "timestamp": datetime.now().isoformat(),
                "file_name": file_name
            }
            snapshots.insert(0, new_snapshot)
            
            # 5. Retention: Keep last 5 days
            cutoff = datetime.now() - timedelta(days=5)
            to_keep = []
            to_delete = []
            for s in snapshots:
                s_time = datetime.fromisoformat(s["timestamp"])
                if s_time > cutoff:
                    to_keep.append(s)
                else:
                    to_delete.append(s)
            
            for old in to_delete:
                try:
                    sb.storage.from_(bucket_name).remove([old["file_name"]])
                except: pass
                
            sb.table("app_config").upsert({
                "key": "faculty_snapshots",
                "value": {"snapshots": to_keep}
            }).execute()
            
            logging.info(f"Automated Snapshot recorded: {public_url}")
            
        except Exception as e:
            if os.path.exists(pdf_path): os.remove(pdf_path)
            raise e
            
    except Exception as e:
        logging.error(f"Snapshot Automation Failed: {str(e)}")
