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
echo [+] Waiting for backend to initialize (checking localhost:8000)...
:WaitLoop
timeout /t 2 /nobreak > nul
curl -s http://localhost:8000/api/ > nul
if %errorlevel% neq 0 (
    echo [.] Still waiting for backend...
    goto WaitLoop
)
echo [√] Backend is ready!

:: 3. Start the Frontend
echo [+] Launching Flutter Application...

set EXE_PATH=flutter_frontend\build\windows\x64\runner\Release\flutter_frontend.exe

if exist "%EXE_PATH%" (
    echo [√] Found compiled executable. Launching...
    start "" "%EXE_PATH%"
) else (
    echo [!] Compiled executable not found. 
    echo [!] Running in debug mode via 'flutter run' instead...
    cd flutter_frontend
    flutter run -d windows
)

echo.
echo ==========================================
echo    Application Started
echo ==========================================
echo [i] You can close this window now, or leave it open to monitor backend logs.
echo [i] Note: Closing this window will NOT automatically stop Docker containers.
pause
