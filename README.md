# MiscBatFiles

A collection of Windows batch scripts for common system configuration and setup tasks. All scripts require Administrator privileges.

---

## Scripts

### `EnableLongPaths.bat`
Enables Windows Long Path support by setting the `LongPathsEnabled` registry key under `HKLM\SYSTEM\CurrentControlSet\Control\FileSystem`. This lifts the default 260-character `MAX_PATH` limit for applications that support it.

**When to use this:** Necessary for tools like Git, Node.js/npm, and Python package managers that frequently hit path length limits, especially on deep project structures.

**Notes:**
- A system reboot may be required for all applications to recognize the change.
- Requires Windows 10 version 1607 or later.

---

### `InstallWinget.bat`
Installs the Windows Package Manager (`winget`) along with its required dependencies: Microsoft VCLibs and Microsoft UI Xaml 2.8. Intended for Windows LTSC editions, which do not ship with `winget` pre-installed.

**Installs in order:**
1. Microsoft VCLibs x64 14.00 (from Microsoft)
2. Microsoft UI Xaml 2.8 (from GitHub)
3. Windows Package Manager / DesktopAppInstaller (from GitHub)

**Notes:**
- Requires an active internet connection.
- After installation, open a new Command Prompt or PowerShell session before running `winget`.
- Temp files are cleaned up automatically after installation.

---

### `InstallSSH.bat`
Installs and configures the OpenSSH Server on Windows using DISM, sets the service to start automatically on boot, starts it immediately, and adds a Windows Firewall inbound rule for TCP port 22.

**What it does:**
1. Installs `OpenSSH.Server` via DISM (pulls from Windows Update)
2. Sets the `sshd` service to automatic startup
3. Starts the `sshd` service
4. Opens TCP port 22 in Windows Firewall

**Notes:**
- Requires access to Windows Update servers for the DISM installation step.
- If a firewall rule for port 22 already exists, the `netsh` command will silently skip it.

---

## Usage

1. Right-click the desired `.bat` file.
2. Select **Run as administrator**.
3. Follow any on-screen prompts.

All scripts will exit with an error message if they are not run with Administrator privileges.

---

## Requirements

- Windows 10 or Windows 11 (LTSC or standard editions as applicable)
- Administrator privileges
- Internet access (for `InstallWinget.bat` and `InstallSSH.bat`)

---

## License

MIT License. Copyright (c) 2026 Tyler. See [LICENSE](LICENSE) for full details.
