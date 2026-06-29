import sys
import os
import re
from pathlib import Path

# Mock QueryIntent
class Intent:
    def __init__(self, intent, program):
        self.intent = intent
        self.program = program

def _is_curriculum_table(text: str) -> bool:
    # Look for course code patterns: AAA 123
    codes = len(re.findall(r"\b[A-Z]{2,4}\s*\d{3,4}\b", text, re.IGNORECASE))
    # Look for table-like rows ending in hours: "Course Name 3 2" or "[3]"
    # Note: re.MULTILINE is needed for ^ and $ but we are searching for patterns within lines
    rows  = len(re.findall(r"[\u0600-\u06FF\w\s]+\s*\[?\d\]?\s*[\d\"]?", text))
    # Try a simpler row pattern for course names followed by numbers
    rows_simple = len(re.findall(r"الترجمة.*?\d", text))
    
    headers = len(re.findall(r"level\s*[1-4]|semester\s*[1-2]|credit\s*hours", text, re.IGNORECASE))
    print(f"DEBUG: codes={codes}, rows={rows}, rows_simple={rows_simple}, headers={headers}")
    return codes >= 2 or rows >= 5 or headers >= 1

# Page 15 OCR text snippet
page_15_text = """
كلية العلوم الانسانية والاجتماعية

المقررات الدراسية لبرنامج اللغة الانجليزية والترجمة التخصصية
اولاء المقررات الاجبارية (120 20

[ ) تتسناسماكمدهع لا له معروعدا 11
الترجمة التحريرية العامة [1]) 2 ”
للق انقلا كسة? [ تعتنرع لا السعوعا
11 وعساعصسداطا
الترجمة التحريرية العامة (2)
الترجمة السياسية (1)
الترجمة الاقتصادية (1]: مالية وتجارية 2 2
"""

print(f"Testing Page 15: {_is_curriculum_table(page_15_text)}")
