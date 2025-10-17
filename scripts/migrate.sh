#!/bin/bash
# Usage: ./scripts/migrate.sh
# Reads the Appwrite version from .appwrite-version and runs the migration container
# @see https://appwrite.io/docs/advanced/self-hosting/production/updates#running-the-migration
set -e
if [ ! -f .appwrite-version ]; then
  echo "[ERROR] .appwrite-version file not found. Run 'npm run bump <version>' first."
  exit 1
fi
VERSION=$(cat .appwrite-version)
echo "[INFO] Running Appwrite migration for version $VERSION..."
docker run -it --rm \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume $(pwd):/usr/src/code/appwrite:rw \
  --entrypoint=migrate \
  appwrite/appwrite:$VERSION
