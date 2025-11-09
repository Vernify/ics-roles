#!/usr/bin/env bash
# Graylog backup script
# - Triggers an OpenSearch snapshot for indices matching graylog_*
# - Performs a mongodump of the Graylog MongoDB

set -euo pipefail

: "Ensure required env vars are set"
if [ -z "${OPENSEARCH_URL:-}" ]; then
  echo "Please set OPENSEARCH_URL (e.g. http://graylog-opensearch:9200)"
  exit 1
fi

OUT_DIR="./graylog-backups"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$OUT_DIR"

# Snapshots: repository name used here is 'backup_repo'. You must pre-configure an FS or S3 repository in OpenSearch
REPO_NAME=${OPENSEARCH_SNAPSHOT_REPO:-backup_repo}
SNAP_NAME="graylog-snap-$TIMESTAMP"

echo "Creating OpenSearch snapshot: repo=$REPO_NAME snapshot=$SNAP_NAME"
curl -sS -X PUT "$OPENSEARCH_URL/_snapshot/$REPO_NAME/$SNAP_NAME?wait_for_completion=true" -H 'Content-Type: application/json' -d'
{
  "indices": "graylog_*",
  "ignore_unavailable": true,
  "include_global_state": false
}
'

if [ $? -ne 0 ]; then
  echo "OpenSearch snapshot request failed"
fi

echo "Snapshot created with name: $SNAP_NAME (verify repository storage)") || true

echo "Running MongoDB dump..."
MONGO_ARGS=(--host "${MONGO_HOST:-127.0.0.1}" --port "${MONGO_PORT:-27017}")
if [ -n "${MONGO_USER:-}" ]; then
  MONGO_ARGS+=(--username "$MONGO_USER")
fi
if [ -n "${MONGO_PASSWORD:-}" ]; then
  export MONGO_PWD="$MONGO_PASSWORD"
  # use --authenticationDatabase if needed
fi

DUMP_DIR="$OUT_DIR/mongo-dump-$TIMESTAMP"
mkdir -p "$DUMP_DIR"
if command -v mongodump >/dev/null 2>&1; then
  mongodump "${MONGO_ARGS[@]}" --out "$DUMP_DIR"
else
  echo "mongodump not found in PATH; run this script on the host with MongoDB client installed"
fi

ARCHIVE="$OUT_DIR/graylog-backup-$TIMESTAMP.tar.gz"
tar -czf "$ARCHIVE" -C "$OUT_DIR" "mongo-dump-$TIMESTAMP"

echo "Graylog backup archive: $ARCHIVE"
echo "OpenSearch snapshot: $SNAP_NAME (repository: $REPO_NAME)"

echo "Tip: move $ARCHIVE to durable storage and verify OpenSearch repository storage contains the snapshot files."
