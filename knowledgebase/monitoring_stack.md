# Monitoring Stack - Knowledge Base

This stack deploys Graphite, Graylog (with MongoDB and OpenSearch), Grafana, and a monitoring_proxy (Nginx) container in Docker. All persistent data lives under `/opt/docker_volumes` to simplify backup and recovery.

## Backup and Restore

- Backup: Recursively back up `/opt/docker_volumes`.
  - This includes all application data, configs, dashboards, and journals.
- Restore:
  1. Restore `/opt/docker_volumes` to the target host with the same paths and permissions.
  2. Re-run `ansible/playbooks/infra-monitoring.yml` against the host.
  3. Containers will be recreated and reattach to the restored volumes.

No database-level exports are required; volumes contain everything.

## Component summary

- Graphite (graphiteapp/graphite-statsd)
  - Volumes: `/opt/docker_volumes/graphite/{storage,config}`
  - Ports: 2003, 2004, 8125/udp, 8126, 8080 (default mapping; adjust via vars)
- Graylog 6.3.5 + MongoDB 6 + OpenSearch 2.11.1
  - Volumes:
    - `/opt/docker_volumes/graylog/mongo/data`
    - `/opt/docker_volumes/graylog/opensearch/data`
    - `/opt/docker_volumes/graylog/graylog/{data,journal}`
  - Ports: 9000 (UI), 1514/tcp+udp (syslog), 12201/udp (GELF). Change via vars.
  - Requires sysctl: `vm.max_map_count=262144`.
- Grafana
  - Volumes: `/opt/docker_volumes/grafana/{data,provisioning}`
  - Ports: internal only by default (proxied via Nginx).
- monitoring_proxy (Nginx reverse proxy)
  - Volumes: `/opt/docker_volumes/monitoring-proxy/{conf,conf.d,certs,logs}`
  - Ports: 80 and 443 published.

## TLS

TLS is optional and disabled by default. When enabled, monitoring_proxy terminates HTTPS and backend services remain on the internal network.

## Secrets

- Graylog requires `graylog_password_secret` and `graylog_root_password_sha2`.
  - Store in Ansible Vault or fetch from Hashicorp Vault via Jenkins pipeline.
- Grafana admin credentials are variables; set via Vault in production.
- Vault PKI settings: supply `VAULT_APPROLE_ROLE_ID` and `VAULT_APPROLE_SECRET_ID` via Jenkins withVault (or use a Vault token), and ensure a PKI role (e.g., `internal`) exists with appropriate policies.

## Running

- Install collections (pipeline does this): `community.docker`, `ansible.posix`, `community.general`.
- Execute the playbook against your target inventory group.

## Notes

- All roles use named Docker volumes bound to host directories under `/opt/docker_volumes`.
- Nginx proxies only HTTP/HTTPS. Non-HTTP inputs (e.g., Graylog syslog/GELF, Graphite plaintext/UDP) are published directly on the host.
