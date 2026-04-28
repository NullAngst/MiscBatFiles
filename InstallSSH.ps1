#Requires -RunAsAdministrator

# Check if OpenSSH Server is already installed
$existing = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server*" }
if ($existing.State -eq "Installed") {
    Write-Host "OpenSSH Server is already installed on this system. No changes made." -ForegroundColor Yellow
    exit 0
}

try {
    # Install OpenSSH Server using the capability name resolved at runtime
    Write-Host "Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name $existing.Name -ErrorAction Stop

    # Set service to start automatically and start it now
    Write-Host "Configuring OpenSSH Server to start automatically on boot..."
    Set-Service -Name sshd -StartupType Automatic -ErrorAction Stop

    Write-Host "Starting the OpenSSH Server service..."
    Start-Service -Name sshd -ErrorAction Stop

    # Add firewall rule if one does not already exist
    Write-Host "Checking Windows Firewall for TCP port 22..."
    $ruleName = "OpenSSH Server (sshd)"
    $ruleExists = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($ruleExists) {
        Write-Host "Firewall rule already exists. Skipping." -ForegroundColor Yellow
    } else {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22 -ErrorAction Stop | Out-Null
        Write-Host "Firewall rule added for TCP port 22."
    }

    Write-Host ""
    Write-Host "Success. OpenSSH Server is installed, running, and accepting connections." -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Error "Installation failed: $_"
    Write-Host "Ensure your machine has access to Windows Update servers."
    exit 1
}
