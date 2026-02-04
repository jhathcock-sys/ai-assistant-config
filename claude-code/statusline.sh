#!/bin/bash
# =============================================================================
# Claude Code Status Line Script
# =============================================================================
# This script generates a custom status line for Claude Code, similar to how
# Powerlevel10k customizes your terminal prompt.
#
# How it works:
#   1. Claude Code passes JSON data about the current session via stdin
#   2. We parse that JSON using jq to extract useful information
#   3. We output a single line with ANSI color codes for styling
#   4. Claude Code displays this line at the bottom of the interface
#
# JSON Input includes: model info, workspace paths, cost tracking,
# context window usage, session details, and more.
# =============================================================================

# -----------------------------------------------------------------------------
# ANSI Color Codes
# -----------------------------------------------------------------------------
# These escape sequences tell the terminal to change text colors.
# Format: \e[<style>;<color>m  where:
#   - 0 = reset, 1 = bold
#   - 30-37 = foreground colors, 90-97 = bright foreground colors
#   - Colors: 30=black, 31=red, 32=green, 33=yellow, 34=blue, 35=magenta, 36=cyan, 37=white
# -----------------------------------------------------------------------------
RESET='\e[0m'           # Reset all formatting
BOLD='\e[1m'            # Bold text

# Color definitions (bright/vivid versions for better visibility)
ORANGE='\e[38;5;208m'   # 256-color mode: orange (model name)
CYAN='\e[96m'           # Bright cyan (directory)
GREEN='\e[92m'          # Bright green (git branch)
YELLOW='\e[93m'         # Bright yellow (context percentage)
MAGENTA='\e[95m'        # Bright magenta (cost)
DIM='\e[2m'             # Dimmed text (separators)

# -----------------------------------------------------------------------------
# Read JSON Input
# -----------------------------------------------------------------------------
# Claude Code sends session data as JSON through stdin. We read it once
# and store it in a variable to avoid multiple reads (stdin is a stream).
# -----------------------------------------------------------------------------
input=$(cat)

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
# Using jq to parse JSON. The -r flag outputs "raw" strings without quotes.
# The '//' operator provides a default value if the field is null/missing.
# -----------------------------------------------------------------------------

# Get the human-readable model name (e.g., "Opus", "Sonnet")
get_model_name() {
    echo "$input" | jq -r '.model.display_name // "Unknown"'
}

# Get the current working directory path
get_current_dir() {
    echo "$input" | jq -r '.workspace.current_dir // "~"'
}

# Get the context window usage percentage (pre-calculated by Claude Code)
# This tells you how much of the available context is being used
get_context_percent() {
    echo "$input" | jq -r '.context_window.used_percentage // 0'
}

# Get the session usage percentage (how much of the total session budget is used)
# This tracks the cumulative context across all messages in the session
get_session_percent() {
    # Try to get pre-calculated session percentage
    local session_pct=$(echo "$input" | jq -r '.session.used_percentage // empty')
    if [ -n "$session_pct" ]; then
        echo "$session_pct"
    else
        # Fallback: calculate from tokens if available
        local tokens_used=$(echo "$input" | jq -r '.session.tokens_used // 0')
        local tokens_limit=$(echo "$input" | jq -r '.session.tokens_limit // 0')
        if [ "$tokens_limit" -gt 0 ]; then
            echo "scale=2; ($tokens_used / $tokens_limit) * 100" | bc
        else
            echo "0"
        fi
    fi
}

# Get the total cost of the session in USD
get_cost() {
    echo "$input" | jq -r '.cost.total_cost_usd // 0'
}

# Get lines of code added during this session
get_lines_added() {
    echo "$input" | jq -r '.cost.total_lines_added // 0'
}

# Get lines of code removed during this session
get_lines_removed() {
    echo "$input" | jq -r '.cost.total_lines_removed // 0'
}

# -----------------------------------------------------------------------------
# Git Branch Detection
# -----------------------------------------------------------------------------
# Check if we're in a git repository and get the current branch name.
# This runs git commands directly rather than relying on the JSON input.
# -----------------------------------------------------------------------------
get_git_branch() {
    # First, check if we're inside a git repository
    # 'git rev-parse --git-dir' returns 0 if in a repo, non-zero otherwise
    # We redirect stdout/stderr to /dev/null to suppress output
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Get the current branch name
        # --show-current returns just the branch name (empty if detached HEAD)
        local branch=$(git branch --show-current 2>/dev/null)
        if [ -n "$branch" ]; then
            echo "$branch"
        else
            # Handle detached HEAD state (e.g., during rebase or checkout of a commit)
            echo "detached"
        fi
    fi
    # Returns empty string if not in a git repo
}

# -----------------------------------------------------------------------------
# Build the Status Line
# -----------------------------------------------------------------------------
# Assemble all the components into a single line with colors and icons.
# Icons used (requires a Nerd Font or emoji support):
#   📁 or  = directory
#   🌿 or  = git branch
#   📊 or  = context/stats
#   💰 or  = cost
# -----------------------------------------------------------------------------

# Extract all values
MODEL=$(get_model_name)
DIR=$(get_current_dir)
DIR_NAME="${DIR##*/}"           # Extract just the directory name (basename)
CONTEXT=$(get_context_percent)
SESSION=$(get_session_percent)
COST=$(get_cost)
GIT_BRANCH=$(get_git_branch)
LINES_ADD=$(get_lines_added)
LINES_DEL=$(get_lines_removed)

# Format percentages as integers (remove decimal places)
CONTEXT_INT=$(printf "%.0f" "$CONTEXT")
SESSION_INT=$(printf "%.0f" "$SESSION")

# Format cost to 4 decimal places for readability
COST_FMT=$(printf "%.4f" "$COST")

# Build the output string piece by piece
output=""

# Model name in orange (identifies which Claude model is active)
output+="${ORANGE}${BOLD}${MODEL}${RESET}"

# Separator
output+="${DIM} | ${RESET}"

# Current directory in cyan
output+="${CYAN}📁 ${DIR_NAME}${RESET}"

# Git branch (only show if in a repo)
if [ -n "$GIT_BRANCH" ]; then
    output+="${DIM} | ${RESET}"
    output+="${GREEN}🌿 ${GIT_BRANCH}${RESET}"
fi

# Context window usage in yellow (per-message context)
# This helps you know when you're approaching the context limit
output+="${DIM} | ${RESET}"
output+="${YELLOW}📊 Ctx:${CONTEXT_INT}%${RESET}"

# Session usage percentage in yellow (cumulative session budget)
# This shows how much of your total session you've used
output+="${DIM} | ${RESET}"
output+="${YELLOW}📈 Sess:${SESSION_INT}%${RESET}"

# Lines changed (only show if there are changes)
if [ "$LINES_ADD" != "0" ] || [ "$LINES_DEL" != "0" ]; then
    output+="${DIM} | ${RESET}"
    output+="${GREEN}+${LINES_ADD}${RESET}"
    output+="${DIM}/${RESET}"
    output+="${MAGENTA}-${LINES_DEL}${RESET}"
fi

# Cost in magenta (helps track API usage costs)
output+="${DIM} | ${RESET}"
output+="${MAGENTA}💰\$${COST_FMT}${RESET}"

# -----------------------------------------------------------------------------
# Output
# -----------------------------------------------------------------------------
# Print the final status line. The -e flag enables interpretation of
# escape sequences (needed for ANSI color codes).
# -----------------------------------------------------------------------------
echo -e "$output"
