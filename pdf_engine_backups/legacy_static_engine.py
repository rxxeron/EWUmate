from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
from reportlab.lib import colors
from reportlab.platypus import Table, TableStyle, SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from datetime import datetime
import os

class EWUmatePDFEngine:
    def __init__(self, output_path, data):
        self.output_path = output_path
        self.c = None # Defer initialization
        self.width, self.height = A4
        self.data = data
        self.ewu_green = colors.Color(0.18, 0.49, 0.19) # #2e7d32
        self.margin = 35
        self.label_x = 75
        self.colon_x = 180 
        self.value_x = 195 
        self.max_text_width = self.width - (self.value_x + 50) 
        current_dir = os.path.dirname(os.path.abspath(__file__))
        self.logo_path = os.path.join(current_dir, "logo.png")
        
        self.label_size = 12
        self.value_size = 12
        self.line_height = 16

    def generate(self):
        template = self.data.get('template', 'assignment')
        
        if template == 'physics_lab':
            self.render_physics_lab()

        # Initialize canvas for standard templates
        self.c = canvas.Canvas(self.output_path, pagesize=A4)
        
        if template == 'term_paper':
            self.c.setStrokeColor(colors.black)
        else:
            self.c.setStrokeColor(self.ewu_green)
            
        self.c.setLineWidth(1.5)
        self.c.rect(self.margin, self.margin, self.width-(self.margin*2), self.height-(self.margin*2), stroke=1, fill=0)
        
        self.c.setStrokeColor(colors.black)
        self.c.setFillColor(colors.black)
        self.c.setLineWidth(0.5)

        self.draw_header()
        
        if template in ['physics_lab', 'Physics Lab']:
            self.render_physics_lab()
        elif template == 'mps_assignment':
            self.render_mps_assignment()
        elif template in ['lab_report', 'Lab Report']:
            self.render_lab_report()
        elif template in ['assignment', 'general_assignment']:
            self.render_assignment()
        elif template in ['group_project', 'term_paper', 'project_report']:
            self.render_group_project()
        else:
            self.render_assignment()
        
        self.c.save()

    def draw_footer_dates(self):
        self.c.setFont("Times-Bold", self.label_size)
        y_footer = 100 
        alloc_date = self.data.get('allocation_date', '').strip()
        sub_date = self.data.get('submission_date', '').strip()
        
        if alloc_date:
            self.c.drawString(self.label_x, y_footer, f"Date of Allocation: {alloc_date}")
            self.c.drawString(self.label_x, y_footer - self.line_height, f"Date of Submission: {sub_date}")
        else:
            self.c.drawString(self.label_x, y_footer, f"Date of Submission: {sub_date}")

    def draw_wrapped_value(self, text, x, y, max_w=None):
        width_limit = max_w if max_w else self.max_text_width
        words = str(text).split(' ')
        lines = []
        current_line = []
        for word in words:
            test_line = " ".join(current_line + [word])
            if self.c.stringWidth(test_line, self.c._fontname, self.c._fontsize) < width_limit:
                current_line.append(word)
            else:
                lines.append(" ".join(current_line))
                current_line = [word]
        lines.append(" ".join(current_line))
        curr_y = y
        for line in lines:
            self.c.drawString(x, curr_y, line)
            curr_y -= self.line_height
        return curr_y

    def draw_dynamic_value(self, text, x, y, max_w=None, bold_val=False):
        width_limit = max_w if max_w else self.max_text_width
        val_font = "Times-Bold" if bold_val else "Times-Roman"
        self.c.setFont(val_font, self.value_size)
        current_size = self.value_size
        while current_size >= 10:
            if self.c.stringWidth(str(text), val_font, current_size) < width_limit:
                self.c.setFont(val_font, current_size)
                self.c.drawString(x, y, str(text))
                return y - self.line_height
            current_size -= 0.5
        self.c.setFont(val_font, 10)
        new_y = self.draw_wrapped_value(text, x, y, width_limit)
        return new_y

    def draw_centred_wrapped_text(self, text, y, max_w, font_size=18):
        self.c.setFont("Times-Bold", font_size)
        words = str(text).split(' ')
        lines = []
        current_line = []
        for word in words:
            test_line = " ".join(current_line + [word])
            if self.c.stringWidth(test_line, "Times-Bold", font_size) < max_w:
                current_line.append(word)
            else:
                lines.append(" ".join(current_line))
                current_line = [word]
        if current_line:
            lines.append(" ".join(current_line))
        curr_y = y
        for line in lines:
            self.c.drawCentredString(self.width/2, curr_y, line)
            curr_y -= (font_size + 4)
        return curr_y

    def draw_header(self):
        y_top = self.height - 50
        if os.path.exists(self.logo_path):
            try:
                self.c.drawImage(ImageReader(self.logo_path), (self.width-150)/2, y_top-50, width=150, height=50, preserveAspectRatio=True, mask='auto')
            except:
                pass
        self.c.setFont("Times-Bold", 14)
        self.c.drawCentredString(self.width/2, y_top-70, self.data.get('header_dept', 'Department of CSE'))
        self.c.setFont("Times-Roman", 8)
        self.c.drawCentredString(self.width/2, y_top-80, "A/2, Jahurul Islam Avenue, Jahurul Islam City, Aftabnagar, Dhaka-1212")
        self.c.setFont("Times-Bold", 11)
        self.c.drawCentredString(self.width/2, y_top-95, f"Semester: {self.data.get('semester', 'Summer 2026')}")

    def render_physics_lab(self):
        y = self.height - 210
        
        # Right Side items (Course info)
        items_right = [("Course Name", self.data.get('course_title', '')), 
                       ("Course Code", self.data.get('course_code', '')), 
                       ("Section No", self.data.get('section', '')),
                       ("Group No", self.data.get('group_no', ''))]
        
        x_right = self.width / 2 - 10
        label_w = 80
        
        for label, val in items_right:
            self.c.setFont("Times-Bold", self.label_size)
            self.c.drawString(x_right, y, label)
            self.c.drawString(x_right + label_w, y, ":")
            val_x = x_right + label_w + 10
            max_w = self.width - self.margin - val_x - 10
            y = self.draw_dynamic_value(val, val_x, y, max_w=max_w)
            y -= 8
            
        y -= 40 # gap before Experiment block
        
        # Left Side items (Experiment info)
        items_left = [("Experiment No", self.data.get('lab_no', '01')),
                      ("Name of the Experiment", self.data.get('topic', ''))]
                      
        left_label_w = 135
        
        for label, val in items_left:
            self.c.setFont("Times-Bold", self.label_size)
            self.c.drawString(self.label_x, y, label)
            self.c.drawString(self.label_x + left_label_w, y, ":")
            y = self.draw_dynamic_value(val, self.label_x + left_label_w + 10, y)
            y -= 8
            
        y -= 20 # gap before dates
        
        # Dates block
        alloc_date = self.data.get('allocation_date', '').strip()
        sub_date = self.data.get('submission_date', '').strip()
        
        if alloc_date:
            self.c.setFont("Times-Bold", self.label_size)
            self.c.drawString(self.label_x, y, "Date of Allocation")
            self.c.drawString(self.label_x + left_label_w, y, ":")
            self.c.setFont("Times-Roman", self.value_size)
            self.c.drawString(self.label_x + left_label_w + 10, y, alloc_date)
            y -= self.line_height + 8
            
        if sub_date:
            self.c.setFont("Times-Bold", self.label_size)
            self.c.drawString(self.label_x, y, "Date of Submission")
            self.c.drawString(self.label_x + left_label_w, y, ":")
            self.c.setFont("Times-Roman", self.value_size)
            self.c.drawString(self.label_x + left_label_w + 10, y, sub_date)
            y -= self.line_height + 8
            
        self.draw_submission_footer(y - 40, is_lab=True)

    def draw_inline_dates(self, start_y):
        y = start_y
        alloc_date = self.data.get('allocation_date', '').strip()
        sub_date = self.data.get('submission_date', '').strip()
        self.c.setFont("Times-Bold", self.label_size)
        
        if alloc_date:
            self.c.drawString(self.label_x, y, f"Date of Allocation: {alloc_date}")
            y -= self.line_height
            
        if sub_date:
            self.c.drawString(self.label_x, y, f"Date of Submission: {sub_date}")
            y -= self.line_height
        return y

    def render_lab_report(self):
        y_top = self.height - 210
        self.c.setFont("Times-Bold", 14)
        self.c.drawCentredString(self.width/2, y_top, f"Lab Report No: {self.data.get('lab_no', '01')}")
        self.c.drawCentredString(self.width/2, y_top-30, "Lab Topic:")
        topic = self.data.get('topic', 'EXPERIMENT NAME').strip()
        y = self.draw_centred_wrapped_text(topic, y_top-60, self.width-140, font_size=18)
        
        y -= 50
        items = [("Course Title", self.data.get('course_title', '')), 
                 ("Course Code", self.data.get('course_code', '')), 
                 ("Section", self.data.get('section', ''))]
        for label, val in items:
            self.c.setFont("Times-Bold", self.label_size)
            self.c.drawString(self.label_x, y, label)
            self.c.drawString(self.colon_x, y, ":")
            y = self.draw_dynamic_value(val, self.value_x, y)
            
        y = self.draw_submission_footer(y - 60, is_lab=True)
        self.draw_inline_dates(y - 40)

    def render_mps_assignment(self):
        y_top = self.height - 210
        self.c.setFont("Times-Bold", 20)
        self.c.drawCentredString(self.width/2, y_top, "Assignment")
        tw = self.c.stringWidth("Assignment", "Times-Bold", 20)
        self.c.line(self.width/2 - (tw/2), y_top-3, self.width/2 + (tw/2), y_top-3)
        y = y_top - 80
        items = [
            ("Course Title", self.data.get('course_title', '')), 
            ("Course Code", self.data.get('course_code', '')), 
            ("Section", self.data.get('section', '')),
            ("Instructor", self.data.get('teacher_name', ''))
        ]
        for label, val in items:
            self.c.setFont("Times-Bold", self.label_size)
            self.c.drawString(self.label_x, y, label)
            self.c.drawString(self.colon_x, y, ":")
            y = self.draw_dynamic_value(val, self.value_x, y)
            
        y = self.draw_mps_table(y - 80)
        self.draw_inline_dates(y - 60)

    def draw_mps_table(self, start_y):
        table_width = 380
        row_height = 25
        label_col_width = 100
        x_start = (self.width - table_width) / 2
        rows = [
            ("Name", self.data.get('students')[0]['name'] if self.data.get('students') else self.data.get('student_name', '')),
            ("Student ID", self.data.get('students')[0]['id'] if self.data.get('students') else self.data.get('student_id', '')),
            ("Group No.", self.data.get('group_no', ''))
        ]
        curr_y = start_y
        for label, val in rows:
            self.c.rect(x_start, curr_y - row_height, label_col_width, row_height)
            self.c.rect(x_start + label_col_width, curr_y - row_height, table_width - label_col_width, row_height)
            self.c.setFont("Times-Bold", self.label_size)
            self.c.drawString(x_start + 10, curr_y - 17, label)
            self.c.setFont("Times-Roman", self.value_size)
            self.c.drawString(x_start + label_col_width + 10, curr_y - 17, str(val))
            curr_y -= row_height
        return curr_y

    def render_assignment(self):
        topic = self.data.get('topic', '').strip()
        y_top = self.height - 210
        if topic:
            self.c.setFont("Times-Bold", 12)
            self.c.drawCentredString(self.width/2, y_top, "ASSIGNMENT ON")
            y = self.draw_centred_wrapped_text(topic, y_top-25, self.width-140, font_size=18)
            y -= 20
        else:
            self.c.setFont("Times-Bold", 20)
            self.c.drawCentredString(self.width/2, y_top-20, "Assignment")
            tw = self.c.stringWidth("Assignment", "Times-Bold", 20)
            self.c.setLineWidth(1)
            self.c.line(self.width/2 - (tw/2), y_top-23, self.width/2 + (tw/2), y_top-23)
            self.c.setLineWidth(0.5)
            y = y_top - 90
            
        items = [("Course Title", self.data.get('course_title', '')), 
                 ("Course Code", self.data.get('course_code', '')), 
                 ("Section", self.data.get('section', ''))]
        for label, val in items:
            self.c.setFont("Times-Bold", self.label_size)
            self.c.drawString(self.label_x, y, label)
            self.c.drawString(self.colon_x, y, ":")
            y = self.draw_dynamic_value(val, self.value_x, y)
            
        y = self.draw_submission_footer(y - 60)
        self.draw_inline_dates(y - 40)

    def render_group_project(self):
        template = self.data.get('template')
        is_term_paper = (template == 'term_paper')
        students = self.data.get('students', [])
        num_students = len(students) if students else 1
        
        is_compact = (num_students > 2)
        y_top_offset = 180 if is_compact else 210
        gap_title = 20 if is_compact else 30
        gap_topic = 25 if is_compact else 30
        gap_after_topic = 25 if is_compact else 50
        gap_course_item = 0 if is_compact else 8
        gap_footer = 20 if is_compact else 50
        gap_dates = 10 if is_compact else 30
        
        title_label = "TERM PAPER ON" if is_term_paper else "PROJECT REPORT ON"
        y = self.height - y_top_offset
        self.c.setFont("Times-Bold", 12)
        self.c.drawCentredString(self.width/2, y, title_label)
        
        y -= gap_title
        topic = self.data.get('topic', 'PROJECT TITLE')
        self.c.setLineWidth(1)
        self.c.line(self.margin + 20, y, self.width - (self.margin + 20), y)
        y -= gap_topic
        y = self.draw_centred_wrapped_text(topic, y, self.width-140, font_size=16)
        self.c.line(self.margin + 20, y+5, self.width - (self.margin + 20), y+5)
        self.c.setLineWidth(0.5)
        
        y -= gap_after_topic
        
        items = [
                 ("Course Title", self.data.get('course_title', '')), 
                 ("Course Code", self.data.get('course_code', '')), 
                 ("Section", self.data.get('section', '')),
                 ("Group No", self.data.get('group_no', ''))]
        
        if not is_term_paper:
            items = [("Course Code", self.data.get('course_code', '')), 
                     ("Course Title", self.data.get('course_title', '')), 
                     ("Section", self.data.get('section', '')),
                     ("Group No", self.data.get('group_no', ''))]
            
        if is_term_paper:
            box_top = y + 15
            temp_y = y
            for label, val in items:
                self.c.setFont("Times-Bold", self.label_size)
                self.c.drawString(self.label_x, temp_y, label)
                self.c.drawString(self.colon_x, temp_y, ":")
                temp_y = self.draw_dynamic_value(val, self.value_x, temp_y)
                temp_y -= gap_course_item
            box_bottom = temp_y + 5
            self.c.rect(self.margin + 20, box_bottom, self.width - (self.margin + 20)*2, box_top - box_bottom)
            y = temp_y
        else:
            for label, val in items:
                self.c.setFont("Times-Bold", self.label_size)
                self.c.drawString(self.label_x, y, label)
                self.c.drawString(self.colon_x, y, ":")
                y = self.draw_dynamic_value(val, self.value_x, y)
                y -= gap_course_item
        
        y = self.draw_submission_footer(y - gap_footer, is_group=True, is_term_paper=is_term_paper)
        self.draw_inline_dates(y - gap_dates)

    def draw_submission_footer(self, start_y, is_group=False, is_lab=False, is_term_paper=False):
        y = start_y
        self.c.setFont("Times-Bold", 12)
        footer_label = "SUBMITTED TO:"
        if is_term_paper:
            footer_label = "Submitted to:"
        elif is_lab:
            footer_label = "INSTRUCTOR"
            
        self.c.drawString(self.label_x, y, footer_label)
        tw = self.c.stringWidth(footer_label, "Times-Bold", 12)
        self.c.line(self.label_x, y-2, self.label_x+tw, y-2) 
        
        y -= 20
        self.c.setFont("Times-Bold", 13)
        self.c.drawString(self.label_x, y, self.data.get('teacher_name', ''))
        y -= self.line_height
        self.c.setFont("Times-Roman", 12)
        self.c.drawString(self.label_x, y, self.data.get('designation', ''))
        y -= self.line_height
        y = self.draw_dynamic_value(self.data.get('teacher_dept', ''), self.label_x, y, bold_val=False)
        self.c.drawString(self.label_x, y, "East West University")
        
        students = self.data.get('students', [])
        num_students = len(students) if students else 1
        is_compact = (is_group and num_students > 2)
        gap_before_by = 30 if is_compact else 50
        
        y -= gap_before_by
        self.c.setFont("Times-Bold", 12)
        footer_label_by = "SUBMITTED BY:"
        if is_term_paper:
            footer_label_by = "Submitted by:"
        elif is_group and not is_term_paper:
            footer_label_by = "PREPARED BY:"
            
        self.c.drawString(self.label_x, y, footer_label_by)
        tw_by = self.c.stringWidth(footer_label_by, "Times-Bold", 12)
        self.c.line(self.label_x, y-2, self.label_x+tw_by, y-2)
        
        students = self.data.get('students', [])
        if not students:
            students = [{'name': self.data.get('student_name', ''), 'id': self.data.get('student_id', ''), 
                         'program': self.data.get('program', ''), 'dept': self.data.get('student_dept', '')}]
        
        y -= 20
        for s in students:
            if not s.get('name'): continue
            block_start_y = y + 10 
            self.c.setFont("Times-Bold", 13)
            self.c.drawString(self.label_x, y, s.get('name'))
            y -= self.line_height
            # Student info values are NOT bold in web preview
            for label, val in [("ID", s.get('id', '')), ("Program", s.get('program', '')), ("Department", s.get('dept', ''))]:
                self.c.setFont("Times-Bold", self.label_size)
                self.c.drawString(self.label_x, y, label)
                self.c.drawString(self.colon_x, y, ":")
                y = self.draw_dynamic_value(val, self.value_x, y, bold_val=False)
            
            if is_group:
                if is_term_paper:
                    self.c.setStrokeColor(colors.black)
                else:
                    self.c.setStrokeColor(self.ewu_green)
                self.c.setLineWidth(2)
                self.c.line(self.label_x - 10, block_start_y, self.label_x - 10, y + self.line_height - 2)
                self.c.setStrokeColor(colors.black)
            y -= 5 
        return y
