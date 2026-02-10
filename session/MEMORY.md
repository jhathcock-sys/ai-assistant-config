# Claude Code Memory

## Project Quick Reference

| Project | Path | Repository | Live URL |
|---------|------|------------|----------|
| homelab-ops | /home/cib/homelab-ops | github.com:jhathcock-sys/Dockers.git | - |
| homelab-docs | /home/cib/Documents/HomeLab/HomeLab | github.com:jhathcock-sys/homelab-docs.git | - |
| homelab-wiki | /home/cib/homelab-wiki | github.com:jhathcock-sys/homelab-wiki.git | https://jhathcock-sys.github.io/homelab-wiki/ |
| podcast-studio | /home/cib/podcast-studio | github.com:jhathcock-sys/podcast-studio.git | - |
| my-portfolio | /home/cib/my-portfolio | github.com:jhathcock-sys/me.git | https://jhathcock-sys.github.io/me/ |
| ai-assistant-config | /home/cib/ai-assistant-config | github.com:jhathcock-sys/ai-assistant-config.git | - |

## Workstation Configuration

**Platform:** Pop!_OS 24.04 LTS (COSMIC Desktop)

### System Tools
- **Shell:** Zsh with Powerlevel10k theme
- **Backups:** Timeshift (RSYNC snapshots)
- **Firewall:** UFW enabled
- **Network:** Tailscale VPN mesh, Ed25519 SSH keys
- **Containers:** Docker + Portainer (localhost:9000)

### Zsh Aliases
- `update` → sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y
- `install` → sudo apt install
- `myip` → curl ifconfig.me
- `ports` → sudo lsof -i -P -n | grep LISTEN

### Notes
- COSMIC Terminal headerbar: ~/.config/cosmic/com.system76.CosmicTerm/v1/show_headerbar
- Night Light: use gammastep (NVIDIA/Wayland limitation)

## Workflow Reminders

### Homelab Documentation Sync
**IMPORTANT:** After updating the Obsidian vault (`homelab-docs`), always ask:
> "Would you like me to sync the vault to the public wiki?"

If yes, run:
```bash
cd ~/homelab-wiki && ./sync-sanitize.sh
```

This syncs content from the private Obsidian vault to the public wiki at https://jhathcock-sys.github.io/homelab-wiki/ with sanitization (removes IPs, credentials, personal info).

### Quartz Wiki Requirements
**CRITICAL:** The homelab wiki uses Quartz v4, which has specific file naming requirements:
- **Homepage MUST be named `index.md`** (lowercase, no underscore) in `content/` directory
- Using `_Index.md` or `Index.md` will cause build warnings and homepage won't display
- Both `homelab-docs` and `homelab-wiki` must use `index.md` to stay in sync
- Quartz will generate `index.html` from `index.md` for GitHub Pages

## GitOps Workflow

- **Repository:** `homelab-ops` at `/home/cib/homelab-ops`
- **Add new services to repo** for drift prevention
- **Drift Detection:** `cd ~/homelab-ops && ./scripts/drift-detection.sh`
- **Pi5 stacks:** Must be in both `pi5/` AND `proxmox/pi5-stacks/` directories

## Common Patterns

### SSH Access
- **Pi5:** `ssh cib@192.168.1.234` (username is `cib`, not root)
- **ProxMoxBox:** `ssh root@192.168.1.4`

### Docker Networks
- Always create external networks before deploying: `docker network create homelab`
- Check with: `docker network ls`

---

**Note:** Detailed infrastructure info, service configurations, and historical changes are now stored in ChromaDB. Query the `infrastructure`, `documentation`, and `decisions` collections for:
- Server resource usage and deployment patterns
- Service URLs and monitoring endpoints
- Common mistakes and troubleshooting guides
- Changelog and recent changes
