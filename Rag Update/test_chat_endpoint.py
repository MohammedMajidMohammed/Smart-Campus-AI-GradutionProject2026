#!/usr/bin/env python3
"""
Test script to debug chat endpoint
"""
import requests
import json

BASE_URL = "http://localhost:8080"

def test_health():
    """Test health endpoint"""
    print("=" * 60)
    print("Testing Health Endpoint")
    print("=" * 60)
    try:
        response = requests.get(f"{BASE_URL}/api/health")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"ERROR: {e}")
        return False

def test_cors_test():
    """Test CORS test endpoint"""
    print("\n" + "=" * 60)
    print("Testing CORS Test Endpoint")
    print("=" * 60)
    try:
        response = requests.get(f"{BASE_URL}/api/cors-test")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"ERROR: {e}")
        return False

def test_chat():
    """Test chat endpoint"""
    print("\n" + "=" * 60)
    print("Testing Chat Endpoint")
    print("=" * 60)
    try:
        payload = {
            "question": "من هو رئيس الجامعة"
        }
        headers = {
            "Content-Type": "application/json",
            "accept": "application/json"
        }
        
        print(f"URL: {BASE_URL}/api/chat/")
        print(f"Payload: {json.dumps(payload, ensure_ascii=False)}")
        
        response = requests.post(
            f"{BASE_URL}/api/chat/",
            json=payload,
            headers=headers,
            timeout=30
        )
        
        print(f"Status: {response.status_code}")
        print(f"Headers: {dict(response.headers)}")
        
        if response.status_code == 200:
            print(f"Response: {json.dumps(response.json(), ensure_ascii=False, indent=2)}")
        else:
            print(f"Error Response: {response.text}")
        
        return response.status_code == 200
    except requests.exceptions.ConnectionError as e:
        print(f"ERROR: Cannot connect to server. Is it running?")
        print(f"Details: {e}")
        return False
    except requests.exceptions.Timeout as e:
        print(f"ERROR: Request timed out")
        print(f"Details: {e}")
        return False
    except Exception as e:
        print(f"ERROR: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_options():
    """Test OPTIONS preflight request"""
    print("\n" + "=" * 60)
    print("Testing OPTIONS Preflight")
    print("=" * 60)
    try:
        response = requests.options(
            f"{BASE_URL}/api/chat/",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "content-type"
            }
        )
        print(f"Status: {response.status_code}")
        print(f"Headers:")
        for key, value in response.headers.items():
            if "access-control" in key.lower() or "cors" in key.lower():
                print(f"  {key}: {value}")
        return response.status_code in [200, 204]
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    print("\n")
    print("Smart Campus RAG - Chat Endpoint Test")
    print("=" * 60)
    print(f"Testing against: {BASE_URL}")
    print("")
    
    results = []
    
    results.append(("Health", test_health()))
    results.append(("CORS Test", test_cors_test()))
    results.append(("OPTIONS", test_options()))
    results.append(("Chat", test_chat()))
    
    print("\n" + "=" * 60)
    print("Test Results Summary")
    print("=" * 60)
    for name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{name:20} {status}")
    
    print("")

