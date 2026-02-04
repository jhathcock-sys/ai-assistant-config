# CLAUDE.md - Homelab Infrastructure

<project>
    <overview>
        Infrastructure as Code repository for a ProxMox-based homelab.
        All services deployed via Docker Compose with planned Kubernetes migration.
    </overview>

    <repository_structure>
        <dir path="proxmox/" server="ProxMoxBox (192.168.1.4)">
            <stack name="dockhand" port="3000">Docker management UI</stack>
            <stack name="homepage" port="4000">Dashboard + config/</stack>
            <stack name="homelab-tools" port="3100">Homebox asset inventory</stack>
            <stack name="minecraft" ports="25565, 19132/udp">PaperMC + Geyser/Floodgate</stack>
            <stack name="monitoring" ports="3030, 9090, 9093, 3101, 9100, 8081">Prometheus, Grafana, Loki, Alertmanager</stack>
            <stack name="nginx-proxy-manager" ports="80, 443, 81">Reverse proxy</stack>
            <stack name="uptime-kuma" port="3001">Service health monitoring</stack>
        </dir>
        <dir path="pi5/" server="Pi5 (192.168.1.234)" note="Managed via Hawser">
            <stack name="infra" ports="53, 8080">Pi-hole + Tailscale</stack>
            <stack name="mealie" port="9925">Recipe management</stack>
            <stack name="nebula-sync">Pi-hole sync</stack>
        </dir>
    </repository_structure>

    <deployment>
        <cmd name="deploy">cd proxmox/&lt;stack&gt; &amp;&amp; docker-compose up -d</cmd>
        <cmd name="update">docker-compose pull &amp;&amp; docker-compose up -d</cmd>
        <cmd name="logs">docker-compose logs -f</cmd>
    </deployment>

    <secrets_management>
        <step>Copy .env.example to .env</step>
        <step>Generate key: openssl rand -hex 32</step>
        <rule>Never commit .env files (gitignored)</rule>
    </secrets_management>

    <conventions>
        <rule>All services use restart: unless-stopped</rule>
        <rule>Docker socket mounts use :ro where write access not needed</rule>
        <rule>Data persistence via local volume mounts (./data, ./appdata)</rule>
        <rule>Service-per-directory structure with docker-compose.yaml in each</rule>
        <rule>Never use privileged: true - use specific capabilities instead</rule>
        <rule>No default password fallbacks in environment variables</rule>
        <rule>Add security_opt: no-new-privileges:true to containers</rule>
    </conventions>

    <security_hardening date="2026-02-03" commit="d403912">
        <overview>
            Security audit identified critical vulnerabilities. Applied hardening to reduce
            container escape and privilege escalation risks.
        </overview>
        <fix service="cAdvisor" file="proxmox/monitoring/docker-compose.yaml">
            <issue>privileged: true grants full host access</issue>
            <solution>Replaced with cap_add: SYS_PTRACE + security_opt: no-new-privileges:true</solution>
        </fix>
        <fix service="Grafana" file="proxmox/monitoring/docker-compose.yaml">
            <issue>Default password fallback :-admin in env var</issue>
            <solution>Removed fallback - requires explicit GRAFANA_PASSWORD in .env</solution>
        </fix>
        <fix service="Uptime Kuma" file="proxmox/uptime-kuma/docker-compose.yaml">
            <issue>Docker socket without read-only flag</issue>
            <solution>Added :ro flag to /var/run/docker.sock mount</solution>
        </fix>
        <fix service="Dockhand" file="proxmox/dockhand/docker-compose.yaml">
            <issue>Docker socket without read-only flag</issue>
            <solution>Added :ro flag to /var/run/docker.sock mount</solution>
            <note>May limit container management features - revert if needed</note>
        </fix>
        <remaining_recommendations>
            <item priority="high">Pin container images to specific versions (currently using :latest)</item>
            <item priority="medium" status="completed">Add memory/CPU limits (deploy.resources) to all services - Completed 2026-02-04</item>
            <item priority="medium">Add health checks to critical services</item>
            <item priority="low">Create isolated Docker networks for service tiers</item>
        </remaining_recommendations>
    </security_hardening>

    <resource_management date="2026-02-04" commits="e266a08, e301826">
        <overview>
            Implemented comprehensive memory limits across all 20 containers to prevent resource
            exhaustion and enable accurate monitoring. Fixed Prometheus alerts showing +Inf%.
        </overview>
        <implementation>
            <server name="ProxMoxBox" ram="8GB">
                <allocation total="9.5GB" overcommit="1.19x" status="Very safe with monitoring">
                    <service name="mc-server" limit="5GB" usage="3.93GB" />
                    <service name="prometheus" limit="768MB" usage="213MB" />
                    <service name="grafana" limit="512MB" usage="390MB" />
                    <service name="loki" limit="512MB" usage="158MB" />
                    <service name="cadvisor" limit="512MB" usage="163MB" />
                    <service name="dockhand" limit="256MB" usage="151MB" />
                    <service name="uptime-kuma" limit="256MB" usage="179MB" />
                    <service name="homepage" limit="256MB" usage="104MB" />
                    <service name="homebox" limit="256MB" usage="28MB" />
                    <service name="alertmanager" limit="128MB" usage="17MB" />
                    <service name="promtail" limit="128MB" usage="45MB" />
                    <service name="node-exporter" limit="64MB" usage="15MB" />
                    <service name="alertmanager-discord" limit="64MB" usage="1.3MB" />
                </allocation>
            </server>
            <server name="Pi5" ram="8GB">
                <note>Raspberry Pi OS lacks memory cgroup accounting - limits configured for documentation</note>
                <service name="pihole" limit="512MB" />
                <service name="tailscale" limit="256MB" />
                <service name="promtail" limit="128MB" />
                <service name="nebula-sync" limit="128MB" />
                <service name="node-exporter" limit="64MB" />
                <service name="mealie" limit="1GB" />
            </server>
        </implementation>
        <prometheus_alerts>
            <fix alert="ContainerHighMemory">
                Split into two alerts: ContainerHighMemory (percentage for limited containers)
                and ContainerHighMemoryAbsolute (GB usage for unlimited containers).
                Filters out unlimited containers (limit > 100GB) from percentage calculations.
            </fix>
            <result>100% alert actionability - no more +Inf% messages</result>
        </prometheus_alerts>
    </resource_management>
</project>

<infrastructure>
    <topology>
        <device ip="192.168.1.3" name="Primary Pi-hole" role="Main DNS (ns1.home.lab)" type="LXC" />
        <device ip="192.168.1.4" name="ProxMoxBox (Dell R430)" role="Main Docker Host, Dockhand" type="VM" />
        <device ip="192.168.1.5" name="Synology NAS (DS220j)" role="Network Storage (DSM)" type="NAS" />
        <device ip="192.168.1.6" name="Nginx Proxy Manager" role="Reverse Proxy" type="LXC" />
        <device ip="192.168.1.7" name="Wazuh VM (Debian 12)" role="SIEM v4.14.2" type="VM" />
        <device ip="192.168.1.8" name="Podcast Studio" role="Video Recording Platform (planned)" type="Docker" />
        <device ip="192.168.1.234" name="Pi5 (Raspberry Pi 5)" role="Secondary DNS, Tailscale, Mealie" type="Physical" />
        <device ip="192.168.1.253" name="Proxmox" role="Hypervisor" type="Physical" />
        <!-- Used IPs: .3, .4, .5, .6, .7, .8, .234, .253 | Next available: .9, .10 -->
    </topology>

    <access_points>
        <ssh target="ProxMoxBox">ssh root@192.168.1.4</ssh>
        <ssh target="Pi5">ssh cib@192.168.1.234</ssh>
        <ssh target="Wazuh">ssh root@192.168.1.7</ssh>
        <ssh target="Pi-hole LXC">ssh root@192.168.1.3</ssh>
        <ssh target="NPM LXC">ssh root@192.168.1.6</ssh>

        <web_interface name="Dockhand" url="http://192.168.1.4:3000" />
        <web_interface name="Homepage" url="http://192.168.1.4:4000" />
        <web_interface name="Grafana" url="http://192.168.1.4:3030" creds="admin / N0r@1251" />
        <web_interface name="Prometheus" url="http://192.168.1.4:9090" />
        <web_interface name="Alertmanager" url="http://192.168.1.4:9093" note="Discord notifications" />
        <web_interface name="Loki" url="http://192.168.1.4:3101" note="Log aggregation" />
        <web_interface name="Uptime Kuma" url="http://192.168.1.4:3001" />
        <web_interface name="Homebox" url="http://192.168.1.4:3100" />
        <web_interface name="Wazuh Dashboard" url="https://192.168.1.7" creds="admin / ddZtfWVFD+7IV64.6DJzKRBPa6wYvSbA" />
        <web_interface name="Wazuh API" url="http://192.168.1.7:55000" />
        <web_interface name="Pi-hole Primary" url="http://192.168.1.3/admin" />
        <web_interface name="Pi-hole Secondary" url="http://192.168.1.234:8080/admin" />
        <web_interface name="NPM Admin" url="http://192.168.1.6:81" />
    </access_points>

    <services>
        <server name="ProxMoxBox" ip="192.168.1.4">
            <service name="Dockhand" port="3000" stack="dockhand" />
            <service name="Homepage" port="4000" stack="homepage" />
            <service name="Homebox" port="3100" stack="homelab-tools" />
            <service name="Uptime Kuma" port="3001" stack="uptime-kuma" />
            <service name="Minecraft Java" port="25565" stack="minecraft" />
            <service name="Minecraft Bedrock" port="19132/udp" stack="minecraft" />
            <service name="Grafana" port="3030" stack="monitoring" />
            <service name="Prometheus" port="9090" stack="monitoring" />
            <service name="Alertmanager" port="9093" stack="monitoring" />
            <service name="Loki" port="3101" stack="monitoring" />
            <service name="Node Exporter" port="9100" stack="monitoring" />
            <service name="cAdvisor" port="8081" stack="monitoring" />
            <service name="NPM" ports="80, 443, 81" stack="nginx-proxy-manager" />
        </server>
        <server name="Pi5" ip="192.168.1.234">
            <service name="Pi-hole" ports="53, 8080" stack="infra" />
            <service name="Tailscale" stack="infra" />
            <service name="Mealie" port="9925" stack="mealie" />
            <service name="Nebula-sync" stack="nebula-sync" />
            <service name="Node Exporter" port="9100" />
            <service name="Promtail" />
        </server>
        <server name="Pi-hole LXC" ip="192.168.1.3">
            <service name="Pi-hole" ports="53, 80" />
            <service name="Node Exporter" port="9100" />
        </server>
        <server name="NPM LXC" ip="192.168.1.6">
            <service name="Nginx Proxy Manager" ports="80, 443, 81" />
            <service name="Node Exporter" port="9100" />
        </server>
        <server name="Wazuh VM" ip="192.168.1.7">
            <service name="Wazuh Dashboard" port="443" />
            <service name="Wazuh API" port="55000" />
            <service name="Wazuh Indexer" port="9200" />
            <service name="Agent Registration" port="1515" />
            <service name="Agent Communication" port="1514" />
            <service name="Node Exporter" port="9100" />
        </server>
    </services>

    <stack_mapping>
        <server name="ProxMoxBox">
            <git_path>proxmox/&lt;stack&gt;/</git_path>
            <deploy_path>/opt/&lt;stack&gt;/</deploy_path>
        </server>
        <server name="Pi5">
            <git_path>pi5/&lt;stack&gt;/</git_path>
            <deploy_path>/opt/pi5-stacks/&lt;stack&gt;/</deploy_path>
            <note>Managed via Hawser agent from Dockhand</note>
        </server>
    </stack_mapping>
</infrastructure>

<monitoring>
    <prometheus url="http://192.168.1.4:9090">
        <scrape_targets>
            <target job="proxmoxbox" endpoint="node-exporter:9100" />
            <target job="pi5" endpoint="192.168.1.234:9100" />
            <target job="pihole" endpoint="192.168.1.3:9100" />
            <target job="npm" endpoint="192.168.1.6:9100" />
            <target job="wazuh" endpoint="192.168.1.7:9100" />
            <target job="cadvisor" endpoint="cadvisor:8080" />
            <target job="prometheus" endpoint="localhost:9090" />
        </scrape_targets>
        <retention>30 days</retention>
    </prometheus>

    <alertmanager url="http://192.168.1.4:9093">
        <routing>Discord via alertmanager-discord bridge</routing>
        <timing group_wait="30s" group_interval="5m" repeat_interval="4h" />
    </alertmanager>

    <alerts>
        <rule name="DiskSpaceWarning" expr="disk > 80%" severity="warning" />
        <rule name="DiskSpaceCritical" expr="disk > 90%" severity="critical" />
        <rule name="HighMemoryUsage" expr="memory > 90% for 5m" severity="warning" />
        <rule name="HighCPUUsage" expr="cpu > 90% for 5m" severity="warning" />
        <rule name="HostDown" expr="unreachable 2m" severity="critical" />
        <rule name="PrometheusTargetDown" expr="scrape fail 2m" severity="critical" />
        <rule name="ContainerDown" expr="missing 2m" severity="warning" />
        <rule name="ContainerHighCPU" expr="container cpu > 80% for 5m" severity="warning" />
        <rule name="ContainerRestarting" expr="> 3x/hour" severity="warning" />
    </alerts>

    <dashboards>
        <dashboard name="Homelab Overview" uid="homelab-overview" note="Single pane of glass" />
        <dashboard name="Docker Containers" uid="docker-containers" note="Container metrics" />
        <dashboard name="Loki Logs" uid="loki-logs" />
        <dashboard name="Node Exporter Full" id="1860" source="grafana.com" />
        <dashboard name="cAdvisor" id="14282" source="grafana.com" />
    </dashboards>

    <loki url="http://192.168.1.4:3101">
        <retention>30 days</retention>
        <sources>Docker containers, syslog, auth.log from all hosts</sources>
    </loki>

    <wazuh url="https://192.168.1.7">
        <version>4.14.2</version>
        <agents>
            <agent id="001" name="SRV-DOCKER01" host="ProxMoxBox (192.168.1.4)" />
            <agent id="002" name="pi-infra" host="Pi5 (192.168.1.234)" />
            <agent id="003" name="SRV-DNS01" host="Pi-hole LXC (192.168.1.3)" />
            <agent id="004" name="SRV-NPM01" host="NPM LXC (192.168.1.6)" />
        </agents>
        <api_creds user="wazuh" note="Admin API access" />
    </wazuh>
</monitoring>
