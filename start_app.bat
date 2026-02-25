@echo off
setlocal

echo ==========================================
echo    Fund Management - One-Click Start
echo ==========================================

:: 0. Check if Docker is running
echo [+] Checking if Docker status...
docker version >nul 2>&1
if %errorlevel% equ 0 goto DockerReady

echo [!] Docker Engine is not running.

:: Check if Docker Desktop process is running but engine isn't ready
tasklist /fi "imagename eq Docker Desktop.exe" 2>nul | find "Docker Desktop.exe" > nul
if %errorlevel% equ 0 (
    echo [+] Docker Desktop is already starting up...
) else (
    echo [+] Attempting to launch Docker Desktop...
    if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
        start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    ) else (
        echo [!] Error: Docker Desktop not found at standard path.
        echo [!] Please start Docker Desktop manually.
        pause
        exit /b 1
    )
)

echo [+] Waiting for Docker Engine to be ready (this may take a minute)...
:DockerWaitLoop
timeout /t 5 /nobreak > nul
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo [.] Still waiting for Docker Engine...
    goto DockerWaitLoop
)

:DockerReady
echo [√] Docker is running!

:: 1. Start Docker services (DB and Backend)
echo [+] Starting Database and Backend (Docker)...
docker-compose up -d

if %errorlevel% neq 0 (
    echo [!] Error occurred while starting services.
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
