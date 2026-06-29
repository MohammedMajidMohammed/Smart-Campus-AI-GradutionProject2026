import os

def search_files(directory, query):
    for root, dirs, files in os.walk(directory):
        if "venv" in root.split(os.sep):
            continue
        for file in files:
            if file.endswith(".py"):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        lines = f.readlines()
                    for idx, line in enumerate(lines):
                        if query in line:
                            print(f"{path}:{idx+1}: {line.strip()}")
                except Exception:
                    pass

if __name__ == "__main__":
    search_files(".", "ChatOpenAI")
