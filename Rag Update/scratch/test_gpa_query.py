import os
import sys
import time
import subprocess
import requests
import json

# Reconfigure stdout to use UTF-8
sys.stdout.reconfigure(encoding="utf-8")

print("Smart Campus RAG - End-to-End GPA Query Test")
print("=" * 60)

# Create/clean server log file
server_cwd = r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update"
log_filepath = os.path.join(server_cwd, "scratch", "server.log")
os.makedirs(os.path.dirname(log_filepath), exist_ok=True)
log_file = open(log_filepath, "w", encoding="utf-8")

print("Launching FastAPI server (logging to scratch/server.log)...")
server_process = subprocess.Popen(
    [sys.executable, "main.py"],
    cwd=server_cwd,
    stdout=log_file,
    stderr=subprocess.STDOUT,
    text=True,
    encoding="utf-8"
)

# Wait for server to start
print("Waiting 20 seconds for the server to load ChromaDB and model...")
time.sleep(20)

# Check if server is running
if server_process.poll() is not None:
    print("ERROR: Server failed to start immediately. Let's show the logs:")
    log_file.close()
    with open(log_filepath, "r", encoding="utf-8") as f:
        print(f.read())
    sys.exit(1)

print("FastAPI server started successfully (PID: {})".format(server_process.pid))

# 2. Query the chat endpoint
query = (
    "دلوقتي أنا ال gpa بتاعي 2.5 و أنا فرقه رابعه اسجل كام ماده و ايه الحد الاقصي لعد الساعات "
    "اللي ممكن اسجلها و ايه المواد اللي اسجلها في كلية الحاسبات والذكاء الاصطناعي قسم برنامج إنترنت الأشياء وتحليل البيانات الضخمة"
)

payload = {
    "question": query,
    "top_k": 4
}
headers = {
    "Content-Type": "application/json",
    "accept": "application/json"
}

url = "http://127.0.0.1:8000/api/chat/"
print("\nQuerying: {}".format(url))
print("Question: {}".format(query))
print("=" * 60)

try:
    response = requests.post(url, json=payload, headers=headers, timeout=60)
    print("Status Code: {}".format(response.status_code))
    if response.status_code == 200:
        resp_json = response.json()
        print("\nChatbot Response:")
        print(resp_json.get("answer", "No answer found"))
        print("\nVerifier Verdict: {}".format(resp_json.get("answerVerdict", "N/A")))
        print("Sources Cited:")
        for doc in resp_json.get("sources", []):
            print("- File: {} | Page: {}".format(doc.get("fileName"), doc.get("page")))
    else:
        print("Error response: {}".format(response.text))
except Exception as e:
    print("Request failed: {}".format(e))
finally:
    # Close log file
    log_file.close()
    
    # 3. Terminate the server process
    print("\n" + "=" * 60)
    print("Shutting down the server process...")
    server_process.terminate()
    try:
        server_process.wait(timeout=5)
        print("Server process terminated.")
    except subprocess.TimeoutExpired:
        server_process.kill()
        print("Server process killed.")
        
    # Show the server output logs
    print("\n--- Server Logs ---")
    with open(log_filepath, "r", encoding="utf-8") as f:
        print(f.read())
