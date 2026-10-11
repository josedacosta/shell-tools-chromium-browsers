# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Repository:** https://github.com/josedacosta/chromium-browsers-tools.git

This repository contains macOS utility scripts for managing Chromium-based browsers. The scripts are located in the `tools/` directory and support multiple browsers through an interactive selection menu.

## Supported Browsers

- Google Chrome (includes Chrome Canary)
  - ⚠️ **Excludes** [Google Chrome for Testing](https://developer.chrome.com/blog/chrome-for-testing) — handled separately
- Chromium
- Brave
- Microsoft Edge
- Opera
- Vivaldi
- Arc

## Repository Structure

```
chromium-browsers-tools/
├── tools/
│   ├── deep-uninstall.sh   # Complete browser uninstaller (interactive selection)
│   ├── export-settings.sh  # Settings export to Markdown (interactive selection)
│   └── find-traces.sh      # Traces finder with .txt report (interactive selection)
├── .github/                # GitHub templates (issues, PR)
├── README.md               # Project documentation
├── LICENSE                 # MIT License
├── CONTRIBUTING.md         # Contribution guidelines
├── CODE_OF_CONDUCT.md      # Code of conduct
├── SECURITY.md             # Security policy
├── .gitignore              # Git ignore rules
└── jose/                   # User prompts/notes (not code)
```

## Scripts

### tools/deep-uninstall.sh
Complete browser removal script for macOS. Removes all traces including profiles, caches, preferences, and system files. Supports all Chromium-based browsers through an interactive menu.

```bash
# Dry-run mode (simulation, no deletion)
bash tools/deep-uninstall.sh --dry-run

# Actual deletion (requires double confirmation)
bash tools/deep-uninstall.sh
```

**Features**:
- Interactive browser selection at startup (1-7 for individual, 8 for all)
- Browser-specific file patterns to prevent cross-contamination
- Double confirmation required before deletion
- Dry-run mode for safe testing
- Keystone/Google Software Update removal (Google Chrome only)

### tools/export-settings.sh
Exports browser settings to a readable Markdown format for manual replication.

```bash
bash tools/export-settings.sh
```

**Requires**: `jq` (install with `brew install jq`)

**Output**: Creates a timestamped folder (`export_settings_{browser}_{timestamp}/`) with:
- `{BROWSER}_SETTINGS.md` - Human-readable settings summary
- `settings_export.json` - Structured JSON export
- `Preferences.json` - Raw browser preferences
- `Local_State.json` - Global browser state

### tools/find-traces.sh
Searches the entire system for remaining browser files and folders.

```bash
bash tools/find-traces.sh
```

**Features**:
- Interactive browser selection at startup (1-7 for individual, 8 for all)
- Full system scan with configurable exclusions
- Browser-specific search patterns
- Reports all matching files and folders
- **Exports results to a `.txt` file** (`browser_traces_{browser}_{timestamp}.txt`) in the current directory for easy sharing with LLMs

## Language Rules

**MANDATORY**: The entire project must be written in **American English**.

This includes:
- All source code
- All comments in code
- All documentation (README, etc.)
- All user-facing messages in scripts
- All variable names and function names

**Exceptions** (French allowed):
- `./jose/` - Personal notes and prompts
- `CLAUDE.md` - Personal instructions file

## Development Guidelines

### Naming Conventions

#### Source files in `./jose/` and `./tools/`
- Use **kebab-case** for all `.sh`, `.txt`, `.json`, and `.md` filenames
- Example: `find-traces.sh`, `configure-github-repo.md`
- **Exception**: `jose/PROMPTS.md` must stay in uppercase

#### Generated output files
- Use **snake_case** for generated output files (e.g., `browser_traces_*.txt`, `export_settings_*/`)

#### GitHub files (`.github/` and root)
- Follow the **most popular convention** for public open source GitHub repositories
- Standard root files: `README.md`, `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`
- Issue templates: `bug_report.md`, `feature_request.md` (snake_case, GitHub default)
- PR template: `PULL_REQUEST_TEMPLATE.md`
- Config files: `CODEOWNERS`, `config.yml`

### Browser Isolation
**CRITICAL**: Always use browser-specific identifiers to prevent cross-contamination:
- Google Chrome: `com.google.Chrome*`, `Google Chrome*` (also covers Chrome Canary: `com.google.Chrome.canary*`)
- Chromium: `org.chromium.Chromium*`, `Chromium*`
- Brave: `com.brave.Browser*`, `BraveSoftware*`, `Brave Browser*`
- Microsoft Edge: `com.microsoft.edgemac*`, `Microsoft Edge*`
- Opera: `com.operasoftware.Opera*`, `Opera*`
- Vivaldi: `com.vivaldi.Vivaldi*`, `Vivaldi*`
- Arc: `company.thebrowser.Browser*`, `Arc*`

**Never use generic patterns** like `*chrome*` that could affect other browsers. Each browser has unique bundle IDs and paths - always verify before adding new removal targets.

### Git Ignore Rules
The following are ignored and should not be committed:
- `browser_traces_*.txt` - Generated trace reports
- `**/export_settings_*/` - Exported settings folders
- `**/*_export*.json` - Export JSON files
- `**/Preferences.json`, `**/Local_State.json` - Raw browser data
- `jose/` - Personal notes
- `CLAUDE.md` - Personal instructions
