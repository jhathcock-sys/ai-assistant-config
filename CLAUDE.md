# CLAUDE.md - AI Assistant Config

This file provides guidance to Claude Code when working in this repository.

<project>
    <overview>
        Backup repository for Claude Code memory files, custom skills, and reusable prompts.
        This is the source of truth for AI assistant configuration.
    </overview>

    <structure>
        <dir path="claude-code/">
            <file path="CLAUDE.md">Backup of ~/.claude/CLAUDE.md (global memory)</file>
            <dir path="skills/">Custom Claude Code skills (future)</dir>
        </dir>
        <dir path="prompts/">Reusable prompt templates (future)</dir>
    </structure>

    <sync_commands>
        <cmd name="backup">cp ~/.claude/CLAUDE.md ~/ai-assistant-config/claude-code/CLAUDE.md</cmd>
        <cmd name="restore">cp ~/ai-assistant-config/claude-code/CLAUDE.md ~/.claude/CLAUDE.md</cmd>
        <cmd name="commit">git add -A &amp;&amp; git commit -m "Update memory" &amp;&amp; git push</cmd>
    </sync_commands>

    <memory_architecture>
        <file path="~/.claude/CLAUDE.md" scope="global">
            Always loaded - persona, directives, interaction rules, workstation
        </file>
        <file path="&lt;project&gt;/CLAUDE.md" scope="project">
            Loaded when in project directory - project-specific context
        </file>
        <file path="&lt;project&gt;/CLAUDE.local.md" scope="session">
            Gitignored - private notes, session history
        </file>
    </memory_architecture>
</project>

## Sync Workflow

```bash
# After making changes to global memory
cp ~/.claude/CLAUDE.md ~/ai-assistant-config/claude-code/CLAUDE.md
cd ~/ai-assistant-config
git add -A && git commit -m "Update memory" && git push

# Restore from backup (new machine)
cp ~/ai-assistant-config/claude-code/CLAUDE.md ~/.claude/CLAUDE.md
```

## Memory Tree

| File | Scope | Content |
|------|-------|---------|
| `~/.claude/CLAUDE.md` | Global | Persona, directives, workstation |
| `homelab-ops/CLAUDE.md` | Project | Infrastructure, services, monitoring |
| `my-portfolio/CLAUDE.md` | Project | Hugo structure, content tips |
| `ai-assistant-config/CLAUDE.md` | Project | This file - sync instructions |
