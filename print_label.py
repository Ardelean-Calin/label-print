#!/usr/bin/env python3
"""
Script to print labels using brother_ql
"""

import sys
import os
import tempfile
import subprocess
from brother_ql.conversion import convert
from brother_ql.backends.helpers import send
from brother_ql.raster import BrotherQLRaster

def print_label(text, printer_path):
    """Print a text label to the specified printer path"""
    
    # Create a temporary file for the label content
    with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp_file:
        tmp_path = tmp_file.name
    
    try:
        # Generate a PNG with the text using typst
        typst_content = f"""
        #set page(width: 62mm, height: 12mm, margin: 1mm)
        #set text(font: "Iosevka Aile", size: 10pt)
        #align(center + horizon)[
          #text(weight: "bold")[{text}]
        ]
        """
        
        typst_file = tempfile.NamedTemporaryFile(suffix='.typ', delete=False)
        typst_file.write(typst_content.encode('utf-8'))
        typst_file.close()
        
        subprocess.run(["typst", "compile", typst_file.name, tmp_path], check=True)
        
        # Print the generated image using brother_ql
        qlr = BrotherQLRaster('QL-800')
        qlr.exception_on_warning = True
        
        convert(
            qlr=qlr,
            images=[tmp_path],
            label='12',
            rotate='0',
            threshold=70,
            dither=False,
            compress=False,
            red=False,
            dpi_600=True,
            hq=True,
        )
        
        send(
            instructions=qlr.data,
            printer_identifier=printer_path,
            backend_identifier='linux_kernel',
            blocking=True,
        )
        
        print(f"Label printed successfully to {printer_path}")
        
    except Exception as e:
        print(f"Error printing label: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        # Clean up temporary files
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        if os.path.exists(typst_file.name):
            os.unlink(typst_file.name)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python print_label.py TEXT PRINTER_PATH")
        sys.exit(1)
    
    text = sys.argv[1]
    printer_path = sys.argv[2]
    print_label(text, printer_path)
