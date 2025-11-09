#!/usr/bin/env bash
# Grafana restore helper (imports dashboards and copies provisioning files)

set -euo pipefail

if [ -z "${GRAFANA_URL:-}" ] || [ -z "${GRAFANA_API_KEY:-}" ]; then
  echo "Please set GRAFANA_URL and GRAFANA_API_KEY environment variables"
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-to-backup-tar.gz>"
  exit 1
fi

BACKUP_TAR=$1
TMP_DIR=$(mktemp -d)
tar -xzf "$BACKUP_TAR" -C "$TMP_DIR"

echo "Restoring provisioning files (if present)..."
# Optionally copy provisioning files back to Grafana provisioning directory. This typically requires host access.
if [ -d "$TMP_DIR/datasources" ] || [ -d "$TMP_DIR/dashboards" ]; then
  echo "Provisioning files are present in the archive. Copy them to the Grafana provisioning directory on host manually or via Ansible."
fi

if [ -d "$TMP_DIR/dashboards" ]; then
  echo "Importing dashboards via API..."
  for f in "$TMP_DIR/dashboards"/*.json; do
    if [ ! -f "$f" ]; then
      continue
    fi
    echo "Importing $f"
    # Grafana expects { dashboard: {...}, overwrite: true, folderId: 0 }
    DASH_JSON=$(jq '{dashboard: .dashboard, overwrite: true}' "$f")
    curl -sS -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${GRAFANA_API_KEY}" -d "$DASH_JSON" "${GRAFANA_URL}/api/dashboards/db" | jq .
  done
fi

echo "Note: If you restored a DB file (sqlite or Postgres), you must stop Grafana, replace DB, and start Grafana."
rm -rf "$TMP_DIR"

echo "Grafana restore finished (dashboards imported). Verify in the Grafana UI."
