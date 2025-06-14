@echo off
SETLOCAL

SET DOCKER_USER=bayselonarrend
SET IMAGE_NAME=melezh
SET VERSION=0.2.0

SET PROJECT_DIR=%CD%

echo === Build RU ===
cd /d "%PROJECT_DIR%\release\ru"
docker build --no-cache -f Dockerfile -t %DOCKER_USER%/%IMAGE_NAME%:%VERSION%-ru -t %DOCKER_USER%/%IMAGE_NAME%:latest-ru .
REM docker push %DOCKER_USER%/%IMAGE_NAME%:%VERSION%-ru
REM docker push %DOCKER_USER%/%IMAGE_NAME%:latest-ru

echo.
echo === Build RU ===
cd /d "%PROJECT_DIR%\release\en"
docker build --no-cache -f Dockerfile -t %DOCKER_USER%/%IMAGE_NAME%:%VERSION%-en -t %DOCKER_USER%/%IMAGE_NAME%:latest-en .
REM docker push %DOCKER_USER%/%IMAGE_NAME%:%VERSION%-en
REM docker push %DOCKER_USER%/%IMAGE_NAME%:latest-en

echo.
echo === Ready ===

ENDLOCAL