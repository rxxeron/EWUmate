import logging
import azure.functions as func
import json
import sys
import os

# Add root to path for imports
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from scraper_utils import run_sync

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Portal Sync Triggered via HTTP.')
    is_preview = req.params.get('preview') == 'true'
    custom_semester = req.params.get('semester')
    
    try:
        result = run_sync(custom_semester, is_preview)
        
        status_code = 200
        if result.get("status") == "error":
            if "Login Failed" in result.get("error", ""):
                status_code = 401
            else:
                status_code = 500
                
        return func.HttpResponse(json.dumps(result), status_code=status_code, mimetype="application/json")
    except Exception as e:
        logging.exception("Error in portal_sync_trigger")
        return func.HttpResponse(json.dumps({"status": "error", "error": str(e)}), status_code=500, mimetype="application/json")
