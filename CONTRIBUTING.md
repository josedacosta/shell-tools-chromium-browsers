# Contributing

Thank you for your interest in contributing to this project! Here's how you can help.

## How to Contribute

### Reporting Bugs

1. Check if the issue already exists in [Issues](../../issues)
2. If not, create a new issue with:
   - Your macOS version
   - The browser you were trying to uninstall
   - The exact error message or unexpected behavior
   - Steps to reproduce the issue

### Suggesting Features

1. Open an issue with the `enhancement` label
2. Describe the feature and why it would be useful
3. If possible, suggest an implementation approach

### Submitting Changes

1. Fork the repository
2. Create a new branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Test your changes on macOS
5. Commit with a clear message (`git commit -m "Add feature X"`)
6. Push to your fork (`git push origin feature/my-feature`)
7. Open a Pull Request

## Code Guidelines

### Language

- All code, comments, and documentation must be in **American English**
- Exception: `jose/` folder (personal notes)

### Naming Conventions

- Use `kebab-case` for `.sh` script filenames (e.g., `find-traces.sh`)
- Use `snake_case` for generated output files

### Browser Isolation

**CRITICAL**: Always use browser-specific identifiers to prevent cross-contamination.

```
Google Chrome: com.google.Chrome*, Google Chrome*
Chromium:      org.chromium.Chromium*, Chromium*
Brave:         com.brave.Browser*, BraveSoftware*
Edge:          com.microsoft.edgemac*, Microsoft Edge*
Opera:         com.operasoftware.Opera*, Opera*
Vivaldi:       com.vivaldi.Vivaldi*, Vivaldi*
Arc:           company.thebrowser.Browser*, Arc*
```

**Never** use generic patterns like `*chrome*` that could affect other browsers.

### Testing

Before submitting:

1. Run `bash -n script.sh` to check syntax
2. Test with `--dry-run` mode when available
3. Test on a real macOS system (these scripts are macOS-only)

## Questions?

Feel free to open an issue if you have questions about contributing.
