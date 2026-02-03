# AI Assistant Configuration

Personal configuration, memory files, and custom skills for AI coding assistants.

## Structure

```
ai-assistant-config/
├── claude-code/
│   ├── CLAUDE.md           # Global memory file (~/.claude/CLAUDE.md)
│   └── skills/             # Custom skills (future)
│       └── .gitkeep
├── prompts/                # Reusable prompt templates (future)
│   └── .gitkeep
└── README.md
```

## Claude Code Memory

The `claude-code/CLAUDE.md` file is my global context file for [Claude Code](https://claude.ai/code). It uses a structured XML format for better hierarchy and queryability.

### Core Directives

| Directive | Purpose |
|-----------|---------|
| **Idempotency** | Prefer solutions that can run multiple times without breaking |
| **Security First** | Least-privilege, no chmod 777, always suggest UFW rules |
| **Network Awareness** | Check topology before suggesting static IPs |
| **Documentation** | Include educational comments in all scripts |
| **Docker Compose Only** | Never provide `docker run`, always provide compose files |

### Installation

```bash
# Backup existing config
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak

# Symlink or copy
ln -sf ~/ai-assistant-config/claude-code/CLAUDE.md ~/.claude/CLAUDE.md
# OR
cp ~/ai-assistant-config/claude-code/CLAUDE.md ~/.claude/CLAUDE.md
```

## Documentation

Full writeup on the memory system design: https://jhathcock-sys.github.io/me/projects/claude-memory/

## Related Repositories

- [homelab-ops](https://github.com/jhathcock-sys/Dockers) - Infrastructure as Code for homelab
- [Portfolio](https://github.com/jhathcock-sys/me) - Personal portfolio site
