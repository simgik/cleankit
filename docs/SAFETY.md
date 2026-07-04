# Safety model

CleanKit is intentionally conservative.

## Read-only first

Every interactive run starts with a scan. The scan writes a report and does not remove anything.

## Explicit cleanup choice

Cleanup runs only after the user selects `U`.

## What cleanup can change

- Broken uninstall registry entries
- Broken Start Menu/Desktop shortcuts
- Services/drivers whose configured executable or driver path no longer exists

## What cleanup does not touch

- Browser profiles
- Cookies
- Saved passwords
- Documents
- Game saves
- Arbitrary `%APPDATA%` folders
- Whole `Program Files` directories

## Backups and logs

Registry entries are exported before removal. Shortcuts are moved into a timestamped quarantine folder. Service removal output is logged.
