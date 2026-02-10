#!/bin/bash
# Install dependencies for ChromaDB deployment
# Run with: sudo bash install-dependencies.sh

set -e

echo "=== Installing Python pip and venv ==="
apt update
apt install -y python3-pip python3-venv

echo ""
echo "=== Installing uv (for MCP server) ==="
# Install uv for the current user (not as root)
if [ -n "$SUDO_USER" ]; then
    # Running via sudo, install for the actual user
    su - $SUDO_USER -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
else
    # Not running via sudo
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo ""
echo "=== Verifying installations ==="
su - $SUDO_USER -c 'python3 --version'
su - $SUDO_USER -c 'pip3 --version'
su - $SUDO_USER -c 'source ~/.local/bin/env && uvx --version' || echo "⚠ uv installed, but shell needs to be restarted"

echo ""
echo "✅ Dependencies installed!"
echo ""
echo "Please run: source ~/.local/bin/env"
echo "Or restart your shell, then continue with deployment."
