#!/bin/bash
# Patch docker-compose.yml to ensure appwrite service is attached to 'runtimes' network
# Usage: ./scripts/fix-appwrite-network.sh
set -e

COMPOSE_FILE="$(dirname "$0")/../docker-compose.yml"
NETWORK_NAME="runtimes"
SERVICE_NAME="appwrite"

# Check if 'runtimes' is already in the appwrite service networks
if yq e ".services.${SERVICE_NAME}.networks[]" "$COMPOSE_FILE" | grep -q "$NETWORK_NAME"; then
  echo "[INFO] Network '$NETWORK_NAME' already present in '$SERVICE_NAME' service."
else
  echo "[INFO] Adding network '$NETWORK_NAME' to '$SERVICE_NAME' service..."
  yq e ".services.${SERVICE_NAME}.networks += [\"${NETWORK_NAME}\"]" -i "$COMPOSE_FILE"
  echo "[INFO] Network '$NETWORK_NAME' added."
fi

# Recreate containers to apply network changes
npm run up:recreate
