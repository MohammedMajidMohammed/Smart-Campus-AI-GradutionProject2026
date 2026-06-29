import json, sys

def load(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

old = load('evaluation_report_old.json')
new = load('evaluation_report.json')

def compute_metrics(data):
    meta = data.get('metadata', {})
    total = meta.get('total_questions', len(data.get('results', [])))
    avg_chunks = meta.get('average_chunks', 0)
    faculty_rate = meta.get('faculty_detection_rate', 0)
    error_dist = meta.get('error_distribution', {})
    # Partial Retrieval count
    partial = error_dist.get('Partial Retrieval', 0)
    halluc = error_dist.get('Hallucination', 0)
    overgen = error_dist.get('Over-generation', 0)
    # overall factual accuracy approximated as not hallucination or overgen
    factual_ok = total - halluc - overgen
    factual_acc = factual_ok / total if total else 0
    return {
        'total': total,
        'partial_pct': partial / total if total else 0,
        'faculty_rate': faculty_rate,
        'halluc_pct': halluc / total if total else 0,
        'avg_chunks': avg_chunks,
        'factual_acc': factual_acc,
    }

old_m = compute_metrics(old)
new_m = compute_metrics(new)

def fmt(p):
    return f"{p:.1%}" if isinstance(p, float) else str(p)

lines = []
lines.append('## Comparison Report')
lines.append('| Metric | Old | New | Change |')
lines.append('|---|---|---|---|')
for key, label in [
    ('partial_pct', 'Partial Retrieval %'),
    ('faculty_rate', 'Faculty Detection Rate %'),
    ('halluc_pct', 'Hallucination %'),
    ('avg_chunks', 'Avg Chunks per Q'),
    ('factual_acc', 'Overall Factual Accuracy %'),
]:
    old_val = old_m[key]
    new_val = new_m[key]
    change = new_val - old_val
    lines.append(f"| {label} | {fmt(old_val)} | {fmt(new_val)} | {fmt(change) if isinstance(change, float) else f'{change:.2f}' } |")

# Identify top/bottom 5 questions by improvement/worsening based on error category changes
# For simplicity, we list questions where old had Partial Retrieval and new does not (improved), and vice versa.
improved = []
worsened = []
for old_rec, new_rec in zip(old.get('results', []), new.get('results', [])):
    if old_rec.get('error_category') == 'Partial Retrieval' and new_rec.get('error_category') != 'Partial Retrieval':
        improved.append((old_rec.get('question'), old_rec.get('error_category'), new_rec.get('error_category')))
    if old_rec.get('error_category') != 'Partial Retrieval' and new_rec.get('error_category') == 'Partial Retrieval':
        worsened.append((new_rec.get('question'), old_rec.get('error_category'), new_rec.get('error_category')))

lines.append('\n### Top 5 Improved Questions (Partial Retrieval resolved)')
for q, old_err, new_err in improved[:5]:
    lines.append(f"- {q[:80]}... (was {old_err}, now {new_err})")
if not improved:
    lines.append('None')

lines.append('\n### Top 5 New Problematic Questions (Partial Retrieval introduced)')
for q, old_err, new_err in worsened[:5]:
    lines.append(f"- {q[:80]}... (was {old_err}, now {new_err})")
if not worsened:
    lines.append('None')

# Recommendations placeholder
lines.append('\n### Recommendations for next round')
recs = [
    'Further tune section‑boost logic once a stable implementation is available.',
    'Investigate remaining Partial Retrieval cases and consider expanding metadata filters.',
    'Add stricter hallucination detection using LLM verification.',
    'Evaluate cross‑encoder re‑ranking thresholds on validation set.',
    'Consider augmenting Arabic queries with transliteration to improve BM25 recall.',
]
for r in recs:
    lines.append(f"- {r}")

report = '\n'.join(lines)
with open('comparison_report.md', 'w', encoding='utf-8') as f:
    f.write(report)
print('Comparison report generated.')
