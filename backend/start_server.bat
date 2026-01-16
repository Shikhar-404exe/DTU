@echo off
echo Starting SIH2025 Backend Server...
echo.
echo Server will be accessible at:
echo - Local: http://127.0.0.1:8000
echo - Network: http://172.17.4.116:8000
echo.
cd /d "%~dp0"
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause
