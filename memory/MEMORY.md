# Claude Code Memory

## Workflow Reminders

### Homelab Documentation Sync
**IMPORTANT:** After updating the Obsidian vault (`homelab-docs`), always ask:
> "Would you like me to sync the vault to the public wiki?"

If yes, run:
```bash
cd ~/homelab-wiki && ./sync-sanitize.sh
```

This syncs content from the private Obsidian vault to the public wiki at https://jhathcock-sys.github.io/homelab-wiki/ with sanitization (removes IPs, credentials, personal info).

## Infrastructure Notes

### Server Resource Usage
- **ProxMoxBox (192.168.1.4):** Primary Docker host, typically 50-60% memory used, CPU at 60%+
- **Pi5 (192.168.1.234):** Secondary services node, low resource usage (<15% memory, <5% CPU)
- **Decision Pattern:** Deploy always-on lightweight services to Pi5, heavier workloads to ProxMoxBox

### GitOps Workflow
- Repository: `homelab-ops` at `/home/cib/homelab-ops`
- When deploying new services, add compose files to repo for drift prevention
- **Drift Detection:** Run `cd ~/homelab-ops && ./scripts/drift-detection.sh` to validate infrastructure
- Pi5 stacks must be in TWO locations:
  - `pi5/` directory (actual deployment location)
  - `proxmox/pi5-stacks/` directory (for Dockhand/Hawser remote management)
  - Both in Git AND deployed to `/opt/pi5-stacks/` on ProxMoxBox

### Prometheus Configuration
- Never configured standalone containers as scrape targets (unless they expose metrics)
- Container metrics covered by cAdvisor at 192.168.1.4:8081
- Current targets: prometheus, proxmoxbox, pi5, cadvisor, pihole, npm, wazuh, synology-snmp

## Automation & Tools

### GitOps Drift Detection
- **Script:** `~/homelab-ops/scripts/drift-detection.sh`
- **Purpose:** Validates running containers match repository
- **Checks:** 21 containers across ProxMoxBox (14) and Pi5 (7)
- **Usage:** `cd ~/homelab-ops && ./scripts/drift-detection.sh`
- **Exit code:** Number of issues found (0 = clean)
- **Important:** Excludes `proxmox/pi5-stacks/` when checking ProxMoxBox (Hawser remote management)

## Common Mistakes Avoided

### SSH Authentication
- **Pi5 username is `cib`**, not `root`
- Always use: `ssh cib@192.168.1.234`
- ProxMoxBox uses `root`: `ssh root@192.168.1.4`

### Docker Networks
- Always create external networks before deploying: `docker network create homelab`
- Check with: `docker network ls`

### Memory Limits
- Pi5 kernel doesn't support memory cgroup limits (warnings are informational only)
- Still include limits in compose files for documentation and ProxMoxBox deployment

## Infrastructure Cleanup Completed (2026-02-04)
- Removed Syncthing (replaced by Obsidian LiveSync/CouchDB)
- Removed Komodo test directory
- Backup retained at `/home/syncthing.backup-20260204` until ~2026-03-06

## Active Services

### Obsidian LiveSync (Pi5)
- CouchDB at 192.168.1.234:5984
- Credentials: `/home/cib/obsidian-livesync-credentials.txt`
- Real-time vault sync across devices
- Works alongside Git for version control

### Monitoring Stack (ProxMoxBox)
- Grafana: 192.168.1.4:3030
- Prometheus: 192.168.1.4:9090
- Alertmanager: 192.168.1.4:9093 (Discord notifications)
- Loki: 192.168.1.4:3101

### Management Tools
- Dockhand: 192.168.1.4:3000 (Docker management)
- Homepage: 192.168.1.4:4000 (Dashboard)
- Uptime Kuma: 192.168.1.4:3001 (Health checks)
