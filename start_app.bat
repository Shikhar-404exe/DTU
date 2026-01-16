@echo off
echo ==========================================
echo   🚀 Starting Rural Education App...
echo ==========================================

REM --- Start Backend ---
cd backend
echo 🔹 Starting backend server on port 8000...
start cmd /k "python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload"

REM --- Start Flutter App ---
cd ..
echo 🔹 Starting Flutter app on connected device...
start cmd /k "flutter run"

echo ==========================================
echo ✅ Both backend and app are running!
echo ==========================================
pause
