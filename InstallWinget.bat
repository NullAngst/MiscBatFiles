@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Failure: You must right-click and run this script as Administrator.
    pause
    exit /b 1
)

echo Initializing Winget Installation for LTSC...
echo This will download files directly from Microsoft and GitHub. Please wait.
echo.

:: Set TLS 1.2 for PowerShell downloads to prevent connection errors
set PS_TLS=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

echo [1/3] Downloading and installing Microsoft VCLibs...
powershell -NoProfile -Command "%PS_TLS% Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile '%TEMP%\vclibs.appx'; Add-AppxPackage -Path '%TEMP%\vclibs.appx'"

echo [2/3] Downloading and installing Microsoft UI Xaml 2.8...
powershell -NoProfile -Command "%PS_TLS% Invoke-WebRequest -Uri 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' -OutFile '%TEMP%\xaml.appx'; Add-AppxPackage -Path '%TEMP%\xaml.appx'"

echo [3/3] Downloading and installing Winget (DesktopAppInstaller)...
powershell -NoProfile -Command "%PS_TLS% Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile '%TEMP%\winget.msixbundle'; Add-AppxPackage -Path '%TEMP%\winget.msixbundle'"

:: Clean up temp files
del /q "%TEMP%\vclibs.appx" >nul 2>&1
del /q "%TEMP%\xaml.appx" >nul 2>&1
del /q "%TEMP%\winget.msixbundle" >nul 2>&1

if %errorLevel% equ 0 (
    echo.
    echo Success. Winget should now be installed.
    echo Close this window and open a new Command Prompt or PowerShell to use it.
) else (
    echo.
    echo Installation encountered an error. Check your internet connection or firewall.
)
echo.
pause
