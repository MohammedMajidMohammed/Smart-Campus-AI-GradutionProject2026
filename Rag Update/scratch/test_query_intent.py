import os
import sys
from dotenv import load_dotenv

# Add project root to path
sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")

load_dotenv()

from routes.retrieval.query_understanding import understand_query
from routes.chat import llm, ChatRequest
import re

question = "شرط الانسحاب من المقررات في كلية الحاسبات والذكاء الاصطناعي"

query_intent = understand_query(question, llm=llm)

print(f"Query: {question}")
print(f"Intent: {query_intent.intent}")
print(f"Confidence: {query_intent.confidence}")

# Check advising query logic in chat.py
_query_lower = question.lower()
_is_advising_query = any(kw in _query_lower for kw in [
    # GPA / Advising
    "gpa", "cgpa", "معدل", "جي بي", "إنذار", "انذار", "warning", "probation",
    # Failures / Prerequisites
    "رسوب", "راسب", "شايل", "ملحق", "شلت", "failed", "fail", "أقل من", "اقل من",
    "2.", "2,", "٢", "متطلب", "متطلبات", "prereq", "prerequisite",
    # Withdrawal / Drop
    "انسحاب", "الانسحاب", "سحب", "السحب", "withdraw", "withdrawal", "drop",
    # Rules / Conditions / Regulations
    "شرط", "شروط", "قواعد", "قاعدة", "لوائح", "لائحة", "نظام", "rules", "regulations", "policy", "قانون", "قوانين",
    # Transfer
    "تحويل", "التحويل", "نقل", "transfer",
    # Attendance / Absences
    "حرمان", "الحرمان", "حرم", "غياب", "الغياب", "حضور", "الحضور", "attendance", "absence", "missing",
    # General / Registration / Admission
    "تسجيل", "التسجيل", "قبول", "القبول", "registration", "enrollment", "admission"
])

print(f"_is_advising_query: {_is_advising_query}")
print(f"_is_subjects_query (first check): {query_intent.intent == 'subjects list' and query_intent.confidence >= 0.50 and not _is_advising_query}")
