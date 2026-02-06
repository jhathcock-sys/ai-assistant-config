# CLAUDE.md - Homelab Documentation Vault

<project>
    <overview>
        Obsidian vault containing structured homelab infrastructure documentation.
        Wiki-style organization with 31 cross-linked markdown files across 8 folders.
        Git-versioned for history tracking and backup.
    </overview>

    <repository>
        <name>homelab-docs</name>
        <url>https://github.com/jhathcock-sys/homelab-docs</url>
        <visibility>private</visibility>
        <local_path>/home/cib/Documents/HomeLab/HomeLab</local_path>
    </repository>

    <structure>
        <folder name="Infrastructure">
            Network-Topology.md - IP assignments, device roles (192.168.1.0/24)
            GitOps-Workflow.md - Docker Compose management via Git (homelab-ops repo)
            Workstation-Setup.md - Pop!_OS COSMIC laptop configuration
        </folder>
        <folder name="Services">
            Homepage-Dashboard.md - Dashboard at 192.168.1.4:4000
            Dockhand.md - Docker management UI + Hawser remote management
            Pi-hole.md - DNS servers (192.168.1.3, 192.168.1.234)
            Minecraft-Server.md - Game server configuration
            Homebox.md - Inventory management
            NAS-Synology.md - Synology DS220j integration (192.168.1.5)
            Monitoring/ subfolder - Prometheus, Grafana, Loki, Alertmanager
        </folder>
        <folder name="Security">
            Wazuh-SIEM.md - Security monitoring (192.168.1.7)
            Security-Hardening.md - Docker security improvements
            Best-Practices.md - Security guidelines
        </folder>
        <folder name="Projects">
            Podcast-Studio.md - Video recording platform
            Portfolio-Site.md - Hugo site documentation
            Claude-Memory-System.md - AI memory architecture
            Homelab-Wiki.md - Public wiki mirror with Quartz (jhathcock-sys.github.io/homelab-wiki)
        </folder>
        <folder name="Reference">
            Personal-Context.md - Profile, goals, learning path
            Docker-Commands.md - Useful commands and SSH keys
            Troubleshooting.md - Common issues
            Environment-Files.md - .env templates
            GitHub-Repositories.md - Repo links
        </folder>
        <folder name="Roadmap">
            Future-Plans.md - Upcoming projects (OPNsense, media stack)
            Current-TODO.md - Active tasks
        </folder>
        <folder name="Changelog">
            _Changelog-Index.md - Timeline overview
            2026-02/ subfolder - Detailed session notes by date
        </folder>
    </structure>

    <navigation>
        <entry_point>_Index.md</entry_point>
        <link_syntax>[[Page-Name]] or [[Page-Name|Display Text]]</link_syntax>
        <breadcrumb>[[_Index|← Back to Index]] at top of each page</breadcrumb>
        <related_pages>Listed at bottom of each page</related_pages>
    </navigation>

    <security>
        <gitignore>
            Excludes: Wazuh Creds.md, Token files, Secrets/, Build Outs/, Config Files/
            Pattern matching: **/*secret*.md, **/*password*.md, **/*cred*.md
        </gitignore>
        <sensitive_files>
            Never commit credentials or tokens
            Use separate Secrets/ folder (gitignored)
        </sensitive_files>
    </security>

    <workflow>
        <update_page>
            1. Navigate to appropriate folder
            2. Edit markdown file
            3. Add [[wiki-links]] to related pages
            4. git add, commit, push
        </update_page>
        <add_page>
            1. Create file in appropriate folder
            2. Add header with breadcrumb: [[_Index|← Back to Index]]
            3. Add wiki links to/from related pages
            4. Update _Index.md if major addition
            5. git add, commit, push
        </add_page>
        <reference_syntax>
            Use [[Page-Name]] for internal links
            Use [[Page-Name#Section]] for section links
            Use [[Page-Name|Custom Text]] for custom link text
        </reference_syntax>
    </workflow>

    <statistics>
        <files>35 total (31 documentation + 4 supporting)</files>
        <lines>3,898 lines of documentation</lines>
        <links>150+ internal wiki links</links>
        <folders>8 main categories</folders>
    </statistics>

    <related_projects>
        <project>homelab-ops - Docker Compose stacks (GitOps repository)</project>
        <project>homelab-wiki - Public sanitized mirror (Quartz v4, GitHub Pages)</project>
        <project>my-portfolio - Portfolio site documenting homelab projects</project>
        <project>ai-assistant-config - Backup of all CLAUDE.md files</project>
    </related_projects>

    <metadata>
        <created>2026-02-04</created>
        <transformed_from>Monolithic 1,550-line "Homelab and Portfolio Log.md"</transformed_from>
        <backup>Synced to ai-assistant-config/homelab-docs/</backup>
    </metadata>
</project>
