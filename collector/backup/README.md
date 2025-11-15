# Backup and Restore: Grafana and Graylog

This directory contains scripts and instructions to backup and restore Grafana and Graylog components used in this repo.

High-level summary
- Grafana: backup dashboards (via API), provisioning files (JSON), and optionally the Grafana DB (SQLite or PostgreSQL dump). Restore by copying provisioning files and importing dashboards via the API or restoring DB file.
- Graylog: backup OpenSearch (Elasticsearch-compatible) indices using the snapshot API and backup Graylog's MongoDB using `mongodump`. Restore using OpenSearch snapshot restore and `mongorestore`.

Security and operational notes
- Store credentials (Grafana API key, OpenSearch user, MongoDB credentials) in a secure vault (HashiCorp Vault/Ansible Vault) and never directly in the scripts.
- Test restores in a staging environment before applying to production.
- Keep snapshots on a remote, durable storage (NFS, S3, or another object store). Scripts here write local tarballs; adapt them to push to object storage.

Files
- `../grafana/backup/grafana-backup.sh` — backup Grafana (dashboards + provisioning + DB). Requires GRAFANA_URL and GRAFANA_API_KEY.
- `../grafana/backup/grafana-restore.sh` — restore Grafana dashboards and optionally DB.
- `../graylog/backup/graylog-backup.sh` — backup OpenSearch snapshots and MongoDB dump. Requires OPENSEARCH_URL and MONGO_* env vars.
- `../graylog/backup/graylog-restore.sh` — restore OpenSearch snapshot and MongoDB dump. Use with caution.

Typical usage
1. Copy the scripts to the infra-monitoring host (or run from a management host that can reach services).
2. Export required environment variables (or use a wrapper that reads secrets from Vault/Ansible Vault):

```bash
export GRAFANA_URL=https://grafana.example.local
export GRAFANA_API_KEY=eyJr:...
export OPENSEARCH_URL=http://graylog-opensearch:9200
export MONGO_HOST=127.0.0.1
export MONGO_PORT=27017
export MONGO_USER=graylog
export MONGO_PASSWORD=secret
```

3. Run the backup script and copy the produced archive to durable storage.

Restore checklist (summary)
- Stop or pause ingestion in Graylog (so new messages don't interfere with restore).
- Restore MongoDB first (mongorestore) then restore OpenSearch snapshot.
- For Grafana, restore provisioning files and import dashboards via API; optionally restore DB if you want historical user/session metadata preserved.

If you want, I can wire these into an Ansible playbook (uses Ansible Vault for secrets) and add a scheduled cron job for rotating backups.
