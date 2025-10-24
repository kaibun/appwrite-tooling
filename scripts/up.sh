#!/bin/bash
# Usage: ./scripts/up.sh
# Starts all Appwrite containers
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"
load_env

docker compose up -d --remove-orphans
