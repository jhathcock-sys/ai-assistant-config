# ChromaDB Shared Memory - Quick Start Guide

**Goal:** Get ChromaDB shared memory working in 20 minutes.

---

## Prerequisites Checklist

- [ ] Dell Stronghold deployed with Docker (192.168.1.60)
- [ ] Can ping Dell from workstation: `ping 192.168.1.60`
- [ ] Python 3.8+ on workstation: `python3 --version`
- [ ] uvx available (comes with Claude Code): `uvx --version`

---

## Step 1: Deploy ChromaDB on Dell (10 minutes)

### 1.1 Generate Auth Token

On your workstation:
```bash
openssl rand -hex 32
# Save this token - you'll need it in multiple places
```

### 1.2 Update Docker Configuration

On Dell Stronghold:
```bash
cd ~/stronghold

# If .env doesn't exist, create it from template
cp .env.template .env
chmod 600 .env

# Edit .env and add the token you generated
nano .env
# Add: CHROMADB_AUTH_TOKEN=your_token_here
```

### 1.3 Copy Updated docker-compose.yml

From workstation:
```bash
scp ~/Documents/docker-compose.yml stronghold:~/stronghold/
```

### 1.4 Start Services

On Dell:
```bash
cd ~/stronghold
docker compose up -d
docker ps | grep chromadb  # Verify it's running
```

### 1.5 Configure UFW

On Dell:
```bash
sudo ufw allow from 192.168.1.0/24 to any port 8000 comment "ChromaDB"
sudo ufw reload
```

### 1.6 Test Connection

From workstation:
```bash
export CHROMADB_AUTH_TOKEN="your_token_here"
curl -H "Authorization: Bearer $CHROMADB_AUTH_TOKEN" \
  http://192.168.1.60:8000/api/v1/heartbeat

# Expected: {"nanosecond heartbeat": ...}
```

✅ **Phase 1 Complete!**

---

## Step 2: Configure MCP Server (5 minutes)

### 2.1 Create Environment File

```bash
cd /home/cib/ai-assistant-config/scripts
cp .env.example .env
chmod 600 .env

# Edit and set CHROMADB_AUTH_TOKEN (same token from Step 1.1)
nano .env
```

### 2.2 Run Setup Script

```bash
./setup-mcp-server.sh
```

### 2.3 Verify MCP Server

```bash
claude mcp list
# Should show: homelab-memory (user scope)

claude mcp get homelab-memory
# Shows full configuration
```

✅ **Phase 2 Complete!**

---

## Step 3: Ingest Documentation (5 minutes)

### 3.1 Install Python Dependencies

```bash
cd /home/cib/ai-assistant-config/scripts
pip install --user -r requirements-chromadb.txt
```

Or use a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-chromadb.txt
```

### 3.2 Run Initial Ingestion

```bash
./ingest-to-chromadb.py --full --verbose
```

Expected output:
```
2026-02-09 21:50:00 [INFO] Connecting to ChromaDB at 192.168.1.60:8000...
2026-02-09 21:50:00 [INFO] Connected to ChromaDB at 192.168.1.60:8000
2026-02-09 21:50:01 [INFO] Collection 'infrastructure' ready (count: 0)
2026-02-09 21:50:01 [INFO] Collection 'decisions' ready (count: 0)
2026-02-09 21:50:01 [INFO] Collection 'documentation' ready (count: 0)
2026-02-09 21:50:01 [INFO] Found X source configurations
2026-02-09 21:50:02 [INFO] Processed MEMORY.md: 5 chunks
2026-02-09 21:50:02 [INFO] Processed CLAUDE.md: 8 chunks
...
2026-02-09 21:50:05 [INFO] ✓ Ingestion complete: 150 added, 0 updated
```

✅ **Phase 3 Complete!**

---

## Step 4: Verify Everything Works (5 minutes)

### 4.1 Run Verification Tests

```bash
./verify-chromadb.sh
```

All tests should pass:
- ✓ Test 1: Connectivity
- ✓ Test 2: MCP server configured
- ✓ Test 3: Collections exist
- ✓ Test 4: Semantic search works
- ✓ Test 5: Ingestion script ready

### 4.2 Test in Claude Code Session

Start a Claude Code session:
```bash
claude
```

In the session, try these queries:

**Test 1 - Infrastructure query:**
```
User: What IP is ChromaDB running on?
```
Claude should return: 192.168.1.60:8000 (from infrastructure collection)

**Test 2 - Decision recall:**
```
User: Why are we using ChromaDB for shared memory?
```
Claude should recall the reasoning from documentation

**Test 3 - MCP tools:**
```
User: /mcp
```
Should show `homelab-memory` connected with 12 tools

✅ **Phase 5 Complete!**

---

## You're Done! 🎉

ChromaDB shared memory is now operational.

### What You Can Do Now

1. **Ask infrastructure questions:**
   - "What services are running on Dell Stronghold?"
   - "Show me the network topology"
   - "What ports are exposed?"

2. **Recall decisions:**
   - "Why did we choose token auth for ChromaDB?"
   - "What security hardening did we implement?"

3. **Find documentation:**
   - "How do I restart the n8n container?"
   - "Show me the Docker Compose configuration"

### Optional: Proceed to Phase 6

If everything works, you can now slim down CLAUDE.md files:

**⚠️ IMPORTANT:** Backup first!
```bash
cp ~/.claude/session/MEMORY.md ~/.claude/session/MEMORY.md.bak
cp ~/homelab-ops/CLAUDE.md ~/homelab-ops/CLAUDE.md.bak

cd /home/cib/ai-assistant-config
git add -A
git commit -m "backup: CLAUDE.md files before ChromaDB migration"
```

Then proceed with Phase 6 in the deployment checklist.

---

## Troubleshooting

### Connection Refused
```bash
# Verify Dell is reachable
ping 192.168.1.60

# Check ChromaDB is running
ssh stronghold 'docker ps | grep chromadb'

# Check UFW
ssh stronghold 'sudo ufw status | grep 8000'
```

### Authentication Failed
```bash
# Verify tokens match
grep CHROMADB_AUTH_TOKEN /home/cib/ai-assistant-config/scripts/.env
ssh stronghold 'grep CHROMADB_AUTH_TOKEN ~/stronghold/.env'
```

### MCP Server Disconnected
```bash
# Check MCP configuration
claude mcp get homelab-memory

# Remove and re-add
claude mcp remove homelab-memory
cd /home/cib/ai-assistant-config/scripts
./setup-mcp-server.sh
```

### No Search Results
```bash
# Check collection counts
./verify-chromadb.sh

# Re-run ingestion
./ingest-to-chromadb.py --full --verbose
```

---

## Resources

- **Full Docs:** [README-chromadb.md](./README-chromadb.md)
- **Detailed Guide:** [DEPLOYMENT-CHECKLIST.md](./DEPLOYMENT-CHECKLIST.md)
- **Implementation Summary:** [../Documents/ChromaDB-Implementation-Summary.md](../../Documents/ChromaDB-Implementation-Summary.md)
- **Stronghold Plan:** [../Documents/Sentient_Stronghold_Empire_Plan.md](../../Documents/Sentient_Stronghold_Empire_Plan.md)

---

**Total Time:** ~20 minutes
**Complexity:** Low
**Reversible:** Yes (full rollback plan available)
**Status:** ✅ Ready to Deploy
