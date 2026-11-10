# BoostMyWindows

Open-source tool to make **Windows 10 and 11** faster for gaming, work and everyday use.
Run it, pick a mode (or tick the tweaks you want), let it apply everything, reboot.
It creates a **System Restore point** first, so you can undo it all.

Created by [devcarlos21](https://github.com/devcarlos21).

## Modes

Each mode includes the ones above it. Higher modes trade protection and features for speed.

| Mode | What it does | Keeps you protected? |
|------|--------------|----------------------|
| **Easy** | Power plan, visual effects off, telemetry/ads off, background apps off, temp cleanup, Windows 11 UI tweaks. Safe and reversible. | Yes |
| **Medium** | Easy + disables low-impact services, removes OneDrive and preinstalled bloatware, fixed pagefile. | Yes |
| **Extreme** | Medium + disables Windows Search, fingerprint/Hello, location, remote desktop; removes startup entries; game CPU/network tweaks. | Yes, but some features stop working |
| **YOLO** | Extreme + turns off **Windows Update and Microsoft Defender**. For a play-only PC. | **No antivirus, no patches** |
| **Custom** | A checkbox window (built-in Out-GridView) to pick exactly which tweaks to apply. | Depends on what you tick |

## How to use

1. Clone or download the repo:
   ```bash
   git clone https://github.com/devcarlos21/BoostMyWindows.git
   ```
2. Double-click `EJECUTAR.bat` (it requests administrator rights by itself), or from an admin PowerShell:
   ```powershell
   # Interactive menu:
   powershell -ExecutionPolicy Bypass -File .\BoostMyWindows.ps1

   # Pick a mode directly:
   .\BoostMyWindows.ps1 -Mode Medium

   # Checkbox menu (choose tweak by tweak):
   .\BoostMyWindows.ps1 -Mode Custom

   # Fully unattended, no questions:
   .\BoostMyWindows.ps1 -Mode Medium -Force
   ```
3. Reboot when it finishes.

**To undo:** Start menu -> *Create a restore point* -> *System Restore* -> pick *"Antes de BoostMyWindows"*.

## Read this before running

- Start with **Easy** or **Medium**. They are safe and keep your antivirus and updates on.
- **YOLO leaves the PC with no antivirus and no security patches.** Use it only on a machine you play on - never for banking or risky downloads.
- Disabling services and apps can break features: Windows Search, fingerprint login (Windows Hello), location, remote desktop, some Store apps, Xbox features.
- `-Force` skips the single confirmation. Without it, the script shows the plan and warnings and asks once.
- Turning off Defender needs one manual step: Microsoft requires you to disable **Tamper Protection** by hand in Windows Security. No script can do it for you - the tool pauses and tells you how.
- Not tested on every Windows build. Use at your own risk; the restore point is your way back.

## Roadmap

- [x] Windows 11 support
- [x] Modes: Easy, Medium, Extreme, YOLO
- [x] Checkbox menu to pick what to apply
- [x] Unattended run (`-Force`)
- [ ] Standalone executable with a friendly UI and animations
- [ ] One-click revert of every change
- [ ] English translation of the script output

## Contributing

Issues and pull requests are welcome. Keep tweaks reversible, give each new module a `Tier`
(`Easy`/`Medium`/`Extreme`/`YOLO`) and a `Warn` note describing what may stop working.
