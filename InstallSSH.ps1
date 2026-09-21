#Requires -RunAsAdministrator

# Internal name of the rule the OpenSSH.Server capability creates on install.
# Matching on Name (not DisplayName) is locale independent and avoids duplicates.
$ruleName        = "OpenSSH-Server-In-TCP"
$ruleDisplayName = "OpenSSH Server (sshd)"   # Display name used by earlier versions of this script
$restartNeeded   = $false

try {
    $capability = Get-WindowsCapability -Online -ErrorAction Stop |
        Where-Object { $_.Name -like "OpenSSH.Server*" } |
        Select-Object -First 1

    if (-not $capability) {
        throw "No OpenSSH.Server capability is available on this system."
    }

    if ($capability.State -eq "Installed") {
        Write-Host "OpenSSH Server is already installed. Verifying service and firewall configuration..." -ForegroundColor Yellow
    } else {
        # Install using the capability name resolved at runtime
        Write-Host "Installing $($capability.Name)..."
        $result = Add-WindowsCapability -Online -Name $capability.Name -ErrorAction Stop
        if ($result.RestartNeeded) { $restartNeeded = $true }
    }

    Write-Host "Configuring OpenSSH Server to start automatically on boot..."
    Set-Service -Name sshd -StartupType Automatic -ErrorAction Stop

    $service = Get-Service -Name sshd -ErrorAction Stop
    if ($service.Status -eq "Running") {
        Write-Host "The sshd service is already running."
    } else {
        Write-Host "Starting the OpenSSH Server service..."
        Start-Service -Name sshd -ErrorAction Stop
    }

    Write-Host "Checking Windows Firewall for TCP port 22..."
    $rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
    if (-not $rule) {
        $rule = Get-NetFirewallRule -DisplayName $ruleDisplayName -ErrorAction SilentlyContinue
    }

    if ($rule) {
        if ($rule | Where-Object { $_.Enabled -ne "True" }) {
            $rule | Enable-NetFirewallRule -ErrorAction Stop
            Write-Host "Existing firewall rule was disabled. Enabled it."
        } else {
            Write-Host "Firewall rule already exists. Skipping." -ForegroundColor Yellow
        }
    } else {
        New-NetFirewallRule -Name $ruleName -DisplayName $ruleDisplayName -Enabled True `
            -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 -ErrorAction Stop | Out-Null
        Write-Host "Firewall rule added for TCP port 22."
    }

    Write-Host ""
    Write-Host "Success. OpenSSH Server is installed and running, and inbound TCP 22 is allowed." -ForegroundColor Green
    if ($restartNeeded) {
        Write-Host "A reboot is required to complete the installation." -ForegroundColor Yellow
    }

} catch {
    Write-Host ""
    Write-Error "Installation failed: $_"
    Write-Host "Ensure your machine has access to Windows Update servers."
    exit 1
}
