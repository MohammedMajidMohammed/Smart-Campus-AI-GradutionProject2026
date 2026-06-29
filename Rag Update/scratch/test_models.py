import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

api_key = os.getenv("OPENROUTER_API_KEY")
print("API Key loaded:", api_key[:10] + "..." if api_key else "None")

models_to_test = [
    "google/gemini-2.5-flash",
    "google/gemini-2.0-flash-exp:free",
    "meta-llama/llama-3-8b-instruct:free",
    "google/gemma-2-9b-it:free",
    "openai/gpt-oss-120b:free"
]

for model in models_to_test:
    print(f"\n--- Testing Model: {model} ---")
    try:
        llm = ChatOpenAI(
            openai_api_key=api_key,
            openai_api_base="https://openrouter.ai/api/v1",
            model_name=model,
            temperature=0.1,
            max_tokens=150,
            default_headers={
                "HTTP-Referer": "http://localhost:8000",
                "X-Title": "Test",
            }
        )
        resp = llm.invoke("من هو رئيس جامعة المنوفية الأهلية؟ أجب باختصار.")
        print("Response:", resp.content if hasattr(resp, "content") else str(resp))
    except Exception as e:
        print("Error:", e)
