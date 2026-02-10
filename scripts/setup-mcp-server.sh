#!/bin/bash
# ChromaDB MCP Server Setup Script (Phase 2)
# Configures the chroma-mcp server for Claude Code
#
# Usage: ./setup-mcp-server.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "ChromaDB MCP Server Setup (Phase 2)"
echo "============================================"
echo ""

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${YELLOW}⚠ Missing .env file${NC}"
    echo ""
    echo "Creating .env from template..."
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        chmod 600 "$SCRIPT_DIR/.env"
        echo ""
        echo -e "${YELLOW}Please edit $SCRIPT_DIR/.env and fill in:${NC}"
        echo "  - CHROMADB_AUTH_TOKEN (same as in ~/Documents/.env on Dell)"
        echo ""
        echo "Then run this script again."
        exit 1
    else
        echo "ERROR: .env.example not found!"
        exit 1
    fi
fi

source "$SCRIPT_DIR/.env"

if [ -z "$CHROMADB_AUTH_TOKEN" ]; then
    echo -e "${YELLOW}⚠ CHROMADB_AUTH_TOKEN not set in .env${NC}"
    echo ""
    echo "Edit $SCRIPT_DIR/.env and set CHROMADB_AUTH_TOKEN"
    echo "(It should match the token in ~/Documents/.env on Dell Stronghold)"
    exit 1
fi

CHROMADB_HOST="${CHROMADB_HOST:-192.168.1.60}"
CHROMADB_PORT="${CHROMADB_PORT:-8000}"

echo "Configuration:"
echo "  Host: ${CHROMADB_HOST}"
echo "  Port: ${CHROMADB_PORT}"
echo "  Token: ${CHROMADB_AUTH_TOKEN:0:8}... (hidden)"
echo ""

# Check if MCP server already exists
if claude mcp list 2>&1 | grep -q "homelab-memory"; then
    echo -e "${YELLOW}⚠ MCP server 'homelab-memory' already configured${NC}"
    echo ""
    read -p "Remove and reconfigure? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing server..."
        claude mcp remove homelab-memory
    else
        echo "Skipping. Use 'claude mcp remove homelab-memory' to remove manually."
        exit 0
    fi
fi

echo "Adding MCP server 'homelab-memory'..."
echo ""

# Add the MCP server
claude mcp add --transport stdio --scope user \
  homelab-memory -- uvx chroma-mcp \
  --client-type http --host "$CHROMADB_HOST" --port "$CHROMADB_PORT" \
  --custom-auth-credentials "$CHROMADB_AUTH_TOKEN"

echo ""
echo -e "${GREEN}✓ MCP server 'homelab-memory' configured${NC}"
echo ""

# Verify
echo "Verifying configuration..."
claude mcp get homelab-memory

echo ""
echo "============================================"
echo "Setup Complete!"
echo "============================================"
echo ""
echo "The MCP server is now configured. To verify it works:"
echo ""
echo "  1. Start a Claude Code session"
echo "  2. Check tools with: /mcp"
echo "  3. Test a query: \"What IP is ChromaDB running on?\""
echo ""
echo "Next steps:"
echo "  1. Deploy Dell Stronghold (docker compose up -d)"
echo "  2. Run ingestion: ./ingest-to-chromadb.py --full"
echo "  3. Run verification: ./verify-chromadb.sh"
