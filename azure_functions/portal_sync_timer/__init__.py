import datetime
import logging
import azure.functions as func
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from scraper_utils import run_sync

def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc).isoformat()

    if mytimer.past_due:
        logging.info('The timer is past due!')

    logging.info('Portal Sync Timer Triggered at %s', utc_timestamp)
    
    # [NEW] Weekly Faculty Master Sync (Every Sunday)
    if datetime.datetime.utcnow().weekday() == 6:
        logging.info("Sunday detected: Running Weekly Faculty Master Sync...")
        try:
            from scraper_utils import run_faculty_master_sync
            run_faculty_master_sync()
        except Exception as e:
            logging.error(f"Weekly Faculty Master Sync failed: {e}")

    # Run the sync process in full (non-preview mode)
    result = run_sync(is_preview=False)
    
    if result.get("status") == "success":
        logging.info("Portal Sync Timer Completed Successfully: %s", result.get("report"))
        
        # ─── Automated Faculty Snapshot ──────────────────────────────────
        try:
            from snapshot_utils import run_automated_snapshot
            # We assume the last semester in the report is the one to snapshot
            # or we can pull it from scraper_config.
            sb_url = os.environ.get("SUPABASE_URL")
            sb_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_SERVICE_KEY")
            sb = create_client(sb_url, sb_key)
            config = sb.table("scraper_config").select("target_semesters").execute()
            if config.data:
                sems = [s.strip() for s in config.data[0].get("target_semesters", "").split(",")]
                for sem in sems:
                    run_automated_snapshot(sem)
        except Exception as e:
            logging.error(f"Post-sync snapshot failed: {e}")
        # ────────────────────────────────────────────────────────────────
    else:
        logging.error("Portal Sync Timer Failed: %s", result.get("error"))
