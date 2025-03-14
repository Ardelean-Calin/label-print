# Make this use uv's script mode instead AI!
#!/usr/bin/env python3
"""
Script to print labels using brother_ql
"""

import sys
import os
import tempfile
import subprocess
import shutil
import argparse
from brother_ql.conversion import convert
from brother_ql.backends.helpers import send
from brother_ql.raster import BrotherQLRaster

def print_label(text, printer_path=None, dry_run=False):
    """
    Print a text label to the specified printer path
    
    If dry_run is True, only generate the image and open it for preview
    """
    
    # Create a temporary file for the label content
    with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp_file:
        tmp_path = tmp_file.name
    
    try:
        # Use the template.typ file with the text as input
        template_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "template.typ")
        font_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fonts")
        
        # Create a temporary file for the text content
        text_file = tempfile.NamedTemporaryFile(suffix='.txt', delete=False)
        text_file.write(text.encode('utf-8'))
        text_file.close()
        
        # Compile using the template and text input
        subprocess.run([
            "typst", "compile", 
            template_path, 
            tmp_path,
            "--font-path",
            font_path,
            "--input", f"text={text}"
        ], check=True)
        
        if dry_run:
            # In dry-run mode, copy the image to a temporary directory and open it
            temp_dir = tempfile.gettempdir()
            preview_path = os.path.join(temp_dir, "label_preview.png")
            shutil.copy(tmp_path, preview_path)
            print(f"Label preview generated at {preview_path}")
            
            # Try to open the image with the default viewer
            try:
                if os.name == 'posix':
                    subprocess.run(["xdg-open", preview_path], check=False)
                elif os.name == 'nt':
                    os.startfile(preview_path)
                elif os.name == 'darwin':
                    subprocess.run(["open", preview_path], check=False)
            except Exception as e:
                print(f"Could not open preview automatically: {e}")
                print(f"Please open {preview_path} manually to view the label")
        else:
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
        if 'text_file' in locals() and os.path.exists(text_file.name):
            os.unlink(text_file.name)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Print labels using brother_ql')
    parser.add_argument('text', help='Text to print on the label')
    parser.add_argument('--printer', dest='printer_path', default='/dev/usb/lp0', help='Path to the printer device (default: /dev/usb/lp0)')
    parser.add_argument('--dry-run', action='store_true', help='Generate preview without printing')

    args = parser.parse_args()

    print_label(args.text, args.printer_path, args.dry_run)
