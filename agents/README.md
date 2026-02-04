# Custom Sub-Agents for Homelab Claude Code

This directory contains specialized agents for homelab infrastructure management.

## Available Agents

| Agent | Purpose | Model | Invocation Example |
|-------|---------|-------|-------------------|
| **security-reviewer** | Security audit for Docker stacks | Sonnet | "Review proxmox/monitoring/ for security issues" |
| **infra-validator** | Pre-deployment conflict detection | Sonnet | "Validate my new jellyfin stack for conflicts" |
| **doc-sync** | Documentation synchronization | Haiku | "Check documentation after adding Dockhand" |
| **deploy-helper** | Convention compliance validation | Haiku | "Validate this compose file before deployment" |

## Quick Start

### Single Agent
```bash
# Security audit
"Use security-reviewer to check proxmox/dockhand/"

# Validate before deployment
"Use infra-validator to check my new stack in proxmox/jellyfin/"

# Find documentation gaps
"Use doc-sync to check what's missing"

# Check conventions
"Use deploy-helper to validate proxmox/monitoring/docker-compose.yaml"
```

### Parallel Execution (Recommended)
```bash
# Review new stack with multiple agents at once
"Review proxmox/jellyfin/ with security-reviewer AND infra-validator in parallel"

# Full pre-deployment check
"Run security-reviewer, infra-validator, and deploy-helper on proxmox/monitoring/ in parallel"

# After infrastructure changes
"Run doc-sync and infra-validator in parallel to check for issues"
```

## Agent Details

### security-reviewer
**Checks**:
- ✓ Privileged mode abuse
- ✓ Docker socket mounts (read-only enforcement)
- ✓ Hardcoded secrets / default passwords
- ✓ Image tag pinning (no :latest in prod)
- ✓ Security options (no-new-privileges)
- ✓ UFW firewall rule suggestions

**Output**: Security audit report with severity levels (CRITICAL → LOW)

**Best For**: Pre-production deployments, security audits, post-change validation

---

### infra-validator
**Checks**:
- ✓ Port conflicts (vs existing allocations)
- ✓ IP address conflicts (192.168.1.0/24)
- ✓ Volume path existence
- ✓ Docker Compose syntax validation
- ✓ Resource allocation (memory/CPU limits)
- ✓ Network configuration issues

**Output**: Infrastructure validation report (PASS/WARNINGS/FAIL)

**Best For**: Before running `docker-compose up`, detecting resource exhaustion risks

---

### doc-sync
**Checks**:
- ✓ Missing service documentation pages
- ✓ Outdated port references
- ✓ Outdated IP addresses
- ✓ Broken WikiLinks in Obsidian vault
- ✓ Missing README files in stacks
- ✓ Stale change dates (docs vs actual code)

**Output**: Documentation sync report with action items

**Best For**: After adding/modifying services, periodic documentation audits

---

### deploy-helper
**Checks**:
- ✓ Restart policies (must be `unless-stopped`)
- ✓ Security options (no-new-privileges)
- ✓ Memory limits (prevents OOM)
- ✓ Environment variable patterns (no default passwords)
- ✓ Volume mount conventions
- ✓ Health check suggestions
- ✓ Image tag pinning
- ✓ Network binding security

**Output**: Convention compliance report with code fix suggestions

**Best For**: Before committing changes, ensuring consistency across stacks

## Workflow Examples

### New Service Deployment
```bash
# Step 1: Create docker-compose.yaml
# Step 2: Validate in parallel
"Review proxmox/jellyfin/ with security-reviewer, infra-validator, and deploy-helper in parallel"

# Step 3: Fix issues, then deploy
cd ~/homelab-ops/proxmox/jellyfin && docker-compose up -d

# Step 4: Update documentation
"Use doc-sync to find what documentation I need to create"
```

### Security Audit (All Stacks)
```bash
# Audit all ProxMoxBox stacks in parallel
"Use security-reviewer to audit proxmox/dockhand, proxmox/monitoring, proxmox/homepage, and proxmox/minecraft in parallel"
```

### Pre-Commit Validation
```bash
# Before git commit
"Run deploy-helper and security-reviewer on modified compose files in parallel"
```

### Documentation Maintenance
```bash
# Monthly check
"Use doc-sync to find outdated documentation and broken links"
```

## Configuration

Each agent file uses this YAML frontmatter:
```yaml
---
name: agent-name
description: When to use this agent
model: sonnet | haiku | opus
subagent_type: general-purpose
---
```

## Context Files

Agents reference these files for homelab state:
- `~/.claude/CLAUDE.md` - Global user preferences, core directives
- `~/homelab-ops/CLAUDE.md` - Port allocations, IP topology, resource limits
- `~/Documents/HomeLab/HomeLab/_Index.md` - Documentation structure

## Model Selection

- **Haiku** (doc-sync, deploy-helper) - Fast, cost-effective for pattern matching
- **Sonnet** (security-reviewer, infra-validator) - Balanced performance for analysis
- **Opus** - Not currently used (reserve for complex migrations)

## Tips

1. **Always run security-reviewer before production** - Catches privilege escalation risks
2. **Use infra-validator before docker-compose up** - Prevents port/IP conflicts
3. **Run agents in parallel when possible** - Single message with multiple agents
4. **Check doc-sync after infrastructure changes** - Keeps Obsidian vault synchronized
5. **Use deploy-helper as a linter** - Enforces homelab conventions

## Extending Agents

To create new agents:
1. Create `~/.claude/agents/my-agent.md`
2. Add YAML frontmatter with name, description, model, subagent_type
3. Write detailed prompt with checks, output format, execution workflow
4. Test: "Use my-agent to [task]"

## Support

Agent behavior follows:
- **Idempotency** - Check state before changes
- **Security First** - Least privilege, no chmod 777
- **Network Awareness** - 192.168.1.0/24 topology
- **Documentation** - Educational comments in all output
- **Docker Compose Only** - Never suggest docker run commands
