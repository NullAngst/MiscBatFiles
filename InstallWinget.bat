@echo off
setlocal EnableExtensions

:: Check for Administrator privileges.
:: fltmc requires elevation and, unlike "net session", does not depend on the
:: Server (LanmanServer) service running.
fltmc >nul 2>&1
if errorlevel 1 (
    echo Failure: You must right-click and run this script as Administrator.
    pause
    exit /b 1
)

:: This installer depends entirely on PowerShell (downloads, archive extraction,
:: Appx deployment). Rather than maintain a second, drifting copy of that logic as
:: inline one-liners, this launcher runs InstallWinget.ps1 from the same folder.
set "PS1=%~dp0InstallWinget.ps1"

if not exist "%PS1%" (
    echo InstallWinget.ps1 was not found next to this file:
    echo   %PS1%
    echo Download both files from the repository into the same folder.
    pause
    exit /b 1
)

:: -ExecutionPolicy Bypass applies to this process only. It also avoids the
:: RemoteSigned block on files downloaded from the internet.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "RC=%errorlevel%"

echo.
pause
exit /b %RC%
