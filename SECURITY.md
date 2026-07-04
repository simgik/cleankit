# Security Policy

CleanKit can remove stale uninstall registry entries, broken shortcuts, and dead services after explicit user confirmation.

## Supported versions

Only the latest released version is supported.

## Reporting a vulnerability

Open a GitHub issue with the smallest reproduction you can provide.

Do not include passwords, tokens, registry exports containing secrets, or private file paths unless they are required and sanitized.

## Design constraints

- No cleanup runs before a read-only scan.
- Registry uninstall entries are exported before removal.
- Shortcut cleanup is logged and uses a quarantine folder.
- Service cleanup logs the `sc delete` result.
- The tool does not inspect browser profiles, cookies, documents, saved passwords, or arbitrary app data.
