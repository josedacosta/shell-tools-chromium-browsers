#!/bin/bash
# =============================================================================
# Chromium-based Browser Traces Finder
# =============================================================================
#
# PLATFORM:     macOS only (uses macOS-specific paths and commands)
# SHELL:        Bash (tested with GNU bash 3.2+)
#
# DESCRIPTION:
#   Scans the entire macOS filesystem to find all remaining files and folders
#   associated with a specific Chromium-based browser. Useful for verifying
#   a complete uninstall or diagnosing issues with residual files.
#
# SUPPORTED BROWSERS:
#   Google Chrome, Chromium, Brave, Microsoft Edge, Opera, Vivaldi, Arc
#
# USAGE:
#   bash find-traces.sh    # Interactive browser selection
#
# OUTPUT:
#   - Displays results in the terminal with color highlighting
#   - Exports a plain text report (.txt) for easy sharing with LLMs
#
# NOTE:
#   This script prioritizes functionality over code elegance. It may be long,
#   repetitive, and not fully optimized. Code refactoring is planned for a
#   future version.
#
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# =============================================================================
# BROWSER SELECTION
# =============================================================================
clear
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║              CHROMIUM-BASED BROWSER TRACES FINDER                        ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Select a browser to search for:${NC}"
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

# Set browser-specific variables based on selection
# CRITICAL: Each browser has UNIQUE patterns to avoid cross-contamination
case "$browser_choice" in
    1)
        BROWSER_NAME="Google Chrome"
        # Patterns specifically for Google Chrome (NOT generic "chrome" which could match other browsers)
        PATTERNS=(
            "*google*chrome*"
            "*chrome*google*"
            "*com.google.Chrome*"
            "*Google Chrome*"
        )
        ;;
    2)
        BROWSER_NAME="Chromium"
        # Patterns specifically for Chromium (using org.chromium identifier)
        PATTERNS=(
            "*org.chromium*"
            "*Chromium*"
        )
        ;;
    3)
        BROWSER_NAME="Brave"
        # Patterns specifically for Brave
        PATTERNS=(
            "*com.brave*"
            "*BraveSoftware*"
            "*Brave Browser*"
            "*Brave-Browser*"
        )
        ;;
    4)
        BROWSER_NAME="Microsoft Edge"
        # Patterns specifically for Microsoft Edge
        PATTERNS=(
            "*com.microsoft.edge*"
            "*Microsoft Edge*"
            "*microsoft-edge*"
        )
        ;;
    5)
        BROWSER_NAME="Opera"
        # Patterns specifically for Opera
        PATTERNS=(
            "*com.operasoftware*"
            "*Opera*"
        )
        ;;
    6)
        BROWSER_NAME="Vivaldi"
        # Patterns specifically for Vivaldi
        PATTERNS=(
            "*com.vivaldi*"
            "*Vivaldi*"
        )
        ;;
    7)
        BROWSER_NAME="Arc"
        # Patterns specifically for Arc
        PATTERNS=(
            "*company.thebrowser*"
            "*Arc*"
        )
        ;;
    8)
        BROWSER_NAME="All Chromium-based browsers"
        # All patterns combined
        PATTERNS=(
            # Google Chrome
            "*google*chrome*"
            "*chrome*google*"
            "*com.google.Chrome*"
            "*Google Chrome*"
            # Chromium
            "*org.chromium*"
            "*Chromium*"
            # Brave
            "*com.brave*"
            "*BraveSoftware*"
            "*Brave Browser*"
            "*Brave-Browser*"
            # Microsoft Edge
            "*com.microsoft.edge*"
            "*Microsoft Edge*"
            "*microsoft-edge*"
            # Opera
            "*com.operasoftware*"
            "*Opera*"
            # Vivaldi
            "*com.vivaldi*"
            "*Vivaldi*"
            # Arc
            "*company.thebrowser*"
            "*Arc*"
        )
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Invalid choice. Please run the script again and select 1-8."
        exit 1
        ;;
esac

echo -e "${GREEN}[OK]${NC} Selected: $BROWSER_NAME"
echo ""

# =============================================================================
# OUTPUT FILE SETUP
# =============================================================================

# Create output directory and file (save in current working directory)
OUTPUT_DIR="$(pwd)"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BROWSER_SLUG=$(echo "$BROWSER_NAME" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
OUTPUT_FILE="$OUTPUT_DIR/browser_traces_${BROWSER_SLUG}_${TIMESTAMP}.txt"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Directories to search
SEARCH_DIRS=(
    "/"
)

# Directories to exclude from search
EXCLUDE_DIRS=(
    "$HOME/Projects"
    "$HOME/.Trash"
)

# =============================================================================
# HEADER
# =============================================================================
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║                         BROWSER TRACES FINDER                            ║${NC}"
echo -e "${CYAN}${BOLD}║            Searching for: ${BROWSER_NAME}$(printf '%*s' $((47 - ${#BROWSER_NAME})) '')║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# DISPLAY CONFIGURATION
# =============================================================================
echo -e "${BOLD}Configuration:${NC}"
echo ""
echo -e "  ${GREEN}${BOLD}Search locations:${NC}"
for dir in "${SEARCH_DIRS[@]}"; do
    if [[ "$dir" == "/" ]]; then
        echo -e "    ${GREEN}✓${NC} ${BOLD}/${NC} ${DIM}(entire system)${NC}"
    else
        echo -e "    ${GREEN}✓${NC} $dir"
    fi
done
echo ""
echo -e "  ${RED}${BOLD}Excluded locations:${NC}"
for dir in "${EXCLUDE_DIRS[@]}"; do
    echo -e "    ${RED}✗${NC} $dir"
done
echo ""
echo -e "  ${MAGENTA}${BOLD}Search patterns:${NC}"
for pattern in "${PATTERNS[@]}"; do
    echo -e "    ${MAGENTA}?${NC} $pattern"
done
echo ""

# =============================================================================
# BUILD EXCLUDE ARGUMENTS FOR FIND COMMAND
# =============================================================================
EXCLUDE_ARGS=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS -path \"$dir\" -prune -o"
    EXCLUDE_ARGS="$EXCLUDE_ARGS -path \"/System/Volumes/Data$dir\" -prune -o"
done

# Build pattern arguments
PATTERN_ARGS=""
for i in "${!PATTERNS[@]}"; do
    if [[ $i -eq 0 ]]; then
        PATTERN_ARGS="-iname \"${PATTERNS[$i]}\""
    else
        PATTERN_ARGS="$PATTERN_ARGS -o -iname \"${PATTERNS[$i]}\""
    fi
done

# =============================================================================
# RUN SEARCH
# =============================================================================
echo -e "${YELLOW}${BOLD}Starting search...${NC}"
echo -e "${DIM}This may take several minutes depending on your disk size.${NC}"
echo ""

START=$(date +%s)

# Create temporary file for results
RESULTS_FILE=$(mktemp)

for search_dir in "${SEARCH_DIRS[@]}"; do
    eval "find \"$search_dir\" $EXCLUDE_ARGS \\( $PATTERN_ARGS \\) -print 2>/dev/null"
done | sort -u > "$RESULTS_FILE"

END=$(date +%s)
DURATION=$((END - START))

# =============================================================================
# DISPLAY RESULTS
# =============================================================================
RESULT_COUNT=$(wc -l < "$RESULTS_FILE" | tr -d ' ')
SCAN_DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Results:${NC}"
echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# =============================================================================
# WRITE TO OUTPUT FILE (plain text for LLM consumption)
# =============================================================================
{
    echo "==============================================================================="
    echo "BROWSER TRACES FINDER - SCAN REPORT"
    echo "==============================================================================="
    echo ""
    echo "Browser:        $BROWSER_NAME"
    echo "Scan date:      $SCAN_DATE"
    echo "Scan duration:  ${DURATION}s"
    echo "Files found:    $RESULT_COUNT"
    echo ""
    echo "Search patterns used:"
    for pattern in "${PATTERNS[@]}"; do
        echo "  - $pattern"
    done
    echo ""
    echo "Excluded directories:"
    for dir in "${EXCLUDE_DIRS[@]}"; do
        echo "  - $dir"
    done
    echo ""
    echo "==============================================================================="
    echo "RESULTS"
    echo "==============================================================================="
    echo ""
    if [[ $RESULT_COUNT -eq 0 ]]; then
        echo "No $BROWSER_NAME traces found. The system is clean."
    else
        echo "Found $RESULT_COUNT file(s)/folder(s) related to $BROWSER_NAME:"
        echo ""
        while IFS= read -r line; do
            if [[ "$line" != /System/Volumes/Data/* ]]; then
                echo "$line"
            fi
        done < "$RESULTS_FILE"
    fi
    echo ""
    echo "==============================================================================="
    echo "END OF REPORT"
    echo "==============================================================================="
} > "$OUTPUT_FILE"

# =============================================================================
# DISPLAY TO SCREEN
# =============================================================================
if [[ $RESULT_COUNT -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}  ✓ No $BROWSER_NAME traces found!${NC}"
    echo -e "${GREEN}    Your system is clean.${NC}"
else
    echo -e "${YELLOW}${BOLD}  ⚠ Found $RESULT_COUNT file(s)/folder(s) related to $BROWSER_NAME:${NC}"
    echo ""

    while IFS= read -r line; do
        # Skip /System/Volumes/Data duplicates for cleaner output
        if [[ "$line" != /System/Volumes/Data/* ]]; then
            echo -e "    ${RED}→${NC} $line"
        fi
    done < "$RESULTS_FILE"
fi

echo ""
echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Summary:${NC}"
echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Browser:${NC}        $BROWSER_NAME"
echo -e "  ${BOLD}Files found:${NC}    $RESULT_COUNT"
echo -e "  ${BOLD}Scan duration:${NC}  ${DURATION}s"
echo -e "  ${BOLD}Scan completed:${NC} $SCAN_DATE"
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  📄 Report saved to:${NC}"
echo -e "${GREEN}     $OUTPUT_FILE${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Cleanup
rm -f "$RESULTS_FILE"
