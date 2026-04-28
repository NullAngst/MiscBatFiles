@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Failure: You must right-click and run this script as Administrator.
    pause
    exit /b 1
)

echo Installing OpenSSH Server via DISM...
dism /Online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0

if %errorLevel% neq 0 (
    echo.
    echo Installation failed. Ensure your machine has access to Windows Update servers.
    pause
    exit /b 1
)

echo.
echo Configuring OpenSSH Server to start automatically on boot...
sc config sshd start= auto

echo.
echo Starting the OpenSSH Server service...
net start sshd

echo.
echo Ensuring Windows Firewall allows inbound TCP 22...
netsh advfirewall firewall add rule name="OpenSSH Server (sshd)" dir=in action=allow protocol=TCP localport=22 >nul 2>&1

echo.
echo Success. OpenSSH Server is installed, running, and accepting connections.
echo.
pause
