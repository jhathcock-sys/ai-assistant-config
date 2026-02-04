# CLAUDE.md - AI Assistant Config

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
        <dir path="homelab-ops/">
            <file path="CLAUDE.md">Backup of homelab-ops project memory</file>
        </dir>
        <dir path="homelab-docs/">
            <file path="CLAUDE.md">Backup of homelab-docs project memory</file>
        </dir>
        <dir path="homelab-wiki/">
            <file path="CLAUDE.md">Backup of homelab-wiki project memory</file>
        </dir>
        <dir path="podcast-studio/">
            <file path="CLAUDE.md">Backup of podcast-studio project memory</file>
        </dir>
        <dir path="my-portfolio/">
            <file path="CLAUDE.md">Backup of my-portfolio project memory</file>
        </dir>
        <dir path="prompts/">Reusable prompt templates (future)</dir>
    </structure>

    <sync_commands>
        <cmd name="backup">cp ~/.claude/CLAUDE.md ~/ai-assistant-config/claude-code/CLAUDE.md</cmd>
        <cmd name="restore">cp ~/ai-assistant-config/claude-code/CLAUDE.md ~/.claude/CLAUDE.md</cmd>
        <cmd name="commit">git add -A &amp;&amp; git commit -m "Update memory" &amp;&amp; git push</cmd>
        <cmd name="full_sync">backup + commit combined</cmd>
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

    <memory_tree>
        <file path="~/.claude/CLAUDE.md" scope="Global" content="Persona, directives, workstation, project pointers" />
        <file path="homelab-ops/CLAUDE.md" scope="Project" content="Infrastructure, Docker stacks, monitoring, security" />
        <file path="homelab-docs/CLAUDE.md" scope="Project" content="Obsidian vault structure, navigation, documentation" />
        <file path="homelab-wiki/CLAUDE.md" scope="Project" content="Quartz v4 wiki, sanitization pipeline, GitHub Pages deployment" />
        <file path="podcast-studio/CLAUDE.md" scope="Project" content="LiveKit video recording, architecture, deployment" />
        <file path="my-portfolio/CLAUDE.md" scope="Project" content="Hugo site structure, content tips, commands" />
        <file path="ai-assistant-config/CLAUDE.md" scope="Project" content="This file - memory backup, sync instructions" />
    </memory_tree>
</project>
