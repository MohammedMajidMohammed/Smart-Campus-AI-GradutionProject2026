"""
convert_new_pdfs.py  —  PDF -> JSON  (batch converter for all new faculty files)
"""
import sys, io, json, traceback
from pathlib import Path

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")

sys.path.append(str(Path(__file__).parent))
from routes.pdf_processor import extract_and_structure_pdf

FILES_DIR  = Path("files")
OUTPUT_DIR = Path("processed_pdfs")
OUTPUT_DIR.mkdir(exist_ok=True)

# exact file names as they appear on disk  (files/ folder)
NEW_FILES = [
    "دليل تمريض.pdf",
    "دليل صيدلة.pdf",
    "دليل_الطالب_نهائي_علاج_طبيعي_2025_2026.pdf",
    "دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf",
    "لائحة الجامعة الأهلية.pdf",
    "لائحة طب بيطري ساعات معتمدة1-1 (1).pdf",
    "لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf",
    "student guide 25-26-2.pdf",
]


def convert(pdf_name: str, force: bool = False) -> bool:
    pdf_path = FILES_DIR / pdf_name
    out_path = OUTPUT_DIR / (pdf_name + ".json")

    if not pdf_path.exists():
        print(f"  [NOT FOUND]  {pdf_name}")
        return False

    if out_path.exists() and not force:
        print(f"  [SKIP]  {pdf_name}  ({out_path.stat().st_size // 1024} KB — already exists)")
        return True

    print(f"\n  [CONVERTING]  {pdf_name} ...")
    try:
        pdf_bytes  = pdf_path.read_bytes()
        structured = extract_and_structure_pdf(pdf_bytes, pdf_name)

        if not structured or not structured.get("pages"):
            print(f"  [ERROR]  No pages extracted")
            return False

        pages  = len(structured["pages"])
        chars  = sum(len(p.get("text", "")) for p in structured["pages"])
        method = structured.get("extraction_method", "?")

        out_path.write_text(
            json.dumps(structured, ensure_ascii=False, indent=2),
            encoding="utf-8"
        )
        print(f"  [OK]  pages={pages}  chars={chars:,}  method={method}  "
              f"size={out_path.stat().st_size // 1024} KB")
        return True

    except Exception as exc:
        print(f"  [ERROR]  {exc}")
        traceback.print_exc()
        return False


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true", help="Force overwrite existing JSONs")
    args = parser.parse_args()

    print("=" * 60)
    print("  PDF  →  JSON  Batch Converter")
    print("=" * 60)

    ok = fail = 0
    for f in NEW_FILES:
        if convert(f, force=args.force):
            ok += 1
        else:
            fail += 1

    print("\n" + "=" * 60)
    print(f"  Result: {ok} converted  |  {fail} failed")
    print(f"  Output: {OUTPUT_DIR.resolve()}")
    print("=" * 60)
    print("\n📋  All JSON files now in processed_pdfs/:")
    for p in sorted(OUTPUT_DIR.glob("*.json")):
        print(f"     {p.name}  ({p.stat().st_size // 1024} KB)")
