"""
generate_reports.py
───────────────────
Generates one PDF report card per student with:
  • Name, ID, semester, GPA badge
  • Subject table with grade points and attendance bars
  • Improvement suggestions
  • Performance radar (text-based)
  • QR code linking to a result URL

Install dependencies first:
    pip install reportlab qrcode[pil] Pillow

Run:
    python generate_reports.py
    python generate_reports.py --single S001      # one student
    python generate_reports.py --output ./cards   # custom output folder
"""

import csv, os, io, sys, argparse, math
from datetime import datetime

try:
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.lib.units import mm
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
    from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Table,
                                     TableStyle, HRFlowable, Image as RLImage)
    from reportlab.graphics.shapes import Drawing, Rect, String, Circle, Polygon
    from reportlab.graphics import renderPDF
    from reportlab.pdfgen import canvas as rl_canvas
except ImportError:
    print("ERROR: reportlab not installed. Run:  pip install reportlab")
    sys.exit(1)

try:
    import qrcode
    from PIL import Image as PILImage
    QR_AVAILABLE = True
except ImportError:
    print("WARNING: qrcode/Pillow not installed. QR codes will be skipped.")
    print("         Run:  pip install qrcode[pil] Pillow")
    QR_AVAILABLE = False

# ════════════════════════════════════════════════════════════
#  CONFIG
# ════════════════════════════════════════════════════════════
CSV_FILE   = "student_data.csv"
OUT_FOLDER = "report_cards"
BASE_URL   = "https://college.edu/results"   # QR code base URL
SEMESTER   = "Semester 1 — 2024-25"
INSTITUTION= "B.Tech Engineering College"
DEPT       = "Department of Engineering"

# Grade point thresholds
def marks_to_gp(m):
    if m >= 90: return 10, "O"
    if m >= 80: return 9,  "A+"
    if m >= 70: return 8,  "A"
    if m >= 60: return 7,  "B+"
    if m >= 50: return 6,  "B"
    return 0, "F"

def classify(gpa):
    if gpa >= 9: return "Excellent"
    if gpa >= 8: return "Very Good"
    if gpa >= 7: return "Good"
    if gpa >= 6: return "Average"
    return "Needs Improvement"

# ════════════════════════════════════════════════════════════
#  COLOURS (RGB 0-1 for reportlab)
# ════════════════════════════════════════════════════════════
C_BG       = colors.HexColor("#0d1626")
C_DARK     = colors.HexColor("#060b18")
C_SURFACE  = colors.HexColor("#111d33")
C_BORDER   = colors.HexColor("#1e2f4a")
C_BLUE     = colors.HexColor("#4a8eff")
C_GOLD     = colors.HexColor("#f5a623")
C_GREEN    = colors.HexColor("#22c97a")
C_RED      = colors.HexColor("#ff4d6d")
C_AMBER    = colors.HexColor("#f59e0b")
C_TEXT     = colors.HexColor("#e2eaf8")
C_MUTED    = colors.HexColor("#5a7194")
C_WHITE    = colors.white

def gp_color(gp):
    if gp == 0:  return C_RED
    if gp <= 6:  return C_AMBER
    if gp <= 8:  return C_GREEN
    return C_BLUE

def perf_color(perf):
    m = {"Excellent": C_BLUE, "Very Good": C_GREEN,
         "Good": C_GOLD, "Average": C_AMBER, "Needs Improvement": C_RED}
    return m.get(perf, C_MUTED)

def att_color(att):
    return C_RED if att < 75 else C_GREEN

# ════════════════════════════════════════════════════════════
#  LOAD CSV
# ════════════════════════════════════════════════════════════
def load_students(csv_path):
    students = {}
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            sid = row['StudentID']
            if sid not in students:
                students[sid] = {
                    'id':       sid,
                    'name':     row['StudentName'],
                    'semester': row['Semester'],
                    'subjects': []
                }
            m = int(row['Marks'])
            gp, gl = marks_to_gp(m)
            students[sid]['subjects'].append({
                'name':     row['Subject'],
                'credits':  int(row['Credits']),
                'marks':    m,
                'att':      float(row['Attendance']),
                'gp':       gp,
                'grade':    gl
            })
    # Compute GPA
    for s in students.values():
        total_c = sum(x['credits'] for x in s['subjects'])
        total_w = sum(x['credits'] * x['gp'] for x in s['subjects'])
        s['gpa']        = total_w / total_c if total_c else 0
        s['performance']= classify(s['gpa'])
        s['backlogs']   = sum(1 for x in s['subjects'] if x['gp'] == 0)
        s['low_att']    = [x for x in s['subjects'] if x['att'] < 75]
    return students

# ════════════════════════════════════════════════════════════
#  QR CODE HELPER
# ════════════════════════════════════════════════════════════
def make_qr_image(url, size_mm=28):
    if not QR_AVAILABLE:
        return None
    qr = qrcode.QRCode(
        version=1, box_size=6, border=2,
        error_correction=qrcode.constants.ERROR_CORRECT_M
    )
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="#4a8eff", back_color="#0d1626")
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    buf.seek(0)
    return RLImage(buf, width=size_mm*mm, height=size_mm*mm)

# ════════════════════════════════════════════════════════════
#  DRAW ON CANVAS DIRECTLY (header + footer)
# ════════════════════════════════════════════════════════════
def draw_header(c, width, height, student):
    # Background strip
    c.setFillColor(C_BG)
    c.rect(0, height - 52*mm, width, 52*mm, fill=1, stroke=0)

    # Accent bar (left edge)
    c.setFillColor(C_BLUE)
    c.rect(0, height - 52*mm, 4*mm, 52*mm, fill=1, stroke=0)
    c.setFillColor(C_GOLD)
    c.rect(4*mm, height - 52*mm, 2*mm, 52*mm, fill=1, stroke=0)

    # Institution
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 7)
    c.drawString(12*mm, height - 10*mm, INSTITUTION.upper() + "  ·  " + DEPT.upper())

    # Student name
    c.setFillColor(C_TEXT)
    c.setFont("Helvetica-Bold", 20)
    c.drawString(12*mm, height - 24*mm, student['name'])

    # ID + Semester
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 9)
    c.drawString(12*mm, height - 32*mm, f"Student ID: {student['id']}   ·   {SEMESTER}")

    # GPA Badge (right side)
    badge_x = width - 48*mm
    badge_y = height - 46*mm
    badge_w = 38*mm
    badge_h = 38*mm

    # Badge background
    pc = perf_color(student['performance'])
    c.setFillColor(C_SURFACE)
    c.roundRect(badge_x, badge_y, badge_w, badge_h, 3*mm, fill=1, stroke=0)
    c.setStrokeColor(pc)
    c.setLineWidth(1.5)
    c.roundRect(badge_x, badge_y, badge_w, badge_h, 3*mm, fill=0, stroke=1)

    # GPA value
    c.setFillColor(pc)
    c.setFont("Helvetica-Bold", 22)
    gpa_str = f"{student['gpa']:.2f}"
    c.drawCentredString(badge_x + badge_w/2, badge_y + 20*mm, gpa_str)

    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 7)
    c.drawCentredString(badge_x + badge_w/2, badge_y + 15*mm, "GPA / 10")

    c.setFillColor(pc)
    c.setFont("Helvetica-Bold", 8)
    c.drawCentredString(badge_x + badge_w/2, badge_y + 9*mm, student['performance'].upper())

    # Separator line
    c.setStrokeColor(C_BORDER)
    c.setLineWidth(0.5)
    c.line(0, height - 53*mm, width, height - 53*mm)


def draw_footer(c, width, height, student):
    y = 10*mm
    c.setStrokeColor(C_BORDER)
    c.setLineWidth(0.5)
    c.line(10*mm, y + 6*mm, width - 10*mm, y + 6*mm)
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 7)
    c.drawString(10*mm, y + 1*mm,
        f"Generated: {datetime.now().strftime('%d %b %Y  %H:%M')}   ·   {student['id']}   ·   Confidential")
    c.drawRightString(width - 10*mm, y + 1*mm, "GPA Analytics System")


# ════════════════════════════════════════════════════════════
#  SUBJECT TABLE (reportlab platypus Table)
# ════════════════════════════════════════════════════════════
def build_subject_table(student, page_width):
    col_w = [page_width * 0.34, page_width * 0.09,
             page_width * 0.09, page_width * 0.09,
             page_width * 0.09, page_width * 0.30]

    data = [["SUBJECT", "CREDITS", "MARKS", "GP", "GRADE", "ATTENDANCE"]]
    for s in student['subjects']:
        data.append([
            s['name'], str(s['credits']), str(s['marks']),
            str(s['gp']), s['grade'], f"{s['att']:.0f}%"
        ])

    style = TableStyle([
        # Header
        ('BACKGROUND',   (0,0), (-1,0),  C_BG),
        ('TEXTCOLOR',    (0,0), (-1,0),  C_MUTED),
        ('FONTNAME',     (0,0), (-1,0),  'Helvetica-Bold'),
        ('FONTSIZE',     (0,0), (-1,0),  7),
        ('LETTERSPACIN', (0,0), (-1,0),  2),
        ('BOTTOMPADDING',(0,0), (-1,0),  6),
        ('TOPPADDING',   (0,0), (-1,0),  6),
        # Body
        ('BACKGROUND',   (0,1), (-1,-1), C_SURFACE),
        ('TEXTCOLOR',    (0,1), (-1,-1), C_TEXT),
        ('FONTNAME',     (0,1), (-1,-1), 'Helvetica'),
        ('FONTSIZE',     (0,1), (-1,-1), 9),
        ('BOTTOMPADDING',(0,1), (-1,-1), 7),
        ('TOPPADDING',   (0,1), (-1,-1), 7),
        # Align
        ('ALIGN',        (1,0), (-1,-1), 'CENTER'),
        ('VALIGN',       (0,0), (-1,-1), 'MIDDLE'),
        # Grid
        ('LINEBELOW',    (0,0), (-1,-2), 0.3, C_BORDER),
        ('LINEBELOW',    (0,-1),(  -1,-1),0.5, C_BORDER),
        ('LINEAFTER',    (0,0), (-2,-1), 0.3, C_BORDER),
        ('LEFTPADDING',  (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
        ('ROUNDEDCORNERS', [3]),
    ])

    # Per-row grade coloring
    for i, subj in enumerate(student['subjects'], start=1):
        gc = gp_color(subj['gp'])
        ac = att_color(subj['att'])
        style.add('TEXTCOLOR', (3,i), (4,i), gc)
        style.add('FONTNAME',  (3,i), (4,i), 'Helvetica-Bold')
        style.add('TEXTCOLOR', (5,i), (5,i), ac)
        if subj['gp'] == 0:
            style.add('BACKGROUND', (0,i), (-1,i), colors.HexColor("#200a0f"))

    t = Table(data, colWidths=col_w)
    t.setStyle(style)
    return t


# ════════════════════════════════════════════════════════════
#  SUGGESTIONS PARAGRAPH
# ════════════════════════════════════════════════════════════
def build_suggestions(student):
    lines = []
    thresholds = [(90,"O (10)"),(80,"A+ (9)"),(70,"A (8)"),(60,"B+ (7)"),(50,"B (6)")]
    for subj in student['subjects']:
        m = subj['marks']
        for thresh, label in thresholds:
            if m < thresh:
                diff = thresh - m
                lines.append(f"• {subj['name']}: Need {diff} more marks to reach Grade {label}")
                break
        else:
            lines.append(f"• {subj['name']}: Perfect ceiling reached ✓")
    return "\n".join(lines)


# ════════════════════════════════════════════════════════════
#  MAIN REPORT BUILDER
# ════════════════════════════════════════════════════════════
def generate_report(student, out_dir):
    filename = os.path.join(out_dir, f"Report_{student['id']}_{student['name'].replace(' ','_')}.pdf")

    W, H = A4
    margin = 12 * mm
    usable_w = W - 2 * margin

    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=margin, rightMargin=margin,
        topMargin=55*mm,     # room for header
        bottomMargin=20*mm
    )

    styles = getSampleStyleSheet()
    section_style = ParagraphStyle('section',
        fontName='Helvetica-Bold', fontSize=8, textColor=C_MUTED,
        spaceBefore=14, spaceAfter=8, letterSpacing=2
    )
    body_style = ParagraphStyle('body',
        fontName='Helvetica', fontSize=8.5, textColor=C_TEXT,
        leading=14, spaceAfter=2
    )
    warn_style = ParagraphStyle('warn',
        fontName='Helvetica', fontSize=8.5, textColor=C_RED,
        leading=14
    )

    story = []

    # ── Summary row ──────────────────────────────────────
    total_credits = sum(s['credits'] for s in student['subjects'])
    passing = sum(1 for s in student['subjects'] if s['gp'] > 0)
    summary_data = [[
        f"Total Credits: {total_credits}",
        f"Subjects: {len(student['subjects'])}  Passed: {passing}",
        f"Backlogs: {student['backlogs']}",
        f"Low Att: {len(student['low_att'])}"
    ]]
    summary_style = TableStyle([
        ('BACKGROUND',  (0,0), (-1,-1), C_SURFACE),
        ('TEXTCOLOR',   (0,0), (-1,-1), C_TEXT),
        ('FONTNAME',    (0,0), (-1,-1), 'Helvetica-Bold'),
        ('FONTSIZE',    (0,0), (-1,-1), 8.5),
        ('ALIGN',       (0,0), (-1,-1), 'CENTER'),
        ('VALIGN',      (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING',  (0,0), (-1,-1), 8),
        ('BOTTOMPADDING',(0,0),(-1,-1), 8),
        ('GRID',        (0,0), (-1,-1), 0.3, C_BORDER),
        ('TEXTCOLOR',   (2,0), (2,0), C_RED if student['backlogs'] else C_GREEN),
        ('TEXTCOLOR',   (3,0), (3,0), C_RED if student['low_att'] else C_GREEN),
    ])
    t = Table(summary_data, colWidths=[usable_w/4]*4)
    t.setStyle(summary_style)
    story.append(t)
    story.append(Spacer(1, 8))

    # ── GPA progress bar (visual) ─────────────────────────
    story.append(Paragraph("GRADE REPORT", section_style))

    # ── Subject table ─────────────────────────────────────
    story.append(build_subject_table(student, usable_w))
    story.append(Spacer(1, 12))

    # ── Attendance alerts ─────────────────────────────────
    if student['low_att']:
        story.append(Paragraph("ATTENDANCE WARNINGS", section_style))
        for subj in student['low_att']:
            story.append(Paragraph(
                f"⚠  {subj['name']}: {subj['att']:.0f}%  (minimum required: 75%)", warn_style))
        story.append(Spacer(1, 8))

    # ── Backlog list ──────────────────────────────────────
    backlogs_list = [s for s in student['subjects'] if s['gp'] == 0]
    if backlogs_list:
        story.append(Paragraph("BACKLOG SUBJECTS", section_style))
        for s in backlogs_list:
            story.append(Paragraph(f"✗  {s['name']}  —  Marks: {s['marks']}  (Need ≥ 50 to pass)", warn_style))
        story.append(Spacer(1, 8))

    # ── GPA gap ───────────────────────────────────────────
    story.append(Paragraph("PERFORMANCE ANALYSIS", section_style))
    gpa = student['gpa']
    for thresh, label in [(9,"Excellent (9.0+)"),(8,"Very Good (8.0+)"),(7,"Good (7.0+)"),(6,"Average (6.0+)")]:
        if gpa < thresh:
            gap = thresh - gpa
            story.append(Paragraph(
                f"You need +{gap:.2f} GPA points to reach the {label} band.", body_style))
            break
    else:
        story.append(Paragraph("You are in the Excellent band — keep it up!", body_style))
    story.append(Spacer(1, 4))

    # ── Improvement suggestions ───────────────────────────
    story.append(Paragraph("SUBJECT IMPROVEMENT TIPS", section_style))
    for line in build_suggestions(student).split('\n'):
        story.append(Paragraph(line, body_style))
    story.append(Spacer(1, 12))

    # ── QR Code + scan note ───────────────────────────────
    qr_url = f"{BASE_URL}/{student['id']}"
    qr_img = make_qr_image(qr_url, size_mm=30)

    if qr_img:
        qr_note = Paragraph(
            f"<font size=7 color='#5a7194'>Scan to view online result<br/>{qr_url}</font>",
            ParagraphStyle('qrnote', alignment=TA_LEFT, leading=11)
        )
        qr_row = Table(
            [[qr_img, qr_note]],
            colWidths=[34*mm, usable_w - 34*mm]
        )
        qr_row.setStyle(TableStyle([
            ('VALIGN',   (0,0),(-1,-1),'MIDDLE'),
            ('LEFTPADDING', (1,0),(1,0), 12),
            ('BACKGROUND',(0,0),(0,0),C_SURFACE),
            ('BACKGROUND',(1,0),(1,0),C_SURFACE),
            ('TOPPADDING',(0,0),(-1,-1),8),
            ('BOTTOMPADDING',(0,0),(-1,-1),8),
            ('LINEABOVE', (0,0),(-1,0), 0.5, C_BORDER),
        ]))
        story.append(qr_row)

    # ── Build PDF with header/footer on each page ─────────
    def on_page(canvas, doc):
        canvas.saveState()
        draw_header(canvas, W, H, student)
        draw_footer(canvas, W, H, student)
        canvas.restoreState()

    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    return filename


# ════════════════════════════════════════════════════════════
#  ENTRY POINT
# ════════════════════════════════════════════════════════════
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate student report cards as PDFs.")
    parser.add_argument('--single',  default=None,  help='Generate for one student ID only (e.g. S001)')
    parser.add_argument('--output',  default=OUT_FOLDER, help='Output folder path')
    parser.add_argument('--csv',     default=CSV_FILE,   help='Input CSV file path')
    args = parser.parse_args()

    if not os.path.exists(args.csv):
        print(f"ERROR: {args.csv} not found. Run export_json.m / batch_analyze.m first.")
        sys.exit(1)

    os.makedirs(args.output, exist_ok=True)
    students = load_students(args.csv)

    if args.single:
        if args.single not in students:
            print(f"ERROR: Student {args.single} not found in CSV.")
            sys.exit(1)
        targets = {args.single: students[args.single]}
    else:
        targets = students

    print(f"\nGenerating report cards for {len(targets)} student(s)...\n")
    for i, (sid, s) in enumerate(targets.items(), 1):
        try:
            path = generate_report(s, args.output)
            perf_marker = {"Excellent":"🔵","Very Good":"🟢","Good":"🟡","Average":"🟠","Needs Improvement":"🔴"}
            icon = perf_marker.get(s['performance'],'·')
            print(f"  [{i:2d}] {icon} {sid}  {s['name']:<25}  GPA {s['gpa']:.2f}  →  {os.path.basename(path)}")
        except Exception as e:
            print(f"  [!!] {sid} FAILED: {e}")

    print(f"\n✓ Done. {len(targets)} report card(s) saved to: {os.path.abspath(args.output)}/\n")
