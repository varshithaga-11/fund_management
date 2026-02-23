@echo off
setlocal

echo ==========================================
echo    Fund Management - One-Click Start
echo ==========================================

:: 1. Start Docker services (DB and Backend)
echo [+] Starting Database and Backend (Docker)...
docker-compose up -d

if %errorlevel% neq 0 (
    echo [!] Error: Docker is not running or docker-compose.yml not found.
    pause
    exit /b %errorlevel%
)

:: 2. Wait for backend to be ready
echo [+] Waiting for backend to initialize...
timeout /t 10 /nobreak > nul

:: 3. Start the Frontend
echo [+] Launching Flutter Desktop Application...
cd flutter_frontend

:: Check if Windows support is enabled, if not enable it
if not exist "windows" (
    echo [!] Windows folder missing. Enabling Windows platform...
    flutter create --platforms=windows .
)

:: Run the app
flutter run -d windows

echo.
echo ==========================================
echo    Application Closed
echo ==========================================
pause
