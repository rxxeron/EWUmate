import os
import sys
import unittest.mock as mock

# Mock azure.functions
sys.modules['azure'] = mock.MagicMock()
sys.modules['azure.functions'] = mock.MagicMock()

import logging
logging.basicConfig(level=logging.INFO)

# Set env vars manually for the script from the root .env
from dotenv import load_dotenv
load_dotenv(os.path.join(os.getcwd(), '..', '.env'))

# Also set the expected keys for scraper_utils
os.environ["SUPABASE_URL"] = os.getenv("SUPABASE_URL", "")
os.environ["SUPABASE_SERVICE_ROLE_KEY"] = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

sys.path.append(os.getcwd())

from scraper_utils import run_faculty_master_sync

print("Triggering Manual Faculty Master Sync + Snapshot (Local Mock)...")
result = run_faculty_master_sync()
print(f"Result: {result}")
