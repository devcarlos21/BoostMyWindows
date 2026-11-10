# BoostMyWindows

Open-source tool to make Windows 10 (and soon 11) faster for gaming, work and everyday use.
Run it, let it apply the tweaks, reboot. It creates a restore point first, so you can undo everything.

> **Status: early version.** Today it is a single aggressive PowerShell script for **Windows 10**.
> The modes, the checkbox menu, Windows 11 support and the executable are the plan, not done yet
> (see [Roadmap](#roadmap)).

## What the current script does

- Creates a **System Restore point** before touching anything.
- Power plan: Ultimate Performance, no core parking, no hibernation, no fast startup.
- Minimal visual effects, mouse acceleration off.
- Disables ~60 unneeded services (telemetry, Xbox, SysMain, search indexing, Windows Update...).
- Disables third-party and telemetry scheduled tasks, removes startup entries (a backup list is saved to the Desktop).
- Uninstalls OneDrive and the built-in Windows apps (keeps Store, Calculator, Photos, codecs).
- **Turns off Microsoft Defender and Windows Update.**
- Fixed-size pagefile on the SSD, higher CPU priority for games.
- Finds `gta_sa.exe` and `speed.exe` (GTA San Andreas, NFS Most Wanted 2005) and sets high priority, run as admin and no fullscreen optimizations.
- Installs DirectX 9 runtime, cleans temp files and component store, runs TRIM.
- Writes a log to the Desktop (`optimizacion-log.txt`).

## Read this before running it

This is the "YOLO" profile: it is meant for a PC you use mainly to play.

- With Defender and Windows Update off, the PC gets **no antivirus and no patches**. Do not use it for banking or risky downloads.
- Removing apps and services can break things (Xbox features, Windows search, Cortana, some Store apps, remote desktop...).
- It still asks you to press ENTER once and, if Tamper Protection is on, to turn it off by hand in Windows Security.
- Not tested on every Windows build. Use at your own risk; the restore point is your way back.

## How to use

1. Download or clone this repo:
   ```bash
   git clone https://github.com/devcarlos21/BoostMyWindows.git
   ```
2. Double-click `EJECUTAR.bat` (it asks for administrator rights by itself), or run in an admin PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\optimizar-windows10.ps1
   ```
3. Follow the prompts and reboot when it finishes.

**To undo:** Start menu → *Create a restore point* → *System Restore* → pick *"Antes de optimizar para juegos"*.

## Roadmap

- [ ] Windows 11 support
- [ ] Modes: Easy, Medium, Extreme, YOLO (with warnings on what may stop working)
- [ ] Checkbox menu to pick what to remove or keep
- [ ] Fully unattended run (no ENTER, handle Defender Tamper Protection automatically where possible)
- [ ] Standalone executable with a friendly UI and animations
- [ ] One-click revert of every change
- [ ] English translation of the script output

## Contributing

Issues and pull requests are welcome. Keep tweaks safe and reversible, and tag the risk level (Easy / Medium / Extreme / YOLO) of anything you add.

## Author

Created by [devcarlos21](https://github.com/devcarlos21).
