@echo off
title Smart Campus RAG API Server
echo ===================================================
echo     Smart Campus RAG API Server
echo ===================================================
echo.
echo [1] Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH.
    echo Please install Python 3.10+ and add it to your environment variables.
    pause
    exit /b
)

echo [2] Your local IP addresses (for Flutter physical device connection):
powershell -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -Property IPAddress, InterfaceAlias"
echo.
echo * Note: If using Android Emulator, use: http://10.0.2.2:8000/api/chat/
echo * Note: If using iOS Simulator or Desktop, use: http://127.0.0.1:8000/api/chat/
echo * Note: If using Physical Phone, update AppConstants.regulationsChatbotApiUrl in Flutter with: http://[IPAddress_from_above]:8000/api/chat/
echo.
echo ===================================================
echo Starting FastAPI server on port 8000...
echo ===================================================
python main.py
pause
