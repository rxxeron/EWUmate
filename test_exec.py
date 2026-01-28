
import sys
import os

with open("execution_test.txt", "w") as f:
    f.write(f"Python executable: {sys.executable}\n")
    f.write(f"CWD: {os.getcwd()}\n")
    f.write(f"Files: {os.listdir('.')}\n")

print("Execution test complete.")
