
import sys
import io
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"C:\Users\Right Click\.gemini\antigravity\brain\cf0ea8bc-79f2-4638-b749-b5e8c92f36dd\.system_generated\tasks\task-1747.log", "r", encoding="utf-8") as f:
    log = f.read()

parts = log.split("==================================================")
for part in parts:
    if "TESTING FACULTY:" in part or "STATUS:" in part:
        print("\n==================================================")
        lines = part.strip().split('\n')
        if len(lines) <= 20:
            print('\n'.join(lines))
        else:
            print('\n'.join(lines[:10]))
            print("...")
            print('\n'.join(lines[-15:]))
