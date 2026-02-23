---
description: How to deploy the full stack (Flutter + Django + PostgreSQL) as a local desktop suite
---

# Full-Stack Desktop Deployment Guide (Windows)

To deploy your entire system (Frontend, Backend, and Database) locally on a single machine, follow these steps.

---

## Part 1: PostgreSQL Database Setup

For a local desktop deployment, the database must be running on the user's machine.

### Option A: Manual Installation (Simplest for End Users)
1. Download and install **PostgreSQL 16+** from [enterprisedb.com](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads).
2. During installation, set the password to `1234` (matching your `settings.py`).
3. Open **pgAdmin 4** or **psql** and create a database named `fund_management`.

### Option B: Docker (Best for Tech-Savvy Users)
If the user has Docker installed, you can provide a `docker-compose.yml` file to start PostgreSQL instantly.

---

## Part 2: Django Backend Deployment

To run the backend without requiring a Python installation on the user's machine, you can bundle it using **PyInstaller**.

### 1. Install PyInstaller
```powershell
pip install pyinstaller
```

### 2. Create a Startup Script (`run_backend.py`)
Create a simple script in the `backend` folder to launch the server:
```python
import os
import sys
from django.core.management import execute_from_command_line

if __name__ == "__main__":
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
    # You can hardcode 'runserver' and '0.0.0.0:8000' here for the executable
    execute_from_command_line([sys.argv[0], "runserver", "0.0.0.0:8000", "--noreload"])
```

### 3. Build the Executable
```powershell
pyinstaller --name="FundManagementBackend" --onefile run_backend.py
```
This will create a `FundManagementBackend.exe` in the `dist/` folder.

---

## Part 3: Flutter Desktop Application

Follow the steps in the previous guide to build the Flutter Windows app:
```powershell
flutter create --platforms=windows .
flutter build windows
```

---

## Part 4: Final Packaging (The "Desktop Suite")

To make it easy for the user, create a folder structure like this:

```text
FundManagementSuite/
├── Backend/
│   └── FundManagementBackend.exe
├── Frontend/
│   └── (Contents of build/windows/x64/runner/Release/)
└── start_app.bat  <-- A double-clickable launcher
```

### `start_app.bat` (Launcher Script)
```batch
@echo off
echo Starting Fund Management Suite...

:: 1. Start the Backend in the background
start /b "" "Backend\FundManagementBackend.exe"

:: 2. Wait a few seconds for Backend to initialize
timeout /t 5

:: 3. Launch the Frontend
start "" "Frontend\flutter_frontend.exe"

echo App started successfully!
```

---

## Important Considerations for Local Desktop
1. **Migrations**: The first time the app runs, you need to run `python manage.py migrate`. You can add this to your `run_backend.py` script so it happens automatically before starting the server.
2. **Static/Media Files**: Ensure the `media` and `static` folders are handled correctly by the executable (use absolute paths relative to the `.exe`).
3. **Hardcoded URLs**: Ensure the Flutter app is pointing to `http://localhost:8000` for all API calls.
