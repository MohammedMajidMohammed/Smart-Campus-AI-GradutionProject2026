with open("routes/chat.py", "r", encoding="utf-8") as f:
    content = f.read()

import re
matches = re.findall(r"(_SYSTEM_PROMPT\w*\s*=.*?\"\"\"(?:.*?)\"\"\")", content, re.DOTALL)
for m in matches:
    print("Found prompt:")
    print(m[:200] + "...")
    print("-" * 50)
