import os
import sys
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

sys.stdout.reconfigure(encoding='utf-8')
load_dotenv()

api_key = os.getenv("OPENROUTER_API_KEY")

try:
    llm = ChatOpenAI(
        openai_api_key=api_key,
        openai_api_base="https://openrouter.ai/api/v1",
        model_name="openrouter/free",
        temperature=0.1,
        max_tokens=300,
        default_headers={
            "HTTP-Referer": "http://localhost:8000",
            "X-Title": "Test",
        }
    )
    resp = llm.invoke("من هو رئيس جامعة المنوفية الأهلية؟ أجب باختصار.")
    print("Response:")
    print(resp.content if hasattr(resp, "content") else str(resp))
except Exception as e:
    print("Error:", e)
