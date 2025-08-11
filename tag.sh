#!/bin/bash
# tag.sh - Tag the current commit with a version number, force-move the tag if it already exists, and push to origin.
# Usage: ./tag.sh 1.0.0

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

VERSION="$1"
TAG="$VERSION"

echo "Tagging current commit as $TAG (force if exists) and pushing to origin..."

git tag -f -a "$TAG" -m "Release version $VERSION"
git push origin "$TAG" --force

echo "Tag $TAG has been created and pushed to origin."
