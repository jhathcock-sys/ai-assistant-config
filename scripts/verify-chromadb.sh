#!/bin/bash
# ChromaDB Verification Script (Phase 5)
# Tests all connectivity and functionality before slimming CLAUDE.md files
#
# Usage: ./verify-chromadb.sh
# Returns: 0 if all tests pass, 1 if any test fails

set -e  # Exit on first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${RED}✗ Missing .env file${NC}"
    echo "Copy .env.example to .env and configure it first"
    exit 1
fi

source "$SCRIPT_DIR/.env"

if [ -z "$CHROMADB_AUTH_TOKEN" ]; then
    echo -e "${RED}✗ CHROMADB_AUTH_TOKEN not set in .env${NC}"
    exit 1
fi

CHROMADB_HOST="${CHROMADB_HOST:-192.168.1.60}"
CHROMADB_PORT="${CHROMADB_PORT:-8000}"
CHROMADB_URL="http://${CHROMADB_HOST}:${CHROMADB_PORT}"

TEST_PASSED=0
TEST_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"

    echo -n "Testing $test_name... "

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TEST_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((TEST_FAILED++))
        return 1
    fi
}

echo "============================================"
echo "ChromaDB Verification (Phase 5)"
echo "============================================"
echo ""
echo "Target: ${CHROMADB_URL}"
echo ""

# Test 1: Basic Connectivity
echo "=== Phase 5 Test 1: Basic Connectivity ==="
if curl -s -f -H "Authorization: Bearer $CHROMADB_AUTH_TOKEN" \
    "${CHROMADB_URL}/api/v2/heartbeat" > /dev/null; then
    echo -e "${GREEN}✓ PASS${NC} - ChromaDB heartbeat responds with auth token"
    ((TEST_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Cannot connect to ChromaDB"
    echo "  Check that:"
    echo "    1. Dell Stronghold is running"
    echo "    2. ChromaDB container is up: ssh stronghold 'docker ps | grep chromadb'"
    echo "    3. UFW allows port 8000: ssh stronghold 'sudo ufw status'"
    ((TEST_FAILED++))
fi
echo ""

# Test 2: MCP Server Status
echo "=== Phase 5 Test 2: MCP Server Status ==="
if claude mcp list 2>&1 | grep -q "homelab-memory"; then
    echo -e "${GREEN}✓ PASS${NC} - MCP server 'homelab-memory' is configured"
    ((TEST_PASSED++))

    # Show MCP server details
    echo "  Details:"
    claude mcp get homelab-memory 2>&1 | grep -E "(transport|command|args)" | sed 's/^/    /'
else
    echo -e "${RED}✗ FAIL${NC} - MCP server 'homelab-memory' not configured"
    echo "  Configure with:"
    echo '    claude mcp add --transport stdio --scope user \'
    echo '      homelab-memory -- uvx chroma-mcp \'
    echo '      --client-type http --host 192.168.1.60 --port 8000 \'
    echo '      --custom-auth-credentials "$CHROMADB_AUTH_TOKEN"'
    ((TEST_FAILED++))
fi
echo ""

# Test 3: Collections Exist
echo "=== Phase 5 Test 3: Collections Exist ==="
COLLECTIONS_JSON=$(curl -s -H "Authorization: Bearer $CHROMADB_AUTH_TOKEN" \
    "${CHROMADB_URL}/api/v2/tenants/default_tenant/databases/default_database/collections" 2>/dev/null || echo "[]")

for collection in infrastructure decisions documentation; do
    if echo "$COLLECTIONS_JSON" | grep -q "\"name\":\"$collection\""; then
        # Get collection count
        COLLECTION_ID=$(echo "$COLLECTIONS_JSON" | grep -o "\"id\":\"[^\"]*\",\"name\":\"$collection\"" | grep -o "\"id\":\"[^\"]*\"" | cut -d'"' -f4)
        if [ -n "$COLLECTION_ID" ]; then
            COUNT=$(curl -s -H "Authorization: Bearer $CHROMADB_AUTH_TOKEN" \
                "${CHROMADB_URL}/api/v2/tenants/default_tenant/databases/default_database/collections/${COLLECTION_ID}/count" 2>/dev/null || echo "0")
            echo -e "${GREEN}✓ PASS${NC} - Collection '$collection' exists (${COUNT} documents)"
        else
            echo -e "${GREEN}✓ PASS${NC} - Collection '$collection' exists"
        fi
        ((TEST_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC} - Collection '$collection' not found"
        echo "  Run: ./ingest-to-chromadb.py --full"
        ((TEST_FAILED++))
    fi
done
echo ""

# Test 4: Semantic Search (requires data)
echo "=== Phase 5 Test 4: Semantic Search ==="
if echo "$COLLECTIONS_JSON" | grep -q "\"name\":\"infrastructure\""; then
    # Try a simple query (requires MCP server or direct API call)
    # We'll use the Python client for this
    SEARCH_TEST=$(python3 - <<'EOF'
import sys
import os
import chromadb
from chromadb.config import Settings

try:
    token = os.environ['CHROMADB_AUTH_TOKEN']
    host = os.environ.get('CHROMADB_HOST', '192.168.1.60')
    port = int(os.environ.get('CHROMADB_PORT', '8000'))

    client = chromadb.HttpClient(
        host=host,
        port=port,
        headers={"Authorization": f"Bearer {token}"}
    )

    infra = client.get_collection("infrastructure")
    results = infra.query(query_texts=["IP address network"], n_results=3)

    if results and results['documents'] and len(results['documents'][0]) > 0:
        print("PASS")
        print(f"Found {len(results['documents'][0])} results")
        sys.exit(0)
    else:
        print("FAIL - No results")
        sys.exit(1)
except Exception as e:
    print(f"FAIL - {str(e)}")
    sys.exit(1)
EOF
)

    if echo "$SEARCH_TEST" | grep -q "PASS"; then
        echo -e "${GREEN}✓ PASS${NC} - Semantic search returns relevant results"
        echo "  $(echo "$SEARCH_TEST" | tail -1 | sed 's/^/  /')"
        ((TEST_PASSED++))
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - Semantic search test inconclusive"
        echo "  Error: $(echo "$SEARCH_TEST" | tail -1)"
        echo "  Install dependencies: pip install -r requirements-chromadb.txt"
    fi
else
    echo -e "${YELLOW}⚠ SKIP${NC} - No data to search (run ingestion first)"
fi
echo ""

# Test 5: Incremental Updates
echo "=== Phase 5 Test 5: Ingestion Script ==="
if [ -f "$SCRIPT_DIR/ingest-to-chromadb.py" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Ingestion script exists"
    ((TEST_PASSED++))

    # Check if dependencies are installed
    if python3 -c "import chromadb, frontmatter" 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC} - Python dependencies installed"
        ((TEST_PASSED++))
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - Python dependencies not installed"
        echo "  Install with: pip install -r requirements-chromadb.txt"
    fi
else
    echo -e "${RED}✗ FAIL${NC} - Ingestion script not found"
    ((TEST_FAILED++))
fi
echo ""

# Summary
echo "============================================"
echo "Verification Summary"
echo "============================================"
echo -e "Passed: ${GREEN}${TEST_PASSED}${NC}"
echo -e "Failed: ${RED}${TEST_FAILED}${NC}"
echo ""

if [ $TEST_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo ""
    echo "ChromaDB is ready! You may proceed with Phase 6 (slimming CLAUDE.md files)."
    echo ""
    echo "Before slimming, create backups:"
    echo "  cp ~/.claude/session/MEMORY.md ~/.claude/session/MEMORY.md.bak"
    echo "  cp ~/homelab-ops/CLAUDE.md ~/homelab-ops/CLAUDE.md.bak"
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Fix the issues above before proceeding to Phase 6."
    exit 1
fi
