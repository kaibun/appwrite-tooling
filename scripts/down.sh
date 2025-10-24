#!/bin/bash
# Usage: ./scripts/down.sh
# Stops all Appwrite containers
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"
load_env

docker compose down
