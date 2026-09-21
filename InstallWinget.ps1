#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# Windows PowerShell 5.1 redraws the Invoke-WebRequest progress bar for every chunk,
# which makes large downloads (the msixbundle is several hundred MB) extremely slow.
$ProgressPreference = "SilentlyContinue"

# Add TLS 1.2 without removing any protocols already enabled.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Winget is already installed on this system. No changes made." -ForegroundColor Yellow
    exit 0
}

Write-Host "Initializing Winget installation for LTSC..."
Write-Host "This will download files directly from GitHub. Please wait."
Write-Host ""

$repo    = "microsoft/winget-cli"
$workDir = Join-Path ([IO.Path]::GetTempPath()) ("winget-install-" + [guid]::NewGuid().ToString("N"))

try {
    # Resolve the native OS architecture. A 32-bit PowerShell on a 64-bit OS
    # reports x86 in PROCESSOR_ARCHITECTURE and the real value in PROCESSOR_ARCHITEW6432.
    $nativeArch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    $arch = switch ($nativeArch) {
        "AMD64" { "x64" }
        "ARM64" { "arm64" }
        "x86"   { "x86" }
        default { throw "Unsupported processor architecture: $nativeArch" }
    }

    New-Item -ItemType Directory -Path $workDir -Force | Out-Null

    # Step 1: Resolve the latest release tag once, so every file comes from the same
    # release. This follows the /releases/latest redirect instead of calling the
    # GitHub API, which is rate limited to 60 unauthenticated requests per hour.
    Write-Host "[1/4] Resolving latest winget release..."
    $resp = Invoke-WebRequest -Uri "https://github.com/$repo/releases/latest" -Method Head -UseBasicParsing
    $finalUri = if ($resp.BaseResponse.ResponseUri) {
        $resp.BaseResponse.ResponseUri.AbsoluteUri               # Windows PowerShell 5.1
    } else {
        $resp.BaseResponse.RequestMessage.RequestUri.AbsoluteUri # PowerShell 7+
    }
    $tag = ($finalUri -split "/tag/")[-1]
    if ($tag -notmatch "^v\d") { throw "Could not determine the latest winget release tag (got '$finalUri')." }
    Write-Host "      Latest release: $tag ($arch)"
    $downloadBase = "https://github.com/$repo/releases/download/$tag"

    # Step 2: Dependencies. Each winget release publishes the exact framework packages
    # it needs in DesktopAppInstaller_Dependencies.zip. Using that archive keeps the
    # dependency set in sync with winget itself (current releases require
    # Microsoft.WindowsAppRuntime and no longer use Microsoft.UI.Xaml).
    Write-Host "[2/4] Downloading and installing dependencies..."
    $depsZip = Join-Path $workDir "DesktopAppInstaller_Dependencies.zip"
    $depsDir = Join-Path $workDir "deps"
    Invoke-WebRequest -Uri "$downloadBase/DesktopAppInstaller_Dependencies.zip" -OutFile $depsZip -UseBasicParsing
    Expand-Archive -Path $depsZip -DestinationPath $depsDir -Force

    $archDir = Join-Path $depsDir $arch
    if (-not (Test-Path $archDir)) { throw "The dependency archive has no '$arch' folder." }
    $deps = @(Get-ChildItem -Path $archDir -Filter *.appx | Sort-Object Name)
    if ($deps.Count -eq 0) { throw "No dependency packages found for '$arch'." }

    foreach ($dep in $deps) {
        Write-Host "      $($dep.Name)"
        try {
            Add-AppxPackage -Path $dep.FullName
        } catch {
            # 0x80073D06: a higher version of this package is already installed.
            if ($_.Exception.Message -match "0x80073D06") {
                Write-Host "      A newer version is already installed. Skipping."
            } else {
                throw
            }
        }
    }

    # Step 3: Winget (DesktopAppInstaller) for the account running this script.
    Write-Host "[3/4] Downloading and installing Winget (DesktopAppInstaller)..."
    $bundle = Join-Path $workDir "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    Invoke-WebRequest -Uri "$downloadBase/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile $bundle -UseBasicParsing
    Add-AppxPackage -Path $bundle

    # Step 4: Provision for all users (best effort). Add-AppxPackage only registers the
    # package for the account running this script, which is a different account from
    # the logged-in user when UAC prompted for separate admin credentials.
    # Provisioning needs the release's license file, whose name contains a hash, so it
    # can only be found through the API. If that fails, the per-user install still stands.
    Write-Host "[4/4] Provisioning Winget for all users..."
    try {
        $release  = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/tags/$tag" -Headers @{ "User-Agent" = "MiscBatFiles-InstallWinget" }
        $licAsset = $release.assets | Where-Object { $_.name -like "*_License1.xml" } | Select-Object -First 1
        if (-not $licAsset) { throw "No license file found in release $tag." }

        $license = Join-Path $workDir $licAsset.name
        Invoke-WebRequest -Uri $licAsset.browser_download_url -OutFile $license -UseBasicParsing
        Add-AppxProvisionedPackage -Online -PackagePath $bundle -DependencyPackagePath $deps.FullName -LicensePath $license | Out-Null
        Write-Host "      Provisioned. Other accounts will receive Winget at their next sign-in."
    } catch {
        Write-Warning "Provisioning for all users was skipped: $($_.Exception.Message)"
        Write-Warning "Winget is still installed for the current account ($env:USERNAME)."
    }

    $pkg = Get-AppxPackage -Name Microsoft.DesktopAppInstaller
    Write-Host ""
    Write-Host "Success. Winget is installed (DesktopAppInstaller $($pkg.Version)) for $env:USERNAME." -ForegroundColor Green
    Write-Host "Close this window and open a new PowerShell or Command Prompt session to use it."

} catch {
    Write-Host ""
    Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Ensure your internet connection and firewall are not blocking GitHub."
    exit 1

} finally {
    # Clean up temp files regardless of success or failure
    Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
