<div align="center">

```
 ██████╗██╗  ██╗██████╗  ██████╗ ███╗   ███╗██╗██╗   ██╗███╗   ███╗
██╔════╝██╔══██║██╔══██╗██╔═══██╗████╗ ████║██║██║   ██║████╗ ████║
██║     ███████║██████╔╝██║   ██║██╔████╔██║██║██║   ██║██╔████╔██║
██║     ██╔══██║██╔══██╗██║   ██║██║╚██╔╝██║██║██║   ██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║╚██████╔╝██║ ╚═╝ ██║██║╚██████╔╝██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝
          ─────── BROWSERS TOOLS ───────
```

**Deep uninstall scripts for Chromium-based browsers on macOS**

[![Platform](https://img.shields.io/badge/platform-macOS-blue?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/shell-bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-yellow?style=for-the-badge)](LICENSE)

</div>

---

> [!NOTE]
> **Platform:** macOS only (macOS 10.15 Catalina or later)
> **Shell:** Bash (GNU bash 3.2+, included with macOS)
> **Dependencies:** `jq` (only for `tools/export-settings.sh` — install with `brew install jq`)

---

## Why This Repository?

### The Problem

On macOS, simply dragging a browser to the Trash **does not actually uninstall it**. Chromium-based browsers leave behind a significant amount of residual data scattered across your system:

- **User profiles** in `~/Library/Application Support/`
- **Caches** in `~/Library/Caches/`
- **Preferences** (`.plist` files) in `~/Library/Preferences/`
- **Cookies** in `~/Library/Cookies/`
- **Saved states** in `~/Library/Saved Application State/`
- **Launch agents** in `~/Library/LaunchAgents/`
- **Logs and crash reports** in `~/Library/Logs/`
- **System-level files** in `/Library/`
- **Temporary files** in `/tmp/` and `/private/var/folders/`
- And much more...

When you reinstall the browser, **all this residual data is reused**. This means:
- Old corrupted settings may cause bugs or slowdowns
- Privacy-sensitive data (cookies, history) persists
- You never get the "fresh install" experience
- Performance issues from previous installs carry over

### The Solution

This repository provides Bash scripts for **complete, deep cleaning** of Chromium-based browsers on macOS. The goal is simple: **start from scratch** with a truly clean slate, as if the browser had never been installed on your machine.

---

## What Each Script Does

| Script | Purpose |
|--------|---------|
| [`tools/export-settings.sh`](tools/export-settings.sh) | **Backup** — Exports your settings to a readable file before uninstalling |
| [`tools/deep-uninstall.sh`](tools/deep-uninstall.sh) | **Complete removal** — Deletes the browser AND all its traces from the entire system |
| [`tools/find-traces.sh`](tools/find-traces.sh) | **Verification** — Scans your system to find any remaining browser files |

### Recommended Workflow

1. **Export your settings** with `tools/export-settings.sh` (optional but recommended)
2. **Preview the deletion** with `tools/deep-uninstall.sh --dry-run`
3. **Run the deep uninstall** with `tools/deep-uninstall.sh`
4. **Verify the cleanup** with `tools/find-traces.sh`
5. **Reinstall the browser** fresh from the official website
6. **Reconfigure manually** using your exported settings file

---

## Supported Browsers

| Browser | Bundle ID | Application Support Path |
|---------|-----------|--------------------------|
| Google Chrome ¹ | `com.google.Chrome` | `~/Library/Application Support/Google/Chrome` |
| Chromium | `org.chromium.Chromium` | `~/Library/Application Support/Chromium` |
| Brave | `com.brave.Browser` | `~/Library/Application Support/BraveSoftware/Brave-Browser` |
| Microsoft Edge | `com.microsoft.edgemac` | `~/Library/Application Support/Microsoft Edge` |
| Opera | `com.operasoftware.Opera` | `~/Library/Application Support/com.operasoftware.Opera` |
| Vivaldi | `com.vivaldi.Vivaldi` | `~/Library/Application Support/Vivaldi` |
| Arc | `company.thebrowser.Browser` | `~/Library/Application Support/Arc` |

¹ **Google Chrome** also includes **Chrome Canary** — they share the same Google Keystone updater and are removed together.

> [!WARNING]
> [Google Chrome for Testing](https://developer.chrome.com/blog/chrome-for-testing) is **NOT removed** by these scripts. It's a separate installation used by testing tools (Playwright, Puppeteer) and will be handled by a dedicated script.

---

## Available Scripts

### 1. `tools/deep-uninstall.sh` — Complete Uninstaller

**Purpose**: Completely remove a browser and ALL its traces from the system.

This script performs a full purge, going far beyond a simple uninstall. It removes:

| Category | What Gets Removed |
|----------|-------------------|
| Application | `.app` file from `/Applications` and `~/Applications` |
| User profiles | Bookmarks, passwords, history, extensions, browsing data |
| Caches | All browser and helper caches |
| Cookies | `.binarycookies` files and cookie folders |
| Preferences | `.plist` files in `~/Library/Preferences` |
| Launch Agents | Auto-start services |
| Keystone | Google Software Update (Chrome only) |
| Saved State | Saved application states |
| Logs | Logs and crash reports |
| Containers | Sandboxed data |
| Temporary files | In `/tmp`, `/private/var/folders`, etc. |
| System files | In `/Library` (requires sudo) |
| Dock | Removes icon from Dock |

#### Usage

```bash
# Dry-run mode (no deletion)
bash tools/deep-uninstall.sh --dry-run

# Actual deletion (requires double confirmation)
bash tools/deep-uninstall.sh
```

#### Built-in Safety Features

1. **Double confirmation**: You must type `YES` then a specific phrase (e.g., `DELETE CHROME`)
2. **5-second countdown**: Delay before deletion starts
3. **Dry-run mode**: Preview what would be deleted without removing anything
4. **Browser isolation**: Each browser uses its own identifiers, no risk of deleting another browser's files

#### Interactive Menu

<details>
<summary>Click to see the interactive menu</summary>

```
Select a browser to uninstall:

  1) Google Chrome (includes Chrome Canary)
  2) Chromium
  3) Brave
  4) Microsoft Edge
  5) Opera
  6) Vivaldi
  7) Arc
  8) All browsers    <- Removes ALL browsers
```

</details>

---

### 2. `tools/find-traces.sh` — Traces Finder

**Purpose**: Scan the system to find all remaining files/folders from a browser.

Useful for:
- Verifying that an uninstall is complete
- Finding leftover files after a manual uninstall
- Diagnosing issues related to residual files

#### Usage

```bash
bash tools/find-traces.sh
```

#### How It Works

1. Displays a browser selection menu
2. Scans the entire system (`/`) with configurable exclusions
3. Uses browser-specific patterns
4. Displays a list of all found files/folders
5. Shows a summary with total count and scan duration

#### Default Exclusions

- `~/Projects` - Avoids scanning your development projects
- `~/.Trash` - Ignores the trash

#### Search Patterns (Google Chrome example)

```
*google*chrome*
*chrome*google*
*com.google.Chrome*
*Google Chrome*
```

---

### 3. `tools/export-settings.sh` — Settings Export

**Purpose**: Export browser settings in a readable format for manual replication.

Useful for:
- Backing up your configuration before reinstalling
- Documenting your current settings
- Migrating settings to another browser

#### Prerequisites

```bash
brew install jq
```

#### Usage

```bash
bash tools/export-settings.sh
```

#### Generated Files

The script creates a timestamped folder containing:

| File | Description |
|------|-------------|
| `{BROWSER}_SETTINGS.md` | Human-readable Markdown summary of all settings |
| `settings_export.json` | Structured JSON export |
| `Preferences.json` | Raw browser preferences file |
| `Local_State.json` | Global browser state |

#### Exported Information

- **Installed extensions**: Name, version, ID, permissions
- **Privacy settings**: Cookies, tracking, secure DNS
- **Search engines**: Default and custom
- **Content settings**: JavaScript, popups, notifications
- **Appearance settings**: Theme, homepage, startup tab
- **Network settings**: Proxy, prefetch
- **Profile information**: Name, path, Google account (if applicable)

---

## Security and Isolation

**CRITICAL**: Each script uses UNIQUE identifiers per browser to prevent cross-contamination.

Example - If you select Vivaldi:
- Only `com.vivaldi.Vivaldi*` and `Vivaldi*` files are targeted
- No Google Chrome, Brave, etc. files are touched
- Google Keystone sections are skipped (reserved for Chrome)

This isolation is guaranteed by:
1. Browser-specific variables (`BUNDLE_ID`, `APP_NAME`, etc.)
2. Explicit conditions (`if [[ "$HAS_KEYSTONE" == true ]]`)
3. Unique search patterns for each browser

---

## Usage Examples

### Scenario 1: Clean Chrome Reinstall

```bash
# 1. Export current settings
bash tools/export-settings.sh
# Choose 1) Google Chrome

# 2. Preview what will be deleted
bash tools/deep-uninstall.sh --dry-run
# Choose 1) Google Chrome

# 3. Completely remove Chrome
bash tools/deep-uninstall.sh
# Choose 1) Google Chrome
# Confirm with YES then DELETE CHROME

# 4. Verify nothing remains
bash tools/find-traces.sh
# Choose 1) Google Chrome
# Should display "No Google Chrome traces found!"

# 5. Reinstall Chrome and manually reconfigure
# using the exported CHROME_SETTINGS.md file
```

### Scenario 2: Remove All Browsers

```bash
# Remove ALL Chromium browsers
bash tools/deep-uninstall.sh
# Choose 8) All browsers
# Confirm with YES then DELETE ALL BROWSERS
```

### Scenario 3: Diagnostics

```bash
# Chrome behaving strangely? Look for residual files
bash tools/find-traces.sh
# Choose 1) Google Chrome
```

---

## Important Notes

> [!CAUTION]
> **Back up your data** before using `tools/deep-uninstall.sh` — deletion is **IRREVERSIBLE**

> [!TIP]
> **Always use `--dry-run` first** to see what will be deleted before running the actual deletion

- **Keychain** requires manual intervention (instructions provided at script end)
- **System files** in `/Library` require administrator rights (sudo)

---

## System Requirements

| Requirement | Details |
|-------------|---------|
| **Operating System** | macOS 10.15 Catalina or later (darwin) |
| **Shell** | Bash 3.2+ (included with macOS by default) |
| **Terminal** | Any macOS terminal (Terminal.app, iTerm2, etc.) |
| **Dependencies** | `jq` — only required for `tools/export-settings.sh` |

### Installing Dependencies

```bash
# Install jq using Homebrew
brew install jq
```

### Verifying Your Shell

```bash
# Check your Bash version
bash --version
# Should output: GNU bash, version 3.2.57 or later
```

> [!IMPORTANT]
> These scripts use macOS-specific paths (`~/Library/Application Support/`, `/Library/`, etc.) and commands. They are **not compatible** with Linux or Windows without modification.

---

## License

This project is licensed under the [MIT License](LICENSE) — free to use, modify, and distribute.
