#!/usr/bin/env python3
"""
Test script to diagnose OpenRouter embeddings API issues
"""
import os
from dotenv import load_dotenv
from langchain_openai import OpenAIEmbeddings

load_dotenv()

def test_openrouter_embeddings():
    """Test OpenRouter embeddings API"""
    print("=" * 60)
    print("Testing OpenRouter Embeddings API")
    print("=" * 60)
    
    # Check API key
    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        print("❌ ERROR: OPENROUTER_API_KEY not found in .env file")
        print("\nPlease create a .env file with:")
        print("OPENROUTER_API_KEY=sk-or-v1-your-actual-key-here")
        return False
    
    if api_key == "your_openrouter_api_key_here" or api_key.strip() == "":
        print("❌ ERROR: OPENROUTER_API_KEY is set to placeholder value")
        print("Please set your actual OpenRouter API key in .env file")
        return False
    
    if not api_key.startswith("sk-or-v1-"):
        print(f"⚠️  WARNING: API key doesn't start with 'sk-or-v1-'")
        print(f"Current key starts with: {api_key[:10]}...")
    
    print(f"✓ API Key found: {api_key[:15]}...")
    
    # Initialize embeddings
    try:
        embeddings = OpenAIEmbeddings(
            openai_api_key=api_key,
            openai_api_base="https://openrouter.ai/api/v1",
            model="text-embedding-ada-002",
            default_headers={
                "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
                "X-Title": "Smart Campus RAG",
            }
        )
        print("✓ Embeddings client initialized")
    except Exception as e:
        print(f"❌ ERROR initializing embeddings: {str(e)}")
        return False
    
    # Test embedding
    test_text = "This is a test"
    print(f"\nTesting with text: '{test_text}'")
    
    try:
        result = embeddings.embed_query(test_text)
        if result and len(result) > 0:
            print(f"✓ SUCCESS! Generated embedding with {len(result)} dimensions")
            print(f"  First few values: {result[:5]}")
            return True
        else:
            print("❌ ERROR: API returned empty embedding")
            print("Possible causes:")
            print("  1. No credits in OpenRouter account")
            print("  2. API key is invalid")
            print("  3. OpenRouter doesn't support embeddings endpoint")
            return False
    except Exception as e:
        error_msg = str(e)
        print(f"❌ ERROR: {error_msg}")
        
        if "401" in error_msg or "Unauthorized" in error_msg:
            print("\n🔍 Diagnosis: Invalid API key")
            print("Solution: Check your OPENROUTER_API_KEY in .env file")
        elif "402" in error_msg or "credits" in error_msg.lower():
            print("\n🔍 Diagnosis: No credits")
            print("Solution: Add credits at https://openrouter.ai/")
        elif "No embedding data" in error_msg:
            print("\n🔍 Diagnosis: OpenRouter may not support embeddings")
            print("Solution: Use OpenAI API key for embeddings instead")
            print("  Add to .env: OPENAI_API_KEY=sk-your-openai-key")
        else:
            print("\n🔍 Check:")
            print("  1. API key is valid at https://openrouter.ai/keys")
            print("  2. Account has credits at https://openrouter.ai/")
            print("  3. Try using OpenAI API for embeddings")
        
        return False

def test_openai_embeddings():
    """Test OpenAI embeddings API as fallback"""
    print("\n" + "=" * 60)
    print("Testing OpenAI Embeddings API (Fallback)")
    print("=" * 60)
    
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("⚠️  OPENAI_API_KEY not found (this is optional)")
        return False
    
    try:
        embeddings = OpenAIEmbeddings(
            openai_api_key=api_key,
            model="text-embedding-ada-002"
        )
        result = embeddings.embed_query("test")
        if result and len(result) > 0:
            print(f"✓ SUCCESS! OpenAI embeddings work ({len(result)} dimensions)")
            return True
    except Exception as e:
        print(f"❌ OpenAI embeddings error: {str(e)}")
        return False

if __name__ == "__main__":
    print("\n")
    success = test_openrouter_embeddings()
    
    if not success:
        print("\n" + "=" * 60)
        print("Trying OpenAI as fallback...")
        test_openai_embeddings()
    
    print("\n" + "=" * 60)
    print("Diagnosis complete!")
    print("=" * 60)

