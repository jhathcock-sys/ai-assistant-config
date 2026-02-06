# CLAUDE.md - AI Assistant Config

<project>
    <overview>
        Backup repository for Claude Code memory files, custom agents, and configuration.
        Uses symlink-based workflow - this repo is the single source of truth.
    </overview>

    <architecture>
        <memory_system>
            Symlink-based: Active Claude Code memory locations link to files in this repo.
            Changes propagate immediately, sync.sh commits and pushes to Git.
        </memory_system>

        <file_structure>
            global/CLAUDE.md      → ~/.claude/CLAUDE.md (user profile, directives)
            session/MEMORY.md     → ~/.claude/projects/-home-cib--claude/memory/MEMORY.md (operational knowledge)
            projects/*/CLAUDE.md  → Project-specific context (loaded when in project directory)
            agents/               → Custom agent definitions for homelab operations
            scripts/              → Helper scripts (install-symlinks.sh, sync.sh)
        </file_structure>
    </architecture>

    <memory_hierarchy>
        <layer name="Global" file="global/CLAUDE.md" size="~3KB">
            User profile, persona, core directives, interaction rules, learning path
        </layer>
        <layer name="Session" file="session/MEMORY.md" size="~8KB">
            Workflow reminders, infrastructure notes, project quick-reference,
            common mistakes, active services, recent changes
        </layer>
        <layer name="Project" file="projects/*/CLAUDE.md" size="Varies">
            Project-specific: repository structure, conventions, access points,
            deployment commands, topology, monitoring config
        </layer>
    </memory_hierarchy>

    <workflow>
        <setup>
            ./scripts/install-symlinks.sh  # One-time setup
        </setup>
        <edit>
            # Edit files directly in this repo OR through symlinks
            vim global/CLAUDE.md
            vim session/MEMORY.md
        </edit>
        <sync>
            ./scripts/sync.sh "Optional commit message"
            # OR manually: git add -A && git commit && git push
        </sync>
    </workflow>

    <projects>
        <project name="homelab-ops" file="projects/homelab-ops/CLAUDE.md">
            Docker Compose stacks, monitoring, security, topology, resource limits
        </project>
        <project name="homelab-docs" file="projects/homelab-docs/CLAUDE.md">
            Obsidian vault structure, navigation, documentation workflow
        </project>
        <project name="homelab-wiki" file="projects/homelab-wiki/CLAUDE.md">
            Quartz v4 wiki, sanitization pipeline, GitHub Pages deployment
        </project>
        <project name="podcast-studio" file="projects/podcast-studio/CLAUDE.md">
            LiveKit video recording platform architecture
        </project>
        <project name="my-portfolio" file="projects/my-portfolio/CLAUDE.md">
            Hugo portfolio site structure, content tips, commands
        </project>
    </projects>

    <security>
        <credentials>
            Never commit passwords/tokens to Git
            Use *.local.md files (gitignored) for sensitive data
            Pattern: Replace with [REDACTED - see CLAUDE.local.md]
        </credentials>
        <gitignore>
            *.local.md, **/CLAUDE.local.md, secrets/, credentials/
        </gitignore>
    </security>

    <custom_agents>
        <agent name="deploy-helper" file="agents/deploy-helper.md">
            Validate Docker Compose files against homelab conventions
        </agent>
        <agent name="infra-validator" file="agents/infra-validator.md">
            Pre-deployment validation (port conflicts, resource allocation)
        </agent>
        <agent name="security-reviewer" file="agents/security-reviewer.md">
            Security audit for Docker stacks (privileged mode, secrets, UFW rules)
        </agent>
        <agent name="doc-sync" file="agents/doc-sync.md">
            Keep homelab-docs vault synchronized with homelab-ops infrastructure
        </agent>
    </custom_agents>

    <maintenance>
        <guidelines>
            Keep global CLAUDE.md focused on user/persona (~3KB target)
            Keep session MEMORY.md for operational knowledge (~5-8KB target)
            Move stale session content to project CLAUDE.md files
            Run periodic cleanup with sync.sh
        </guidelines>
        <rollback>
            cp -r ~/ai-assistant-config ~/ai-assistant-config.backup-YYYYMMDD
        </rollback>
    </maintenance>

    <related>
        <repo url="github.com:jhathcock-sys/Dockers">homelab-ops - Infrastructure stacks</repo>
        <repo url="github.com:jhathcock-sys/homelab-docs">homelab-docs - Private Obsidian vault</repo>
        <repo url="github.com:jhathcock-sys/homelab-wiki">homelab-wiki - Public wiki mirror</repo>
        <repo url="github.com:jhathcock-sys/me">my-portfolio - Portfolio site</repo>
        <repo url="github.com:jhathcock-sys/podcast-studio">podcast-studio - Video recording platform</repo>
    </related>
</project>
