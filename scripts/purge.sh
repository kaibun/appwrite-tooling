#!/bin/bash
# Usage: ./scripts/purge.sh
# Permanently deletes all backups after user confirmation
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"
load_env

BACKUP_DIR="./backups"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "No backups directory found. Nothing to purge."
  exit 0
fi

echo "[DANGER] This will permanently delete ALL backups in $BACKUP_DIR."
read -p "Are you sure you want to continue? (yes/NO): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted. No backups were deleted."
  exit 1
fi

rm -rf "$BACKUP_DIR"/*
echo "All backups have been purged from $BACKUP_DIR."
