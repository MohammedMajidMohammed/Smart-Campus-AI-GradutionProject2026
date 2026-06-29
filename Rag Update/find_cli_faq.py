with open("chat_cli.py", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "التدريب" in line or "الصيفي" in line or "87" in line or "60%" in line:
        print(f"Line {i+1}: {line.strip()}")
