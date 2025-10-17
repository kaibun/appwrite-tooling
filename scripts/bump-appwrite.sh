#!/bin/bash
# Usage: ./scripts/bump-appwrite.sh <appwrite-version>
# Example: ./scripts/bump-appwrite.sh 1.8.0-RC4
# Requires: yq (https://github.com/mikefarah/yq), curl, diff

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <appwrite-version> (e.g. 1.8.0-RC4)"
  exit 1
fi

VERSION="$1"
REMOTE_COMPOSE_URL="https://github.com/appwrite/appwrite/raw/${VERSION}/docker-compose.yml"
LOCAL_COMPOSE="./docker-compose.yml"
TMP_REMOTE="/tmp/appwrite-compose-remote.yml"
TMP_NEW="/tmp/appwrite-compose-new.yml"

# Check dependencies
yq --version >/dev/null 2>&1 || { echo "[ERROR] yq is required (https://github.com/mikefarah/yq)"; exit 1; }
curl --version >/dev/null 2>&1 || { echo "[ERROR] curl is required"; exit 1; }
diff --version >/dev/null 2>&1 || { echo "[ERROR] diff is required"; exit 1; }

# Download remote compose
echo "Downloading official docker-compose.yml for Appwrite $VERSION..."
curl -fsSL "$REMOTE_COMPOSE_URL" -o "$TMP_REMOTE"

# Copy local compose for editing
cp "$LOCAL_COMPOSE" "$TMP_NEW"


# For each service in local compose, update image tag if present in remote
echo "Updating image tags based on official compose..."
IMAGE_CHANGE_LOG=""
SERVICES=$(yq --yaml-fix-merge-anchor-to-spec=true e '.services | keys | .[]' "$LOCAL_COMPOSE")
for SVC in $SERVICES; do
  REMOTE_IMAGE=$(yq --yaml-fix-merge-anchor-to-spec=true e ".services.$SVC.image" "$TMP_REMOTE")
  if [ "$REMOTE_IMAGE" != "null" ]; then
    # Replace 'appwrite-dev' by 'appwrite/appwrite:<version>'
    if [[ "$REMOTE_IMAGE" == "appwrite-dev" ]]; then
      FINAL_IMAGE="appwrite/appwrite:$VERSION"
    else
      FINAL_IMAGE="$REMOTE_IMAGE"
    fi
    yq --yaml-fix-merge-anchor-to-spec=true e -i ".services.$SVC.image = \"$FINAL_IMAGE\"" "$TMP_NEW"
    echo "  - $SVC: set image to $FINAL_IMAGE"
    IMAGE_CHANGE_LOG+="  - $SVC: set image to $FINAL_IMAGE"
    IMAGE_CHANGE_LOG+=$'\n'
  fi
done

echo
# Show diff and ask for confirmation
echo "--- DIFF (local vs. new) ---"
diff -u "$LOCAL_COMPOSE" "$TMP_NEW" || true
echo "----------------------------"
echo
read -p "Apply these changes to $LOCAL_COMPOSE? [y/N] " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  mv "$TMP_NEW" "$LOCAL_COMPOSE"
  echo "$VERSION" > .appwrite-version
  echo "[OK] $LOCAL_COMPOSE updated. Version $VERSION saved to .appwrite-version."
  # Save image change log to CHANGELOG.md
  echo "# Docker Compose image bump to Appwrite $VERSION - $(date '+%Y-%m-%d %H:%M:%S')" >> CHANGELOG.md
  echo >> CHANGELOG.md
  printf "%s" "$IMAGE_CHANGE_LOG" >> CHANGELOG.md
  echo >> CHANGELOG.md
else
  echo "[ABORTED] No changes applied."
  rm "$TMP_NEW"
fi
rm "$TMP_REMOTE" 2>/dev/null || true
