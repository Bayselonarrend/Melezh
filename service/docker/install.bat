@echo off
setlocal enabledelayedexpansion

:: Configuration
set IMAGE_NAME=melezh-server
set CONTAINER_NAME=melezh-app
set PORT=8080

echo.
echo ##############################################
echo # Install and Run Melezh with Docker (Windows)
echo ##############################################
echo.

:: Check for Docker
where docker >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ Docker is not installed. Make sure Docker Desktop is running.
    exit /b 1
)

echo ✅ Docker is installed.

:: Build Docker image
echo.
echo 🏗️ Building Docker image...
docker build -t %IMAGE_NAME% .

if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to build Docker image.
    exit /b 1
)

:: Check if container exists
for /f "tokens=*" %%a in ('docker ps -a -f "name=%CONTAINER_NAME%" --format "{{.Status}}" 2^>nul') do set CONTAINER_EXISTS=1

if defined CONTAINER_EXISTS (
    echo.
    echo ⚠️ Container "%CONTAINER_NAME%" already exists.
    set /p ANSWER=Do you want to remove it? [Y/N]: 
    if /i "!ANSWER!"=="y" (
        echo 🗑️ Removing old container...
        docker stop %CONTAINER_NAME% >nul 2>&1 || echo Failed to stop container.
        docker rm %CONTAINER_NAME% >nul 2>&1 || echo Failed to remove container.
    ) else (
        echo ℹ️ Installation cancelled by user.
        exit /b 0
    )
)

:: Run container
echo.
echo ▶️ Starting container on port %PORT%...
docker run -d ^
  --name %CONTAINER_NAME% ^
  -p %PORT%:%PORT% ^
  %IMAGE_NAME%

if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to start container.
    exit /b 1
)

:: Success message
echo.
echo ✅ Server is now running!
echo 🌐 Open in browser: http://localhost:%PORT%
echo 📄 View logs: docker logs %CONTAINER_NAME%
echo.

endlocal