# Graylog + OpenSearch: startup and proxy troubleshooting

Applies to: Graylog 6.3.5, OpenSearch 2.11.1, monitoring_proxy (Nginx) container

Summary
- Symptom: Graylog UI 502 via proxy; Graylog logs show repeated connection refused to OpenSearch; OpenSearch container fails to create data/nodes with AccessDeniedException.
- Root cause: Bound OpenSearch data directory on host was owned by root; OpenSearch image runs as UID/GID 1000 and could not write.
- Fix: Ensure `/opt/docker_volumes/graylog/opensearch/data` is owned by UID/GID 1000 and mode 0775 before (re)starting OpenSearch.

How we fixed it (Ansible)
- Ownership and permissions for OpenSearch data dir:
  - Defaults: `graylog_opensearch_user_id: 1000`, `graylog_opensearch_group_id: 1000`.
  - Task: `ansible.builtin.file` on `/opt/docker_volumes/graylog/opensearch/data` with `owner`, `group`, `mode: '0775'`.
- Readiness wait: Ensure OpenSearch API is reachable before starting Graylog.
- Graylog-to-OpenSearch config: Use env `GRAYLOG_OPENSEARCH_HOSTS` (e.g., `http://graylog-opensearch:9200`) and matching settings in `graylog.conf`.

Run the role
- Apply Graylog stack:
  - ansible-playbook ... --tags graylog
- Optional: wipe data (not for production):
  - ansible-playbook ... --tags graylog -e graylog_reset_data=true

Verify via monitoring_proxy
- ansible-playbook ... --tags verify
- Expect HTTP 200 for Graphite, Grafana, and Graylog with Host headers.
- If you see connection refused, retry after a short delay or ensure host firewall allows inbound 80/443.

Notes
- The proxy uses host-based routing; only one default_server is defined.
- Health checks: OpenSearch must be up before Graylog transitions to healthy.
- Required sysctl: `vm.max_map_count=262144` (set via `monitoring_common`).
