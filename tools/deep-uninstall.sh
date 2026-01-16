#!/bin/bash
# =============================================================================
# Complete Chromium-based Browser Deep Uninstaller
# =============================================================================
#
# PLATFORM:     macOS only (requires macOS 10.15 Catalina or later)
# SHELL:        Bash (tested with GNU bash 3.2+)
# CREATED:      2026-01-16
#
# DESCRIPTION:
#   This script PERMANENTLY removes ALL traces of the selected Chromium-based
#   browser from your macOS system, including profiles, caches, preferences,
#   cookies, extensions, and system-level files.
#
# SUPPORTED BROWSERS:
#   Google Chrome, Chromium, Brave, Microsoft Edge, Opera, Vivaldi, Arc
#
# USAGE:
#   bash deep-uninstall.sh              # Interactive mode with confirmation
#   bash deep-uninstall.sh --dry-run    # Preview mode (no deletion)
#
# WARNING:
#   This operation is IRREVERSIBLE. Always run with --dry-run first!
#
# NOTE:
#   This script prioritizes functionality over code elegance. It may be long,
#   repetitive, and not fully optimized. Code refactoring is planned for a
#   future version.
#
# =============================================================================

# Colors for display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Bold colors
BOLD_RED='\033[1;31m'
BOLD_YELLOW='\033[1;33m'
BOLD_GREEN='\033[1;32m'
BOLD_WHITE='\033[1;37m'

# Background colors
BG_RED='\033[41m'
BG_YELLOW='\033[43m'
BG_BLACK='\033[40m'

# Blinking
BLINK='\033[5m'

# Dry-run mode
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_kill() {
    echo -e "${MAGENTA}[KILL]${NC} $1"
}

# Function to remove a file/folder
remove_item() {
    local path="$1"
    local description="$2"

    if [[ -e "$path" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove: $path"
        else
            rm -rf "$path" 2>/dev/null && log_success "Removed: $description" || log_warning "Could not remove: $path"
        fi
    fi
}

# Function to remove files matching a glob pattern
remove_pattern() {
    local pattern="$1"
    local description="$2"

    for item in $pattern; do
        if [[ -e "$item" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove: $item"
            else
                rm -rf "$item" 2>/dev/null && log_success "Removed: $item" || log_warning "Could not remove: $item"
            fi
        fi
    done
}

# Function to remove files using find
remove_find() {
    local search_path="$1"
    local name_pattern="$2"

    if [[ -d "$search_path" ]]; then
        find "$search_path" -name "$name_pattern" 2>/dev/null | while read -r item; do
            if [[ -e "$item" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove: $item"
                else
                    rm -rf "$item" 2>/dev/null && log_success "Removed: $(basename "$item")"
                fi
            fi
        done
    fi
}

# =============================================================================
# BROWSER SELECTION
# =============================================================================
clear
echo ""
echo -e "${CYAN}${BOLD_WHITE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD_WHITE}║              CHROMIUM-BASED BROWSER UNINSTALLER                          ║${NC}"
echo -e "${CYAN}${BOLD_WHITE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD_WHITE}Select a browser to uninstall:${NC}"
echo ""
echo -e "  1) Google Chrome ${DIM}(includes Chrome Canary)${NC}"
echo "  2) Chromium"
echo "  3) Brave"
echo "  4) Microsoft Edge"
echo "  5) Opera"
echo "  6) Vivaldi"
echo "  7) Arc"
echo -e "  8) ${RED}All browsers${NC}"
echo ""
read -p "Enter your choice (1-8): " browser_choice
echo ""

# Handle "All browsers" option
DELETE_ALL=false
if [[ "$browser_choice" == "8" ]]; then
    DELETE_ALL=true
    BROWSER_NAME="ALL BROWSERS"
    BROWSER_NAME_UPPER="ALL BROWSERS"
    DELETE_PHRASE="DELETE ALL BROWSERS"
fi

# =============================================================================
# SET BROWSER-SPECIFIC VARIABLES
# CRITICAL: Each browser has UNIQUE identifiers to prevent cross-contamination
# =============================================================================
case "$browser_choice" in
    1)
        BROWSER_NAME="Google Chrome"
        BROWSER_NAME_UPPER="GOOGLE CHROME"
        APP_NAME="Google Chrome.app"
        # Additional apps to remove (Canary, Dev, etc.)
        ADDITIONAL_APPS=("Google Chrome Canary.app")
        BUNDLE_ID="com.google.Chrome"
        # Process names to kill
        PROCESS_NAMES=("Google Chrome" "Google Chrome Helper" "Google Chrome Canary" "Google Chrome Dev")
        # Application Support paths
        APP_SUPPORT_PATHS=(
            "$HOME/Library/Application Support/Google/Chrome"
            "$HOME/Library/Application Support/Google/Chrome Dev"
            "$HOME/Library/Application Support/Google/Chrome Canary"
            "$HOME/Library/Application Support/Google/GoogleUpdater"
            "$HOME/Library/Application Support/Google/RLZ"
            "$HOME/Library/Application Support/Google/Measurement"
            "$HOME/Library/Application Support/Google/RemoteConfig"
            "$HOME/Library/Application Support/Google/consentOptions"
        )
        # Cache paths
        CACHE_PATHS=(
            "$HOME/Library/Caches/Google/Chrome"
            "$HOME/Library/Caches/Google/Chrome Canary"
            "$HOME/Library/Caches/Google"
            "$HOME/Library/Caches/com.google.Chrome"
            "$HOME/Library/Caches/com.google.Chrome.helper"
            "$HOME/Library/Caches/com.google.Chrome.canary"
            "$HOME/Library/Caches/com.google.Chrome.canary.helper"
            "$HOME/Library/Caches/com.google.GoogleUpdater"
            "$HOME/Library/Caches/com.google.Keystone"
            "$HOME/Library/Caches/com.google.Keystone.Agent"
            "$HOME/Library/Caches/com.google.SoftwareUpdate"
            "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.google.Chrome"
            "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.google.Chrome.canary"
        )
        # Preferences
        PREF_FILES=(
            "$HOME/Library/Preferences/com.google.Chrome.plist"
            "$HOME/Library/Preferences/com.google.Chrome.canary.plist"
            "$HOME/Library/Preferences/com.google.Chrome.helper.plist"
            "$HOME/Library/Preferences/com.google.Chrome.canary.helper.plist"
            "$HOME/Library/Preferences/com.google.Chrome.renderer.plist"
            "$HOME/Library/Preferences/com.google.Chrome.canary.renderer.plist"
            "$HOME/Library/Preferences/com.google.Keystone.plist"
            "$HOME/Library/Preferences/com.google.Keystone.Agent.plist"
            "$HOME/Library/Preferences/com.google.antigravity.plist"
            "$HOME/Library/Preferences/com.google.gmp.measurement.monitor.plist"
        )
        PREF_PATTERNS=(
            "$HOME/Library/Preferences/ByHost/com.google.antigravity.ShipIt.*.plist"
            "$HOME/Library/Preferences/ByHost/com.google.Chrome.*.plist"
            "$HOME/Library/Preferences/ByHost/com.google.Keystone.*.plist"
        )
        # Cookies
        COOKIE_FILES=(
            "$HOME/Library/Cookies/com.google.Chrome.binarycookies"
            "$HOME/Library/Cookies/com.google.Chrome.canary.binarycookies"
        )
        COOKIE_PATTERNS=(
            "$HOME/Library/Cookies/com.google.Chrome*"
            "$HOME/Library/Cookies/com.google.Chrome.canary*"
        )
        # Launch Agents
        LAUNCH_AGENT_FILES=(
            "$HOME/Library/LaunchAgents/com.google.keystone.agent.plist"
            "$HOME/Library/LaunchAgents/com.google.keystone.xpcservice.plist"
            "$HOME/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist"
            "$HOME/Library/LaunchAgents/com.google.Chrome.plist"
        )
        # HTTP Storages
        HTTP_STORAGE_PATHS=(
            "$HOME/Library/HTTPStorages/com.google.Chrome"
            "$HOME/Library/HTTPStorages/com.google.GoogleUpdater"
            "$HOME/Library/HTTPStorages/com.google.Keystone"
            "$HOME/Library/HTTPStorages/com.google.antigravity"
        )
        # Containers
        CONTAINER_PATHS=(
            "$HOME/Library/Containers/com.google.Chrome"
            "$HOME/Library/Containers/com.google.Chrome.helper"
        )
        APP_SCRIPTS_PATHS=()
        # Logs
        LOG_PATHS=(
            "$HOME/Library/Logs/Google"
            "$HOME/Library/Logs/Google/Chrome"
            "$HOME/Library/Logs/com.google.Chrome"
            "$HOME/Library/Logs/GoogleSoftwareUpdateAgent.log"
        )
        # WebKit
        WEBKIT_PATHS=(
            "$HOME/Library/WebKit/Google/Chrome"
            "$HOME/Library/WebKit/com.google.Chrome"
        )
        # Saved State pattern
        SAVED_STATE_PATTERN="com.google.Chrome*.savedState"
        # Group Container pattern
        GROUP_CONTAINER_PATTERN="*com.google.Chrome*"
        # Crash report patterns
        CRASH_PATTERNS=("Google Chrome*" "com.google.Chrome*")
        # Temp file patterns
        TEMP_PATTERNS=(".com.google.Chrome.*" "com.google.Chrome*" "Google Chrome*" "com.google.Keystone*" "com.google.Chrome*.code_sign_clone")
        # Has Keystone updater
        HAS_KEYSTONE=true
        # Keychain Safe Storage name
        SAFE_STORAGE_NAME="Chrome Safe Storage"
        # Second confirmation phrase
        DELETE_PHRASE="DELETE CHROME"
        ;;
    2)
        BROWSER_NAME="Chromium"
        BROWSER_NAME_UPPER="CHROMIUM"
        APP_NAME="Chromium.app"
        ADDITIONAL_APPS=()
        BUNDLE_ID="org.chromium.Chromium"
        PROCESS_NAMES=("Chromium" "Chromium Helper")
        APP_SUPPORT_PATHS=(
            "$HOME/Library/Application Support/Chromium"
        )
        CACHE_PATHS=(
            "$HOME/Library/Caches/Chromium"
            "$HOME/Library/Caches/org.chromium.Chromium"
            "$HOME/Library/Caches/org.chromium.Chromium.helper"
            "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/org.chromium.Chromium"
        )
        PREF_FILES=(
            "$HOME/Library/Preferences/org.chromium.Chromium.plist"
            "$HOME/Library/Preferences/org.chromium.Chromium.helper.plist"
            "$HOME/Library/Preferences/org.chromium.Chromium.renderer.plist"
            "$HOME/Library/Preferences/org.chromium.Chromium.helper.renderer.plist"
        )
        PREF_PATTERNS=(
            "$HOME/Library/Preferences/ByHost/org.chromium.Chromium.*.plist"
        )
        COOKIE_FILES=(
            "$HOME/Library/Cookies/org.chromium.Chromium.binarycookies"
        )
        COOKIE_PATTERNS=(
            "$HOME/Library/Cookies/org.chromium.Chromium*"
        )
        LAUNCH_AGENT_FILES=(
            "$HOME/Library/LaunchAgents/org.chromium.Chromium.plist"
        )
        HTTP_STORAGE_PATHS=(
            "$HOME/Library/HTTPStorages/org.chromium.Chromium"
        )
        CONTAINER_PATHS=(
            "$HOME/Library/Containers/org.chromium.Chromium"
            "$HOME/Library/Containers/org.chromium.Chromium.helper"
        )
        APP_SCRIPTS_PATHS=()
        LOG_PATHS=(
            "$HOME/Library/Logs/Chromium"
            "$HOME/Library/Logs/org.chromium.Chromium"
        )
        WEBKIT_PATHS=(
            "$HOME/Library/WebKit/Chromium"
            "$HOME/Library/WebKit/org.chromium.Chromium"
        )
        SAVED_STATE_PATTERN="org.chromium.Chromium*.savedState"
        GROUP_CONTAINER_PATTERN="*org.chromium.Chromium*"
        CRASH_PATTERNS=("Chromium*" "org.chromium.Chromium*")
        TEMP_PATTERNS=(".org.chromium.Chromium.*" "org.chromium.Chromium*" "Chromium*")
        HAS_KEYSTONE=false
        SAFE_STORAGE_NAME="Chromium Safe Storage"
        DELETE_PHRASE="DELETE CHROMIUM"
        ;;
    3)
        BROWSER_NAME="Brave"
        BROWSER_NAME_UPPER="BRAVE"
        APP_NAME="Brave Browser.app"
        ADDITIONAL_APPS=()
        BUNDLE_ID="com.brave.Browser"
        PROCESS_NAMES=("Brave Browser" "Brave Browser Helper")
        APP_SUPPORT_PATHS=(
            "$HOME/Library/Application Support/BraveSoftware/Brave-Browser"
            "$HOME/Library/Application Support/BraveSoftware"
        )
        CACHE_PATHS=(
            "$HOME/Library/Caches/BraveSoftware/Brave-Browser"
            "$HOME/Library/Caches/BraveSoftware"
            "$HOME/Library/Caches/com.brave.Browser"
            "$HOME/Library/Caches/com.brave.Browser.helper"
            "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.brave.Browser"
        )
        PREF_FILES=(
            "$HOME/Library/Preferences/com.brave.Browser.plist"
            "$HOME/Library/Preferences/com.brave.Browser.helper.plist"
        )
        PREF_PATTERNS=(
            "$HOME/Library/Preferences/ByHost/com.brave.Browser.*.plist"
        )
        COOKIE_FILES=(
            "$HOME/Library/Cookies/com.brave.Browser.binarycookies"
        )
        COOKIE_PATTERNS=(
            "$HOME/Library/Cookies/com.brave.Browser*"
        )
        LAUNCH_AGENT_FILES=(
            "$HOME/Library/LaunchAgents/com.brave.Browser.plist"
        )
        HTTP_STORAGE_PATHS=(
            "$HOME/Library/HTTPStorages/com.brave.Browser"
        )
        CONTAINER_PATHS=(
            "$HOME/Library/Containers/com.brave.Browser"
            "$HOME/Library/Containers/com.brave.Browser.helper"
        )
        APP_SCRIPTS_PATHS=()
        LOG_PATHS=(
            "$HOME/Library/Logs/BraveSoftware"
            "$HOME/Library/Logs/com.brave.Browser"
        )
        WEBKIT_PATHS=(
            "$HOME/Library/WebKit/com.brave.Browser"
        )
        SAVED_STATE_PATTERN="com.brave.Browser*.savedState"
        GROUP_CONTAINER_PATTERN="*com.brave.Browser*"
        CRASH_PATTERNS=("Brave Browser*" "com.brave.Browser*")
        TEMP_PATTERNS=(".com.brave.Browser.*" "com.brave.Browser*" "Brave Browser*" "com.brave.Browser.code_sign_clone")
        HAS_KEYSTONE=false
        SAFE_STORAGE_NAME="Brave Safe Storage"
        DELETE_PHRASE="DELETE BRAVE"
        ;;
    4)
        BROWSER_NAME="Microsoft Edge"
        BROWSER_NAME_UPPER="MICROSOFT EDGE"
        APP_NAME="Microsoft Edge.app"
        ADDITIONAL_APPS=()
        BUNDLE_ID="com.microsoft.edgemac"
        PROCESS_NAMES=("Microsoft Edge" "Microsoft Edge Helper")
        APP_SUPPORT_PATHS=(
            "$HOME/Library/Application Support/Microsoft Edge"
            "$HOME/Library/Application Support/Microsoft/Edge"
            "$HOME/Library/Application Support/Microsoft/EdgeUpdater"
            "$HOME/Library/Microsoft/MicrosoftSoftwareUpdate/Actives/com.microsoft.edgemac"
        )
        CACHE_PATHS=(
            "$HOME/Library/Caches/Microsoft Edge"
            "$HOME/Library/Caches/Microsoft"
            "$HOME/Library/Caches/com.microsoft.edgemac"
            "$HOME/Library/Caches/com.microsoft.edgemac.helper"
            "$HOME/Library/Caches/com.microsoft.EdgeUpdater"
            "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.microsoft.edgemac"
        )
        PREF_FILES=(
            "$HOME/Library/Preferences/com.microsoft.edgemac.plist"
            "$HOME/Library/Preferences/com.microsoft.edgemac.helper.plist"
        )
        PREF_PATTERNS=(
            "$HOME/Library/Preferences/ByHost/com.microsoft.edgemac.*.plist"
        )
        COOKIE_FILES=(
            "$HOME/Library/Cookies/com.microsoft.edgemac.binarycookies"
        )
        COOKIE_PATTERNS=(
            "$HOME/Library/Cookies/com.microsoft.edgemac*"
        )
        LAUNCH_AGENT_FILES=(
            "$HOME/Library/LaunchAgents/com.microsoft.edgemac.plist"
            "$HOME/Library/LaunchAgents/com.microsoft.EdgeUpdater.wake.plist"
        )
        HTTP_STORAGE_PATHS=(
            "$HOME/Library/HTTPStorages/com.microsoft.edgemac"
            "$HOME/Library/HTTPStorages/com.microsoft.EdgeUpdater"
        )
        CONTAINER_PATHS=(
            "$HOME/Library/Containers/com.microsoft.edgemac"
            "$HOME/Library/Containers/com.microsoft.edgemac.helper"
            "$HOME/Library/Containers/com.microsoft.edgemac.wdgExtension"
        )
        APP_SCRIPTS_PATHS=(
            "$HOME/Library/Application Scripts/com.microsoft.edgemac.wdgExtension"
        )
        LOG_PATHS=(
            "$HOME/Library/Logs/Microsoft Edge"
            "$HOME/Library/Logs/com.microsoft.edgemac"
        )
        WEBKIT_PATHS=(
            "$HOME/Library/WebKit/com.microsoft.edgemac"
        )
        SAVED_STATE_PATTERN="com.microsoft.edgemac*.savedState"
        GROUP_CONTAINER_PATTERN="*com.microsoft.edgemac*"
        CRASH_PATTERNS=("Microsoft Edge*" "com.microsoft.edgemac*")
        TEMP_PATTERNS=(".com.microsoft.edgemac.*" "com.microsoft.edgemac*" "Microsoft Edge*" "com.microsoft.edgemac.code_sign_clone")
        HAS_KEYSTONE=false
        SAFE_STORAGE_NAME="Microsoft Edge Safe Storage"
        DELETE_PHRASE="DELETE EDGE"
        ;;
    5)
        BROWSER_NAME="Opera"
        BROWSER_NAME_UPPER="OPERA"
        APP_NAME="Opera.app"
        ADDITIONAL_APPS=()
        BUNDLE_ID="com.operasoftware.Opera"
        PROCESS_NAMES=("Opera" "Opera Helper")
        APP_SUPPORT_PATHS=(
            "$HOME/Library/Application Support/com.operasoftware.Opera"
        )
        CACHE_PATHS=(
            "$HOME/Library/Caches/com.operasoftware.Opera"
            "$HOME/Library/Caches/com.operasoftware.Opera.helper"
            "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.operasoftware.Opera"
        )
        PREF_FILES=(
            "$HOME/Library/Preferences/com.operasoftware.Opera.plist"
            "$HOME/Library/Preferences/com.operasoftware.Opera.helper.plist"
        )
        PREF_PATTERNS=(
            "$HOME/Library/Preferences/ByHost/com.operasoftware.Opera.*.plist"
        )
        COOKIE_FILES=(
            "$HOME/Library/Cookies/com.operasoftware.Opera.binarycookies"
        )
        COOKIE_PATTERNS=(
            "$HOME/Library/Cookies/com.operasoftware.Opera*"
        )
        LAUNCH_AGENT_FILES=(
            "$HOME/Library/LaunchAgents/com.operasoftware.Opera.plist"
        )
        HTTP_STORAGE_PATHS=(
            "$HOME/Library/HTTPStorages/com.operasoftware.Opera"
            "$HOME/Library/HTTPStorages/com.operasoftware.Installer.Opera"
        )
        CONTAINER_PATHS=(
            "$HOME/Library/Containers/com.operasoftware.Opera"
            "$HOME/Library/Containers/com.operasoftware.Opera.helper"
        )
        APP_SCRIPTS_PATHS=()
        LOG_PATHS=(
            "$HOME/Library/Logs/Opera"
            "$HOME/Library/Logs/com.operasoftware.Opera"
        )
        WEBKIT_PATHS=(
            "$HOME/Library/WebKit/com.operasoftware.Opera"
        )
        SAVED_STATE_PATTERN="com.operasoftware.Opera*.savedState"
        GROUP_CONTAINER_PATTERN="*com.operasoftware.Opera*"
        CRASH_PATTERNS=("Opera*" "com.operasoftware.Opera*")
        TEMP_PATTERNS=(".com.operasoftware.Opera.*" "com.operasoftware.Opera*" "Opera*" ".Opera.*" "com.operasoftware.Opera.code_sign_clone")
        HAS_KEYSTONE=false
        SAFE_STORAGE_NAME="Opera Safe Storage"
        DELETE_PHRASE="DELETE OPERA"
        ;;
    6)
        BROWSER_NAME="Vivaldi"
        BROWSER_NAME_UPPER="VIVALDI"
        APP_NAME="Vivaldi.app"
        ADDITIONAL_APPS=()
        BUNDLE_ID="com.vivaldi.Vivaldi"
        PROCESS_NAMES=("Vivaldi" "Vivaldi Helper")
        APP_SUPPORT_PATHS=(
            "$HOME/Library/Application Support/Vivaldi"
        )
        CACHE_PATHS=(
            "$HOME/Library/Caches/Vivaldi"
            "$HOME/Library/Caches/com.vivaldi.Vivaldi"
            "$HOME/Library/Caches/com.vivaldi.Vivaldi.helper"
            "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.vivaldi.Vivaldi"
        )
        PREF_FILES=(
            "$HOME/Library/Preferences/com.vivaldi.Vivaldi.plist"
            "$HOME/Library/Preferences/com.vivaldi.Vivaldi.helper.plist"
        )
        PREF_PATTERNS=(
            "$HOME/Library/Preferences/ByHost/com.vivaldi.Vivaldi.*.plist"
        )
        COOKIE_FILES=(
            "$HOME/Library/Cookies/com.vivaldi.Vivaldi.binarycookies"
        )
        COOKIE_PATTERNS=(
            "$HOME/Library/Cookies/com.vivaldi.Vivaldi*"
        )
        LAUNCH_AGENT_FILES=(
            "$HOME/Library/LaunchAgents/com.vivaldi.Vivaldi.plist"
        )
        HTTP_STORAGE_PATHS=(
            "$HOME/Library/HTTPStorages/com.vivaldi.Vivaldi"
        )
        CONTAINER_PATHS=(
            "$HOME/Library/Containers/com.vivaldi.Vivaldi"
            "$HOME/Library/Containers/com.vivaldi.Vivaldi.helper"
        )
        APP_SCRIPTS_PATHS=()
        LOG_PATHS=(
            "$HOME/Library/Logs/Vivaldi"
            "$HOME/Library/Logs/com.vivaldi.Vivaldi"
        )
        WEBKIT_PATHS=(
            "$HOME/Library/WebKit/Vivaldi"
            "$HOME/Library/WebKit/com.vivaldi.Vivaldi"
        )
        SAVED_STATE_PATTERN="com.vivaldi.Vivaldi*.savedState"
        GROUP_CONTAINER_PATTERN="*com.vivaldi.Vivaldi*"
        CRASH_PATTERNS=("Vivaldi*" "com.vivaldi.Vivaldi*")
        TEMP_PATTERNS=(".com.vivaldi.Vivaldi.*" "com.vivaldi.Vivaldi*" "Vivaldi*")
        HAS_KEYSTONE=false
        SAFE_STORAGE_NAME="Vivaldi Safe Storage"
        DELETE_PHRASE="DELETE VIVALDI"
        ;;
    7)
        BROWSER_NAME="Arc"
        BROWSER_NAME_UPPER="ARC"
        APP_NAME="Arc.app"
        ADDITIONAL_APPS=()
        BUNDLE_ID="company.thebrowser.Browser"
        PROCESS_NAMES=("Arc" "Arc Helper")
        APP_SUPPORT_PATHS=(
            "$HOME/Library/Application Support/Arc"
            "$HOME/Library/Application Support/firestore/Arc"
        )
        CACHE_PATHS=(
            "$HOME/Library/Caches/Arc"
            "$HOME/Library/Caches/company.thebrowser.Browser"
            "$HOME/Library/Caches/company.thebrowser.Browser.helper"
            "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/company.thebrowser.Browser"
            "$HOME/Library/Caches/SentryCrash/Arc"
        )
        PREF_FILES=(
            "$HOME/Library/Preferences/company.thebrowser.Browser.plist"
            "$HOME/Library/Preferences/company.thebrowser.Browser.helper.plist"
        )
        PREF_PATTERNS=(
            "$HOME/Library/Preferences/ByHost/company.thebrowser.Browser.*.plist"
        )
        COOKIE_FILES=(
            "$HOME/Library/Cookies/company.thebrowser.Browser.binarycookies"
        )
        COOKIE_PATTERNS=(
            "$HOME/Library/Cookies/company.thebrowser.Browser*"
        )
        LAUNCH_AGENT_FILES=(
            "$HOME/Library/LaunchAgents/company.thebrowser.Browser.plist"
        )
        HTTP_STORAGE_PATHS=(
            "$HOME/Library/HTTPStorages/company.thebrowser.Browser"
            "$HOME/Library/HTTPStorages/company.thebrowser.Browser.binarycookies"
        )
        CONTAINER_PATHS=(
            "$HOME/Library/Containers/company.thebrowser.Browser"
            "$HOME/Library/Containers/company.thebrowser.Browser.helper"
        )
        APP_SCRIPTS_PATHS=()
        LOG_PATHS=(
            "$HOME/Library/Logs/Arc"
            "$HOME/Library/Logs/company.thebrowser.Browser"
        )
        WEBKIT_PATHS=(
            "$HOME/Library/WebKit/Arc"
            "$HOME/Library/WebKit/company.thebrowser.Browser"
        )
        SAVED_STATE_PATTERN="company.thebrowser.Browser*.savedState"
        GROUP_CONTAINER_PATTERN="*company.thebrowser.Browser*"
        CRASH_PATTERNS=("Arc*" "company.thebrowser.Browser*")
        TEMP_PATTERNS=(".company.thebrowser.Browser.*" "company.thebrowser.Browser*" "Arc*")
        HAS_KEYSTONE=false
        SAFE_STORAGE_NAME="Arc Safe Storage"
        DELETE_PHRASE="DELETE ARC"
        ;;
    8)
        # "All browsers" - variables already set before switch
        # This case is just to prevent the error
        ;;
    *)
        log_error "Invalid choice. Please run the script again and select 1-8."
        exit 1
        ;;
esac

if [[ "$DELETE_ALL" == true ]]; then
    log_info "All Chromium-based browsers selected for removal"
else
    log_success "Selected browser: $BROWSER_NAME"
fi
echo ""

# =============================================================================
# MASSIVE WARNING BANNER
# =============================================================================
clear
echo ""
echo ""
echo -e "${BG_RED}${BOLD_WHITE}                                                                              ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}  ██████╗  █████╗ ███╗   ██╗ ██████╗ ███████╗██████╗ ██╗                       ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}  ██╔══██╗██╔══██╗████╗  ██║██╔════╝ ██╔════╝██╔══██╗██║                       ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}  ██║  ██║███████║██╔██╗ ██║██║  ███╗█████╗  ██████╔╝██║                       ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}  ██║  ██║██╔══██║██║╚██╗██║██║   ██║██╔══╝  ██╔══██╗╚═╝                       ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}  ██████╔╝██║  ██║██║ ╚████║╚██████╔╝███████╗██║  ██║██╗                       ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝                       ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}                                                                              ${NC}"
echo ""
echo -e "${BG_RED}${BOLD_WHITE}                    PERMANENT DELETION WARNING                                ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}                                                                              ${NC}"
echo ""
echo ""
echo -e "${BOLD_RED}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD_RED}║                                                                            ║${NC}"
echo -e "${BOLD_RED}║   ${BLINK}⚠️  WARNING: THIS SCRIPT WILL PERMANENTLY DELETE ALL DATA! ⚠️${NC}${BOLD_RED}            ║${NC}"
echo -e "${BOLD_RED}║                                                                            ║${NC}"
echo -e "${BOLD_RED}║   Browser: ${YELLOW}$BROWSER_NAME${NC}${BOLD_RED}$(printf '%*s' $((51 - ${#BROWSER_NAME})) '')║${NC}"
echo -e "${BOLD_RED}║                                                                            ║${NC}"
echo -e "${BOLD_RED}║   This includes:                                                           ║${NC}"
echo -e "${BOLD_RED}║   ${YELLOW}• All your bookmarks${NC}${BOLD_RED}                                                     ║${NC}"
echo -e "${BOLD_RED}║   ${YELLOW}• All your saved passwords${NC}${BOLD_RED}                                               ║${NC}"
echo -e "${BOLD_RED}║   ${YELLOW}• All your browsing history${NC}${BOLD_RED}                                              ║${NC}"
echo -e "${BOLD_RED}║   ${YELLOW}• All your extensions and their data${NC}${BOLD_RED}                                     ║${NC}"
echo -e "${BOLD_RED}║   ${YELLOW}• All your $BROWSER_NAME profiles${NC}${BOLD_RED}$(printf '%*s' $((36 - ${#BROWSER_NAME})) '')║${NC}"
echo -e "${BOLD_RED}║   ${YELLOW}• All cookies and session data${NC}${BOLD_RED}                                           ║${NC}"
echo -e "${BOLD_RED}║   ${YELLOW}• All autofill data${NC}${BOLD_RED}                                                      ║${NC}"
echo -e "${BOLD_RED}║   ${YELLOW}• $BROWSER_NAME application${NC}${BOLD_RED}$(printf '%*s' $((48 - ${#BROWSER_NAME})) '')║${NC}"
echo -e "${BOLD_RED}║                                                                            ║${NC}"
echo -e "${BOLD_RED}║   ${BOLD_WHITE}>>> THIS ACTION CANNOT BE UNDONE! <<<${NC}${BOLD_RED}                                  ║${NC}"
echo -e "${BOLD_RED}║                                                                            ║${NC}"
echo -e "${BOLD_RED}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BG_YELLOW}${BOLD_WHITE}                                                                              ${NC}"
    echo -e "${BG_YELLOW}${BOLD_WHITE}                        DRY-RUN MODE ENABLED                                  ${NC}"
    echo -e "${BG_YELLOW}${BOLD_WHITE}                  No files will actually be deleted                           ${NC}"
    echo -e "${BG_YELLOW}${BOLD_WHITE}                                                                              ${NC}"
    echo ""
fi

# =============================================================================
# FIRST CONFIRMATION
# =============================================================================
echo ""
echo -e "${BOLD_YELLOW}┌──────────────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD_YELLOW}│                         FIRST CONFIRMATION REQUIRED                         │${NC}"
echo -e "${BOLD_YELLOW}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${WHITE}Are you absolutely sure you want to ${BOLD_RED}PERMANENTLY DELETE${NC}${WHITE} all $BROWSER_NAME data?${NC}"
echo ""
echo -e "${CYAN}Type ${BOLD_WHITE}YES${NC}${CYAN} (in uppercase) to continue, or anything else to abort:${NC}"
echo ""
read -p ">>> " FIRST_CONFIRM
echo ""

if [[ "$FIRST_CONFIRM" != "YES" ]]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                          OPERATION CANCELED                                ║${NC}"
    echo -e "${GREEN}║                                                                            ║${NC}"
    echo -e "${GREEN}║              No files have been deleted. Your data is safe.                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
fi

# =============================================================================
# SECOND CONFIRMATION (DOUBLE CHECK)
# =============================================================================
echo ""
echo -e "${BG_RED}${BOLD_WHITE}                                                                              ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}                           FINAL WARNING!                                     ${NC}"
echo -e "${BG_RED}${BOLD_WHITE}                                                                              ${NC}"
echo ""
echo -e "${BOLD_RED}┌──────────────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD_RED}│                         SECOND CONFIRMATION REQUIRED                        │${NC}"
echo -e "${BOLD_RED}│                                                                             │${NC}"
echo -e "${BOLD_RED}│    This is your LAST CHANCE to cancel this operation!                      │${NC}"
echo -e "${BOLD_RED}│                                                                             │${NC}"
echo -e "${BOLD_RED}│    Once you confirm, ALL $BROWSER_NAME data will be PERMANENTLY ERASED.$(printf '%*s' $((11 - ${#BROWSER_NAME})) '')│${NC}"
echo -e "${BOLD_RED}│    There is NO recovery possible after this point.                         │${NC}"
echo -e "${BOLD_RED}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${WHITE}To confirm deletion, type ${BOLD_RED}$DELETE_PHRASE${NC}${WHITE} exactly:${NC}"
echo ""
read -p ">>> " SECOND_CONFIRM
echo ""

if [[ "$SECOND_CONFIRM" != "$DELETE_PHRASE" ]]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                          OPERATION CANCELED                                ║${NC}"
    echo -e "${GREEN}║                                                                            ║${NC}"
    echo -e "${GREEN}║              No files have been deleted. Your data is safe.                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
fi

# =============================================================================
# COUNTDOWN BEFORE DELETION
# =============================================================================
echo ""
echo -e "${BOLD_YELLOW}Starting deletion in...${NC}"
echo ""
for i in 5 4 3 2 1; do
    echo -e "${BOLD_RED}   $i...${NC}"
    sleep 1
done
echo ""
echo -e "${BOLD_RED}   STARTING DELETION PROCESS!${NC}"
echo ""
sleep 1

# =============================================================================
# FUNCTION TO CONFIGURE BROWSER VARIABLES
# =============================================================================
configure_browser_vars() {
    local choice="$1"
    case "$choice" in
        1)
            BROWSER_NAME="Google Chrome"
            BROWSER_NAME_UPPER="GOOGLE CHROME"
            APP_NAME="Google Chrome.app"
            ADDITIONAL_APPS=("Google Chrome Canary.app")
            BUNDLE_ID="com.google.Chrome"
            PROCESS_NAMES=("Google Chrome" "Google Chrome Helper" "Google Chrome Canary" "Google Chrome Dev")
            APP_SUPPORT_PATHS=("$HOME/Library/Application Support/Google/Chrome" "$HOME/Library/Application Support/Google/Chrome Dev" "$HOME/Library/Application Support/Google/Chrome Canary" "$HOME/Library/Application Support/Google/GoogleUpdater" "$HOME/Library/Application Support/Google/RLZ" "$HOME/Library/Application Support/Google/Measurement" "$HOME/Library/Application Support/Google/RemoteConfig" "$HOME/Library/Application Support/Google/consentOptions")
            CACHE_PATHS=("$HOME/Library/Caches/Google/Chrome" "$HOME/Library/Caches/Google/Chrome Canary" "$HOME/Library/Caches/Google" "$HOME/Library/Caches/com.google.Chrome" "$HOME/Library/Caches/com.google.Chrome.helper" "$HOME/Library/Caches/com.google.Chrome.canary" "$HOME/Library/Caches/com.google.Chrome.canary.helper" "$HOME/Library/Caches/com.google.GoogleUpdater" "$HOME/Library/Caches/com.google.Keystone" "$HOME/Library/Caches/com.google.Keystone.Agent" "$HOME/Library/Caches/com.google.SoftwareUpdate" "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.google.Chrome" "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.google.Chrome.canary")
            PREF_FILES=("$HOME/Library/Preferences/com.google.Chrome.plist" "$HOME/Library/Preferences/com.google.Chrome.canary.plist" "$HOME/Library/Preferences/com.google.Chrome.helper.plist" "$HOME/Library/Preferences/com.google.Chrome.canary.helper.plist" "$HOME/Library/Preferences/com.google.Chrome.renderer.plist" "$HOME/Library/Preferences/com.google.Chrome.canary.renderer.plist" "$HOME/Library/Preferences/com.google.Keystone.plist" "$HOME/Library/Preferences/com.google.Keystone.Agent.plist" "$HOME/Library/Preferences/com.google.antigravity.plist" "$HOME/Library/Preferences/com.google.gmp.measurement.monitor.plist")
            PREF_PATTERNS=("$HOME/Library/Preferences/ByHost/com.google.antigravity.ShipIt.*.plist" "$HOME/Library/Preferences/ByHost/com.google.Chrome.*.plist" "$HOME/Library/Preferences/ByHost/com.google.Keystone.*.plist")
            COOKIE_FILES=("$HOME/Library/Cookies/com.google.Chrome.binarycookies")
            COOKIE_PATTERNS=("$HOME/Library/Cookies/com.google.Chrome*" "$HOME/Library/Cookies/com.google.Chrome.canary*")
            LAUNCH_AGENT_FILES=("$HOME/Library/LaunchAgents/com.google.keystone.agent.plist" "$HOME/Library/LaunchAgents/com.google.keystone.xpcservice.plist" "$HOME/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist" "$HOME/Library/LaunchAgents/com.google.Chrome.plist")
            HTTP_STORAGE_PATHS=("$HOME/Library/HTTPStorages/com.google.Chrome" "$HOME/Library/HTTPStorages/com.google.GoogleUpdater" "$HOME/Library/HTTPStorages/com.google.Keystone" "$HOME/Library/HTTPStorages/com.google.antigravity")
            CONTAINER_PATHS=("$HOME/Library/Containers/com.google.Chrome" "$HOME/Library/Containers/com.google.Chrome.helper")
            APP_SCRIPTS_PATHS=()
            LOG_PATHS=("$HOME/Library/Logs/Google" "$HOME/Library/Logs/Google/Chrome" "$HOME/Library/Logs/com.google.Chrome" "$HOME/Library/Logs/GoogleSoftwareUpdateAgent.log")
            WEBKIT_PATHS=("$HOME/Library/WebKit/Google/Chrome" "$HOME/Library/WebKit/com.google.Chrome")
            SAVED_STATE_PATTERN="com.google.Chrome*.savedState"
            GROUP_CONTAINER_PATTERN="*com.google.Chrome*"
            CRASH_PATTERNS=("Google Chrome*" "com.google.Chrome*")
            TEMP_PATTERNS=(".com.google.Chrome.*" "com.google.Chrome*" "Google Chrome*" "com.google.Keystone*" "com.google.Chrome*.code_sign_clone")
            HAS_KEYSTONE=true
            SAFE_STORAGE_NAME="Chrome Safe Storage"
            ;;
        2)
            BROWSER_NAME="Chromium"
            BROWSER_NAME_UPPER="CHROMIUM"
            APP_NAME="Chromium.app"
            ADDITIONAL_APPS=()
            BUNDLE_ID="org.chromium.Chromium"
            PROCESS_NAMES=("Chromium" "Chromium Helper")
            APP_SUPPORT_PATHS=("$HOME/Library/Application Support/Chromium")
            CACHE_PATHS=("$HOME/Library/Caches/Chromium" "$HOME/Library/Caches/org.chromium.Chromium" "$HOME/Library/Caches/org.chromium.Chromium.helper" "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/org.chromium.Chromium")
            PREF_FILES=("$HOME/Library/Preferences/org.chromium.Chromium.plist" "$HOME/Library/Preferences/org.chromium.Chromium.helper.plist" "$HOME/Library/Preferences/org.chromium.Chromium.renderer.plist" "$HOME/Library/Preferences/org.chromium.Chromium.helper.renderer.plist")
            PREF_PATTERNS=("$HOME/Library/Preferences/ByHost/org.chromium.Chromium.*.plist")
            COOKIE_FILES=("$HOME/Library/Cookies/org.chromium.Chromium.binarycookies")
            COOKIE_PATTERNS=("$HOME/Library/Cookies/org.chromium.Chromium*")
            LAUNCH_AGENT_FILES=("$HOME/Library/LaunchAgents/org.chromium.Chromium.plist")
            HTTP_STORAGE_PATHS=("$HOME/Library/HTTPStorages/org.chromium.Chromium")
            CONTAINER_PATHS=("$HOME/Library/Containers/org.chromium.Chromium" "$HOME/Library/Containers/org.chromium.Chromium.helper")
            APP_SCRIPTS_PATHS=()
            LOG_PATHS=("$HOME/Library/Logs/Chromium" "$HOME/Library/Logs/org.chromium.Chromium")
            WEBKIT_PATHS=("$HOME/Library/WebKit/Chromium" "$HOME/Library/WebKit/org.chromium.Chromium")
            SAVED_STATE_PATTERN="org.chromium.Chromium*.savedState"
            GROUP_CONTAINER_PATTERN="*org.chromium.Chromium*"
            CRASH_PATTERNS=("Chromium*" "org.chromium.Chromium*")
            TEMP_PATTERNS=(".org.chromium.Chromium.*" "org.chromium.Chromium*" "Chromium*")
            HAS_KEYSTONE=false
            SAFE_STORAGE_NAME="Chromium Safe Storage"
            ;;
        3)
            BROWSER_NAME="Brave"
            BROWSER_NAME_UPPER="BRAVE"
            APP_NAME="Brave Browser.app"
            ADDITIONAL_APPS=()
            BUNDLE_ID="com.brave.Browser"
            PROCESS_NAMES=("Brave Browser" "Brave Browser Helper")
            APP_SUPPORT_PATHS=("$HOME/Library/Application Support/BraveSoftware/Brave-Browser" "$HOME/Library/Application Support/BraveSoftware")
            CACHE_PATHS=("$HOME/Library/Caches/BraveSoftware/Brave-Browser" "$HOME/Library/Caches/BraveSoftware" "$HOME/Library/Caches/com.brave.Browser" "$HOME/Library/Caches/com.brave.Browser.helper" "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.brave.Browser")
            PREF_FILES=("$HOME/Library/Preferences/com.brave.Browser.plist" "$HOME/Library/Preferences/com.brave.Browser.helper.plist")
            PREF_PATTERNS=("$HOME/Library/Preferences/ByHost/com.brave.Browser.*.plist")
            COOKIE_FILES=("$HOME/Library/Cookies/com.brave.Browser.binarycookies")
            COOKIE_PATTERNS=("$HOME/Library/Cookies/com.brave.Browser*")
            LAUNCH_AGENT_FILES=("$HOME/Library/LaunchAgents/com.brave.Browser.plist")
            HTTP_STORAGE_PATHS=("$HOME/Library/HTTPStorages/com.brave.Browser")
            CONTAINER_PATHS=("$HOME/Library/Containers/com.brave.Browser" "$HOME/Library/Containers/com.brave.Browser.helper")
            APP_SCRIPTS_PATHS=()
            LOG_PATHS=("$HOME/Library/Logs/BraveSoftware" "$HOME/Library/Logs/com.brave.Browser")
            WEBKIT_PATHS=("$HOME/Library/WebKit/com.brave.Browser")
            SAVED_STATE_PATTERN="com.brave.Browser*.savedState"
            GROUP_CONTAINER_PATTERN="*com.brave.Browser*"
            CRASH_PATTERNS=("Brave Browser*" "com.brave.Browser*")
            TEMP_PATTERNS=(".com.brave.Browser.*" "com.brave.Browser*" "Brave Browser*" "com.brave.Browser.code_sign_clone")
            HAS_KEYSTONE=false
            SAFE_STORAGE_NAME="Brave Safe Storage"
            ;;
        4)
            BROWSER_NAME="Microsoft Edge"
            BROWSER_NAME_UPPER="MICROSOFT EDGE"
            APP_NAME="Microsoft Edge.app"
            ADDITIONAL_APPS=()
            BUNDLE_ID="com.microsoft.edgemac"
            PROCESS_NAMES=("Microsoft Edge" "Microsoft Edge Helper")
            APP_SUPPORT_PATHS=("$HOME/Library/Application Support/Microsoft Edge" "$HOME/Library/Application Support/Microsoft/Edge" "$HOME/Library/Application Support/Microsoft/EdgeUpdater" "$HOME/Library/Microsoft/MicrosoftSoftwareUpdate/Actives/com.microsoft.edgemac")
            CACHE_PATHS=("$HOME/Library/Caches/Microsoft Edge" "$HOME/Library/Caches/Microsoft" "$HOME/Library/Caches/com.microsoft.edgemac" "$HOME/Library/Caches/com.microsoft.edgemac.helper" "$HOME/Library/Caches/com.microsoft.EdgeUpdater" "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.microsoft.edgemac")
            PREF_FILES=("$HOME/Library/Preferences/com.microsoft.edgemac.plist" "$HOME/Library/Preferences/com.microsoft.edgemac.helper.plist")
            PREF_PATTERNS=("$HOME/Library/Preferences/ByHost/com.microsoft.edgemac.*.plist")
            COOKIE_FILES=("$HOME/Library/Cookies/com.microsoft.edgemac.binarycookies")
            COOKIE_PATTERNS=("$HOME/Library/Cookies/com.microsoft.edgemac*")
            LAUNCH_AGENT_FILES=("$HOME/Library/LaunchAgents/com.microsoft.edgemac.plist" "$HOME/Library/LaunchAgents/com.microsoft.EdgeUpdater.wake.plist")
            HTTP_STORAGE_PATHS=("$HOME/Library/HTTPStorages/com.microsoft.edgemac" "$HOME/Library/HTTPStorages/com.microsoft.EdgeUpdater")
            CONTAINER_PATHS=("$HOME/Library/Containers/com.microsoft.edgemac" "$HOME/Library/Containers/com.microsoft.edgemac.helper" "$HOME/Library/Containers/com.microsoft.edgemac.wdgExtension")
            APP_SCRIPTS_PATHS=("$HOME/Library/Application Scripts/com.microsoft.edgemac.wdgExtension")
            LOG_PATHS=("$HOME/Library/Logs/Microsoft Edge" "$HOME/Library/Logs/com.microsoft.edgemac")
            WEBKIT_PATHS=("$HOME/Library/WebKit/com.microsoft.edgemac")
            SAVED_STATE_PATTERN="com.microsoft.edgemac*.savedState"
            GROUP_CONTAINER_PATTERN="*com.microsoft.edgemac*"
            CRASH_PATTERNS=("Microsoft Edge*" "com.microsoft.edgemac*")
            TEMP_PATTERNS=(".com.microsoft.edgemac.*" "com.microsoft.edgemac*" "Microsoft Edge*" "com.microsoft.edgemac.code_sign_clone")
            HAS_KEYSTONE=false
            SAFE_STORAGE_NAME="Microsoft Edge Safe Storage"
            ;;
        5)
            BROWSER_NAME="Opera"
            BROWSER_NAME_UPPER="OPERA"
            APP_NAME="Opera.app"
            ADDITIONAL_APPS=()
            BUNDLE_ID="com.operasoftware.Opera"
            PROCESS_NAMES=("Opera" "Opera Helper")
            APP_SUPPORT_PATHS=("$HOME/Library/Application Support/com.operasoftware.Opera")
            CACHE_PATHS=("$HOME/Library/Caches/com.operasoftware.Opera" "$HOME/Library/Caches/com.operasoftware.Opera.helper" "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.operasoftware.Opera")
            PREF_FILES=("$HOME/Library/Preferences/com.operasoftware.Opera.plist" "$HOME/Library/Preferences/com.operasoftware.Opera.helper.plist")
            PREF_PATTERNS=("$HOME/Library/Preferences/ByHost/com.operasoftware.Opera.*.plist")
            COOKIE_FILES=("$HOME/Library/Cookies/com.operasoftware.Opera.binarycookies")
            COOKIE_PATTERNS=("$HOME/Library/Cookies/com.operasoftware.Opera*")
            LAUNCH_AGENT_FILES=("$HOME/Library/LaunchAgents/com.operasoftware.Opera.plist")
            HTTP_STORAGE_PATHS=("$HOME/Library/HTTPStorages/com.operasoftware.Opera" "$HOME/Library/HTTPStorages/com.operasoftware.Installer.Opera")
            CONTAINER_PATHS=("$HOME/Library/Containers/com.operasoftware.Opera" "$HOME/Library/Containers/com.operasoftware.Opera.helper")
            APP_SCRIPTS_PATHS=()
            LOG_PATHS=("$HOME/Library/Logs/Opera" "$HOME/Library/Logs/com.operasoftware.Opera")
            WEBKIT_PATHS=("$HOME/Library/WebKit/com.operasoftware.Opera")
            SAVED_STATE_PATTERN="com.operasoftware.Opera*.savedState"
            GROUP_CONTAINER_PATTERN="*com.operasoftware.Opera*"
            CRASH_PATTERNS=("Opera*" "com.operasoftware.Opera*")
            TEMP_PATTERNS=(".com.operasoftware.Opera.*" "com.operasoftware.Opera*" "Opera*" ".Opera.*" "com.operasoftware.Opera.code_sign_clone")
            HAS_KEYSTONE=false
            SAFE_STORAGE_NAME="Opera Safe Storage"
            ;;
        6)
            BROWSER_NAME="Vivaldi"
            BROWSER_NAME_UPPER="VIVALDI"
            APP_NAME="Vivaldi.app"
            ADDITIONAL_APPS=()
            BUNDLE_ID="com.vivaldi.Vivaldi"
            PROCESS_NAMES=("Vivaldi" "Vivaldi Helper")
            APP_SUPPORT_PATHS=("$HOME/Library/Application Support/Vivaldi")
            CACHE_PATHS=("$HOME/Library/Caches/Vivaldi" "$HOME/Library/Caches/com.vivaldi.Vivaldi" "$HOME/Library/Caches/com.vivaldi.Vivaldi.helper" "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.vivaldi.Vivaldi")
            PREF_FILES=("$HOME/Library/Preferences/com.vivaldi.Vivaldi.plist" "$HOME/Library/Preferences/com.vivaldi.Vivaldi.helper.plist")
            PREF_PATTERNS=("$HOME/Library/Preferences/ByHost/com.vivaldi.Vivaldi.*.plist")
            COOKIE_FILES=("$HOME/Library/Cookies/com.vivaldi.Vivaldi.binarycookies")
            COOKIE_PATTERNS=("$HOME/Library/Cookies/com.vivaldi.Vivaldi*")
            LAUNCH_AGENT_FILES=("$HOME/Library/LaunchAgents/com.vivaldi.Vivaldi.plist")
            HTTP_STORAGE_PATHS=("$HOME/Library/HTTPStorages/com.vivaldi.Vivaldi")
            CONTAINER_PATHS=("$HOME/Library/Containers/com.vivaldi.Vivaldi" "$HOME/Library/Containers/com.vivaldi.Vivaldi.helper")
            APP_SCRIPTS_PATHS=()
            LOG_PATHS=("$HOME/Library/Logs/Vivaldi" "$HOME/Library/Logs/com.vivaldi.Vivaldi")
            WEBKIT_PATHS=("$HOME/Library/WebKit/Vivaldi" "$HOME/Library/WebKit/com.vivaldi.Vivaldi")
            SAVED_STATE_PATTERN="com.vivaldi.Vivaldi*.savedState"
            GROUP_CONTAINER_PATTERN="*com.vivaldi.Vivaldi*"
            CRASH_PATTERNS=("Vivaldi*" "com.vivaldi.Vivaldi*")
            TEMP_PATTERNS=(".com.vivaldi.Vivaldi.*" "com.vivaldi.Vivaldi*" "Vivaldi*")
            HAS_KEYSTONE=false
            SAFE_STORAGE_NAME="Vivaldi Safe Storage"
            ;;
        7)
            BROWSER_NAME="Arc"
            BROWSER_NAME_UPPER="ARC"
            APP_NAME="Arc.app"
            ADDITIONAL_APPS=()
            BUNDLE_ID="company.thebrowser.Browser"
            PROCESS_NAMES=("Arc" "Arc Helper")
            APP_SUPPORT_PATHS=("$HOME/Library/Application Support/Arc" "$HOME/Library/Application Support/firestore/Arc")
            CACHE_PATHS=("$HOME/Library/Caches/Arc" "$HOME/Library/Caches/company.thebrowser.Browser" "$HOME/Library/Caches/company.thebrowser.Browser.helper" "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/company.thebrowser.Browser" "$HOME/Library/Caches/SentryCrash/Arc")
            PREF_FILES=("$HOME/Library/Preferences/company.thebrowser.Browser.plist" "$HOME/Library/Preferences/company.thebrowser.Browser.helper.plist")
            PREF_PATTERNS=("$HOME/Library/Preferences/ByHost/company.thebrowser.Browser.*.plist")
            COOKIE_FILES=("$HOME/Library/Cookies/company.thebrowser.Browser.binarycookies")
            COOKIE_PATTERNS=("$HOME/Library/Cookies/company.thebrowser.Browser*")
            LAUNCH_AGENT_FILES=("$HOME/Library/LaunchAgents/company.thebrowser.Browser.plist")
            HTTP_STORAGE_PATHS=("$HOME/Library/HTTPStorages/company.thebrowser.Browser" "$HOME/Library/HTTPStorages/company.thebrowser.Browser.binarycookies")
            CONTAINER_PATHS=("$HOME/Library/Containers/company.thebrowser.Browser" "$HOME/Library/Containers/company.thebrowser.Browser.helper")
            APP_SCRIPTS_PATHS=()
            LOG_PATHS=("$HOME/Library/Logs/Arc" "$HOME/Library/Logs/company.thebrowser.Browser")
            WEBKIT_PATHS=("$HOME/Library/WebKit/Arc" "$HOME/Library/WebKit/company.thebrowser.Browser")
            SAVED_STATE_PATTERN="company.thebrowser.Browser*.savedState"
            GROUP_CONTAINER_PATTERN="*company.thebrowser.Browser*"
            CRASH_PATTERNS=("Arc*" "company.thebrowser.Browser*")
            TEMP_PATTERNS=(".company.thebrowser.Browser.*" "company.thebrowser.Browser*" "Arc*")
            HAS_KEYSTONE=false
            SAFE_STORAGE_NAME="Arc Safe Storage"
            ;;
    esac
}

# =============================================================================
# FUNCTION TO PERFORM UNINSTALL FOR CURRENT BROWSER
# =============================================================================
perform_browser_uninstall() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║              UNINSTALLING: $BROWSER_NAME$(printf '%*s' $((49 - ${#BROWSER_NAME})) '')║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Kill processes
    log_kill "Terminating all $BROWSER_NAME processes..."
    for process in "${PROCESS_NAMES[@]}"; do
        pkill -9 -f "$process" 2>/dev/null && log_kill "Killed: $process" || true
    done
    pkill -9 -f "crashpad_handler" 2>/dev/null || true
    sleep 1
    for process in "${PROCESS_NAMES[@]}"; do
        killall -9 "$process" 2>/dev/null || true
        killall -9 "$process Helper (Renderer)" 2>/dev/null || true
        killall -9 "$process Helper (GPU)" 2>/dev/null || true
        killall -9 "$process Helper (Plugin)" 2>/dev/null || true
    done

    # Stop Keystone if Google Chrome
    if [[ "$HAS_KEYSTONE" == true ]]; then
        log_kill "Stopping Google services..."
        launchctl remove com.google.keystone.agent 2>/dev/null || true
        launchctl remove com.google.keystone.xpcservice 2>/dev/null || true
        launchctl unload ~/Library/LaunchAgents/com.google.keystone.agent.plist 2>/dev/null || true
        launchctl unload ~/Library/LaunchAgents/com.google.keystone.xpcservice.plist 2>/dev/null || true
        launchctl unload ~/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist 2>/dev/null || true
        pkill -9 -f "GoogleSoftwareUpdate" 2>/dev/null || true
        pkill -9 -f "keystone" 2>/dev/null || true
        pkill -9 -f "GoogleUpdater" 2>/dev/null || true
    fi

    # Remove main applications
    log_info "Removing applications..."
    remove_item "/Applications/$APP_NAME" "$APP_NAME"
    remove_item "$HOME/Applications/$APP_NAME" "$APP_NAME (user)"
    # Remove additional apps (e.g., Chrome Canary)
    for additional_app in "${ADDITIONAL_APPS[@]}"; do
        remove_item "/Applications/$additional_app" "$additional_app"
        remove_item "$HOME/Applications/$additional_app" "$additional_app (user)"
    done

    # Remove Application Support
    log_info "Removing user data..."
    for path in "${APP_SUPPORT_PATHS[@]}"; do
        remove_item "$path" "$(basename "$path")"
    done

    # Remove caches
    log_info "Removing caches..."
    for path in "${CACHE_PATHS[@]}"; do
        remove_item "$path" "$(basename "$path")"
    done

    # Remove WebKit
    for path in "${WEBKIT_PATHS[@]}"; do
        remove_item "$path" "$(basename "$path")"
    done

    # Remove cookies
    log_info "Removing cookies..."
    for file in "${COOKIE_FILES[@]}"; do
        remove_item "$file" "$(basename "$file")"
    done
    for pattern in "${COOKIE_PATTERNS[@]}"; do
        remove_pattern "$pattern" "cookies"
    done

    # Remove preferences
    log_info "Removing preferences..."
    for file in "${PREF_FILES[@]}"; do
        remove_item "$file" "$(basename "$file")"
    done
    for pattern in "${PREF_PATTERNS[@]}"; do
        remove_pattern "$pattern" "ByHost preferences"
    done

    # Remove launch agents
    for file in "${LAUNCH_AGENT_FILES[@]}"; do
        remove_item "$file" "$(basename "$file")"
    done

    # Remove Keystone if Google Chrome
    if [[ "$HAS_KEYSTONE" == true ]]; then
        log_info "Removing Google Software Update..."
        remove_item "$HOME/Library/Google/GoogleSoftwareUpdate" "GoogleSoftwareUpdate"
        remove_item "$HOME/Library/Google/Google Chrome Brand.plist" "Chrome Brand plist"
        if [[ -d "$HOME/Library/Google" ]] && [[ -z "$(ls -A "$HOME/Library/Google" 2>/dev/null)" ]]; then
            remove_item "$HOME/Library/Google" "Empty Google folder"
        fi
    fi

    # Remove saved state
    log_info "Removing saved state..."
    remove_item "$HOME/Library/Saved Application State/$BUNDLE_ID.savedState" "saved state"
    find "$HOME/Library/Saved Application State" -maxdepth 1 -name "$SAVED_STATE_PATTERN" 2>/dev/null | while read -r item; do
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove: $item"
        else
            rm -rf "$item" 2>/dev/null && log_success "Removed: $(basename "$item")"
        fi
    done

    # Remove logs
    log_info "Removing logs..."
    for path in "${LOG_PATHS[@]}"; do
        remove_item "$path" "$(basename "$path")"
    done
    for pattern in "${CRASH_PATTERNS[@]}"; do
        remove_find "$HOME/Library/Logs/DiagnosticReports" "$pattern"
        remove_find "$HOME/Library/Logs/DiagnosticReports/Retired" "$pattern"
    done

    # Remove HTTP storages
    for path in "${HTTP_STORAGE_PATHS[@]}"; do
        remove_item "$path" "$(basename "$path")"
    done

    # Remove containers
    log_info "Removing containers..."
    for path in "${CONTAINER_PATHS[@]}"; do
        remove_item "$path" "$(basename "$path")"
    done
    if [[ -d "$HOME/Library/Group Containers" ]]; then
        find "$HOME/Library/Group Containers" -maxdepth 1 -name "$GROUP_CONTAINER_PATTERN" -type d 2>/dev/null | while read -r container; do
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove: $container"
            else
                rm -rf "$container" 2>/dev/null && log_success "Removed: $(basename "$container")"
            fi
        done
    fi

    # Remove Application Scripts
    if [[ ${#APP_SCRIPTS_PATHS[@]} -gt 0 ]]; then
        log_info "Removing Application Scripts..."
        for path in "${APP_SCRIPTS_PATHS[@]}"; do
            remove_item "$path" "$(basename "$path")"
        done
    fi

    # Remove temp files
    log_info "Removing temporary files..."
    for pattern in "${TEMP_PATTERNS[@]}"; do
        find /private/var/folders -name "$pattern" 2>/dev/null | while read -r item; do
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove: $item"
            else
                rm -rf "$item" 2>/dev/null && log_success "Removed temp: $(basename "$item")"
            fi
        done
        remove_find "/tmp" "$pattern"
        remove_find "/private/tmp" "$pattern"
        remove_find "/private/var/tmp" "$pattern"
    done

    # Remove from Dock
    if [[ "$DRY_RUN" == false ]]; then
        DOCK_LABEL="${APP_NAME%.app}"
        python3 - "$DOCK_LABEL" <<'PYTHON' 2>/dev/null
import plistlib, os, sys
dock_label = sys.argv[1] if len(sys.argv) > 1 else ""
dock_plist = os.path.expanduser('~/Library/Preferences/com.apple.dock.plist')
try:
    with open(dock_plist, 'rb') as f:
        dock = plistlib.load(f)
    original_count = len(dock.get('persistent-apps', []))
    dock['persistent-apps'] = [app for app in dock.get('persistent-apps', [])
                               if dock_label not in app.get('tile-data', {}).get('file-label', '')]
    if len(dock['persistent-apps']) < original_count:
        with open(dock_plist, 'wb') as f:
            plistlib.dump(dock, f)
        sys.exit(0)
    sys.exit(1)
except:
    sys.exit(1)
PYTHON
        if [[ $? -eq 0 ]]; then
            log_success "Removed $BROWSER_NAME from Dock"
        fi
    fi

    log_success "$BROWSER_NAME uninstall completed!"
}

# =============================================================================
# MAIN UNINSTALL LOGIC
# =============================================================================
if [[ "$DELETE_ALL" == true ]]; then
    # Uninstall all browsers
    UNINSTALLED_COUNT=0
    for browser_num in 1 2 3 4 5 6 7; do
        configure_browser_vars "$browser_num"
        # Check if browser is installed
        if [[ -d "/Applications/$APP_NAME" ]] || [[ -d "$HOME/Applications/$APP_NAME" ]] || [[ -d "${APP_SUPPORT_PATHS[0]}" ]]; then
            perform_browser_uninstall
            ((UNINSTALLED_COUNT++))
        else
            log_warning "$BROWSER_NAME not installed, skipping..."
        fi
    done

    # Final cleanup
    log_info "Refreshing Dock..."
    killall Dock 2>/dev/null || true
    log_info "Flushing DNS cache..."
    sudo dscacheutil -flushcache 2>/dev/null || true
    sudo killall -HUP mDNSResponder 2>/dev/null || true

    # Final message for all browsers
    echo ""
    echo ""
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BG_YELLOW}${BOLD_WHITE}                                                                              ${NC}"
        echo -e "${BG_YELLOW}${BOLD_WHITE}                         DRY-RUN COMPLETE                                     ${NC}"
        echo -e "${BG_YELLOW}${BOLD_WHITE}                                                                              ${NC}"
        echo -e "${BG_YELLOW}${BOLD_WHITE}                  No files were actually deleted                              ${NC}"
        echo -e "${BG_YELLOW}${BOLD_WHITE}             Run without --dry-run to perform deletion                        ${NC}"
        echo -e "${BG_YELLOW}${BOLD_WHITE}                                                                              ${NC}"
    else
        echo -e "${BG_BLACK}${BOLD_GREEN}                                                                              ${NC}"
        echo -e "${BG_BLACK}${BOLD_GREEN}  ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗██╗                ${NC}"
        echo -e "${BG_BLACK}${BOLD_GREEN}  ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝██║                ${NC}"
        echo -e "${BG_BLACK}${BOLD_GREEN}  ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗██║                ${NC}"
        echo -e "${BG_BLACK}${BOLD_GREEN}  ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║╚═╝                ${NC}"
        echo -e "${BG_BLACK}${BOLD_GREEN}  ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║██╗                ${NC}"
        echo -e "${BG_BLACK}${BOLD_GREEN}  ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝╚═╝                ${NC}"
        echo -e "${BG_BLACK}${BOLD_GREEN}                                                                              ${NC}"
        echo ""
        echo -e "${BOLD_GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD_GREEN}║                                                                            ║${NC}"
        echo -e "${BOLD_GREEN}║       ALL BROWSERS have been COMPLETELY REMOVED from your system!         ║${NC}"
        echo -e "${BOLD_GREEN}║                                                                            ║${NC}"
        echo -e "${BOLD_GREEN}║                      Browsers uninstalled: $UNINSTALLED_COUNT                              ║${NC}"
        echo -e "${BOLD_GREEN}║                                                                            ║${NC}"
        echo -e "${BOLD_GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}Recommendations:${NC}"
        echo -e "  ${WHITE}•${NC} Restart your Mac to finalize cleanup"
        echo -e "  ${WHITE}•${NC} Empty Trash if files were moved there"
        echo -e "  ${WHITE}•${NC} Manually check Keychain Access for remaining entries"
    fi
    echo ""
    echo ""
    exit 0
fi

# =============================================================================
# SINGLE BROWSER UNINSTALL (Original code continues below)
# =============================================================================
# AGGRESSIVE FORCE KILL OF ALL BROWSER PROCESSES
# =============================================================================
echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                    FORCE KILLING ALL $BROWSER_NAME_UPPER PROCESSES$(printf '%*s' $((25 - ${#BROWSER_NAME_UPPER})) '')║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_kill "Terminating all $BROWSER_NAME processes..."

# Kill processes by name
for process in "${PROCESS_NAMES[@]}"; do
    pkill -9 -f "$process" 2>/dev/null && log_kill "Killed: $process" || true
done

# Kill crashpad handler
pkill -9 -f "crashpad_handler" 2>/dev/null && log_kill "Killed: crashpad_handler" || true

# Wait for processes to terminate
sleep 2

# Double check and force kill again
log_kill "Performing secondary kill sweep..."
for process in "${PROCESS_NAMES[@]}"; do
    killall -9 "$process" 2>/dev/null || true
    killall -9 "$process Helper (Renderer)" 2>/dev/null || true
    killall -9 "$process Helper (GPU)" 2>/dev/null || true
    killall -9 "$process Helper (Plugin)" 2>/dev/null || true
done

sleep 1

# =============================================================================
# STOP LAUNCH AGENTS (if Google Chrome with Keystone)
# =============================================================================
if [[ "$HAS_KEYSTONE" == true ]]; then
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                  STOPPING ALL GOOGLE SERVICES                              ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log_kill "Unloading user-level launch agents..."
    launchctl remove com.google.keystone.agent 2>/dev/null && log_kill "Removed: com.google.keystone.agent" || true
    launchctl remove com.google.keystone.xpcservice 2>/dev/null && log_kill "Removed: com.google.keystone.xpcservice" || true
    launchctl remove com.google.keystone.user.agent 2>/dev/null && log_kill "Removed: com.google.keystone.user.agent" || true
    launchctl unload ~/Library/LaunchAgents/com.google.keystone.agent.plist 2>/dev/null && log_kill "Unloaded: keystone.agent.plist" || true
    launchctl unload ~/Library/LaunchAgents/com.google.keystone.xpcservice.plist 2>/dev/null && log_kill "Unloaded: keystone.xpcservice.plist" || true
    launchctl unload ~/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist 2>/dev/null && log_kill "Unloaded: GoogleUpdater.wake.plist" || true

    pkill -9 -f "GoogleSoftwareUpdate" 2>/dev/null && log_kill "Killed: GoogleSoftwareUpdate" || true
    pkill -9 -f "keystone" 2>/dev/null && log_kill "Killed: Keystone processes" || true
    pkill -9 -f "Keystone" 2>/dev/null && log_kill "Killed: Keystone processes" || true
    pkill -9 -f "GoogleUpdater" 2>/dev/null && log_kill "Killed: GoogleUpdater" || true
    pkill -9 -f "com.google" 2>/dev/null && log_kill "Killed: com.google processes" || true

    killall -9 "GoogleSoftwareUpdateAgent" 2>/dev/null || true
    killall -9 "GoogleSoftwareUpdateDaemon" 2>/dev/null || true

    log_success "All Google services stopped"
    sleep 1
fi

# =============================================================================
# START DELETION PROCESS
# =============================================================================
echo ""
echo -e "${BOLD_RED}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD_RED}║                    STARTING PERMANENT DELETION                             ║${NC}"
echo -e "${BOLD_RED}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

STEP=1
TOTAL_STEPS=14
if [[ "$HAS_KEYSTONE" == true ]]; then
    TOTAL_STEPS=19
fi

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] MAIN APPLICATIONS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

remove_item "/Applications/$APP_NAME" "$APP_NAME"
remove_item "$HOME/Applications/$APP_NAME" "$APP_NAME (user Applications)"
# Remove additional apps (e.g., Chrome Canary)
for additional_app in "${ADDITIONAL_APPS[@]}"; do
    remove_item "/Applications/$additional_app" "$additional_app"
    remove_item "$HOME/Applications/$additional_app" "$additional_app (user Applications)"
done

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] USER PROFILE DATA (Application Support)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))
log_info "Removing $BROWSER_NAME profiles, history, cookies, extensions, databases..."

for path in "${APP_SUPPORT_PATHS[@]}"; do
    remove_item "$path" "$(basename "$path")"
done

# CrashReporter data
if [[ -d "$HOME/Library/Application Support/CrashReporter" ]]; then
    log_info "Checking CrashReporter for $BROWSER_NAME crashes..."
    for pattern in "${CRASH_PATTERNS[@]}"; do
        remove_find "$HOME/Library/Application Support/CrashReporter" "$pattern"
    done
fi

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] CACHES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

for path in "${CACHE_PATHS[@]}"; do
    remove_item "$path" "$(basename "$path")"
done

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] WEBKIT STORAGE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

for path in "${WEBKIT_PATHS[@]}"; do
    remove_item "$path" "$(basename "$path")"
done

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] COOKIES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

for file in "${COOKIE_FILES[@]}"; do
    remove_item "$file" "$(basename "$file")"
done

for pattern in "${COOKIE_PATTERNS[@]}"; do
    remove_pattern "$pattern" "$BROWSER_NAME cookies"
done

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] PREFERENCES (plist files)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

for file in "${PREF_FILES[@]}"; do
    remove_item "$file" "$(basename "$file")"
done

for pattern in "${PREF_PATTERNS[@]}"; do
    remove_pattern "$pattern" "ByHost preferences"
done

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] LAUNCH AGENTS (User)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

for file in "${LAUNCH_AGENT_FILES[@]}"; do
    remove_item "$file" "$(basename "$file")"
done

# ==============================================================================
if [[ "$HAS_KEYSTONE" == true ]]; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}[$STEP/$TOTAL_STEPS] GOOGLE SOFTWARE UPDATE (Keystone)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    ((STEP++))

    remove_item "$HOME/Library/Google/GoogleSoftwareUpdate" "GoogleSoftwareUpdate"
    remove_item "$HOME/Library/Google/Google Chrome Brand.plist" "Chrome Brand plist"

    if [[ -d "$HOME/Library/Google" ]] && [[ -z "$(ls -A "$HOME/Library/Google" 2>/dev/null)" ]]; then
        remove_item "$HOME/Library/Google" "Empty Google folder"
    fi
fi

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] SAVED APPLICATION STATE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

remove_item "$HOME/Library/Saved Application State/$BUNDLE_ID.savedState" "$BROWSER_NAME saved state"

# Remove all extension saved states
log_info "Searching for $BROWSER_NAME extension saved states..."
find "$HOME/Library/Saved Application State" -maxdepth 1 -name "$SAVED_STATE_PATTERN" 2>/dev/null | while read -r item; do
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove: $item"
    else
        rm -rf "$item" 2>/dev/null && log_success "Removed: $(basename "$item")"
    fi
done

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] LOGS & CRASH REPORTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

for path in "${LOG_PATHS[@]}"; do
    remove_item "$path" "$(basename "$path")"
done

log_info "Removing $BROWSER_NAME crash reports..."
for pattern in "${CRASH_PATTERNS[@]}"; do
    remove_find "$HOME/Library/Logs/DiagnosticReports" "$pattern"
    remove_find "$HOME/Library/Logs/DiagnosticReports/Retired" "$pattern"
done

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] HTTP STORAGES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

for path in "${HTTP_STORAGE_PATHS[@]}"; do
    remove_item "$path" "$(basename "$path")"
done

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] SANDBOX & CONTAINERS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

for path in "${CONTAINER_PATHS[@]}"; do
    remove_item "$path" "$(basename "$path")"
done

log_info "Checking Group Containers..."
if [[ -d "$HOME/Library/Group Containers" ]]; then
    find "$HOME/Library/Group Containers" -maxdepth 1 -name "$GROUP_CONTAINER_PATTERN" -type d 2>/dev/null | while read -r container; do
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove: $container"
        else
            rm -rf "$container" 2>/dev/null && log_success "Removed: $(basename "$container")"
        fi
    done
fi

# Remove Application Scripts
if [[ ${#APP_SCRIPTS_PATHS[@]} -gt 0 ]]; then
    log_info "Removing Application Scripts..."
    for path in "${APP_SCRIPTS_PATHS[@]}"; do
        remove_item "$path" "$(basename "$path")"
    done
fi

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] TEMPORARY FILES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))
log_info "Searching for $BROWSER_NAME temporary files..."

for pattern in "${TEMP_PATTERNS[@]}"; do
    find /private/var/folders -name "$pattern" 2>/dev/null | while read -r item; do
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove: $item"
        else
            rm -rf "$item" 2>/dev/null && log_success "Removed temp: $(basename "$item")"
        fi
    done

    remove_find "/tmp" "$pattern"
    remove_find "/private/tmp" "$pattern"
    remove_find "/private/var/tmp" "$pattern"
done

log_success "Temporary files cleaned"

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] SYSTEM FILES (requires sudo)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

SYSTEM_FILES_EXIST=false

# Check for system files based on browser
if [[ "$HAS_KEYSTONE" == true ]]; then
    [[ -d "/Library/Google/Chrome" ]] && SYSTEM_FILES_EXIST=true
    [[ -d "/Library/Google/GoogleSoftwareUpdate" ]] && SYSTEM_FILES_EXIST=true
    [[ -d "/Library/Google" ]] && SYSTEM_FILES_EXIST=true
    [[ -d "/Library/Application Support/Google/Chrome" ]] && SYSTEM_FILES_EXIST=true
    [[ -d "/Library/Application Support/Google" ]] && SYSTEM_FILES_EXIST=true
    [[ -f "/Library/LaunchAgents/com.google.keystone.agent.plist" ]] && SYSTEM_FILES_EXIST=true
    [[ -f "/Library/LaunchAgents/com.google.keystone.system.agent.plist" ]] && SYSTEM_FILES_EXIST=true
    [[ -f "/Library/LaunchDaemons/com.google.keystone.daemon.plist" ]] && SYSTEM_FILES_EXIST=true
    [[ -d "/Library/Logs/Google/Chrome" ]] && SYSTEM_FILES_EXIST=true
    [[ -f "/Library/Preferences/com.google.Chrome.plist" ]] && SYSTEM_FILES_EXIST=true
    [[ -f "/Library/Preferences/com.google.Keystone.plist" ]] && SYSTEM_FILES_EXIST=true
    [[ -f "/var/log/GoogleSoftwareUpdateAgent.log" ]] && SYSTEM_FILES_EXIST=true
fi

[[ -d "/Library/Application Support/$BROWSER_NAME" ]] && SYSTEM_FILES_EXIST=true
[[ -f "/Library/Preferences/$BUNDLE_ID.plist" ]] && SYSTEM_FILES_EXIST=true
[[ -d "/Library/Managed Preferences/$BUNDLE_ID.plist" ]] && SYSTEM_FILES_EXIST=true

if ls "/Library/Receipts/$BUNDLE_ID"* 1>/dev/null 2>&1 || ls "/var/db/receipts/$BUNDLE_ID"* 1>/dev/null 2>&1; then
    SYSTEM_FILES_EXIST=true
fi

if [[ "$SYSTEM_FILES_EXIST" == true ]]; then
    echo ""
    log_info "Found system-level $BROWSER_NAME files. Removing with sudo..."
    echo ""

    if [[ "$DRY_RUN" == false ]]; then
        # Stop system daemons if Google Chrome with Keystone
        if [[ "$HAS_KEYSTONE" == true ]]; then
            log_kill "Stopping system-level Google services..."
            sudo launchctl remove com.google.keystone.system.agent 2>/dev/null || true
            sudo launchctl remove com.google.keystone.daemon 2>/dev/null || true
            sudo launchctl unload /Library/LaunchAgents/com.google.keystone.agent.plist 2>/dev/null || true
            sudo launchctl unload /Library/LaunchAgents/com.google.keystone.system.agent.plist 2>/dev/null || true
            sudo launchctl unload /Library/LaunchDaemons/com.google.keystone.daemon.plist 2>/dev/null || true

            [[ -d "/Library/Google/Chrome" ]] && sudo rm -rf "/Library/Google/Chrome" && log_success "Removed: /Library/Google/Chrome"
            [[ -d "/Library/Google/GoogleSoftwareUpdate" ]] && sudo rm -rf "/Library/Google/GoogleSoftwareUpdate" && log_success "Removed: /Library/Google/GoogleSoftwareUpdate"
            [[ -d "/Library/Application Support/Google/Chrome" ]] && sudo rm -rf "/Library/Application Support/Google/Chrome" && log_success "Removed: /Library/Application Support/Google/Chrome"
            [[ -d "/Library/Application Support/Google" ]] && sudo rm -rf "/Library/Application Support/Google" && log_success "Removed: /Library/Application Support/Google"
            [[ -f "/Library/LaunchAgents/com.google.keystone.agent.plist" ]] && sudo rm -f "/Library/LaunchAgents/com.google.keystone.agent.plist" && log_success "Removed: System Keystone LaunchAgent"
            [[ -f "/Library/LaunchAgents/com.google.keystone.system.agent.plist" ]] && sudo rm -f "/Library/LaunchAgents/com.google.keystone.system.agent.plist" && log_success "Removed: System Keystone system agent"
            [[ -f "/Library/LaunchDaemons/com.google.keystone.daemon.plist" ]] && sudo rm -f "/Library/LaunchDaemons/com.google.keystone.daemon.plist" && log_success "Removed: System Keystone LaunchDaemon"
            [[ -d "/Library/Logs/Google/Chrome" ]] && sudo rm -rf "/Library/Logs/Google/Chrome" && log_success "Removed: /Library/Logs/Google/Chrome"
            [[ -f "/Library/Preferences/com.google.Chrome.plist" ]] && sudo rm -f "/Library/Preferences/com.google.Chrome.plist" && log_success "Removed: System Chrome preferences"
            [[ -f "/Library/Preferences/com.google.Keystone.plist" ]] && sudo rm -f "/Library/Preferences/com.google.Keystone.plist" && log_success "Removed: System Keystone preferences"
            [[ -f "/var/log/GoogleSoftwareUpdateAgent.log" ]] && sudo rm -f "/var/log/GoogleSoftwareUpdateAgent.log" && log_success "Removed: System GoogleSoftwareUpdateAgent log"

            # Remove empty folders
            if [[ -d "/Library/Google" ]] && [[ -z "$(ls -A /Library/Google 2>/dev/null)" ]]; then
                sudo rm -rf /Library/Google && log_success "Removed: /Library/Google (empty)"
            fi
            if [[ -d "/Library/Logs/Google" ]] && [[ -z "$(ls -A /Library/Logs/Google 2>/dev/null)" ]]; then
                sudo rm -rf /Library/Logs/Google && log_success "Removed: /Library/Logs/Google (empty)"
            fi
        fi

        # Remove browser-specific system files
        [[ -d "/Library/Application Support/$BROWSER_NAME" ]] && sudo rm -rf "/Library/Application Support/$BROWSER_NAME" && log_success "Removed: /Library/Application Support/$BROWSER_NAME"
        [[ -f "/Library/Preferences/$BUNDLE_ID.plist" ]] && sudo rm -f "/Library/Preferences/$BUNDLE_ID.plist" && log_success "Removed: System $BROWSER_NAME preferences"
        [[ -d "/Library/Managed Preferences/$BUNDLE_ID.plist" ]] && sudo rm -rf "/Library/Managed Preferences/$BUNDLE_ID.plist" && log_success "Removed: Managed $BROWSER_NAME preferences"

        # Remove receipts
        sudo rm -f "/Library/Receipts/$BUNDLE_ID"* 2>/dev/null && log_success "Removed: $BROWSER_NAME receipts"
        sudo rm -f "/var/db/receipts/$BUNDLE_ID"* 2>/dev/null && log_success "Removed: $BROWSER_NAME receipts from /var/db"

        # Remove system-level diagnostic reports
        log_info "Removing $BROWSER_NAME diagnostic reports..."
        for pattern in "${CRASH_PATTERNS[@]}"; do
            find /Library/Logs/DiagnosticReports -name "${pattern}.diag" -type f 2>/dev/null | while read -r report; do
                sudo rm -f "$report" 2>/dev/null && log_success "Removed: $(basename "$report")"
            done
        done
    else
        log_info "[DRY-RUN] Would remove system files with sudo"
    fi
else
    log_info "No system-level $BROWSER_NAME files found"
fi

# ==============================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[$STEP/$TOTAL_STEPS] SYSTEM CACHE CLEANUP${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
((STEP++))

if [[ "$DRY_RUN" == false ]]; then
    log_info "Removing $BROWSER_NAME from Dock..."
    # Use the app name without .app extension for Dock label matching
    DOCK_LABEL="${APP_NAME%.app}"
    python3 - "$DOCK_LABEL" <<'PYTHON'
import plistlib, os, sys
dock_label = sys.argv[1] if len(sys.argv) > 1 else ""
dock_plist = os.path.expanduser('~/Library/Preferences/com.apple.dock.plist')
try:
    with open(dock_plist, 'rb') as f:
        dock = plistlib.load(f)
    original_count = len(dock.get('persistent-apps', []))
    dock['persistent-apps'] = [app for app in dock.get('persistent-apps', [])
                               if dock_label not in app.get('tile-data', {}).get('file-label', '')]
    if len(dock['persistent-apps']) < original_count:
        with open(dock_plist, 'wb') as f:
            plistlib.dump(dock, f)
        sys.exit(0)
    sys.exit(1)
except:
    sys.exit(1)
PYTHON
    if [[ $? -eq 0 ]]; then
        log_success "Removed $BROWSER_NAME from Dock"
    fi

    log_info "Refreshing Dock..."
    killall Dock 2>/dev/null || true

    log_info "Flushing DNS cache..."
    sudo dscacheutil -flushcache 2>/dev/null || true
    sudo killall -HUP mDNSResponder 2>/dev/null || true

    log_success "System caches refreshed"
else
    echo -e "  ${YELLOW}[DRY-RUN]${NC} Would remove $BROWSER_NAME from Dock"
    echo -e "  ${YELLOW}[DRY-RUN]${NC} Would refresh Dock and DNS caches"
fi

# =============================================================================
# KEYCHAIN (Manual step)
# =============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}KEYCHAIN (Manual step required)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}$BROWSER_NAME stores passwords and tokens in Keychain Access.${NC}"
echo -e "${YELLOW}To remove them manually:${NC}"
echo ""
echo "  1. Open 'Keychain Access' (Applications > Utilities)"
echo "  2. Search for entries containing:"
echo "     - '$BROWSER_NAME'"
echo "     - '$BUNDLE_ID'"
echo "     - '$SAFE_STORAGE_NAME'"
echo "  3. Delete the found entries"
echo ""
echo -e "${YELLOW}Or use this command:${NC}"
echo "  security delete-generic-password -l '$SAFE_STORAGE_NAME' 2>/dev/null"
echo ""

# =============================================================================
# FINAL SUCCESS MESSAGE
# =============================================================================
echo ""
echo ""
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BG_YELLOW}${BOLD_WHITE}                                                                              ${NC}"
    echo -e "${BG_YELLOW}${BOLD_WHITE}                         DRY-RUN COMPLETE                                     ${NC}"
    echo -e "${BG_YELLOW}${BOLD_WHITE}                                                                              ${NC}"
    echo -e "${BG_YELLOW}${BOLD_WHITE}                  No files were actually deleted                              ${NC}"
    echo -e "${BG_YELLOW}${BOLD_WHITE}             Run without --dry-run to perform deletion                        ${NC}"
    echo -e "${BG_YELLOW}${BOLD_WHITE}                                                                              ${NC}"
else
    echo -e "${BG_BLACK}${BOLD_GREEN}                                                                              ${NC}"
    echo -e "${BG_BLACK}${BOLD_GREEN}  ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗██╗                ${NC}"
    echo -e "${BG_BLACK}${BOLD_GREEN}  ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝██║                ${NC}"
    echo -e "${BG_BLACK}${BOLD_GREEN}  ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗██║                ${NC}"
    echo -e "${BG_BLACK}${BOLD_GREEN}  ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║╚═╝                ${NC}"
    echo -e "${BG_BLACK}${BOLD_GREEN}  ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║██╗                ${NC}"
    echo -e "${BG_BLACK}${BOLD_GREEN}  ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝╚═╝                ${NC}"
    echo -e "${BG_BLACK}${BOLD_GREEN}                                                                              ${NC}"
    echo ""
    echo -e "${BOLD_GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_GREEN}║                                                                            ║${NC}"
    echo -e "${BOLD_GREEN}║       $BROWSER_NAME has been COMPLETELY REMOVED from your system!$(printf '%*s' $((25 - ${#BROWSER_NAME})) '')║${NC}"
    echo -e "${BOLD_GREEN}║                                                                            ║${NC}"
    echo -e "${BOLD_GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Recommendations:${NC}"
    echo -e "  ${WHITE}•${NC} Restart your Mac to finalize cleanup"
    echo -e "  ${WHITE}•${NC} Empty Trash if files were moved there"
    echo -e "  ${WHITE}•${NC} Manually check Keychain Access (see above)"
fi

echo ""
echo ""
