with open("routes/chat.py", "r", encoding="utf-8") as f:
    lines = f.readlines()

for idx, line in enumerate(lines):
    if ".invoke(" in line or "no_info" in line.lower() or "not available" in line.lower():
        # print 5 lines before and 5 lines after
        start = max(0, idx - 5)
        end = min(len(lines), idx + 6)
        print(f"Match on line {idx+1}:")
        for i in range(start, end):
            print(f"  {i+1}: {lines[i].strip()}")
        print("-" * 50)
