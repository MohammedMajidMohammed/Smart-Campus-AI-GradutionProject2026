import os

with open("routes/chat.py", "r", encoding="utf-8") as f:
    for line_no, line in enumerate(f, 1):
        if "faculty" in line.lower() or "detect" in line.lower() or "route" in line.lower():
            if any(k in line.lower() for k in ["def ", "class ", "=", "_FACULTY"]):
                print(f"{line_no}: {line.strip()}")
