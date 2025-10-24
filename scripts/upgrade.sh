#!/bin/bash
# Usage: ./scripts/upgrade.sh
# Reads the Appwrite version from .appwrite-version and runs the upgrade container
# @see https://appwrite.io/docs/advanced/self-hosting/production/updates#install-next-version
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"
load_env

if [ ! -f .appwrite-version ]; then
  echo "[ERROR] .appwrite-version file not found. Run 'npm run bump <version>' first."
  exit 1
fi

VERSION=$(cat .appwrite-version)
echo "[INFO] Upgrading Appwrite stack to version $VERSION..."
docker run -it --rm \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume $(pwd):/usr/src/code/appwrite:rw \
  --entrypoint=upgrade \
  appwrite/appwrite:$VERSION
