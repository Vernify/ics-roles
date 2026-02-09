#!/bin/bash
# Script to identify potentially merged branches after squash merges
# Checks if branch changes are already in main (diff is empty)
# Run this in your git repository

echo "Checking for branches that may be safe to delete..."
echo "=================================================="

for branch in $(git branch --format='%(refname:short)' | grep -v main | grep -v HEAD); do
  if [ -z "$(git diff main...$branch 2>/dev/null)" ]; then
    echo "✓ Branch '$branch' appears merged (no differences with main)"
    echo "  Safe to delete: git branch -d $branch"
  else
    diff_lines=$(git diff main...$branch 2>/dev/null | wc -l)
    echo "✗ Branch '$branch' has $diff_lines lines of differences"
    echo "  Keep this branch"
  fi
  echo
done

echo "For remote branches, check:"
echo "git branch -r | grep -v main"
echo "Then delete with: git push origin --delete <branch-name>"