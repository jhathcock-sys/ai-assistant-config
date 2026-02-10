# ChromaDB Shared Memory - Deployment Checklist

This checklist walks through deploying the ChromaDB shared memory system from scratch.

## Prerequisites

- [ ] Dell Stronghold ready with Ubuntu Server 24.04
- [ ] Docker and Docker Compose installed on Dell
- [ ] Static IP configured: 192.168.1.60
- [ ] Workstation can reach Dell on network (ping 192.168.1.60)

---

## Phase 1: Expose ChromaDB with Authentication ✅

**Status:** Configuration files updated, ready to deploy

### Files Modified
- [x] `/home/cib/Documents/docker-compose.yml` - Added ports, auth, removed read_only
- [x] `/home/cib/Documents/.env.template` - Added CHROMADB_AUTH_TOKEN
- [x] `/home/cib/Documents/Sentient_Stronghold_Empire_Plan.md` - Updated docs

### Deployment Steps

1. **Generate ChromaDB auth token:**
   ```bash
   openssl rand -hex 32
   ```

2. **Copy files to Dell:**
   ```bash
   # On workstation
   scp ~/Documents/docker-compose.yml stronghold:~/stronghold/
   scp ~/Documents/.env.template stronghold:~/stronghold/
   ```

3. **Configure environment on Dell:**
   ```bash
   ssh stronghold
   cd ~/stronghold
   cp .env.template .env
   chmod 600 .env
   nano .env  # Fill in all tokens including CHROMADB_AUTH_TOKEN
   ```

4. **Start services:**
   ```bash
   docker compose up -d
   docker ps  # Verify chromadb is running
   ```

5. **Configure UFW (if not already done):**
   ```bash
   sudo ufw allow from 192.168.1.0/24 to any port 8000 comment "ChromaDB"
   sudo ufw reload
   sudo ufw status
   ```

6. **Test connectivity from workstation:**
   ```bash
   # Set token (get from Dell's .env file)
   export CHROMADB_AUTH_TOKEN="your_token_here"

   # Test heartbeat
   curl -H "Authorization: Bearer $CHROMADB_AUTH_TOKEN" \
     http://192.168.1.60:8000/api/v1/heartbeat

   # Should return: {"nanosecond heartbeat": ...}
   ```

---

## Phase 2: Configure MCP Server

**Status:** Setup script ready

### Prerequisites
- [ ] Phase 1 complete (ChromaDB accessible)
- [ ] Python 3.8+ installed on workstation
- [ ] `uv` or `uvx` installed (comes with Claude Code)

### Steps

1. **Configure environment:**
   ```bash
   cd /home/cib/ai-assistant-config/scripts
   cp .env.example .env
   chmod 600 .env
   nano .env  # Set CHROMADB_AUTH_TOKEN (same as Dell's .env)
   ```

2. **Run setup script:**
   ```bash
   ./setup-mcp-server.sh
   ```

   This will:
   - Verify .env configuration
   - Add MCP server 'homelab-memory' to Claude Code
   - Configure connection to 192.168.1.60:8000 with auth

3. **Verify MCP server:**
   ```bash
   claude mcp list
   # Should show: homelab-memory (user scope)

   claude mcp get homelab-memory
   # Shows full configuration
   ```

4. **Test in Claude Code session:**
   ```bash
   claude
   ```

   Then in the session:
   ```
   /mcp
   ```

   Should show:
   - homelab-memory (connected)
   - 12 tools available (chroma_query_documents, etc.)

---

## Phase 3: Build Ingestion Pipeline ✅

**Status:** Script created, ready to test

### Files Created
- [x] `ingest-to-chromadb.py` - Main ingestion script
- [x] `requirements-chromadb.txt` - Python dependencies
- [x] `.env.example` - Environment template
- [x] `README-chromadb.md` - Documentation

### Steps

1. **Install Python dependencies:**
   ```bash
   cd /home/cib/ai-assistant-config/scripts
   pip install --user -r requirements-chromadb.txt

   # Or use virtual environment:
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements-chromadb.txt
   ```

2. **Test dry run (no writes):**
   ```bash
   ./ingest-to-chromadb.py --dry-run --verbose
   ```

3. **Review what will be ingested:**
   - Check output for file paths
   - Verify collections mapping is correct
   - Confirm chunk counts look reasonable

---

## Phase 4: Organize into Collections

**Status:** Implemented in ingestion script

The script automatically organizes content:

| Collection | Content |
|---|---|
| `infrastructure` | homelab-ops CLAUDE.md, Obsidian Infrastructure/*.md, docker-compose.yml |
| `decisions` | Session MEMORY.md, Obsidian Security/*.md |
| `documentation` | Other project CLAUDE.md, Obsidian Services/Projects/Reference/*.md |

No manual action required - handled by `get_source_configs()` in the script.

---

## Phase 5: Verify Everything Works

**Status:** Verification script ready

### Prerequisites
- [ ] Phase 1-4 complete
- [ ] ChromaDB running on Dell
- [ ] MCP server configured
- [ ] Ingestion script tested

### Steps

1. **Run full ingestion:**
   ```bash
   cd /home/cib/ai-assistant-config/scripts
   ./ingest-to-chromadb.py --full --verbose
   ```

   Expected output:
   - "Connected to ChromaDB at 192.168.1.60:8000"
   - "Collection 'infrastructure' ready (count: ...)"
   - "Processed [file]: X chunks"
   - "✓ Ingestion complete: X added, Y updated"

2. **Run verification tests:**
   ```bash
   ./verify-chromadb.sh
   ```

   Must pass all tests:
   - [x] Test 1: Connectivity (heartbeat responds)
   - [x] Test 2: MCP server configured
   - [x] Test 3: Collections exist with data
   - [x] Test 4: Semantic search returns results
   - [x] Test 5: Ingestion script ready

3. **Manual semantic search test:**

   In a Claude Code session:
   ```
   User: "What IP is Wazuh on?"
   ```

   Claude should:
   - Use `chroma_query_documents` with collection="infrastructure"
   - Return relevant IP information from homelab-ops docs

4. **Test write-back (optional):**

   In Claude Code session:
   ```
   User: "Remember that we decided to use token auth for ChromaDB
          because it's simpler than OAuth for internal services."
   ```

   Claude should:
   - Use `chroma_add_documents` to persist the decision
   - Confirm it was saved to 'decisions' collection

5. **Test incremental update:**
   ```bash
   # Modify a file
   echo "# Test Section\nTest content" >> ~/.claude/session/MEMORY.md

   # Run incremental ingestion
   ./ingest-to-chromadb.py

   # Should report: "Updated 1 file"
   ```

**✅ Phase 5 Complete Criteria:**
- All verification tests pass
- Semantic queries return relevant results
- Write-back persists new knowledge
- Incremental updates work correctly

---

## Phase 6: Slim CLAUDE.md Files

**⚠️ CRITICAL: Only proceed after Phase 5 passes ALL tests!**

### Before Starting
1. **Create backups:**
   ```bash
   cp ~/.claude/session/MEMORY.md ~/.claude/session/MEMORY.md.bak
   cp ~/homelab-ops/CLAUDE.md ~/homelab-ops/CLAUDE.md.bak
   ```

2. **Commit current state to git:**
   ```bash
   cd /home/cib/ai-assistant-config
   git add -A
   git commit -m "backup: CLAUDE.md files before ChromaDB migration"
   ```

### Session MEMORY.md (5.9KB → ~2KB)

**Keep:**
- Project Quick Reference table
- Workflow Reminders section
- Active task/project pointers

**Move to ChromaDB (decisions collection):**
- Infrastructure Notes (IPs, services)
- Common Mistakes section
- Recent Changes log
- Troubleshooting history

### homelab-ops CLAUDE.md (14.6KB → ~4KB)

**Keep:**
- Repository structure overview
- Deployment command reference
- Conventions (file naming, etc.)
- Network topology table (high-level)

**Move to ChromaDB (infrastructure collection):**
- Detailed security_hardening steps
- Resource management details
- Service-specific configurations
- Detailed monitoring setups
- Historical context

### Verification After Slimming

1. **Test Claude Code can still answer questions:**
   ```
   "What's the security hardening we did for Docker?"
   "Show me the network topology"
   "What common mistakes should I avoid?"
   ```

2. **Compare context window savings:**
   ```bash
   # Before
   wc -c ~/.claude/session/MEMORY.md.bak
   wc -c ~/homelab-ops/CLAUDE.md.bak

   # After
   wc -c ~/.claude/session/MEMORY.md
   wc -c ~/homelab-ops/CLAUDE.md
   ```

3. **If something breaks:**
   ```bash
   # Rollback
   cp ~/.claude/session/MEMORY.md.bak ~/.claude/session/MEMORY.md
   cp ~/homelab-ops/CLAUDE.md.bak ~/homelab-ops/CLAUDE.md

   # Or use git
   cd /home/cib/ai-assistant-config
   git checkout HEAD~1 session/MEMORY.md
   ```

---

## Phase 7: Set Up Recurring Ingestion (Optional)

**Status:** Ready to configure

### Steps

1. **Test ingestion script works reliably:**
   ```bash
   # Run a few times manually to ensure stability
   ./ingest-to-chromadb.py
   ```

2. **Add to crontab:**
   ```bash
   crontab -e
   ```

   Add:
   ```cron
   # ChromaDB ingestion - daily at 6 AM
   0 6 * * * cd /home/cib/ai-assistant-config && python3 scripts/ingest-to-chromadb.py >> /tmp/chromadb-ingest.log 2>&1
   ```

3. **Monitor logs:**
   ```bash
   tail -f /tmp/chromadb-ingest.log
   ```

4. **Set up log rotation (optional):**
   ```bash
   # Create /etc/logrotate.d/chromadb-ingest
   sudo nano /etc/logrotate.d/chromadb-ingest
   ```

   Contents:
   ```
   /tmp/chromadb-ingest.log {
       daily
       rotate 7
       compress
       missingok
       notifempty
   }
   ```

---

## Troubleshooting

### Connection Refused

**Problem:** Cannot connect to ChromaDB at 192.168.1.60:8000

**Solutions:**
1. Verify Dell is running: `ping 192.168.1.60`
2. Check container: `ssh stronghold 'docker ps | grep chromadb'`
3. Check UFW: `ssh stronghold 'sudo ufw status | grep 8000'`
4. Test heartbeat: `curl http://192.168.1.60:8000/api/v1/heartbeat`

### Authentication Failed (401)

**Problem:** ChromaDB returns 401 Unauthorized

**Solutions:**
1. Verify token matches:
   ```bash
   # Workstation
   grep CHROMADB_AUTH_TOKEN /home/cib/ai-assistant-config/scripts/.env

   # Dell
   ssh stronghold 'grep CHROMADB_AUTH_TOKEN ~/stronghold/.env'
   ```
2. Check token is sent in header: `-H "Authorization: Bearer $TOKEN"`

### MCP Server Not Connected

**Problem:** `/mcp` shows homelab-memory as "disconnected"

**Solutions:**
1. Check MCP server config: `claude mcp get homelab-memory`
2. Test uvx: `uvx chroma-mcp --help`
3. Remove and re-add: `claude mcp remove homelab-memory && ./setup-mcp-server.sh`
4. Check Claude Code logs: `~/.claude/logs/`

### No Search Results

**Problem:** Queries return empty results

**Solutions:**
1. Check collection counts: `./verify-chromadb.sh`
2. Re-run ingestion: `./ingest-to-chromadb.py --full --verbose`
3. Verify embedding function is working (check ChromaDB logs)

### Ingestion Script Fails

**Problem:** Script exits with error

**Solutions:**
1. Check dependencies: `pip list | grep -E "(chromadb|frontmatter)"`
2. Verify file paths in .env
3. Run with --verbose: `./ingest-to-chromadb.py --full --verbose`
4. Check Python version: `python3 --version` (need 3.8+)

---

## Success Metrics

After full deployment, you should achieve:

- **Context Window Savings:** ~14.5KB → ~6.3KB (worst case)
- **Semantic Search:** Relevant results in <1 second
- **Incremental Updates:** Only changed files processed
- **MCP Integration:** 12 tools available in Claude Code
- **Reliability:** 99%+ uptime (ChromaDB is lightweight)

---

## Rollback Plan

If ChromaDB integration causes issues:

1. **Disable MCP server:**
   ```bash
   claude mcp remove homelab-memory
   ```

2. **Restore CLAUDE.md backups:**
   ```bash
   cp ~/.claude/session/MEMORY.md.bak ~/.claude/session/MEMORY.md
   cp ~/homelab-ops/CLAUDE.md.bak ~/homelab-ops/CLAUDE.md
   ```

3. **Stop ChromaDB (optional):**
   ```bash
   ssh stronghold
   cd ~/stronghold
   docker compose stop chromadb
   ```

4. **Full rollback from git:**
   ```bash
   cd /home/cib/ai-assistant-config
   git log --oneline  # Find commit before migration
   git checkout <commit-hash> session/MEMORY.md
   ```

---

## Maintenance

### Weekly
- Review ingestion logs: `tail -100 /tmp/chromadb-ingest.log`
- Check collection counts: `./verify-chromadb.sh`

### Monthly
- Rotate ChromaDB token (regenerate and update both .env files)
- Review and clean up old documentation
- Backup ChromaDB data: `ssh stronghold 'tar -czf ~/chroma-backup.tar.gz ~/stronghold/chroma-data'`

### Quarterly
- Review context window savings vs semantic quality
- Consider migrating to nomic-embed-text if better embeddings needed
- Update Python dependencies: `pip install --upgrade -r requirements-chromadb.txt`

---

## Resources

- [ChromaDB Documentation](https://docs.trychroma.com/)
- [chroma-mcp GitHub](https://github.com/chroma-core/chroma-mcp)
- [Claude Code MCP Guide](https://docs.anthropic.com/claude/docs/mcp)
- [Sentient Stronghold Plan](../../Documents/Sentient_Stronghold_Empire_Plan.md)
- [Project README](./README-chromadb.md)
