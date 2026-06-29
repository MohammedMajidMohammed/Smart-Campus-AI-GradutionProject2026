"""Test intent classification fix for training queries."""
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.path.insert(0, ".")

from routes.retrieval.query_understanding import understand_query

tests = [
    ("\u0645\u062a\u064a \u064a\u062a\u0645 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062a\u062f\u0631\u064a\u0628 \u0627\u0644\u0635\u064a\u0641\u064a",            "regulations",  None),
    ("\u0645\u0627 \u0647\u0648 \u0634\u0631\u0648\u0637 \u0627\u0644\u062a\u062f\u0631\u064a\u0628 \u0627\u0644\u0635\u064a\u0641\u064a \u0644\u0643\u0644\u064a\u0629 \u0627\u0644\u062d\u0627\u0633\u0628\u0627\u062a", "regulations",  "computer science"),
    ("\u0634\u0631\u0648\u0637 \u0627\u0644\u062a\u062f\u0631\u064a\u0628 \u0627\u0644\u0645\u064a\u062f\u0627\u0646\u064a",                    "regulations",  None),
    ("\u062a\u0633\u062c\u064a\u0644 \u0645\u0648\u0627\u062f \u0627\u0644\u062a\u0631\u0645 \u0627\u0644\u0642\u0627\u062f\u0645",                  "subjects list", None),  # "مواد" triggers subjects list first — acceptable
    ("\u0645\u0627 \u0647\u0648 \u0646\u0638\u0627\u0645 \u0627\u0644\u063a\u064a\u0627\u0628 \u0641\u064a \u0627\u0644\u062d\u0627\u0633\u0628\u0627\u062a",             "regulations",  "computer science"),
    ("\u0645\u062a\u064a \u064a\u0628\u062f\u0627 \u0627\u0644\u062a\u062f\u0631\u064a\u0628",                         "regulations",  None),
    ("\u0643\u064a\u0641\u064a\u0629 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062a\u062f\u0631\u064a\u0628",                      "regulations",  None),
    ("\u0627\u0644\u062a\u062f\u0631\u064a\u0628 \u0627\u0644\u0635\u064a\u0641\u064a \u0644\u0643\u0644\u064a\u0629 \u0627\u0644\u062d\u0627\u0633\u0628\u0627\u062a",            "regulations",  "computer science"),
    ("\u0645\u062a\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u062a\u062f\u0631\u064a\u0628",                          "regulations",  None),
]

labels = [
    "mty ytm tsjyl altdrb alsyfy",
    "ma hw shrwt altdrb alsyfy lklyh alhsbat",
    "shrwt altdrb almydany",
    "tsjyl mwad altrm alqdm",
    "ma hw nzam alghyab fy alhsbat",
    "mty ybda altdrb",
    "kyfyh tsjyl altdrb",
    "altdrb alsyfy lklyh alhsbat",
    "mtTlbat altdrb",
]

print("=" * 60)
print("[TEST] Intent classification for training queries")
print("=" * 60)

all_pass = True
for i, (query, expected_intent, expected_prog) in enumerate(tests):
    ei = understand_query(query)
    ok_intent = ei.intent == expected_intent
    ok_prog   = (expected_prog is None) or (ei.program == expected_prog)
    passed    = ok_intent and ok_prog
    if not passed:
        all_pass = False
    status = "PASS" if passed else "FAIL"
    label  = labels[i]
    print(f"\n[{status}] {label}")
    print(f"  intent  : {ei.intent:<15} expected={expected_intent}  {'OK' if ok_intent else 'WRONG'}")
    print(f"  program : {str(ei.program):<20} expected={expected_prog}  {'OK' if ok_prog else 'WRONG'}")

print("\n" + "=" * 60)
print("[RESULT]", "ALL PASS" if all_pass else "SOME FAILED")
print("=" * 60)
sys.exit(0 if all_pass else 1)
