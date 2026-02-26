@echo off
setlocal

echo ==========================================
echo    CLEARING APP LOCAL STORAGE
echo ==========================================
echo This will remove all local settings, including 
echo activation status and saved login tokens.
echo.

powershell -Command "Get-ChildItem -Path $env:APPDATA\com.example, $env:LOCALAPPDATA\com.example -Filter shared_preferences.json -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force; if ($?) { Write-Host '[√] Local Storage (shared_preferences) cleared successfully.' -ForegroundColor Green } else { Write-Host '[i] Local Storage already clean or file not found.' -ForegroundColor Cyan }"

echo.
echo ==========================================
echo Done! You can now restart the application.
echo ==========================================
timeout /t 3
exit
