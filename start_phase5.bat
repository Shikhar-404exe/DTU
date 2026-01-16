@echo off
REM Phase 5 Quick Start Script
REM Starts backend server and Flutter app

echo ====================================
echo  SIH2025 - Phase 5 Quick Start
echo ====================================
echo.

REM Check if backend is already running
echo [1/4] Checking backend status...
curl -s http://localhost:8000/chatbot/health >nul 2>&1
if %errorlevel% == 0 (
    echo ✓ Backend already running on port 8000
) else (
    echo ✗ Backend not running. Starting backend...
    start "SIH2025 Backend" cmd /k "cd backend && python main.py"
    echo ✓ Backend starting in new window...
    timeout /t 5 /nobreak >nul
)

echo.
echo [2/4] Installing Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ✗ Failed to install dependencies
    pause
    exit /b 1
)
echo ✓ Dependencies installed

echo.
echo [3/4] Running Flutter app...
echo.
echo Available devices:
call flutter devices
echo.

REM Ask user to select device
set /p device="Enter device ID or press Enter for default: "
if "%device%"=="" (
    echo Running on default device...
    call flutter run
) else (
    echo Running on device: %device%
    call flutter run -d %device%
)

echo.
echo [4/4] Done!
pause
