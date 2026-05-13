import logging
import json
import tempfile
import os
import uuid
from supabase import create_client
from .ewumate_pdf_engine import EWUmatePDFEngine

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://jwygjihrbwxhehijldiz.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_SERVICE_KEY")

def handle(req_body):
    logging.info(f"PDF Handler triggered with template: {req_body.get('template')}")
    filename = "academic_report.pdf"

    try:
        # Create a temporary file to store the generated PDF
        with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_file:
            pdf_path = tmp_file.name

        # Initialize the engine and generate the PDF
        engine = EWUmatePDFEngine(pdf_path, req_body)
        engine.generate()

        # Read the generated PDF file
        with open(pdf_path, "rb") as f:
            pdf_data = f.read()

        # Clean up the temporary file
        os.remove(pdf_path)

        # For POST requests, we use the Supabase Storage flow
        # For GET requests (simple URL launch), we return the bytes directly
        # We can distinguish by looking for a specific key or just default to bytes if not catalog
        
        # Actually, let's look at the template. Catalog always uses storage.
        if req_body.get('template') == 'catalog':
            sb = create_client(SUPABASE_URL, SUPABASE_KEY)
            bucket_name = "temporary_pdfs"
            file_id = f"{uuid.uuid4()}.pdf"
            sb.storage.from_(bucket_name).upload(file_id, pdf_data, {"content-type": "application/pdf"})
            public_url = sb.storage.from_(bucket_name).get_public_url(file_id)
            return {"url": public_url}
        
        # Default: Return raw bytes (works for direct launchUrl in browser)
        return pdf_data

    except Exception as e:
        logging.error(f"Error generating PDF in API: {str(e)}")
        return {"error": f"Error generating PDF: {str(e)}"}
