#!/bin/bash
#
# sync.sh - Commit and push memory changes
#
# This script commits any changes to the memory files and pushes to remote.
# Since symlinks are used, files are already in place - we just need to commit.
#
# Usage: ./sync.sh [commit_message]
#

set -e  # Exit on any error

BACKUP_REPO="$HOME/ai-assistant-config"

cd "$BACKUP_REPO"

# Check if there are changes
if git diff --quiet && git diff --cached --quiet; then
    echo "No changes to sync."
    exit 0
fi

# Stage all changes
git add -A

# Use provided commit message or generate one
if [ -n "$1" ]; then
    COMMIT_MSG="$1"
else
    COMMIT_MSG="Memory sync $(date +%Y-%m-%d\ %H:%M)"
fi

# Commit and push
echo "Committing changes..."
git commit -m "$COMMIT_MSG"

echo "Pushing to remote..."
git push

echo "✅ Memory synced successfully!"
