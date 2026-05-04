from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.units import inch
from datetime import datetime

def generate_course_pdf(data, semester, output_path):
    doc = SimpleDocTemplate(output_path, pagesize=A4, rightMargin=30, leftMargin=30, topMargin=30, bottomMargin=30)
    elements = []
    styles = getSampleStyleSheet()
    
    # Custom Header Style (Blue Box)
    header_box_style = TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#E3F2FD")),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('ROUNDEDCORNERS', [10, 10, 10, 10]),
    ])
    
    title_style = ParagraphStyle(
        'HeaderTitle',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor("#1C4370"),
        alignment=1, # Center
        spaceAfter=5
    )
    
    subtitle_style = ParagraphStyle(
        'HeaderSubtitle',
        parent=styles['Normal'],
        fontSize=10,
        textColor=colors.HexColor("#546E7A"),
        alignment=1,
        spaceAfter=2
    )
    
    footer_style = ParagraphStyle(
        'HeaderFooter',
        parent=styles['Normal'],
        fontSize=9,
        textColor=colors.HexColor("#42A5F5"),
        alignment=1,
        fontName='Helvetica-Oblique'
    )
    
    # Build Header
    now_str = datetime.now().strftime('%m/%d/%Y, %I:%M:%S %p')
    header_content = [
        [Paragraph("<b>East West University</b>", title_style)],
        [Paragraph(f"Offered Courses ({semester})  Updated ({now_str}) by rxxeron", subtitle_style)],
        [Paragraph("Generated from EWUmate Application", footer_style)]
    ]
    
    header_table = Table(header_content, colWidths=[7.5 * inch])
    header_table.setStyle(header_box_style)
    elements.append(header_table)
    elements.append(Spacer(1, 0.2 * inch))
    
    # Data Table
    table_data = [["Course", "Section", "Faculty", "Timing", "Room", "Capacity"]]
    for item in data:
        table_data.append([
            item.get("course", ""),
            item.get("section", ""),
            item.get("faculty", ""),
            item.get("timing", ""),
            item.get("room", ""),
            item.get("capacity", "")
        ])
    
    # Optimized Table Sizing
    col_widths = [1.2*inch, 0.6*inch, 0.8*inch, 2.5*inch, 1.2*inch, 1.0*inch]
    t = Table(table_data, repeatRows=1, colWidths=col_widths)
    
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#1C4370")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 10),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.white),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('FONTSIZE', (0, 1), (-1, -1), 9),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F5F5")]),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    
    elements.append(t)
    doc.build(elements)
    return output_path

if __name__ == "__main__":
    # Test logic
    sample_data = [
        {"course": "CSE101", "section": "1", "faculty": "TZE", "timing": "M 08:30 AM - 10:00 AM", "room": "AB2-502", "capacity": "35/35"},
        {"course": "CSE101", "section": "2", "faculty": "RIFAT", "timing": "T 10:00 AM - 11:30 AM", "room": "AB2-202", "capacity": "30/35"}
    ]
    generate_course_pdf(sample_data, "Summer-2026", "test_report.pdf")
