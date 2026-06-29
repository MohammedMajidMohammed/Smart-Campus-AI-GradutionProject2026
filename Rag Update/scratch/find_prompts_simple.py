with open("routes/chat.py", "r", encoding="utf-8") as f:
    for line_no, line in enumerate(f, 1):
        if "prompt" in line.lower() or "template" in line.lower():
            print(f"{line_no}: {line.strip()}")
