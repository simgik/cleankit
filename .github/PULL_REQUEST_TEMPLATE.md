## Summary

- 

## Safety notes

- [ ] No cleanup action runs before a read-only scan.
- [ ] Registry deletions still export `.reg` backups first.
- [ ] Shortcut cleanup still uses quarantine/logging.
- [ ] Service cleanup still logs `sc delete` output.

## Testing

- [ ] PowerShell syntax check passed.
- [ ] Report-only run tested.
- [ ] Cleanup run tested with a fake broken shortcut.
