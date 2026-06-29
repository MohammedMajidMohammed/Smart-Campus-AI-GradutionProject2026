import os
import json
import sys
import io
from langchain_openai import OpenAIEmbeddings
from dotenv import load_dotenv

# Fix encoding
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

load_dotenv()

def test_embeddings():
    key = os.getenv("OPENROUTER_API_KEY")
    base = "https://openrouter.ai/api/v1"
    
    # Try different model names
    models = ["openai/text-embedding-3-small", "text-embedding-ada-002"]
    
    for model in models:
        print(f"Testing model: {model}")
        try:
            embeddings = OpenAIEmbeddings(
                openai_api_key=key,
                openai_api_base=base,
                model=model,
                default_headers={
                    "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
                    "X-Title": "Test",
                }
            )
            res = embeddings.embed_query("hello world")
            print(f"SUCCESS: {model} worked. Vector length: {len(res)}")
            return model
        except Exception as e:
            print(f"FAILED: {model} error: {e}")
    return None

if __name__ == "__main__":
    test_embeddings()
