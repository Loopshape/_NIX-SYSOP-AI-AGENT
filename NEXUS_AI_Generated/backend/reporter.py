from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfgen import canvas
from reportlab.lib import colors
import os

def generate_report(data, filename="nexus_report.pdf"):
    c = canvas.Canvas(filename, pagesize=landscape(A4))
    width, height = landscape(A4)
    
    # Header
    c.setFont("Helvetica-Bold", 24)
    c.setStrokeColor(colors.teal)
    c.drawString(50, height - 50, "NEXUS-AI Operational Intelligence Report")
    
    c.setFont("Helvetica", 12)
    c.drawString(50, height - 70, f"System Integrity: STABLE | Node: {os.uname().nodename}")
    
    # Body
    c.line(50, height - 80, width - 50, height - 80)
    
    y = height - 120
    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, y, "Agent Consensus & Reasoning")
    y -= 30
    
    c.setFont("Helvetica", 10)
    for entry in data.get('swarm_results', []):
        c.drawString(60, y, f"Agent {entry['agent']}: Entropy {entry['entropy']:.4f}")
        y -= 15
        text = entry['response'][:150] + "..." if len(entry['response']) > 150 else entry['response']
        c.drawString(80, y, text)
        y -= 25
        if y < 100:
            c.showPage()
            y = height - 50
            
    c.save()
    return filename

if __name__ == "__main__":
    # Test report
    sample_data = {
        'swarm_results': [
            {'agent': 'CORE', 'entropy': 4.5, 'response': 'Logical analysis of the DOM structure indicates...'},
            {'agent': 'SIGN', 'entropy': 5.1, 'response': 'Pattern detected in the user interaction flow...'}
        ]
    }
    generate_report(sample_data, "test_report.pdf")
