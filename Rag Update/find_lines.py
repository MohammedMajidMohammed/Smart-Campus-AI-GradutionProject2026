
with open("chat_cli.py", "r", encoding="utf-8") as f:
    lines = f.readlines()
for idx, line in enumerate(lines):
    if "building course catalog" in line:
        print(f"Line {idx+1}: {line.strip()}")
        # print context
        start = max(0, idx - 10)
        end = min(len(lines), idx + 15)
        for i in range(start, end):
            print(f"{i+1:4d}: {lines[i]}", end="")
