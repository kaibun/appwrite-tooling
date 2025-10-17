#!/bin/bash
# Usage: ./scripts/migrate.sh
# Reads the Appwrite version from .appwrite-version and runs the migration container
# @see https://appwrite.io/docs/advanced/self-hosting/production/updates#running-the-migration
set -e

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR/utils.sh"
load_env

if [ ! -f .appwrite-version ]; then
  echo "[ERROR] .appwrite-version file not found. Run 'npm run bump <version>' first."
  exit 1
fi
VERSION=$(cat .appwrite-version)
echo "[INFO] Starting all Appwrite services before migration..."
start_appwrite_services
echo "[INFO] Running Appwrite migration for version $VERSION..."
docker compose exec appwrite migrate
echo "[INFO] Migration completed."
