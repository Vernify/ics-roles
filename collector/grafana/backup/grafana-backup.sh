#!/usr/bin/env bash
# Grafana backup script
# - Exports all dashboards via API
# - Archives provisioning files
# - Optionally dumps Grafana DB (sqlite or PostgreSQL)

set -euo pipefail

if [ -z "${GRAFANA_URL:-}" ] || [ -z "${GRAFANA_API_KEY:-}" ]; then
  echo "Please set GRAFANA_URL and GRAFANA_API_KEY environment variables"
  exit 1
fi

OUT_DIR="./grafana-backups"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
TMP_DIR=$(mktemp -d)
mkdir -p "$OUT_DIR"

echo "Fetching list of dashboards from Grafana..."
# Fetch dashboards (dash-db type) and extract uids
DASH_UIDS=$(curl -sS -H "Authorization: Bearer ${GRAFANA_API_KEY}" "${GRAFANA_URL}/api/search?query=&type=dash-db" | jq -r '.[].uid')

mkdir -p "$TMP_DIR/dashboards"
for uid in $DASH_UIDS; do
  echo "Exporting dashboard uid=$uid"
  curl -sS -H "Authorization: Bearer ${GRAFANA_API_KEY}" "${GRAFANA_URL}/api/dashboards/uid/$uid" | jq '. | {dashboard: .dashboard, meta: .meta}' > "$TMP_DIR/dashboards/$uid.json"
done

echo "Copying provisioning files (if present)..."
# Adjust path to where you keep provisioning files in this repo
if [ -d "$(pwd)/../../collector/grafana/datasources" ]; then
  cp -a "$(pwd)/../../collector/grafana/datasources" "$TMP_DIR/" || true
fi
if [ -d "$(pwd)/../../collector/grafana/dashboards" ]; then
  cp -a "$(pwd)/../../collector/grafana/dashboards" "$TMP_DIR/" || true
fi

DB_BACKUP=""
if [ -n "${GRAFANA_DB_PATH:-}" ]; then
  echo "Backing up Grafana DB at $GRAFANA_DB_PATH"
  cp "$GRAFANA_DB_PATH" "$TMP_DIR/grafana.db" || true
  DB_BACKUP=true
fi

ARCHIVE="$OUT_DIR/grafana-backup-$TIMESTAMP.tar.gz"
tar -czf "$ARCHIVE" -C "$TMP_DIR" .
echo "Grafana backup created: $ARCHIVE"

# cleanup
rm -rf "$TMP_DIR"

echo "Done. Copy $ARCHIVE to durable storage (S3/NFS) and secure it."
