#!/bin/env python3

from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfgen import canvas
from reportlab.lib.units import cm
from reportlab.platypus import Image, Paragraph, Frame, SimpleDocTemplate, Spacer, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from PyPDF2 import PdfMerger
import os

# -----------------------------
# Configuration
# -----------------------------
OUTPUT_DIR = "./nexus_pdf_sections"
FINAL_PDF = "./NEXUS_AI_Full_System.pdf"
SECTION_NAMES = [
    "00_Intro",
    "01_Architecture",
    "02_Agent_Logic",
    "03_Dashboard_UI",
    "04_Memory_Graphs",
    "05_Heatmaps",
    "06_Use_Cases",
    "07_Education",
    "08_Styleguide",
    "09_Conclusion"
]
IMAGES_DIR = "./assets/images"  # Pre-rendered screenshots / graphs / heatmaps

os.makedirs(OUTPUT_DIR, exist_ok=True)
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='Header', fontSize=22, leading=26, spaceAfter=10, alignment=1, textColor=colors.HexColor("#00FF00")))
styles.add(ParagraphStyle(name='SubHeader', fontSize=16, leading=20, spaceAfter=8, textColor=colors.HexColor("#00FF00")))
styles.add(ParagraphStyle(name='Body', fontSize=12, leading=16, textColor=colors.white))

# -----------------------------
# Helper Functions
# -----------------------------
def add_text(c, text, x, y, max_width):
    """Add multi-line paragraph text to canvas"""
    para = Paragraph(text, styles['Body'])
    f = Frame(x, y, max_width, 18*cm, showBoundary=0)
    f.addFromList([para], c)

def add_image(c, path, x, y, width, height):
    """Add image to canvas if exists"""
    if os.path.exists(path):
        img = Image(path, width=width, height=height)
        f = Frame(x, y, width, height, showBoundary=0)
        f.addFromList([img], c)

def create_section_pdf(section_name, title_text, body_texts=[], image_files=[]):
    """Create individual section PDF"""
    filename = os.path.join(OUTPUT_DIR, f"{section_name}.pdf")
    c = canvas.Canvas(filename, pagesize=landscape(A4))
    width, height = landscape(A4)

    # Header
    c.setFillColor(colors.HexColor("#00FF00"))
    c.setFont("Helvetica-Bold", 28)
    c.drawCentredString(width/2, height-2*cm, f"NEXUS AI - {title_text}")

    y_position = height - 4*cm
    max_text_width = width - 4*cm

    # Body texts
    for text in body_texts:
        add_text(c, text, 2*cm, y_position, max_text_width)
        y_position -= 4*cm

    # Images
    img_width = (width - 4*cm)
    img_height = 10*cm
    for img_file in image_files:
        add_image(c, os.path.join(IMAGES_DIR, img_file), 2*cm, y_position-img_height, img_width, img_height)
        y_position -= (img_height + 1*cm)

    c.showPage()
    c.save()
    return filename

# -----------------------------
# Generate Section PDFs
# -----------------------------
section_files = []
for idx, section in enumerate(SECTION_NAMES):
    # Placeholder example content
    title = section.replace("_", " ")
    body = [f"This section covers {title}. Detailed technical explanations, diagrams, and UI mockups will be displayed here."]
    images = [f"{section}_example.png"] if os.path.exists(os.path.join(IMAGES_DIR, f"{section}_example.png")) else []
    
    pdf_file = create_section_pdf(section, title, body, images)
    section_files.append(pdf_file)

# -----------------------------
# Merge all sections into final PDF
# -----------------------------
merger = PdfMerger()
for f in section_files:
    merger.append(f)
merger.write(FINAL_PDF)
merger.close()

print(f"✅ Full NEXUS AI PDF generated: {FINAL_PDF}")

