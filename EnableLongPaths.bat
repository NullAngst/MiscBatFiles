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

set "KEY=HKLM\SYSTEM\CurrentControlSet\Control\FileSystem"

:: Read the current value. reg prints REG_DWORD values as hex, e.g. 0x1.
set "LP="
for /f "tokens=3" %%V in ('reg query "%KEY%" /v LongPathsEnabled 2^>nul ^| find /i "LongPathsEnabled"') do set "LP=%%V"

if /i "%LP%"=="0x1" (
    echo Long Paths are already enabled on this system. No changes made.
    echo.
    pause
    exit /b 0
)

echo Enabling Long Paths in Windows Registry...
reg add "%KEY%" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul
if errorlevel 1 (
    echo.
    echo Failed to modify the registry.
    echo.
    pause
    exit /b 1
)

echo.
echo Success. Long paths are now enabled.
echo A system reboot may be required for all applications to recognize the change.
echo.
pause
exit /b 0
