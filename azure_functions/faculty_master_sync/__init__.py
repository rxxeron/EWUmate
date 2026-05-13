import datetime
import logging
import azure.functions as func
from ..scraper_utils import run_faculty_master_sync

def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc).isoformat()

    if mytimer.past_due:
        logging.info('The faculty master sync timer is past due!')

    logging.info('Faculty Master Sync Timer Triggered at %s', utc_timestamp)
    
    result = run_faculty_master_sync()
    
    if result.get("status") == "success":
        logging.info("Faculty Master Sync Completed Successfully.")
    else:
        logging.error("Faculty Master Sync Failed: %s", result.get("error"))
