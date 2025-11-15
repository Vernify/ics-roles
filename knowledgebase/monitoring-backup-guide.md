# Monitoring Backup Guide

Quick reference for backup and restoration operations using the `monitoring_backup` role.

## Prerequisites

- `monitoring_backup` role deployed to monitoring servers
- Grafana API key with Admin role
- OpenSearch credentials
- MongoDB credentials

## Daily Operations

### Check Backup Status

```bash
# Health check
monitoring_backup_monitor.sh

# View logs
tail -f /var/log/backups/wrapper.log
tail -f /var/log/backups/monitor.log
```

### Manual Backup

```bash
# Backup Grafana only
grafana_backup.sh

# Backup Graylog only
graylog_backup.sh

# Run full backup cycle
monitoring_backup_wrapper.sh
```

### Verify Backups

```bash
# Verify latest backups
monitoring_backup_verify.sh all latest

# Verify specific service
monitoring_backup_verify.sh grafana latest
monitoring_backup_verify.sh graylog latest

# Verify specific backup file
monitoring_backup_verify.sh grafana /opt/backups/grafana/daily/grafana_backup_20240315_010000.tar.gz
```

## Backup Schedule

- **Daily backups**: 1:00 AM (retention: 7 days)
- **Weekly backups**: Sunday 1:00 AM (retention: 4 weeks)
- **Monthly backups**: 1st of month 1:00 AM (retention: 2 months)
- **Health checks**: 10:00 AM daily

## Restoration Procedures

### Restore Grafana

```bash
# Stop Grafana (if running standalone)
systemctl stop grafana-server

# Or stop Docker container
docker stop grafana

# Run restoration
monitoring_backup_restore.sh grafana /opt/backups/grafana/daily/grafana_backup_20240315_010000.tar.gz

# Restart Grafana
systemctl start grafana-server
# Or
docker start grafana
```

### Restore Graylog

**Critical**: Graylog restoration requires manual steps.

1. **Stop Graylog**:
```bash
docker stop graylog
```

2. **Check snapshot information**:
```bash
cat /opt/backups/graylog/daily/opensearch_snapshot_20240315_010000.txt
```

3. **Restore OpenSearch snapshot**:
```bash
# List available snapshots
curl -u admin:password http://localhost:9200/_snapshot/graylog_backup/_all

# Restore specific snapshot
curl -X POST -u admin:password \
  "http://localhost:9200/_snapshot/graylog_backup/snapshot_20240315_010000/_restore" \
  -H 'Content-Type: application/json' \
  -d '{
    "indices": "graylog_*",
    "ignore_unavailable": true,
    "include_global_state": false
  }'

# Monitor restoration progress
curl -u admin:password http://localhost:9200/_recovery
```

4. **Restore MongoDB**:
```bash
# Extract backup
tar -xzf /opt/backups/graylog/daily/graylog_backup_20240315_010000.tar.gz -C /tmp/

# Restore to MongoDB
mongorestore --host localhost --port 27017 \
  --username grayloguser --password <password> \
  --authenticationDatabase admin \
  --db graylog /tmp/graylog/
```

5. **Start Graylog**:
```bash
docker start graylog
```

6. **Verify**:
- Log into Graylog web interface
- Check indices: System → Indices
- Verify data by searching recent logs

## Backup Locations

```
/opt/backups/
├── grafana/
│   ├── daily/       # Last 7 days
│   ├── weekly/      # Last 4 weeks
│   └── monthly/     # Last 2 months
└── graylog/
    ├── daily/       # Last 7 days
    ├── weekly/      # Last 4 weeks
    └── monthly/     # Last 2 months
```

## Troubleshooting

### Grafana API Errors

**Symptom**: Dashboard export fails with authentication errors.

**Solution**: Verify API key has Admin role:
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/admin/settings
```

Create new API key if needed:
- Grafana UI → Configuration → API Keys
- Role: Admin
- Update role variable: `monitoring_backup_grafana_api_key`

### OpenSearch Snapshot Failures

**Symptom**: Snapshot creation fails.

**Solution**: Check repository configuration:
```bash
# View repository
curl -u admin:password http://localhost:9200/_snapshot/graylog_backup

# Check repository location permissions
ls -la /mnt/opensearch_backups

# Ensure opensearch user can write
chown -R 1000:1000 /mnt/opensearch_backups
```

### MongoDB Connection Issues

**Symptom**: `mongodump` fails with authentication error.

**Solution**: Test MongoDB connection:
```bash
mongosh --host localhost --port 27017 \
  -u grayloguser -p <password> \
  --authenticationDatabase admin

# If authentication works, check database exists
show dbs
use graylog
show collections
```

### Backup Space Issues

**Symptom**: Disk full, backups failing.

**Solution**: 
```bash
# Check disk usage
df -h /opt/backups

# Review backup sizes
du -sh /opt/backups/*/daily/*
du -sh /opt/backups/*/weekly/*
du -sh /opt/backups/*/monthly/*

# Force cleanup if needed
monitoring_backup_cleanup.sh

# Adjust retention if necessary (edit Ansible variables)
```

### Encrypted Backup Issues

**Symptom**: Cannot decrypt backup.

**Solution**: Verify encryption key:
```bash
# Check key exists
ls -la /opt/backups/.encryption_key

# Test decryption
openssl enc -aes-256-cbc -d \
  -in /opt/backups/grafana/daily/grafana_backup_20240315_010000.tar.gz.enc \
  -out /tmp/test.tar.gz \
  -pass file:/opt/backups/.encryption_key

# Verify decrypted archive
tar -tzf /tmp/test.tar.gz | head
```

## Monitoring Integration

Monitor backup health by:

1. **Log Monitoring**: Parse `/var/log/backups/monitor.log` for "ALERT:" messages
2. **Exit Codes**: Monitor exit code of `monitoring_backup_monitor.sh`
3. **Grafana Dashboard**: Create dashboard tracking:
   - Backup age (hours)
   - Backup sizes
   - Success/failure rates
   - Disk space usage

## Security Notes

- All backup files: `root:root` with `600` permissions
- Backup directories: `700` permissions
- API keys and passwords: Store in Ansible Vault
- Encryption key: `600` permissions, never commit to version control
- Access logs regularly audited

## Contact

For issues not covered by this guide, contact the Infrastructure Team.
