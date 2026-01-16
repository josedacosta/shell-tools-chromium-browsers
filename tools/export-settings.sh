#!/bin/bash
set -euo pipefail
# =============================================================================
# Chromium-based Browser Settings Export Script
# =============================================================================
#
# PLATFORM:     macOS (primary) / Linux (secondary support)
# SHELL:        Bash (tested with GNU bash 3.2+)
# DEPENDENCIES: jq (install with: brew install jq)
#
# DESCRIPTION:
#   Exports browser settings to a human-readable Markdown file for manual
#   replication after a clean reinstall. Also generates JSON exports of
#   raw browser configuration files.
#
# SUPPORTED BROWSERS:
#   Google Chrome, Chromium, Brave, Microsoft Edge, Opera, Vivaldi, Arc
#
# USAGE:
#   bash export-settings.sh    # Interactive browser and profile selection
#
# OUTPUT:
#   Creates a timestamped folder containing:
#   - {BROWSER}_SETTINGS.md    Human-readable settings summary
#   - settings_export.json     Structured JSON export
#   - Preferences.json         Raw browser preferences
#   - Local_State.json         Global browser state
#
# NOTE:
#   This script prioritizes functionality over code elegance. It may be long,
#   repetitive, and not fully optimized. Code refactoring is planned for a
#   future version.
#
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check that jq is installed
if ! command -v jq &> /dev/null; then
    log_error "jq is not installed. Install it with: brew install jq"
    exit 1
fi

# Verify OS is supported
if [[ "$OSTYPE" != "darwin"* ]] && [[ "$OSTYPE" != "linux"* ]]; then
    log_error "Unsupported OS: $OSTYPE"
    exit 1
fi

# Script directory for output
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# BROWSER CONFIGURATION FUNCTION
# =============================================================================
set_browser_config() {
    local choice="$1"

    case "$choice" in
        1)
            BROWSER_NAME="Google Chrome"
            BROWSER_SHORT="chrome"
            BUNDLE_ID="com.google.Chrome"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                BROWSER_BASE="$HOME/Library/Application Support/Google/Chrome"
            else
                BROWSER_BASE="$HOME/.config/google-chrome"
            fi
            SETTINGS_FILE_NAME="CHROME_SETTINGS.md"
            HAS_GOOGLE_ACCOUNT=true
            ;;
        2)
            BROWSER_NAME="Chromium"
            BROWSER_SHORT="chromium"
            BUNDLE_ID="org.chromium.Chromium"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                BROWSER_BASE="$HOME/Library/Application Support/Chromium"
            else
                BROWSER_BASE="$HOME/.config/chromium"
            fi
            SETTINGS_FILE_NAME="CHROMIUM_SETTINGS.md"
            HAS_GOOGLE_ACCOUNT=false
            ;;
        3)
            BROWSER_NAME="Brave"
            BROWSER_SHORT="brave"
            BUNDLE_ID="com.brave.Browser"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                BROWSER_BASE="$HOME/Library/Application Support/BraveSoftware/Brave-Browser"
            else
                BROWSER_BASE="$HOME/.config/BraveSoftware/Brave-Browser"
            fi
            SETTINGS_FILE_NAME="BRAVE_SETTINGS.md"
            HAS_GOOGLE_ACCOUNT=false
            ;;
        4)
            BROWSER_NAME="Microsoft Edge"
            BROWSER_SHORT="edge"
            BUNDLE_ID="com.microsoft.edgemac"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                BROWSER_BASE="$HOME/Library/Application Support/Microsoft Edge"
            else
                BROWSER_BASE="$HOME/.config/microsoft-edge"
            fi
            SETTINGS_FILE_NAME="EDGE_SETTINGS.md"
            HAS_GOOGLE_ACCOUNT=false
            ;;
        5)
            BROWSER_NAME="Opera"
            BROWSER_SHORT="opera"
            BUNDLE_ID="com.operasoftware.Opera"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                BROWSER_BASE="$HOME/Library/Application Support/com.operasoftware.Opera"
            else
                BROWSER_BASE="$HOME/.config/opera"
            fi
            SETTINGS_FILE_NAME="OPERA_SETTINGS.md"
            HAS_GOOGLE_ACCOUNT=false
            ;;
        6)
            BROWSER_NAME="Vivaldi"
            BROWSER_SHORT="vivaldi"
            BUNDLE_ID="com.vivaldi.Vivaldi"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                BROWSER_BASE="$HOME/Library/Application Support/Vivaldi"
            else
                BROWSER_BASE="$HOME/.config/vivaldi"
            fi
            SETTINGS_FILE_NAME="VIVALDI_SETTINGS.md"
            HAS_GOOGLE_ACCOUNT=false
            ;;
        7)
            BROWSER_NAME="Arc"
            BROWSER_SHORT="arc"
            BUNDLE_ID="company.thebrowser.Browser"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                BROWSER_BASE="$HOME/Library/Application Support/Arc"
            else
                return 1  # Arc not available on Linux
            fi
            SETTINGS_FILE_NAME="ARC_SETTINGS.md"
            HAS_GOOGLE_ACCOUNT=false
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

# =============================================================================
# UTILITY FUNCTIONS FOR JSON EXTRACTION
# =============================================================================
extract_json() {
    local file="$1"
    local path="$2"
    local default="${3:-(not set)}"
    local result
    result=$(jq -r "$path // null" "$file" 2>/dev/null)
    if [[ "$result" == "null" || -z "$result" ]]; then
        echo "$default"
    else
        echo "$result"
    fi
}

extract_json_raw() {
    local file="$1"
    local path="$2"
    jq -r "$path // empty" "$file" 2>/dev/null || true
}

extract_json_array_formatted() {
    local file="$1"
    local path="$2"
    jq -r "$path // [] | if type == \"array\" then join(\", \") else . end" "$file" 2>/dev/null || echo "(not set)"
}

section_header() {
    echo ""
    echo "---"
    echo ""
    echo "## $1"
    echo ""
}

subsection() {
    echo ""
    echo "### $1"
    echo ""
}

# =============================================================================
# EXPORT FUNCTION FOR A SINGLE BROWSER
# =============================================================================
export_browser() {
    local browser_num="$1"
    local auto_profile="${2:-false}"  # If true, auto-select Default profile

    if ! set_browser_config "$browser_num"; then
        return 1
    fi

    LOCAL_STATE="$BROWSER_BASE/Local State"

    # Check if browser is installed
    if [[ ! -f "$LOCAL_STATE" ]]; then
        if [[ "$auto_profile" == true ]]; then
            log_warn "$BROWSER_NAME is not installed, skipping..."
            return 1
        else
            log_error "'Local State' file not found in: $BROWSER_BASE"
            log_error "Make sure $BROWSER_NAME is installed and has been run at least once."
            return 1
        fi
    fi

    echo ""
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  Exporting: $BROWSER_NAME${NC}"
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Function to get the friendly name of a profile
    get_profile_name() {
        local profile_dir="$1"
        jq -r ".profile.info_cache.\"$profile_dir\".name // \"(unnamed)\"" "$LOCAL_STATE" 2>/dev/null
    }

    # List all available profiles
    log_info "Available $BROWSER_NAME profiles:"
    PROFILES=()
    PROFILE_NAMES=()

    if [[ -d "$BROWSER_BASE/Default" ]]; then
        PROFILES+=("Default")
        friendly_name=$(get_profile_name "Default")
        PROFILE_NAMES+=("$friendly_name")
        echo "  1) Default - $friendly_name"
    fi

    idx=2
    for dir in "$BROWSER_BASE"/Profile\ *; do
        if [[ -d "$dir" ]]; then
            profile_dir=$(basename "$dir")
            PROFILES+=("$profile_dir")
            friendly_name=$(get_profile_name "$profile_dir")
            PROFILE_NAMES+=("$friendly_name")
            echo "  $idx) $profile_dir - $friendly_name"
            ((idx++))
        fi
    done

    if [[ ${#PROFILES[@]} -eq 0 ]]; then
        log_error "No $BROWSER_NAME profiles found"
        return 1
    fi

    # Profile selection
    if [[ "$auto_profile" == true ]]; then
        # Auto-select Default profile, or first available
        SELECTED_PROFILE="${PROFILES[0]}"
        SELECTED_PROFILE_NAME="${PROFILE_NAMES[0]}"
        log_info "Auto-selecting profile: $SELECTED_PROFILE - $SELECTED_PROFILE_NAME"
    elif [[ ${#PROFILES[@]} -eq 1 ]]; then
        SELECTED_PROFILE="${PROFILES[0]}"
        SELECTED_PROFILE_NAME="${PROFILE_NAMES[0]}"
        log_info "Single profile found, auto-selecting: $SELECTED_PROFILE - $SELECTED_PROFILE_NAME"
    else
        echo ""
        read -p "Select a profile (1-${#PROFILES[@]}) [1]: " choice
        choice=${choice:-1}
        if [[ "$choice" -lt 1 || "$choice" -gt ${#PROFILES[@]} ]]; then
            log_error "Invalid choice"
            return 1
        fi
        SELECTED_PROFILE="${PROFILES[$((choice-1))]}"
        SELECTED_PROFILE_NAME="${PROFILE_NAMES[$((choice-1))]}"
        log_success "Selected profile: $SELECTED_PROFILE - $SELECTED_PROFILE_NAME"
    fi

    PROFILE_DIR="$BROWSER_BASE/$SELECTED_PROFILE"
    PREFERENCES="$PROFILE_DIR/Preferences"
    SECURE_PREFERENCES="$PROFILE_DIR/Secure Preferences"

    if [[ ! -f "$PREFERENCES" ]]; then
        log_error "Preferences file not found for profile: $SELECTED_PROFILE"
        return 1
    fi

    # Create backup folder
    TS="$(date +%Y%m%d-%H%M%S)"
    OUT_DIR="$SCRIPT_DIR/export-settings-${BROWSER_SHORT}-$TS"
    mkdir -p "$OUT_DIR"

    # Copy raw files
    cp -a "$LOCAL_STATE" "$OUT_DIR/Local_State.json"
    cp -a "$PREFERENCES" "$OUT_DIR/Preferences.json"
    [[ -f "$SECURE_PREFERENCES" ]] && cp -a "$SECURE_PREFERENCES" "$OUT_DIR/Secure_Preferences.json"

    log_success "JSON files saved to: $OUT_DIR"

    # Generate summary file
    SUMMARY="$OUT_DIR/$SETTINGS_FILE_NAME"

    {
        echo "# $BROWSER_NAME Settings Export"
        echo ""
        echo "**Export date:** $(date '+%Y-%m-%d %H:%M:%S')"
        echo "**Browser:** $BROWSER_NAME"
        echo "**Profile name:** $SELECTED_PROFILE_NAME"
        echo "**Profile directory:** $SELECTED_PROFILE"
        echo "**Full path:** \`$PROFILE_DIR\`"
        echo ""

        # Google Account info (only for Google Chrome)
        if [[ "$HAS_GOOGLE_ACCOUNT" == true ]]; then
            gaia_name=$(jq -r ".profile.info_cache.\"$SELECTED_PROFILE\".gaia_name // empty" "$LOCAL_STATE" 2>/dev/null)
            gaia_email=$(jq -r ".profile.info_cache.\"$SELECTED_PROFILE\".user_name // empty" "$LOCAL_STATE" 2>/dev/null)
            if [[ -n "$gaia_email" ]]; then
                echo "**Google account:** $gaia_name ($gaia_email)"
                echo ""
            fi

            section_header "GOOGLE ACCOUNT & SYNC"

            echo "### Account Information"
            echo ""

            if [[ -n "$gaia_email" ]]; then
                echo "| Setting | Value |"
                echo "|---------|-------|"
                echo "| Account name | $gaia_name |"
                echo "| Email | $gaia_email |"
                gaia_id=$(jq -r ".profile.info_cache.\"$SELECTED_PROFILE\".gaia_id // \"(not set)\"" "$LOCAL_STATE" 2>/dev/null)
                echo "| Gaia ID | $gaia_id |"
                hosted_domain=$(jq -r ".profile.info_cache.\"$SELECTED_PROFILE\".hosted_domain // \"(personal account)\"" "$LOCAL_STATE" 2>/dev/null)
                echo "| Domain | $hosted_domain |"
                echo ""
            else
                echo "*(No Google account linked to this profile)*"
                echo ""
            fi

            echo "### Sync Settings"
            echo ""
            echo "Data types configured for sync:"
            echo ""

            sync_settings=$(jq -r '.sync.data_type_status_for_sync_to_signin // {}' "$PREFERENCES" 2>/dev/null)
            if [[ -n "$sync_settings" && "$sync_settings" != "{}" ]]; then
                echo "| Data Type | Synced |"
                echo "|-----------|--------|"
                echo "$sync_settings" | jq -r 'to_entries[] | "| \(.key | gsub("_"; " ") | ascii_upcase) | \(if .value then "Yes" else "No" end) |"' 2>/dev/null | head -20
            else
                echo "*(Sync not configured or using defaults)*"
            fi
            echo ""
            echo "*Settings > You and Google > Sync and Google services*"
        fi

        section_header "DOWNLOADS"

        echo "### Downloads"
        echo ""
        echo "| Setting | Value | $BROWSER_NAME Path |"
        echo "|---------|-------|---------------------|"

        dl_dir=$(extract_json "$PREFERENCES" '.savefile.default_directory')
        [[ "$dl_dir" == "(not set)" ]] && dl_dir=$(extract_json "$PREFERENCES" '.download.default_directory')
        [[ "$dl_dir" == "(not set)" ]] && dl_dir=$(extract_json "$PREFERENCES" '.selectfile.last_directory')
        echo "| Default folder | \`$dl_dir\` | Settings > Downloads |"

        dl_prompt=$(extract_json "$PREFERENCES" '.download.prompt_for_download')
        [[ "$dl_prompt" == "true" ]] && dl_prompt_txt="Yes" || dl_prompt_txt="No"
        echo "| Ask where to save | $dl_prompt_txt | Settings > Downloads |"

        open_pdf=$(extract_json "$PREFERENCES" '.download.open_pdf_in_system_reader')
        [[ "$open_pdf" == "true" ]] && pdf_txt="System PDF reader" || pdf_txt="$BROWSER_NAME PDF viewer"
        echo "| Open PDFs with | $pdf_txt | Settings > Downloads |"

        section_header "STARTUP AND HOMEPAGE"

        echo "### On Startup"
        echo ""

        startup_type=$(extract_json_raw "$PREFERENCES" '.session.restore_on_startup')
        [[ -z "$startup_type" ]] && startup_type=$(extract_json_raw "$PREFERENCES" '.browser.restore_on_startup')

        case "$startup_type" in
            1) startup_txt="Open the New Tab page" ;;
            4) startup_txt="Continue where you left off" ;;
            5) startup_txt="Open a specific page or set of pages" ;;
            "") startup_txt="Continue where you left off (default)" ;;
            *) startup_txt="Unknown ($startup_type)" ;;
        esac
        echo "**Startup behavior:** $startup_txt"
        echo ""

        startup_urls=$(jq -r '.session.startup_urls // [] | .[]' "$PREFERENCES" 2>/dev/null)
        if [[ -n "$startup_urls" ]]; then
            echo "**Startup URLs:**"
            echo ""
            echo "$startup_urls" | while read -r url; do
                [[ -n "$url" ]] && echo "- $url"
            done
            echo ""
        fi

        echo "*Settings > On startup*"
        echo ""

        echo "### Homepage"
        echo ""
        echo "| Setting | Value |"
        echo "|---------|-------|"

        homepage=$(extract_json "$PREFERENCES" '.homepage')
        echo "| Homepage URL | \`$homepage\` |"

        homepage_is_ntp=$(extract_json_raw "$PREFERENCES" '.homepage_is_newtabpage')
        [[ "$homepage_is_ntp" == "true" ]] && ntp_txt="Yes" || ntp_txt="No"
        echo "| Use New Tab as homepage | $ntp_txt |"

        show_home_button=$(extract_json_raw "$PREFERENCES" '.browser.show_home_button')
        [[ "$show_home_button" == "true" ]] && btn_txt="Yes" || btn_txt="No"
        echo "| Show Home button | $btn_txt |"

        echo ""
        echo "*Settings > Appearance > Show home button*"

        section_header "SEARCH ENGINE"

        echo "### Default Search Engine"
        echo ""

        search_name=$(extract_json "$PREFERENCES" '.default_search_provider_data.mirrored_template_url_data.short_name')
        [[ "$search_name" == "(not set)" ]] && search_name=$(extract_json "$PREFERENCES" '.default_search_provider_data.template_url_data.short_name')

        search_keyword=$(extract_json "$PREFERENCES" '.default_search_provider_data.mirrored_template_url_data.keyword')
        [[ "$search_keyword" == "(not set)" ]] && search_keyword=$(extract_json "$PREFERENCES" '.default_search_provider_data.template_url_data.keyword')

        echo "| Setting | Value |"
        echo "|---------|-------|"
        echo "| Search engine | $search_name |"
        echo "| Keyword | $search_keyword |"

        echo ""
        echo "*Settings > Search engine*"

        section_header "LANGUAGES"

        echo "### Languages"
        echo ""

        accept_languages=$(extract_json "$PREFERENCES" '.intl.accept_languages')
        echo "**Preferred languages:** \`$accept_languages\`"
        echo ""

        spell_dictionaries=$(extract_json_array_formatted "$PREFERENCES" '.spellcheck.dictionaries')
        echo "**Spell check languages:** $spell_dictionaries"
        echo ""

        spell_enabled=$(extract_json_raw "$PREFERENCES" '.browser.enable_spellchecking')
        [[ "$spell_enabled" == "false" ]] && spell_txt="Disabled" || spell_txt="Enabled"
        echo "**Spell checking:** $spell_txt"
        echo ""

        echo "*Settings > Languages*"

        section_header "PRIVACY AND SECURITY"

        echo "### Cookies and Site Data"
        echo ""

        cookie_behavior=$(extract_json_raw "$PREFERENCES" '.profile.default_content_setting_values.cookies')
        case "$cookie_behavior" in
            1) cookie_txt="Allow all cookies" ;;
            2) cookie_txt="Block all cookies" ;;
            4) cookie_txt="Block third-party cookies" ;;
            "") cookie_txt="Allow all cookies (default)" ;;
            *) cookie_txt="Custom ($cookie_behavior)" ;;
        esac
        echo "- **Cookie behavior:** $cookie_txt"

        dnt=$(extract_json_raw "$PREFERENCES" '.enable_do_not_track')
        [[ "$dnt" == "true" ]] && dnt_txt="Enabled" || dnt_txt="Disabled"
        echo "- **Send \"Do Not Track\" request:** $dnt_txt"

        echo ""
        echo "### Safe Browsing"
        echo ""

        safe_browsing=$(extract_json_raw "$PREFERENCES" '.safebrowsing.enabled')
        safe_browsing_enhanced=$(extract_json_raw "$PREFERENCES" '.safebrowsing.enhanced')

        if [[ "$safe_browsing" == "false" ]]; then
            sb_txt="No protection (not recommended)"
        elif [[ "$safe_browsing_enhanced" == "true" ]]; then
            sb_txt="Enhanced protection"
        else
            sb_txt="Standard protection"
        fi
        echo "- **Protection level:** $sb_txt"

        echo ""
        echo "*Settings > Privacy and security*"

        section_header "APPEARANCE"

        echo "### Theme and Display"
        echo ""
        echo "| Setting | Value |"
        echo "|---------|-------|"

        theme_id=$(extract_json_raw "$PREFERENCES" '.extensions.theme.id')
        [[ -z "$theme_id" ]] && theme_id="Default $BROWSER_NAME theme"
        echo "| Theme | $theme_id |"

        font_size=$(extract_json "$PREFERENCES" '.webkit.webprefs.default_font_size' "16")
        echo "| Default font size | ${font_size}px |"

        fixed_font_size=$(extract_json "$PREFERENCES" '.webkit.webprefs.default_fixed_font_size' "13")
        echo "| Fixed-width font size | ${fixed_font_size}px |"

        min_font_size=$(extract_json "$PREFERENCES" '.webkit.webprefs.minimum_font_size' "0")
        echo "| Minimum font size | ${min_font_size}px |"

        echo ""

        show_bookmarks=$(extract_json_raw "$PREFERENCES" '.bookmark_bar.show_on_all_tabs')
        [[ "$show_bookmarks" == "true" ]] && bm_txt="Always show" || bm_txt="Only on New Tab page"
        echo "- **Bookmarks bar:** $bm_txt"

        echo ""
        echo "*Settings > Appearance*"

        section_header "AUTOFILL AND PASSWORDS"

        echo "### Password Manager"
        echo ""

        password_saving=$(extract_json_raw "$PREFERENCES" '.credentials_enable_service')
        [[ "$password_saving" == "false" ]] && pw_txt="Disabled" || pw_txt="Enabled"
        echo "- **Offer to save passwords:** $pw_txt"

        autosignin=$(extract_json_raw "$PREFERENCES" '.credentials_enable_autosignin')
        [[ "$autosignin" == "false" ]] && as_txt="Disabled" || as_txt="Enabled"
        echo "- **Auto sign-in:** $as_txt"

        echo ""
        echo "### Autofill"
        echo ""

        autofill_addresses=$(extract_json_raw "$PREFERENCES" '.autofill.profile_enabled')
        [[ "$autofill_addresses" == "false" ]] && addr_txt="Disabled" || addr_txt="Enabled"
        echo "- **Save and fill addresses:** $addr_txt"

        autofill_cc=$(extract_json_raw "$PREFERENCES" '.autofill.credit_card_enabled')
        [[ "$autofill_cc" == "false" ]] && cc_txt="Disabled" || cc_txt="Enabled"
        echo "- **Save and fill payment methods:** $cc_txt"

        echo ""
        echo "*Settings > Autofill and passwords*"

        section_header "SYSTEM"

        echo "### System Settings"
        echo ""

        hw_accel=$(jq -r '.hardware_acceleration_mode.enabled // true' "$LOCAL_STATE" 2>/dev/null)
        [[ "$hw_accel" == "false" ]] && hw_txt="Disabled" || hw_txt="Enabled"
        echo "- **Hardware acceleration:** $hw_txt"

        bg_mode=$(extract_json_raw "$PREFERENCES" '.background_mode.enabled')
        [[ "$bg_mode" == "true" ]] && bg_txt="Enabled" || bg_txt="Disabled"
        echo "- **Continue running background apps when $BROWSER_NAME is closed:** $bg_txt"

        echo ""
        echo "*Settings > System*"

        section_header "SITE PERMISSIONS (DEFAULTS)"

        echo "### Default Permissions"
        echo ""
        echo "These are the default behaviors for site permissions:"
        echo ""
        echo "| Permission | Default | Meaning |"
        echo "|------------|---------|---------|"

        interpret_permission() {
            local val="$1"
            case "$val" in
                1) echo "Allow" ;;
                2) echo "Block" ;;
                3) echo "Ask" ;;
                "") echo "Ask (default)" ;;
                *) echo "Custom ($val)" ;;
            esac
        }

        notification=$(extract_json_raw "$PREFERENCES" '.profile.default_content_setting_values.notifications')
        echo "| Notifications | $(interpret_permission "$notification") | Sites can send notifications |"

        location=$(extract_json_raw "$PREFERENCES" '.profile.default_content_setting_values.geolocation')
        echo "| Location | $(interpret_permission "$location") | Sites can access your location |"

        camera=$(extract_json_raw "$PREFERENCES" '.profile.default_content_setting_values.media_stream_camera')
        echo "| Camera | $(interpret_permission "$camera") | Sites can use your camera |"

        mic=$(extract_json_raw "$PREFERENCES" '.profile.default_content_setting_values.media_stream_mic')
        echo "| Microphone | $(interpret_permission "$mic") | Sites can use your microphone |"

        popups=$(extract_json_raw "$PREFERENCES" '.profile.default_content_setting_values.popups')
        [[ -z "$popups" ]] && popups="2"
        echo "| Pop-ups | $(interpret_permission "$popups") | Sites can show pop-ups |"

        javascript=$(extract_json_raw "$PREFERENCES" '.profile.default_content_setting_values.javascript')
        [[ -z "$javascript" ]] && javascript="1"
        echo "| JavaScript | $(interpret_permission "$javascript") | Sites can use JavaScript |"

        clipboard=$(extract_json_raw "$PREFERENCES" '.profile.default_content_setting_values.clipboard')
        echo "| Clipboard | $(interpret_permission "$clipboard") | Sites can access clipboard |"

        echo ""
        echo "*Settings > Privacy and security > Site settings*"

        section_header "INSTALLED EXTENSIONS"

        echo "### Extensions"
        echo ""

        ext_count=$(jq '[.extensions.settings // {} | to_entries[] | select(.value.manifest != null and .value.manifest.name != null)] | length' "$PREFERENCES" 2>/dev/null || echo "0")

        if [[ "$ext_count" -gt 0 ]]; then
            echo "| Extension Name | Extension ID | Status |"
            echo "|----------------|--------------|--------|"

            jq -r '.extensions.settings // {} | to_entries[] | select(.value.manifest != null and .value.manifest.name != null) | "\(.value.manifest.name)|\(.key)|\(.value.state // 0)"' "$PREFERENCES" 2>/dev/null | \
            sort | \
            while IFS='|' read -r ext_name ext_id ext_state; do
                case "$ext_state" in
                    0) state_txt="Disabled" ;;
                    1) state_txt="Enabled" ;;
                    *) state_txt="State $ext_state" ;;
                esac
                echo "| $ext_name | \`$ext_id\` | $state_txt |"
            done

            echo ""
            echo "**To reinstall:** Search for each extension by name on the [Chrome Web Store](https://chrome.google.com/webstore)"
        else
            echo "*(No extensions installed in this profile)*"
        fi

        echo ""
        echo "*chrome://extensions*"

        section_header "SITE-SPECIFIC PERMISSIONS"

        echo "### Notification Exceptions"
        echo ""

        subsection "Allowed sites"
        allowed_notif=$(jq -r '.profile.content_settings.exceptions.notifications // {} | to_entries[] | select(.value.setting == 1) | .key' "$PREFERENCES" 2>/dev/null | head -30)
        if [[ -n "$allowed_notif" ]]; then
            echo "$allowed_notif" | while read -r site; do
                echo "- \`$site\`"
            done
        else
            echo "*(None)*"
        fi

        subsection "Blocked sites"
        blocked_notif=$(jq -r '.profile.content_settings.exceptions.notifications // {} | to_entries[] | select(.value.setting == 2) | .key' "$PREFERENCES" 2>/dev/null | head -30)
        if [[ -n "$blocked_notif" ]]; then
            echo "$blocked_notif" | while read -r site; do
                echo "- \`$site\`"
            done
        else
            echo "*(None)*"
        fi

        echo ""
        echo "### Cookie Exceptions"
        echo ""

        subsection "Sites allowed to use cookies"
        allowed_cookies=$(jq -r '.profile.content_settings.exceptions.cookies // {} | to_entries[] | select(.value.setting == 1) | .key' "$PREFERENCES" 2>/dev/null | head -30)
        if [[ -n "$allowed_cookies" ]]; then
            echo "$allowed_cookies" | while read -r site; do
                echo "- \`$site\`"
            done
        else
            echo "*(None)*"
        fi

        section_header "KEYBOARD SHORTCUTS"

        echo "### Extension Keyboard Shortcuts"
        echo ""

        shortcuts=$(jq -r '.extensions.commands // {} | to_entries[] | select(.value != null and .value != "") | "\(.key): \(.value)"' "$PREFERENCES" 2>/dev/null | head -30)
        if [[ -n "$shortcuts" ]]; then
            echo '```'
            echo "$shortcuts"
            echo '```'
        else
            echo "*(No custom shortcuts configured)*"
        fi

        echo ""
        echo "*chrome://extensions/shortcuts*"

        section_header "HOW TO REPLICATE THESE SETTINGS"

        if [[ "$HAS_GOOGLE_ACCOUNT" == true ]]; then
            gaia_email_check=$(jq -r ".profile.info_cache.\"$SELECTED_PROFILE\".user_name // empty" "$LOCAL_STATE" 2>/dev/null)
            if [[ -n "$gaia_email_check" ]]; then
                echo "### 1. Sign in to Google Account"
                echo "Sign in with: **$gaia_email_check**"
                echo ""
                echo "This will automatically sync some settings if sync was enabled."
                echo ""
            fi
        fi

        echo "### Configure Basic Settings"
        echo "1. Open $BROWSER_NAME Settings: \`chrome://settings\`"
        echo "2. Set your preferred search engine"
        echo "3. Configure startup behavior"
        echo "4. Set download location"
        echo ""

        echo "### Install Extensions"
        echo "1. Go to [Chrome Web Store](https://chrome.google.com/webstore)"
        echo "2. Search and install each extension listed above"
        echo "3. Configure extension shortcuts at \`chrome://extensions/shortcuts\`"
        echo ""

        echo "### Configure Site Permissions"
        echo "1. Go to \`chrome://settings/content\`"
        echo "2. Add site exceptions for notifications, cookies, etc."
        echo ""

        echo "### Reference Files"
        echo "Raw JSON configuration files are available in:"
        echo "\`$OUT_DIR\`"
        echo ""
        echo "- \`Preferences.json\` - Profile settings"
        echo "- \`Local_State.json\` - Global $BROWSER_NAME settings"
        echo "- \`settings_export.json\` - Structured export"
        echo ""

        echo "---"
        echo "*Generated by export-settings.sh on $(date '+%Y-%m-%d %H:%M:%S')*"

    } > "$SUMMARY"

    # Generate structured JSON export
    JSON_EXPORT="$OUT_DIR/settings_export.json"

    jq -n \
        --arg browser "$BROWSER_NAME" \
        --arg profile_dir "$SELECTED_PROFILE" \
        --arg profile_name "$SELECTED_PROFILE_NAME" \
        --arg date "$(date -Iseconds)" \
        --arg dl_dir "$(extract_json "$PREFERENCES" '.savefile.default_directory')" \
        --arg homepage "$(extract_json "$PREFERENCES" '.homepage')" \
        --arg search "$(extract_json "$PREFERENCES" '.default_search_provider_data.mirrored_template_url_data.short_name')" \
        --arg languages "$(extract_json "$PREFERENCES" '.intl.accept_languages')" \
        --argjson extensions "$(jq '[.extensions.settings // {} | to_entries[] | select(.value.manifest != null and .value.manifest.name != null) | {id: .key, name: .value.manifest.name, enabled: (.value.state == 1)}]' "$PREFERENCES" 2>/dev/null || echo '[]')" \
        '{
            meta: {
                export_date: $date,
                browser: $browser,
                profile_name: $profile_name,
                profile_directory: $profile_dir
            },
            settings: {
                downloads: {
                    default_directory: $dl_dir
                },
                homepage: $homepage,
                search_engine: $search,
                languages: $languages
            },
            extensions: $extensions
        }' > "$JSON_EXPORT"

    # Format JSON files
    log_info "Formatting JSON files..."
    for json_file in "$OUT_DIR"/*.json; do
        if [[ -f "$json_file" ]]; then
            local tmp_file="${json_file}.tmp"
            if jq '.' "$json_file" > "$tmp_file" 2>/dev/null; then
                mv "$tmp_file" "$json_file"
            else
                rm -f "$tmp_file"
                log_warn "Could not format: $(basename "$json_file")"
            fi
        fi
    done
    log_success "JSON files formatted"

    # Final summary for this browser
    echo ""
    log_success "Export complete for $BROWSER_NAME!"
    echo ""
    echo "Files created in: $OUT_DIR"
    echo ""
    echo "   $SETTINGS_FILE_NAME     - Readable summary (Markdown)"
    echo "   settings_export.json     - Structured JSON export"
    echo "   Preferences.json         - Raw $BROWSER_NAME file"
    echo "   Local_State.json         - $BROWSER_NAME global state"
    echo ""

    return 0
}

# =============================================================================
# BROWSER SELECTION
# =============================================================================
clear
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║              CHROMIUM-BASED BROWSER SETTINGS EXPORT                      ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Select a browser to export settings from:${NC}"
echo ""
echo -e "  1) Google Chrome ${DIM}(includes Chrome Canary)${NC}"
echo "  2) Chromium"
echo "  3) Brave"
echo "  4) Microsoft Edge"
echo "  5) Opera"
echo "  6) Vivaldi"
echo "  7) Arc"
echo "  8) All browsers"
echo ""
read -p "Enter your choice (1-8): " browser_choice
echo ""

# =============================================================================
# MAIN EXECUTION
# =============================================================================
if [[ "$browser_choice" == "8" ]]; then
    # Export all browsers
    log_info "Exporting settings for all installed browsers..."
    echo ""

    EXPORTED_COUNT=0
    FAILED_COUNT=0

    for i in 1 2 3 4 5 6 7; do
        if export_browser "$i" true; then
            ((EXPORTED_COUNT++))
        else
            ((FAILED_COUNT++))
        fi
    done

    echo ""
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  EXPORT SUMMARY${NC}"
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}Browsers exported:${NC} $EXPORTED_COUNT"
    echo -e "  ${YELLOW}Browsers skipped:${NC}  $FAILED_COUNT (not installed)"
    echo ""
else
    # Export single browser
    if ! export_browser "$browser_choice" false; then
        exit 1
    fi
fi

echo "Open the generated Markdown files to see the replication guides"
