# ChromaDB Shared Memory System

This directory contains the ingestion pipeline for Claude Code's shared memory system using ChromaDB as a semantic backend.

## Architecture

```
Workstation (Pop!_OS)                    Dell Stronghold (192.168.1.60)
┌─────────────────────┐                  ┌──────────────────────────┐
│ Claude Code CLI     │                  │ ChromaDB (:8000)         │
│   ↕ MCP (stdio)     │                  │   - infrastructure       │
│ chroma-mcp server   │──── HTTP ───────▶│   - decisions            │
│                     │   (token auth)   │   - documentation        │
│ Ingestion Script    │──── HTTP ───────▶│                          │
└─────────────────────┘                  │ OpenClaw ── internal ──▶ │
                                         └──────────────────────────┘
```

## Collections

| Collection | Purpose | Primary Sources |
|---|---|---|
| `infrastructure` | IPs, services, ports, Docker stacks, network topology | homelab-ops CLAUDE.md, Obsidian Infrastructure/*.md, docker-compose.yml |
| `decisions` | Architecture choices, security hardening, troubleshooting | Session MEMORY.md, Obsidian Security/*.md |
| `documentation` | Project docs, service pages, reference material | Project CLAUDE.md files, Obsidian Services/*.md |

## Setup

### 1. Install Dependencies

```bash
cd /home/cib/ai-assistant-config/scripts
python3 -m pip install -r requirements-chromadb.txt
```

Or use a virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-chromadb.txt
```

### 2. Configure Environment

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
chmod 600 .env
```

Edit `.env` and set:
- `CHROMADB_AUTH_TOKEN` (same token as in `~/Documents/.env` on Dell)
- Verify paths for `CLAUDE_CONFIG_DIR`, `OBSIDIAN_VAULT_DIR`, `HOMELAB_OPS_DIR`

### 3. Configure MCP Server (Phase 2)

Add the ChromaDB MCP server to Claude Code:

```bash
claude mcp add --transport stdio --scope user \
  homelab-memory -- uvx chroma-mcp \
  --client-type http --host 192.168.1.60 --port 8000 \
  --custom-auth-credentials "$CHROMADB_AUTH_TOKEN"
```

Verify it's connected:

```bash
claude mcp
```

You should see `homelab-memory` listed with 12 tools.

## Usage

### Initial Ingestion (Full)

Run the ingestion script to populate ChromaDB with all documentation:

```bash
./ingest-to-chromadb.py --full --verbose
```

This will:
1. Connect to ChromaDB at 192.168.1.60:8000
2. Create/verify collections (infrastructure, decisions, documentation)
3. Process all source files (CLAUDE.md, MEMORY.md, Obsidian vault)
4. Chunk by heading boundaries (~800 tokens per chunk)
5. Upsert to ChromaDB with metadata
6. Save state to `.ingest-state.json` for incremental updates

### Incremental Updates

After initial ingestion, run without `--full` to only process changed files:

```bash
./ingest-to-chromadb.py
```

The script tracks file modification times and skips unchanged files.

### Dry Run

Preview what would be ingested without writing to ChromaDB:

```bash
./ingest-to-chromadb.py --dry-run --verbose
```

### Recurring Ingestion (Optional)

Set up a daily cron job for automatic synchronization:

```bash
crontab -e
```

Add:

```cron
# ChromaDB ingestion - daily at 6 AM
0 6 * * * cd /home/cib/ai-assistant-config && python3 scripts/ingest-to-chromadb.py >> /tmp/chromadb-ingest.log 2>&1
```

## MCP Tools Available

Once the MCP server is configured, Claude Code has these tools:

| Tool | Purpose |
|---|---|
| `chroma_query_documents` | Semantic search across collections |
| `chroma_add_documents` | Persist new knowledge during conversations |
| `chroma_update_documents` | Update existing documents |
| `chroma_delete_documents` | Remove documents |
| `chroma_list_collections` | Discover available knowledge domains |
| `chroma_get_collection` | Get collection details and count |
| `chroma_create_collection` | Create new collections |
| `chroma_delete_collection` | Remove collections |
| ... and 4 more |

### Example Queries

**Infrastructure lookup:**
```
User: "What IP is Wazuh on?"
Claude: *uses chroma_query_documents(collection="infrastructure", query="Wazuh IP address")*
```

**Security decision recall:**
```
User: "Why did we choose token auth for ChromaDB?"
Claude: *uses chroma_query_documents(collection="decisions", query="ChromaDB authentication")*
```

**Service documentation:**
```
User: "How do I restart the n8n container?"
Claude: *uses chroma_query_documents(collection="documentation", query="n8n container restart")*
```

## Metadata Schema

Each document chunk includes:

| Field | Description | Example |
|---|---|---|
| `source_file` | Absolute path to source file | `/home/cib/ai-assistant-config/session/MEMORY.md` |
| `source_type` | Type of source | `claude-md`, `obsidian`, `docker-config` |
| `collection` | Target collection | `infrastructure`, `decisions`, `documentation` |
| `domain` | Subject domain | `networking`, `security`, `media` |
| `last_modified` | ISO timestamp of last file modification | `2026-02-09T14:30:00` |
| `chunk_index` | Position of chunk within file | `0`, `1`, `2`, ... |
| `total_chunks` | Total chunks in file | `5` |
| `heading` | Markdown heading for chunk | `## Network Topology` |

## Troubleshooting

### Connection Refused

```
Error: Failed to connect to ChromaDB at 192.168.1.60:8000
```

**Solution:** Ensure Dell Stronghold is running and ChromaDB container is up:

```bash
ssh stronghold
docker ps | grep chromadb
curl -H "Authorization: Bearer $TOKEN" http://192.168.1.60:8000/api/v1/heartbeat
```

### Authentication Failed

```
Error: 401 Unauthorized
```

**Solution:** Verify `CHROMADB_AUTH_TOKEN` matches between:
- Workstation: `/home/cib/ai-assistant-config/scripts/.env`
- Dell: `~/stronghold/.env`

### MCP Server Not Connected

```
claude mcp
# homelab-memory shows "disconnected"
```

**Solution:** Check MCP server configuration:

```bash
# Verify uvx can find chroma-mcp
uvx chroma-mcp --help

# Test connection manually
uvx chroma-mcp --client-type http --host 192.168.1.60 --port 8000 \
  --custom-auth-credentials "$CHROMADB_AUTH_TOKEN"
```

### No Results from Queries

```
User: "What IP is Wazuh on?"
Claude: "I don't have information about Wazuh IPs."
```

**Solution:** Verify data was ingested:

```bash
# Check collection counts
./ingest-to-chromadb.py --verbose
```

Or use Python:

```python
import chromadb
client = chromadb.HttpClient(
    host="192.168.1.60",
    port=8000,
    headers={"Authorization": f"Bearer {token}"}
)
infra = client.get_collection("infrastructure")
print(f"Infrastructure docs: {infra.count()}")
```

## Files

| File | Purpose |
|---|---|
| `ingest-to-chromadb.py` | Main ingestion pipeline script |
| `requirements-chromadb.txt` | Python dependencies |
| `.env.example` | Template for environment variables |
| `.env` | Actual environment variables (gitignored) |
| `.ingest-state.json` | State tracker for incremental updates (auto-generated) |
| `README-chromadb.md` | This file |

## Security Notes

- **ChromaDB port 8000 bound to Dell IP only** (192.168.1.60:8000, not 0.0.0.0)
- **Token authentication required** for all HTTP requests
- **UFW firewall restricts access** to homelab network (192.168.1.0/24)
- **`.env` file is gitignored** and should have `chmod 600` permissions
- **Defense in depth:** Network restriction + token auth + UFW

## Next Steps (Phase 6)

After verifying ChromaDB works correctly, slim down CLAUDE.md files:

### Session MEMORY.md (5.9KB → ~2KB)
- **Keep:** Project Quick Reference table, Workflow Reminders
- **Move to ChromaDB:** Infrastructure Notes, Common Mistakes, Recent Changes

### homelab-ops CLAUDE.md (14.6KB → ~4KB)
- **Keep:** repository_structure, deployment commands, conventions, topology table
- **Move to ChromaDB:** security_hardening, resource_management, services detail, monitoring

**IMPORTANT:** Only proceed with Phase 6 after Phase 5 verification passes!

## Resources

- [ChromaDB Documentation](https://docs.trychroma.com/)
- [chroma-mcp GitHub](https://github.com/chroma-core/chroma-mcp)
- [Claude Code MCP Docs](https://docs.anthropic.com/claude/docs/mcp)
- [Sentient Stronghold Plan](../../Documents/Sentient_Stronghold_Empire_Plan.md)
