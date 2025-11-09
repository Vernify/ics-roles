#!/usr/bin/env bash
# Small helper to (re)build and install the local Ansible collection during development.
# Usage: ./force_local.sh [path-to-collection-root]
# Default path uses this script's repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${1:-$SCRIPT_DIR}"

echo "[force_local] Working directory: ${ROOT_DIR}"
cd "$ROOT_DIR"

if ! command -v ansible-galaxy >/dev/null 2>&1; then
	echo "ERROR: ansible-galaxy not found in PATH. Ensure Ansible is installed." >&2
	exit 2
fi

echo "[force_local] Building collection (force)..."
ansible-galaxy collection build --force

artifact=$(ls -1t *.tar.gz 2>/dev/null | head -n1 || true)
if [ -z "$artifact" ]; then
	echo "ERROR: no collection artifact found after build" >&2
	exit 3
fi

echo "[force_local] Installing artifact: $artifact"

# Determine namespace and collection name from artifact filename (format: namespace-name-version.tar.gz)
artifact_base="${artifact%.tar.gz}"
IFS='-' read -r artifact_namespace artifact_name _rest <<<"$artifact_base"

# Candidate install paths to remove before installing to ensure a clean replacement
repo_local_path="$ROOT_DIR/.ansible/collections/ansible_collections/${artifact_namespace}/${artifact_name}"
user_collections_root="${ANSIBLE_COLLECTIONS_PATHS:-$HOME/.ansible/collections}"
user_install_path="$user_collections_root/ansible_collections/${artifact_namespace}/${artifact_name}"

echo "[force_local] Removing any deployed copies to ensure a clean install (if present)"
if [ -d "$repo_local_path" ]; then
	echo "[force_local] Removing repo-local installed collection: $repo_local_path"
	rm -rf -- "$repo_local_path"
fi

if [ -d "$user_install_path" ]; then
	echo "[force_local] Removing user-installed collection: $user_install_path"
	rm -rf -- "$user_install_path"
fi

ansible-galaxy collection install --force "$artifact"

echo "[force_local] Installed $artifact"
echo "[force_local] To use the collection in a playbook, ensure your ansible.cfg/collections_path or ANSIBLE_COLLECTIONS_PATHS includes the user collection path (default is ~/.ansible/collections)."

exit 0
