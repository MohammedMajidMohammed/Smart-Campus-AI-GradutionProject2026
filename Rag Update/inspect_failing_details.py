
import sys
import io
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"C:\Users\Right Click\.gemini\antigravity\brain\cf0ea8bc-79f2-4638-b749-b5e8c92f36dd\.system_generated\tasks\task-1747.log", "r", encoding="utf-8") as f:
    log = f.read()

parts = log.split("==================================================")
for idx, part in enumerate(parts):
    if "TESTING FACULTY: العلاج الطبيعي" in part:
        print("\n=== PHYSICAL THERAPY DETAILED OUTPUT ===")
        # Print the next part which contains the output
        if idx + 1 < len(parts):
            print(parts[idx + 1].strip())
    if "TESTING FACULTY: الطب البشري" in part:
        print("\n=== MEDICINE DETAILED OUTPUT ===")
        # Print the next part which contains the output
        if idx + 1 < len(parts):
            print(parts[idx + 1].strip())
