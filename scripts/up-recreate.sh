#!/bin/bash
# Usage: ./scripts/up-recreate.sh
# Starts all Appwrite containers, forcing recreation
set -e

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"
load_env

docker compose up -d --remove-orphans --force-recreate
