# Security Policy

## Scope

These scripts run with user-level permissions by default, with optional `sudo` for system-level cleanup. They only delete browser-related files and do not collect, transmit, or store any user data.

## Reporting a Vulnerability

If you discover a security issue, please report it by:

1. **Do NOT** open a public issue
2. Send an email or private message to the maintainer
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Features

### Built-in Safeguards

- **Dry-run mode**: Preview deletions without removing anything (`--dry-run`)
- **Double confirmation**: Requires typing `YES` then a specific phrase
- **5-second countdown**: Delay before deletion starts
- **Browser isolation**: Each browser uses unique identifiers to prevent cross-contamination

### What These Scripts Do NOT Do

- Collect or transmit any data
- Modify system files outside browser-related paths
- Run without user confirmation
- Delete files from other applications

## Best Practices

1. **Always run `--dry-run` first** to review what will be deleted
2. **Export your settings** before uninstalling (`tools/export-settings.sh`)
3. **Review the code** if you have concerns — it's open source
