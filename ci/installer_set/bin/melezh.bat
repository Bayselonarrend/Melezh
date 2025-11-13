@echo off
set "oint_folder=%~dp0"
set "debug_args="

if defined MELEZH_DEBUG (
    for /f "tokens=2 delims==" %%i in ("%MELEZH_DEBUG%") do (
        set "debug_args=-debug -port=%%i -noWait"
    )
)

call "%oint_folder%..\share\oint\bin\oscript.exe" %debug_args% "%oint_folder%..\share\oint\lib\melezh\core\Classes\app.os" %*
@exit /b %ERRORLEVEL%