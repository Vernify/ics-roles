# Monitoring Backup Role

Automated backup and restoration solution for Grafana and Graylog monitoring stack.

## Features

- **Automated Backups**: Scheduled daily backups with retention policies
- **Multiple Services**: Supports Grafana and Graylog
- **Grafana Backup**: Dashboards (via API), provisioning files, configuration, optional database
- **Graylog Backup**: OpenSearch snapshots and MongoDB data
- **Retention Policies**: Daily, weekly, and monthly backups with configurable retention
- **Encryption**: Optional AES-256-CBC encryption for backup archives
- **Verification**: Automated backup integrity checks
- **Monitoring**: Health checks with alerting for missing or stale backups
- **Restoration**: Helper scripts for disaster recovery
- **Logging**: Comprehensive logging with logrotate integration

## Requirements

- Ansible 2.9 or higher
- Target systems: Ubuntu 20.04+, CentOS 7+, Rocky Linux 9+, Oracle Linux 8+, Fedora 20+
- Tools: `curl`, `jq`, `tar`, `openssl`, `mongodump`, `mongorestore`
- API access to Grafana and OpenSearch
- MongoDB credentials for Graylog

## Role Variables

### Core Settings

```yaml
monitoring_backup_enabled: true
monitoring_backup_base_dir: "/opt/backups"
monitoring_backup_retention_days: 7
monitoring_backup_retention_weeks: 4
monitoring_backup_retention_months: 2
monitoring_backup_schedule_wrapper: "0 1 * * *"  # Daily at 1 AM
monitoring_backup_schedule_monitor: "0 10 * * *"  # Daily at 10 AM
monitoring_backup_compression: true
```

### Encryption

```yaml
monitoring_backup_encryption_enabled: false
monitoring_backup_encryption_key_file: "/opt/backups/.encryption_key"
```

### Grafana Settings

```yaml
monitoring_backup_grafana_enabled: true
monitoring_backup_grafana_api_url: "http://localhost:3000"
monitoring_backup_grafana_api_key: ""  # Store in Vault
monitoring_backup_grafana_config_dir: "/etc/grafana"
monitoring_backup_grafana_data_dir: "/var/lib/grafana"
monitoring_backup_grafana_db_enabled: false
monitoring_backup_grafana_db_type: "sqlite3"  # sqlite3 or postgres
```

### Graylog Settings

```yaml
monitoring_backup_graylog_enabled: true
monitoring_backup_graylog_opensearch_url: "http://localhost:9200"
monitoring_backup_graylog_opensearch_username: "admin"
monitoring_backup_graylog_opensearch_password: ""  # Store in Vault
monitoring_backup_graylog_opensearch_repository: "graylog_backup"
monitoring_backup_graylog_opensearch_snapshot_location: "/mnt/opensearch_backups"
monitoring_backup_graylog_mongo_host: "localhost"
monitoring_backup_graylog_mongo_database: "graylog"
monitoring_backup_graylog_mongo_username: "grayloguser"
monitoring_backup_graylog_mongo_password: ""  # Store in Vault
```

See `defaults/main.yml` for complete variable list.

## Dependencies

None.

## Example Playbook

```yaml
---
- name: Configure monitoring backups
  hosts: monitoring_servers
  become: true
  
  vars:
    monitoring_backup_grafana_api_key: "{{ vault_grafana_api_key }}"
    monitoring_backup_graylog_opensearch_password: "{{ vault_opensearch_password }}"
    monitoring_backup_graylog_mongo_password: "{{ vault_mongo_password }}"
    monitoring_backup_encryption_enabled: true
  
  roles:
    - ics.roles.monitoring_backup
```

## Backup Structure

```
/opt/backups/
├── grafana/
│   ├── daily/
│   │   └── grafana_backup_20240315_010000.tar.gz
│   ├── weekly/
│   └── monthly/
├── graylog/
│   ├── daily/
│   │   ├── graylog_backup_20240315_010000.tar.gz
│   │   └── opensearch_snapshot_20240315_010000.txt
│   ├── weekly/
│   └── monthly/
└── .encryption_key (if encryption enabled)
```

## Scripts Deployed

| Script | Purpose | Location |
|--------|---------|----------|
| `grafana_backup.sh` | Backup Grafana | `/usr/local/bin/` |
| `graylog_backup.sh` | Backup Graylog | `/usr/local/bin/` |
| `monitoring_backup_cleanup.sh` | Cleanup old backups | `/usr/local/bin/` |
| `monitoring_backup_verify.sh` | Verify backup integrity | `/usr/local/bin/` |
| `monitoring_backup_restore.sh` | Restore from backup | `/usr/local/bin/` |
| `monitoring_backup_monitor.sh` | Health checks | `/usr/local/bin/` |
| `monitoring_backup_wrapper.sh` | Orchestration | `/usr/local/bin/` |

## Manual Operations

### Verify Backups

```bash
# Verify latest backups for all services
monitoring_backup_verify.sh all latest

# Verify specific service
monitoring_backup_verify.sh grafana latest
monitoring_backup_verify.sh graylog latest

# Verify specific backup file
monitoring_backup_verify.sh grafana /opt/backups/grafana/daily/grafana_backup_20240315_010000.tar.gz
```

### Restore Backups

```bash
# Restore Grafana
monitoring_backup_restore.sh grafana /opt/backups/grafana/daily/grafana_backup_20240315_010000.tar.gz

# Restore Graylog (provides instructions)
monitoring_backup_restore.sh graylog /opt/backups/graylog/daily/graylog_backup_20240315_010000.tar.gz
```

### Check Backup Health

```bash
monitoring_backup_monitor.sh
```

### Manual Backup

```bash
# Backup Grafana
grafana_backup.sh

# Backup Graylog
graylog_backup.sh

# Run full orchestration
monitoring_backup_wrapper.sh
```

## Security Considerations

- All backup directories have `700` permissions (root only)
- Backup files have `600` permissions (root only)
- Scripts have `750` permissions (root owner, root group)
- API keys and passwords should be stored in Ansible Vault
- Encryption key file has `600` permissions if encryption enabled
- Logs are readable by system administrators (`644`)

## Monitoring Integration

The role includes a monitoring script that checks:
- Backup freshness (alerts if >26 hours old)
- Backup counts (alerts if no daily backups)
- Storage space usage (alerts if >90% full)

Integrate with your monitoring stack (Graphite, Graylog, Grafana) by:
1. Parsing `/var/log/backups/monitor.log`
2. Checking exit code of `monitoring_backup_monitor.sh`
3. Setting up alerts based on "ALERT:" messages in logs

## Troubleshooting

### Grafana API Errors

Ensure API key has Admin role:
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" http://localhost:3000/api/admin/settings
```

### OpenSearch Snapshot Repository

Check repository registration:
```bash
curl -u admin:password http://localhost:9200/_snapshot/graylog_backup
```

### MongoDB Connection

Test connectivity:
```bash
mongosh --host localhost --port 27017 -u grayloguser -p password --authenticationDatabase admin
```

### Encryption Issues

Verify encryption key exists and is readable:
```bash
ls -l /opt/backups/.encryption_key
```

### Log Files

Check logs in `/var/log/backups/`:
- `grafana_backup.log`
- `graylog_backup.log`
- `cleanup.log`
- `verify.log`
- `monitor.log`
- `wrapper.log`

## License

MIT

## Author Information

ICS Infrastructure Team
