import py_compile, sys

files = [
    "chat_cli.py",
    "routes/retrieval/hybrid_search.py",
    "routes/retrieval/query_understanding.py",
    "routes/retrieval/section_booster.py",
]

all_ok = True
for f in files:
    try:
        py_compile.compile(f, doraise=True)
        print(f"OK: {f}")
    except py_compile.PyCompileError as e:
        print(f"ERROR: {f}: {e}")
        all_ok = False

sys.exit(0 if all_ok else 1)
