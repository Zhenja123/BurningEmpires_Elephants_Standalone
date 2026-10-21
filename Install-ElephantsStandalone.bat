@echo off
setlocal
title Burning Empires Elephants - Standalone Installer

echo ============================================================
echo   Burning Empires Elephants - Standalone Installer
echo ============================================================
echo.
echo This installer copies the installed elephant module into a
echo separate standalone module. The original module is not changed.
echo.
where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: Windows PowerShell was not found.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-ElephantsStandalone.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if "%RESULT%"=="0" (
    echo Installer finished successfully.
) else (
    echo Installer stopped with an error. Read the message above.
)
pause
exit /b %RESULT%
