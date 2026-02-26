@echo off
setlocal

echo ==========================================
echo    WARNING: DATABASE RESET
echo ==========================================
echo This will PERMANENTLY ERASE ALL DATA in your database.
echo This includes users, products, categories, and settings.
echo.
set /p CONFIRM="Are you absolutely sure you want to proceed? (Y/N): "

if /i "%CONFIRM%" neq "Y" (
    echo Reset cancelled.
    pause
    exit /b 0
)

echo.
echo [+] Stopping and removing containers and VOLUMES...
docker-compose down -v

echo.
echo [+] Clearing Flutter Local Storage (shared_preferences)...
powershell -Command "Get-ChildItem -Path $env:APPDATA\com.example, $env:LOCALAPPDATA\com.example -Filter shared_preferences.json -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force; if ($?) { Write-Host '   [√] Local Storage cleared.' } else { Write-Host '   [i] Local Storage file not found or already clean.' }"

echo.
echo [+] Starting fresh database and backend...
docker-compose up -d

echo.
echo [+] Waiting for backend to initialize and run migrations...
timeout /t 10

echo.
echo [√] Database has been reset and migrations have been applied.
echo [!] Note: You may need to create a new superuser to access the admin panel.
echo [i] Run: docker exec -it fund_management_backend python manage.py createsuperuser
echo.
pause
