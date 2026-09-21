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

set "REBOOT="

:: The sshd service only exists once the capability is installed.
:: Checking the service avoids parsing localized DISM state text.
sc query sshd >nul 2>&1
if not errorlevel 1 (
    echo OpenSSH Server is already installed. Verifying service and firewall configuration...
    goto :configure
)

echo Resolving the OpenSSH Server capability name. This can take a minute...
set "CAP="
for /f "tokens=1 delims=| " %%A in ('dism /Online /English /Get-Capabilities /Format:Table ^| findstr /b /i /c:"OpenSSH.Server~"') do set "CAP=%%A"

if not defined CAP (
    echo.
    echo Could not find an OpenSSH.Server capability on this system.
    echo Ensure your machine has access to Windows Update servers.
    pause
    exit /b 1
)

echo.
echo Installing %CAP% via DISM...
dism /Online /Add-Capability /CapabilityName:%CAP% /NoRestart
set "RC=%errorlevel%"

:: 3010 = success, reboot required.
if "%RC%"=="3010" (
    set "REBOOT=1"
    set "RC=0"
)
if not "%RC%"=="0" (
    echo.
    echo Installation failed with DISM exit code %RC%.
    echo Ensure your machine has access to Windows Update servers.
    pause
    exit /b 1
)

:configure
echo.
echo Configuring OpenSSH Server to start automatically on boot...
sc config sshd start= auto >nul
if errorlevel 1 (
    echo Failed to set the sshd startup type.
    pause
    exit /b 1
)

echo.
echo Starting the OpenSSH Server service...
sc start sshd >nul 2>&1
set "RC=%errorlevel%"

:: 1056 = ERROR_SERVICE_ALREADY_RUNNING
if "%RC%"=="1056" (
    echo The sshd service is already running.
    set "RC=0"
)
if not "%RC%"=="0" (
    echo Failed to start sshd. sc.exe returned error %RC%.
    pause
    exit /b 1
)

echo.
echo Ensuring Windows Firewall allows inbound TCP 22...
:: Installing the capability normally creates a rule named OpenSSH-Server-In-TCP.
:: Rules are matched by that internal name (locale independent) rather than by
:: display name, so a duplicate is not added on every run. PowerShell is used here
:: because netsh can only match rules by display name.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$r = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue; if (-not $r) { $r = Get-NetFirewallRule -DisplayName 'OpenSSH Server (sshd)' -ErrorAction SilentlyContinue }; if ($r) { $r | Enable-NetFirewallRule -ErrorAction Stop; 'Firewall rule already exists and is enabled.' } else { New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction Stop | Out-Null; 'Firewall rule added for TCP port 22.' }"
if errorlevel 1 (
    echo Failed to configure the firewall rule.
    pause
    exit /b 1
)

echo.
echo Success. OpenSSH Server is installed and running, and inbound TCP 22 is allowed.
if defined REBOOT echo A reboot is required to complete the installation.
echo.
pause
exit /b 0
