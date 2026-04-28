#Requires -RunAsAdministrator

# Ensure TLS 1.2 for all web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Winget is already installed on this system. No changes made." -ForegroundColor Yellow
    exit 0
}

Write-Host "Initializing Winget installation for LTSC..."
Write-Host "This will download files directly from Microsoft and GitHub. Please wait."
Write-Host ""

$tempVCLibs = Join-Path $env:TEMP "vclibs.appx"
$tempXaml   = Join-Path $env:TEMP "xaml.appx"
$tempWinget = Join-Path $env:TEMP "winget.msixbundle"

try {
    # Step 1: VCLibs
    Write-Host "[1/3] Downloading and installing Microsoft VCLibs..."
    Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile $tempVCLibs -ErrorAction Stop
    Add-AppxPackage -Path $tempVCLibs -ErrorAction Stop

    # Step 2: UI Xaml (latest release resolved from GitHub API)
    Write-Host "[2/3] Downloading and installing Microsoft UI Xaml (latest)..."
    $xamlRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/microsoft-ui-xaml/releases/latest" -ErrorAction Stop
    $xamlAsset   = $xamlRelease.assets | Where-Object { $_.name -match "x64\.appx$" } | Select-Object -First 1
    if (-not $xamlAsset) { throw "Could not find a UI Xaml x64 asset in the latest GitHub release." }
    Invoke-WebRequest -Uri $xamlAsset.browser_download_url -OutFile $tempXaml -ErrorAction Stop
    Add-AppxPackage -Path $tempXaml -ErrorAction Stop

    # Step 3: Winget
    Write-Host "[3/3] Downloading and installing Winget (DesktopAppInstaller)..."
    Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile $tempWinget -ErrorAction Stop
    Add-AppxPackage -Path $tempWinget -ErrorAction Stop

    Write-Host ""
    Write-Host "Success. Winget is now installed." -ForegroundColor Green
    Write-Host "Close this window and open a new PowerShell or Command Prompt session to use it."

} catch {
    Write-Host ""
    Write-Error "Installation failed: $_"
    Write-Host "Ensure your internet connection and firewall are not blocking GitHub or Microsoft."
    exit 1

} finally {
    # Clean up temp files regardless of success or failure
    Remove-Item $tempVCLibs, $tempXaml, $tempWinget -ErrorAction SilentlyContinue
}
