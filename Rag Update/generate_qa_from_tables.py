import csv
import os

# Paths to extracted tables
TABLE_DIR = os.path.join(os.path.dirname(__file__), "extracted_tables")
OUTPUT_CSV = os.path.join(os.path.dirname(__file__), "english_translation_qa.csv")

# Helper to parse a table CSV and generate QA pairs
def parse_table(csv_path):
    qa_pairs = []
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
        if not rows:
            return []
        # Assume first row may be header if contains non-numeric values
        header = rows[0]
        has_header = any(not any(ch.isdigit() for ch in cell) for cell in header)
        start_idx = 1 if has_header else 0
        for row in rows[start_idx:]:
            if len(row) < 3:
                continue
            code = row[0].strip()
            name = row[1].strip()
            hours = row[2].strip()
            # Generate two QA pairs per row
            q1 = f"ما هو رمز المقرر {name}?"
            a1 = code
            q2 = f"كم عدد الساعات المعتمدة لمقرر {code} ({name})؟"
            a2 = f"{hours} ساعة"
            qa_pairs.append((q1, a1))
            qa_pairs.append((q2, a2))
    return qa_pairs

all_qa = []
for filename in os.listdir(TABLE_DIR):
    if filename.lower().endswith('.csv'):
        path = os.path.join(TABLE_DIR, filename)
        all_qa.extend(parse_table(path))

# Write to output CSV
with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as out_f:
    writer = csv.writer(out_f)
    writer.writerow(['question', 'answer'])
    for q, a in all_qa:
        writer.writerow([q, a])

print(f"Generated {len(all_qa)} QA pairs in {OUTPUT_CSV}")
