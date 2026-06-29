
import sys
import io
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"C:\Users\Right Click\.gemini\antigravity\brain\cf0ea8bc-79f2-4638-b749-b5e8c92f36dd\.system_generated\tasks\task-1747.log", "r", encoding="utf-8") as f:
    log = f.read()

# Let's find lines with "physical therapy" query and look at the subsequent boosts
parts = log.split("TESTING FACULTY: العلاج الطبيعي (Physical Therapy)")
if len(parts) > 1:
    subpart = parts[1].split("TESTING FACULTY:")[0]
    for line in subpart.split('\n'):
        if "DEBUG BOOST" in line or "DEBUG CLI" in line or "DEBUG HYBRID" in line:
            print(line)
