#Requires -RunAsAdministrator

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"

$current = Get-ItemPropertyValue -Path $regPath -Name LongPathsEnabled -ErrorAction SilentlyContinue
if ($current -eq 1) {
    Write-Host "Long Paths are already enabled on this system. No changes made." -ForegroundColor Yellow
    exit 0
}

Write-Host "Enabling Long Paths in Windows Registry..."

try {
    Set-ItemProperty -Path $regPath -Name LongPathsEnabled -Value 1 -Type DWord -ErrorAction Stop
    Write-Host "Success. Long paths are now enabled." -ForegroundColor Green
    Write-Host "A system reboot may be required for all applications to recognize the change."
} catch {
    Write-Error "Failed to modify the registry: $_"
    exit 1
}
