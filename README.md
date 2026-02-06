# AI Assistant Configuration

Personal configuration, memory files, and custom agents for Claude Code.

## Structure

```
ai-assistant-config/
├── global/
│   └── CLAUDE.md              # Global user memory (~3KB)
├── session/
│   └── MEMORY.md              # Session memory (~8KB)
├── projects/                  # Project-specific context files
│   ├── homelab-ops/CLAUDE.md
│   ├── homelab-docs/CLAUDE.md
│   ├── homelab-wiki/CLAUDE.md
│   ├── podcast-studio/CLAUDE.md
│   └── my-portfolio/CLAUDE.md
├── agents/                    # Custom agent definitions
│   ├── deploy-helper.md
│   ├── infra-validator.md
│   ├── security-reviewer.md
│   └── doc-sync.md
├── claude-code/               # Claude Code settings
│   ├── settings.json
│   ├── statusline.sh
│   └── skills/
├── scripts/                   # Helper scripts
│   ├── install-symlinks.sh    # Set up symlink workflow
│   └── sync.sh                # Commit and push changes
├── prompts/                   # Reusable prompt templates
└── README.md
```

## Memory System

This repository uses a **symlink-based workflow** where memory files in active Claude Code locations are symlinked to this repository, making it the single source of truth.

### Memory Organization

| File | Purpose | Size | Location |
|------|---------|------|----------|
| **global/CLAUDE.md** | User profile, persona, directives, interaction rules | ~3KB | Symlinked to `~/.claude/CLAUDE.md` |
| **session/MEMORY.md** | Workflow reminders, infrastructure notes, common mistakes, active services | ~8KB | Symlinked to `~/.claude/projects/-home-cib--claude/memory/MEMORY.md` |
| **projects/*/CLAUDE.md** | Project-specific context (repository structure, conventions, access points) | Varies | Referenced by Claude Code when in project directory |

### Core Directives

| Directive | Purpose |
|-----------|---------|
| **Idempotency** | Prefer solutions that can run multiple times without breaking |
| **Security First** | Least-privilege, no chmod 777, always suggest UFW rules |
| **Network Awareness** | Check topology before suggesting static IPs (192.168.1.0/24) |
| **Documentation** | Include educational comments in all scripts |
| **Docker Compose Only** | Never provide `docker run`, always provide compose files |

## Installation

### Initial Setup

```bash
# Clone the repository
git clone git@github.com:jhathcock-sys/ai-assistant-config.git ~/ai-assistant-config
cd ~/ai-assistant-config

# Install symlinks (backs up existing files first)
./scripts/install-symlinks.sh
```

The script will:
1. Backup existing memory files to `.bak` files
2. Create symlinks from active locations to this repository
3. Verify symlinks are working correctly

### Syncing Changes

After editing memory files (either directly in this repo or through symlinks):

```bash
# Commit and push changes
cd ~/ai-assistant-config
./scripts/sync.sh "Optional custom commit message"
```

Or manually:

```bash
cd ~/ai-assistant-config
git add -A
git commit -m "Memory update"
git push
```

## Credential Management

**IMPORTANT:** Never commit credentials to this repository.

- Sensitive data belongs in `.local.md` files (gitignored)
- Example: `projects/homelab-ops/CLAUDE.local.md` for passwords
- Pattern: Replace credentials with `[REDACTED - see CLAUDE.local.md]` in committed files

## Custom Agents

The `agents/` directory contains specialized agent definitions for homelab operations:

- **deploy-helper** - Validate Docker Compose files against homelab conventions
- **infra-validator** - Pre-deployment validation (port conflicts, resource allocation)
- **security-reviewer** - Security audit for Docker stacks
- **doc-sync** - Keep homelab-docs vault synchronized with homelab-ops infrastructure

## Related Projects

This memory system coordinates context across multiple homelab projects:

| Project | Repository | Purpose |
|---------|------------|---------|
| homelab-ops | [github.com:jhathcock-sys/Dockers](https://github.com/jhathcock-sys/Dockers) | Docker Compose infrastructure stacks |
| homelab-docs | [github.com:jhathcock-sys/homelab-docs](https://github.com/jhathcock-sys/homelab-docs) | Private Obsidian documentation vault |
| homelab-wiki | [github.com:jhathcock-sys/homelab-wiki](https://github.com/jhathcock-sys/homelab-wiki) | [Public wiki mirror](https://jhathcock-sys.github.io/homelab-wiki/) |
| my-portfolio | [github.com:jhathcock-sys/me](https://github.com/jhathcock-sys/me) | [Hugo portfolio site](https://jhathcock-sys.github.io/me/) |
| podcast-studio | [github.com:jhathcock-sys/podcast-studio](https://github.com/jhathcock-sys/podcast-studio) | Video podcast recording platform |

## Documentation

Full writeup on the memory system design: https://jhathcock-sys.github.io/me/projects/claude-memory/

## Rollback

If issues occur, restore from backup:

```bash
rm -rf ~/ai-assistant-config
mv ~/ai-assistant-config.backup-YYYYMMDD ~/ai-assistant-config
```

## Maintenance

- Keep global CLAUDE.md focused on user profile and directives (~3KB target)
- Keep session MEMORY.md for operational knowledge and recent changes (~5-8KB)
- Move old entries from session memory to project CLAUDE.md files when appropriate
- Run periodic cleanup: `git add -A && git commit -m "Memory cleanup" && git push`
