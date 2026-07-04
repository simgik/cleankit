# CleanKit
> wersja polska poniżej

A cautious Windows cleanup toolkit with report-first scans, backups, and explicit cleanup confirmation.
CleanKit is focused on safe, explainable cleanup instead of registry-cleaner magic. It starts with stale app entries, broken shortcuts, and dead services, but the name leaves room for future cleanup modules.

## Features
- Read-only scan first
- Explicit cleanup confirmation after the report
- Registry export before uninstall entry removal
- Shortcut quarantine instead of silent deletion
- Service cleanup with logged `sc delete` output
- Per-run report and action log on the Desktop
- Polish and English launcher
- No browser profile, cookie, password, document, or game-save scanning

## Requirements
- Windows 10 or Windows 11
- Windows PowerShell 5.1
- Administrator rights for complete cleanup

## Quick start
Run the default Polish launcher:
```text
CleanKit.bat
```

Or choose a language explicitly:
```text
CleanKit-PL.bat
CleanKit-EN.bat
```

The app asks for administrator elevation. This is required for full cleanup of registry entries, system Start Menu shortcuts, and services.
Every run starts with a report-only scan. After that you choose whether to clean or keep only the report.
Results are written to:

```text
Desktop\CleanKit\
```

Reports and logs use timestamps in file names, for example:

```text
CleanKit-report-20260704-135500.txt
CleanKit-actions-20260704-135500.log
quarantine-20260704-135500\
```

## What it scans
CleanKit checks:
- `HKLM` and `HKCU` uninstall registry entries with missing install/icon paths
- Start Menu and Desktop `.lnk` shortcuts with missing targets
- Windows services/drivers whose configured `.exe` or `.sys` path no longer exists

## What it does not scan
It does not scan:
- browser profiles
- cookies
- saved passwords
- documents
- game saves
- arbitrary app data
- whole `Program Files` folders
This is intentional. Those areas need app-specific handling and are outside the current safety model.

## Files
- `CleanKit.bat` - default Polish launcher
- `CleanKit-PL.bat` - Polish launcher
- `CleanKit-EN.bat` - English launcher
- `CleanKit.ps1` - interactive wrapper
- `Scan-CleanKit.ps1` - scan and cleanup engine

## Build release zip
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package.ps1
```
The zip is created in:
```text
dist\
```

## Safe test
1. Create a Desktop shortcut pointing to a fake path, for example `C:\does-not-exist.exe`.
2. Run `CleanKit.bat`.
3. Confirm that the scanned profile is your real Windows profile.
4. Choose report-only first and inspect the report.
5. Run again and choose cleanup.
6. Confirm that the fake shortcut moved into the timestamped `quarantine-*` folder.
**Do not choose cleanup if the report contains entries you do not recognize**

## Cleankit
CleanKit to ostrozny zestaw narzedzi do sprzatania Windowsa. Najpierw robi raport, potem pyta, czy ma usuwac/przenosic znalezione elementy.

Aktualnie sprawdza:
- nieaktualne wpisy Dodaj/usun programy
- martwe skroty z Menu Start i Pulpitu
- uslugi/sterowniki wskazujace na nieistniejace pliki
Nie dotyka profili przegladarek, ciasteczek, hasel, dokumentow, save'ow gier ani losowych katalogow AppData.

**Safety details: [docs/SAFETY.md](docs/SAFETY.md).**
**License: MIT**
**Author: simgik**
> Development note: CleanKit is built by simgik with AI-assisted coding and manual review/testing - 04/07/2026 18:15
