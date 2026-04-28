@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Failure: You must right-click and run this script as Administrator.
    pause
    exit /b 1
)

echo Enabling Long Paths in Windows Registry...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f

if %errorLevel% equ 0 (
    echo.
    echo Success. Long paths are now enabled.
    echo A system reboot may be required for all applications to recognize the change.
) else (
    echo.
    echo Failed to modify the registry.
)
echo.
pause
