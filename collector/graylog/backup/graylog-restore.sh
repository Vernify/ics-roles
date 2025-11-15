#!/usr/bin/env bash
# Graylog restore script (high-level helper)
# WARNING: Restoring data is destructive. Read the README and test in staging.

set -euo pipefail

if [ -z "${OPENSEARCH_URL:-}" ]; then
  echo "Please set OPENSEARCH_URL"
  exit 1
fi

if [ $# -lt 2 ]; then
  echo "Usage: $0 <snapshot_repo> <snapshot_name>"
  echo "Example: $0 backup_repo graylog-snap-20250101T000000Z"
  exit 1
fi

REPO=$1
SNAP=$2

echo "Restoring OpenSearch snapshot $SNAP from repo $REPO"
curl -sS -X POST "$OPENSEARCH_URL/_snapshot/$REPO/$SNAP/_restore" -H 'Content-Type: application/json' -d'
{
  "indices": "graylog_*",
  "ignore_unavailable": true,
  "include_global_state": false
}
'

echo "Restore requested. Monitor OpenSearch restore status via cat $OPENSEARCH_URL/_cat/recovery or _snapshot status."

echo "MongoDB restore: use mongorestore to import the dump produced by the backup script. Example:"
echo "  mongorestore --host <host> --port <port> /path/to/mongo-dump"

echo "Important: After restore, restart Graylog and validate indices and messages."
