import sys
import os
from dotenv import load_dotenv

load_dotenv()

# Add azure_functions to path
sys.path.append(os.path.join(os.getcwd(), "azure_functions"))

from snapshot_utils import run_automated_snapshot

print("Starting manual snapshot for Summer 2026...")
try:
    run_automated_snapshot("Summer 2026")
    print("Snapshot process finished.")
except Exception as e:
    print(f"Error during snapshot: {e}")
