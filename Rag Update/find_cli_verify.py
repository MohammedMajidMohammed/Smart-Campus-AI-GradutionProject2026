with open("chat_cli.py", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "is_training_faq" in line or "training" in line.lower() or "verify_answer" in line:
        print(f"Line {i+1}: {line.strip()}")
