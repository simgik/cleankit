# Contributing

Keep changes small and safety-first.

Before opening a pull request:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package.ps1
```

For cleanup behavior, test with a fake broken shortcut first:

1. Create a Desktop shortcut pointing to `C:\does-not-exist.exe`.
2. Run `CleanKit.bat`.
3. Choose report-only first.
4. Run again and choose cleanup.
5. Confirm that the shortcut moved into the timestamped `quarantine-*` folder.

Do not add broad filesystem cleanup without a separate safety design.
