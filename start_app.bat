@echo off
setlocal

echo =====================
echo    Fund Management 
echo =====================

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
    echo [!] Warning: Docker-compose reported an error or warning.
    echo [?] Continuing anyway to check if containers are running...
)

:: 2. Wait for backend to be ready
echo [+] Waiting for backend to initialize (checking http://localhost:8000/api/)...
echo [i] This might take 10-20 seconds if containers are starting for the first time.

set "RETRY_COUNT=0"
:WaitLoop
set /a RETRY_COUNT+=1
if %RETRY_COUNT% gtr 30 (
    echo.
    echo [!] Error: Backend failed to start after 1 minute.
    echo [i] Please check Docker Desktop logs for 'fund_management_backend'.
    pause
    exit /b 1
)

:: Use PowerShell to check the endpoint - more reliable on Windows than curl
powershell -Command "try { $resp = Invoke-WebRequest -Uri 'http://localhost:8000/api/' -UseBasicParsing -TimeoutSec 2; if ($resp.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1

if %errorlevel% neq 0 (
    <nul set /p =.
    timeout /t 2 /nobreak > nul
    goto WaitLoop
)
echo.
echo [√] Backend is ready!

:: 3. Start the Frontend
echo [+] Launching Flutter Application...
echo [i] Note: Keeping this terminal open ensures the backend stops when you close the app.

set EXE_PATH=flutter_frontend\build\windows\x64\runner\Release\fund_management.exe

if exist "%EXE_PATH%" (
    echo [√] Found compiled executable. Launching...
    :: Use 'call' so script waits for the app to close
    call "%EXE_PATH%"
) else (
    echo [!] Compiled executable not found. 
    echo [!] Running in debug mode via 'flutter run' instead...
    pushd flutter_frontend
    call flutter run -d windows
    popd
)

echo.
echo ==========================================
echo    Shutting Down Services
echo ==========================================
echo [+] Stopping Docker containers...
docker-compose down

echo [√] All services stopped successfully.
timeout /t 3
exit
