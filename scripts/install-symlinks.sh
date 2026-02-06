#!/bin/bash
#
# install-symlinks.sh - Set up symlink-based memory workflow
#
# This script creates symlinks from active Claude Code memory locations
# to files in the ai-assistant-config backup repository, making the backup
# repo the single source of truth.
#
# Usage: ./install-symlinks.sh
#

set -e  # Exit on any error

BACKUP_REPO="$HOME/ai-assistant-config"
CLAUDE_DIR="$HOME/.claude"
SESSION_MEMORY_DIR="$CLAUDE_DIR/projects/-home-cib--claude/memory"

echo "=== Claude Code Memory Symlink Installer ==="
echo ""
echo "This will link active memory files to the backup repository."
echo "The backup repo will become the single source of truth."
echo ""

# Create session memory directory if it doesn't exist
if [ ! -d "$SESSION_MEMORY_DIR" ]; then
    echo "Creating session memory directory..."
    mkdir -p "$SESSION_MEMORY_DIR"
fi

# Backup existing files
echo "Backing up existing files..."
[ -f "$CLAUDE_DIR/CLAUDE.md" ] && {
    echo "  - Backing up $CLAUDE_DIR/CLAUDE.md"
    mv "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
}

[ -f "$SESSION_MEMORY_DIR/MEMORY.md" ] && {
    echo "  - Backing up $SESSION_MEMORY_DIR/MEMORY.md"
    mv "$SESSION_MEMORY_DIR/MEMORY.md" "$SESSION_MEMORY_DIR/MEMORY.md.bak"
}

# Create symlinks
echo ""
echo "Creating symlinks..."

echo "  - Linking global CLAUDE.md"
ln -sf "$BACKUP_REPO/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

echo "  - Linking session MEMORY.md"
ln -sf "$BACKUP_REPO/session/MEMORY.md" "$SESSION_MEMORY_DIR/MEMORY.md"

# Verify symlinks
echo ""
echo "Verifying symlinks..."
ls -lh "$CLAUDE_DIR/CLAUDE.md"
ls -lh "$SESSION_MEMORY_DIR/MEMORY.md"

echo ""
echo "✅ Symlinks created successfully!"
echo ""
echo "The backup repo is now the source of truth for memory files."
echo "Use ./sync.sh to commit and push changes."
