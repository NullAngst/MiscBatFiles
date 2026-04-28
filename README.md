# MiscBatFiles

A collection of Windows scripts for common system configuration and setup tasks. Each script is available in two formats -- a PowerShell (`.ps1`) version and a legacy Batch (`.bat`) version. All scripts require Administrator privileges.

---

## Scripts

### Enable Long Paths
**Files:** `EnableLongPaths.ps1` / `EnableLongPaths.bat`

Enables Windows Long Path support by setting the `LongPathsEnabled` registry key under `HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem`. This lifts the default 260-character `MAX_PATH` limit for applications that support it.

**When to use this:** Necessary for tools like Git, Node.js/npm, and Python package managers that frequently hit path length limits, especially on deep project structures.

**Notes:**
- Checks whether Long Paths are already enabled before making any changes.
- A system reboot may be required for all applications to recognize the change.
- Requires Windows 10 version 1607 or later.

---

### Install Winget
**Files:** `InstallWinget.ps1` / `InstallWinget.bat`

Installs the Windows Package Manager (`winget`) along with its required dependencies: Microsoft VCLibs and Microsoft UI Xaml. Intended for Windows LTSC editions, which do not ship with `winget` pre-installed.

**Installs in order:**
1. Microsoft VCLibs x64 14.00 (from Microsoft)
2. Microsoft UI Xaml -- latest stable release, resolved dynamically from the GitHub API at runtime
3. Windows Package Manager / DesktopAppInstaller -- latest stable release (from GitHub)

**Notes:**
- Checks whether `winget` is already installed before doing anything.
- Temp files are cleaned up automatically after installation, even if the script fails.
- After installation, open a new PowerShell or Command Prompt session before running `winget`.
- Requires an active internet connection with access to GitHub and Microsoft servers.

---

### Install OpenSSH Server
**Files:** `InstallSSH.ps1` / `InstallSSH.bat`

Installs and configures the OpenSSH Server on Windows, sets the service to start automatically on boot, starts it immediately, and adds a Windows Firewall inbound rule for TCP port 22.

**What it does:**
1. Resolves and installs the current `OpenSSH.Server` capability dynamically at runtime -- no hardcoded version strings
2. Sets the `sshd` service to automatic startup
3. Starts the `sshd` service
4. Adds a Windows Firewall rule for TCP port 22, or skips it with a notice if one already exists

**Notes:**
- Checks whether OpenSSH Server is already installed before making any changes.
- Requires access to Windows Update servers for capability installation.

---

## Usage

### PowerShell (recommended)

All `.ps1` scripts require an elevated PowerShell session. Right-click the PowerShell icon, select **Run as Administrator**, then run the script:

```powershell
.\EnableLongPaths.ps1
.\InstallWinget.ps1
.\InstallSSH.ps1
```

If you see an error about execution policy, run this once in your elevated session first:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Batch

Right-click the desired `.bat` file and select **Run as administrator**.

---

## Requirements

- Windows 10 or Windows 11 (LTSC or standard editions as applicable)
- Administrator privileges
- PowerShell 5.1 or later for `.ps1` scripts (built into Windows)
- Internet access (for `InstallWinget` and `InstallSSH`)

---

## License

MIT License. Copyright (c) 2026 Tyler. See [LICENSE](LICENSE) for full details.
