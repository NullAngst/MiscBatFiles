# MiscBatFiles

A collection of Windows scripts for common system configuration and setup tasks. Each script is available as a PowerShell (`.ps1`) version and a Batch (`.bat`) version. All scripts require Administrator privileges.

---

## Scripts

### Enable Long Paths

**Files:** `EnableLongPaths.ps1` / `EnableLongPaths.bat`

Enables Windows Long Path support by setting the `LongPathsEnabled` registry value under `HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem`. This lifts the default 260-character `MAX_PATH` limit for applications that declare themselves long-path aware in their manifest.

**When to use this:** Useful for tools like Node.js/npm and Python that frequently hit path length limits on deep project structures.

**Notes:**

- Checks whether Long Paths are already enabled before making any changes.
- A system reboot may be required for all applications to recognize the change.
- Requires Windows 10 version 1607 or later. The PowerShell version checks this; the Batch version does not.
- Only affects applications that opt in. File Explorer and many older applications still enforce the 260-character limit.
- Git for Windows does not read this setting. Enable it separately with `git config --system core.longpaths true`.

---

### Install Winget

**Files:** `InstallWinget.ps1` / `InstallWinget.bat`

Installs the Windows Package Manager (`winget`) and its dependencies. Intended for Windows LTSC editions, which do not ship with `winget` pre-installed.

**What it does:**

1. Resolves the latest stable `winget-cli` release tag, so every file comes from the same release
2. Downloads that release's `DesktopAppInstaller_Dependencies.zip` and installs the framework packages for your architecture (x64, x86, or ARM64). The dependency set comes from the release itself, so it stays correct when Microsoft changes it
3. Installs Windows Package Manager / DesktopAppInstaller for the account running the script
4. Attempts to provision it for all users, so other accounts receive it at their next sign-in

**Notes:**

- Checks whether `winget` is already available before doing anything.
- `InstallWinget.bat` is a launcher for `InstallWinget.ps1` and requires both files in the same folder.
- Dependencies that are already installed at a newer version are skipped rather than treated as failures.
- If you approve the UAC prompt with a different admin account, the per-user install lands on that admin account. Step 4 covers other accounts, but it needs the GitHub API to locate the release license file. If the API is unreachable or rate limited, step 4 is skipped with a warning and only the running account gets `winget`.
- Temp files are cleaned up automatically after installation, even if the script fails.
- After installation, open a new PowerShell or Command Prompt session before running `winget`.
- Requires an active internet connection with access to GitHub.

---

### Install OpenSSH Server

**Files:** `InstallSSH.ps1` / `InstallSSH.bat`

Installs and configures the OpenSSH Server on Windows, sets the service to start automatically on boot, starts it, and makes sure a Windows Firewall inbound rule for TCP port 22 exists and is enabled.

**What it does:**

1. Resolves the current `OpenSSH.Server` capability name at runtime (no hardcoded version strings) and installs it if it is not already present
2. Sets the `sshd` service to automatic startup
3. Starts the `sshd` service if it is not already running
4. Checks for the `OpenSSH-Server-In-TCP` firewall rule that the capability normally creates. If it exists, it is enabled. If it is missing, it is created

**Notes:**

- Safe to re-run. If OpenSSH Server is already installed, the install step is skipped and the service and firewall configuration are still verified, which repairs a disabled service or a missing rule.
- Reports when a reboot is required to finish the capability install.
- The firewall rule only covers port 22. If you change `Port` in `sshd_config`, update the rule yourself.
- The Batch version uses PowerShell for the firewall step, because `netsh` can only match rules by display name.
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

Scripts downloaded through a browser are marked as coming from the internet, and the default execution policy blocks them. Either unblock them once:

```powershell
Get-ChildItem .\*.ps1 | Unblock-File
```

or bypass the policy for a single run without changing any settings:

```powershell
powershell -ExecutionPolicy Bypass -File .\InstallSSH.ps1
```

Setting `RemoteSigned` alone does not help for downloaded files, since it still requires internet-sourced scripts to be signed.

### Batch

Right-click the desired `.bat` file and select **Run as administrator**.

---

## Requirements

- Windows 10 or Windows 11 (LTSC or standard editions as applicable)
- Administrator privileges
- PowerShell 5.1 or later (built into Windows). Required by all `.ps1` scripts, by `InstallWinget.bat`, and by the firewall step of `InstallSSH.bat`
- Internet access (for `InstallWinget` and `InstallSSH`)

---

## License

MIT License. Copyright (c) 2026 Tyler. See [LICENSE](LICENSE) for full details.
