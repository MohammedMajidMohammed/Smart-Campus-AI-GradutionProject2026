
import sys
import io
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"C:\Users\Right Click\.gemini\antigravity\brain\cf0ea8bc-79f2-4638-b749-b5e8c92f36dd\.system_generated\tasks\task-1747.log", "r", encoding="utf-8") as f:
    lines = f.readlines()

print("--- PHYSICAL THERAPY BOOSTS IN LOG ---")
for line in lines:
    if "DEBUG BOOST" in line and "علاج_طبيعي" in line:
        print(line.strip())

print("\n--- MEDICINE BOOSTS IN LOG ---")
for line in lines:
    if "DEBUG BOOST" in line and "طب وجراحه" in line:
        print(line.strip())
