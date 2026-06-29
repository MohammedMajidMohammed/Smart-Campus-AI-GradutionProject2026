import os
import sys
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

# Reconfigure stdout to use utf-8
sys.stdout.reconfigure(encoding='utf-8')

load_dotenv()

api_key = os.getenv("OPENROUTER_API_KEY")

models_to_test = [
    "meta-llama/llama-3.3-70b-instruct:free",
    "google/gemma-4-31b-it:free"
]

for model in models_to_test:
    print(f"\n--- Testing Model: {model} ---")
    try:
        llm = ChatOpenAI(
            openai_api_key=api_key,
            openai_api_base="https://openrouter.ai/api/v1",
            model_name=model,
            temperature=0.1,
            max_tokens=300,
            default_headers={
                "HTTP-Referer": "http://localhost:8000",
                "X-Title": "Test",
            }
        )
        resp = llm.invoke("من هو رئيس جامعة المنوفية الأهلية؟ أجب باختصار.")
        print("Response:", resp.content if hasattr(resp, "content") else str(resp))
    except Exception as e:
        print("Error:", e)
