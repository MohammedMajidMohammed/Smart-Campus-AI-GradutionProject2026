import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

with open('chat_cli.py', 'r', encoding='utf-8') as f:
    for line_no, line in enumerate(f, 1):
        if line.startswith('class '):
            print(f"[{line_no}]: {line.strip()}")
