import requests
import os
import json
import sys

# Fix Arabic output in Windows terminal
sys.stdout.reconfigure(encoding='utf-8')

files_dir = "files"
pdf_files = [
    "طب وجراحه.pdf",
    "لائحه الفم والاسنان جامعة المنوفية الأهليه A-1.pdf",
    "هندسه.pdf",
]

print("=" * 50)
print("RAG Upload Script")
print("=" * 50)

# Check files exist first
for fname in pdf_files:
    fpath = os.path.join(files_dir, fname)
    if os.path.exists(fpath):
        size_mb = os.path.getsize(fpath) / (1024 * 1024)
        print(f"[OK] {fname} ({size_mb:.1f} MB)")
    else:
        print(f"[NOT FOUND] {fname}")
        sys.exit(1)

print("\nOpening files...")
files_payload = []
file_handles = []
for fname in pdf_files:
    fpath = os.path.join(files_dir, fname)
    fh = open(fpath, "rb")
    file_handles.append(fh)
    files_payload.append(("files", (fname, fh, "application/pdf")))
    print(f"  Ready: {fname}")

print("\nUploading to http://localhost:8000/api/upload/")
print("Please wait... this may take 5-15 minutes.\n")

try:
    r = requests.post(
        "http://localhost:8000/api/upload/",
        files=files_payload,
        timeout=900  # 15 minutes timeout
    )
    print(f"Status: {r.status_code}")
    result = r.json()
    print(json.dumps(result, ensure_ascii=False, indent=2))

    print("\n" + "=" * 50)
    print("SUMMARY:")
    for res in result.get("results", []):
        name = res.get("fileName", "?")
        if res.get("success"):
            chunks = res.get("chunks", 0)
            pages = res.get("pages", 0)
            method = res.get("extractionMethod", "?")
            print(f"  [SUCCESS] {name}")
            print(f"            {chunks} chunks | {pages} pages | method={method}")
        else:
            err = res.get("error", "unknown error")
            print(f"  [FAILED]  {name} -> {err}")

except requests.exceptions.ConnectionError:
    print("\n[ERROR] Cannot connect to server!")
    print("Make sure the server is running:")
    print("  uvicorn main:app --host 0.0.0.0 --port 8000")
except Exception as e:
    print(f"\n[ERROR] {e}")
finally:
    for fh in file_handles:
        fh.close()
    print("\nDone.")
