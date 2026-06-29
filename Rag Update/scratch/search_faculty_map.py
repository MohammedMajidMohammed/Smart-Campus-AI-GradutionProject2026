import os

for root, dirs, files in os.walk("."):
    # skip venv and .git
    if "venv" in root or ".git" in root:
        continue
    for file in files:
        if file.endswith(".py"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
                if "faculty_map" in content.lower():
                    print(f"Found FACULTY_MAP in {path}")
