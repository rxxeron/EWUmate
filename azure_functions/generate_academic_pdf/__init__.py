import logging
import azure.functions as func
import json
import tempfile
import os
import uuid
from supabase import create_client
from .ewumate_pdf_engine import EWUmatePDFEngine

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://jwygjihrbwxhehijldiz.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_SERVICE_KEY")

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('generate_academic_pdf trigger function processed a request.')

    try:
        if req.method == 'GET':
            data_param = req.params.get('data')
            if not data_param:
                return func.HttpResponse("Missing 'data' query parameter for GET request.", status_code=400)
            req_body = json.loads(data_param)
        else:
            req_body = req.get_json()
    except ValueError:
        return func.HttpResponse(
             "Invalid JSON.",
             status_code=400
        )

    # If it's a catalog request, use the provided courses
    if req_body.get('template') == 'catalog':
        semester = req_body.get('semester', 'Unknown Semester')
        courses = req_body.get('courses', [])
        
        if not courses:
            return func.HttpResponse("No course data provided for catalog.", status_code=400)
            
        filename = f"Course_Catalog_{semester.replace(' ', '_')}.pdf"
    else:
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

        # ─── New Flow: Upload to Supabase Storage and return URL ───
        # This avoids the URL length limit and allows for large JSON payloads
        if req.method == 'POST' or req_body.get('template') == 'catalog':
            try:
                sb = create_client(SUPABASE_URL, SUPABASE_KEY)
                bucket_name = "temporary_pdfs"
                file_id = f"{uuid.uuid4()}.pdf"
                
                # Upload to Supabase
                sb.storage.from_(bucket_name).upload(file_id, pdf_data, {"content-type": "application/pdf"})
                
                # Get public URL
                public_url = sb.storage.from_(bucket_name).get_public_url(file_id)
                
                return func.HttpResponse(
                    json.dumps({"url": public_url}),
                    status_code=200,
                    mimetype="application/json"
                )
            except Exception as storage_err:
                logging.error(f"Storage upload failed: {storage_err}")
                # Fallback to direct response if storage fails (might still fail on client due to size)
        
        # Return the PDF as the response (Fallback / GET mode)
        return func.HttpResponse(
            pdf_data,
            mimetype="application/pdf",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
                "Access-Control-Allow-Origin": "*"
            }
        )

    except Exception as e:
        logging.error(f"Error generating PDF: {str(e)}")
        return func.HttpResponse(
             f"Error generating PDF: {str(e)}",
             status_code=500
        )
