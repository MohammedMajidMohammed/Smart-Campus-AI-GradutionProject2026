## Comparison Report
| Metric | Old | New | Change |
|---|---|---|---|
| Partial Retrieval % | 83.3% | 0.0% | -83.3% |
| Faculty Detection Rate % | 37.5% | 55.8% | 18.3% |
| Hallucination % | 12.5% | 7.0% | -5.5% |
| Avg Chunks per Q | 470.8% | 441.9% | -29.0% |
| Overall Factual Accuracy % | 87.5% | 93.0% | 5.5% |

### Top 5 Improved Questions (Partial Retrieval resolved)
- من هو رئيس الجامعة؟... (was Partial Retrieval, now Correct Refusal)
- ما هي شروط القبول في الجامعة؟... (was Partial Retrieval, now Language Issue)
- ما هي الرسوم الدراسية؟... (was Partial Retrieval, now Correct Refusal)
- ما هي مواعيد التسجيل؟... (was Partial Retrieval, now Hallucination)
- ما هي التخصصات المتاحة في كلية التمريض؟... (was Partial Retrieval, now Correct Refusal)

### Top 5 New Problematic Questions (Partial Retrieval introduced)
None

### Recommendations for next round
- Further tune section‑boost logic once a stable implementation is available.
- Investigate remaining Partial Retrieval cases and consider expanding metadata filters.
- Add stricter hallucination detection using LLM verification.
- Evaluate cross‑encoder re‑ranking thresholds on validation set.
- Consider augmenting Arabic queries with transliteration to improve BM25 recall.