@echo off
set "oint_folder=%~dp0"
set "debug_args="

if defined MELEZH_DEBUG (
    echo %MELEZH_DEBUG% | findstr /r "^[0-9][0-9]*$" >nul
    if not errorlevel 1 (
        set "debug_args=-debug -port=%MELEZH_DEBUG% -noWait"
        echo "Debug port found: %MELEZH_DEBUG%"
    )
)

call "%oint_folder%..\share\oint\bin\oscript.exe" %debug_args% "%oint_folder%..\share\oint\lib\melezh\core\Classes\app.os" %*
@exit /b %ERRORLEVEL%