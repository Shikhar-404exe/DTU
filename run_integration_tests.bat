@echo off
REM Phase 6: Complete Integration Test Runner

echo ====================================
echo  Phase 6 Integration Tests
echo ====================================
echo.

REM Check if backend is running
echo [1/3] Checking backend status...
curl -s http://localhost:8000/chatbot/health >nul 2>&1
if %errorlevel% == 0 (
    echo ✓ Backend running on port 8000
) else (
    echo ✗ Backend not running!
    echo    Please start backend: cd backend ^&^& python main.py
    echo.
    pause
    exit /b 1
)

echo.
echo [2/3] Running API Endpoint Tests (27 endpoints)...
echo.
cd backend
python test_api_endpoints.py
if %errorlevel% neq 0 (
    echo.
    echo ✗ API tests failed!
    cd ..
    pause
    exit /b 1
)

echo.
echo [3/3] Running Integration Tests (17 tests)...
echo.
python test_integration_phase6.py
if %errorlevel% neq 0 (
    echo.
    echo ✗ Integration tests failed!
    cd ..
    pause
    exit /b 1
)

cd ..

echo.
echo ====================================
echo  All Tests Completed!
echo ====================================
echo.
echo Results saved:
echo   - backend/api_test_results.json
echo   - backend/integration_test_results.json
echo.

pause
