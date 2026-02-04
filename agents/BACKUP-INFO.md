# Claude Code Agents Backup

**Backup Date**: 2026-02-04
**Primary Location**: `~/.claude/agents/`
**Backup Location**: `~/ai-assistant-config/agents/` (this repository)

---

## Backup Contents

| File | Size | Purpose |
|------|------|---------|
| `security-reviewer.md` | 7.2 KB | Security audit for Docker Compose stacks |
| `infra-validator.md` | 8.7 KB | Pre-deployment conflict detection |
| `doc-sync.md` | 8.5 KB | Obsidian vault synchronization |
| `deploy-helper.md` | 9.9 KB | Docker Compose convention enforcement |
| `README.md` | 4.9 KB | Agent usage documentation |

**Total Size**: ~39 KB

---

## Restoration Instructions

### Quick Restore (All Agents)

```bash
# Copy agents back to Claude Code directory
cp -v ~/ai-assistant-config/agents/*.md ~/.claude/agents/

# Verify restoration
ls -lh ~/.claude/agents/
```

### Individual Agent Restore

```bash
# Restore only security-reviewer
cp ~/ai-assistant-config/agents/security-reviewer.md ~/.claude/agents/

# Test agent
claude "Use security-reviewer to check proxmox/monitoring/"
```

---

## Testing After Restore

Verify agents work correctly:

```bash
# Test security-reviewer
"Use security-reviewer to check proxmox/monitoring/"

# Test infra-validator
"Use infra-validator to validate proxmox/dockhand/"

# Test doc-sync
"Use doc-sync to check documentation"

# Test deploy-helper
"Use deploy-helper to validate proxmox/monitoring/docker-compose.yaml"

# Test parallel execution
"Review proxmox/dockhand/ with security-reviewer AND deploy-helper in parallel"
```

---

## Version History

### 2026-02-04 - Initial Backup

**Created 4 custom agents**:
- security-reviewer (Sonnet) - Security auditing
- infra-validator (Sonnet) - Conflict detection
- doc-sync (Haiku) - Documentation sync
- deploy-helper (Haiku) - Convention enforcement

**First Audit Results**:
- Stack: proxmox/monitoring/
- Duration: ~2 minutes
- Findings: 1 critical, 3 high-priority issues
- Generated: 153KB report + UFW firewall script

---

## Agent Dependencies

Agents reference these context files:

| File | Contains | Location |
|------|----------|----------|
| `CLAUDE.md` | Global preferences, core directives | `~/.claude/` |
| `CLAUDE.md` | Port allocations, IP topology | `~/homelab-ops/` |
| `_Index.md` | Documentation structure | `~/Documents/HomeLab/HomeLab/` |

**Restore Note**: Agents will work immediately after restore, but require context files to function optimally.

---

## Backup Schedule

**Recommended**: After any agent modification

**Commands**:
```bash
# Manual backup
cp -v ~/.claude/agents/*.md ~/ai-assistant-config/agents/

# Commit to git
cd ~/ai-assistant-config
git add agents/
git commit -m "Backup Claude Code agents - $(date +%Y-%m-%d)"
git push
```

**Future Enhancement**: Set up automatic backup via cron or git hook.

---

## Related Documentation

**Obsidian Vault**:
- `~/Documents/HomeLab/HomeLab/Projects/Claude-Code-Agents.md`

**Portfolio Site**:
- `~/my-portfolio/content/projects/claude-code-agents.md`

**Homelab Docs**:
- `~/Documents/HomeLab/HomeLab/Security/Monitoring-Stack-Security-Audit.md`

---

## Emergency Recovery

If `~/.claude/agents/` directory is deleted:

```bash
# 1. Restore from this backup
mkdir -p ~/.claude/agents
cp ~/ai-assistant-config/agents/*.md ~/.claude/agents/

# 2. Verify Claude Code settings
cat ~/.claude/settings.json | grep model

# 3. Test agent execution
claude "Use security-reviewer to check proxmox/dockhand/"
```

---

## Maintenance

### Updating Agents

When modifying agents:

1. Edit primary location: `~/.claude/agents/<agent-name>.md`
2. Test changes
3. Backup to this repo: `cp ~/.claude/agents/*.md ~/ai-assistant-config/agents/`
4. Commit: `git add agents/ && git commit -m "Update agent: <change description>"`
5. Push: `git push`

### Version Control Best Practices

- **Commit message format**: `Update agent: <agent-name> - <change summary>`
- **Tag major versions**: `git tag -a v1.0 -m "Initial agent release"`
- **Document breaking changes** in commit messages

---

## Support

**Issues**: Report agent failures or improvement ideas
**Repository**: github.com:jhathcock-sys/ai-assistant-config.git

---

*Last backup: 2026-02-04*
*Agent count: 4*
*Total size: 39 KB*
