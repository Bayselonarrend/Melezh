@echo off
set "oint_folder=%~dp0"
call "%oint_folder%..\share\oint\bin\oscript.exe" "%oint_folder%..\share\oint\lib\melezh\core\Classes\app.os" %*
@exit /b %ERRORLEVEL%
