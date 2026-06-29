with open("chat_cli.py", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "_PROMPT =" in line or "_PROMPT_LEGAL =" in line or "_FALLBACK_PROMPT =" in line:
        print(f"Line {i+1}: {line.strip()}")
