#!/bin/bash
# Script to identify potentially merged branches after squash merges
# Run this in your git repository

echo "Checking for branches that may be safe to delete..."
echo "=================================================="

for branch in $(git branch --format='%(refname:short)' | grep -v main | grep -v HEAD); do
  if [ -z "$(git log --oneline main..$branch 2>/dev/null)" ]; then
    echo "✓ Branch '$branch' appears merged (no unique commits)"
    echo "  Safe to delete: git branch -d $branch"
  else
    unique_commits=$(git log --oneline main..$branch 2>/dev/null | wc -l)
    echo "✗ Branch '$branch' has $unique_commits unique commits"
    echo "  Keep this branch"
  fi
  echo
done

echo "For remote branches, check:"
echo "git branch -r | grep -v main"
echo "Then delete with: git push origin --delete <branch-name>"