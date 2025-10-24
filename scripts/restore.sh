#!/bin/bash
# Usage: ./scripts/restore.sh <backup_dir>
# Restores the Appwrite stack (database and volumes) from a backup directory
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"
load_env

if [ -z "$1" ]; then
  echo "Usage: $0 <backup_dir>"
  exit 1
fi

BACKUP_DIR="$1"

# Stop all containers (better safe than sorry)
echo "Stopping all Appwrite containers for restore..."
docker compose down

# Find or start MariaDB container
read MARIADB_CONTAINER MARIADB_CONTAINER_NAME < <(find_mariadb_container)
if [ -z "$MARIADB_CONTAINER" ]; then
  echo "Starting MariaDB container prior to restoring the database..."
  docker compose up -d mariadb
  # Wait for the container to appear
  for i in {1..10}; do
    read MARIADB_CONTAINER MARIADB_CONTAINER_NAME < <(find_mariadb_container)
    if [ -n "$MARIADB_CONTAINER" ]; then
      break
    fi
    sleep 1
  done
fi
if [ -z "$MARIADB_CONTAINER" ]; then
  echo "[ERROR] Could not find a running MariaDB container (name contains 'appwrite-mariadb')."
  echo "Currently running containers:"
  docker ps --format '  - {{.Names}} (ID: {{.ID}} | Image: {{.Image}})'
  exit 1
fi
echo "Detected MariaDB container: name='$MARIADB_CONTAINER_NAME', id='$MARIADB_CONTAINER'"

# Get MariaDB root password
MYSQL_ROOT_PASSWORD="$(get_mariadb_root_password)"
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
  echo "[ERROR] Neither MYSQL_ROOT_PASSWORD nor _APP_DB_ROOT_PASS is set. Please check your .env file."
  exit 1
fi
echo "[INFO] Using MariaDB root password from .env (hidden for security)."

# Restore MariaDB
if [ -f "$BACKUP_DIR/mariadb.sql" ]; then
  echo "Restoring MariaDB..."
  docker exec -i "$MARIADB_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" < "$BACKUP_DIR/mariadb.sql"
else
  echo "No mariadb.sql found, skipping MariaDB restore."
fi

# Stop all containers before restoring volumes (to ensure consistency)
echo "Stopping all Appwrite containers prior to restoring docker volumes..."
docker compose down


# Detect Compose project name for volume prefix
VOLUME_PREFIX="$(get_volume_prefix)"

# List of Appwrite volumes (without prefix)
APPWRITE_VOLUMES=(
  appwrite-mariadb
  appwrite-redis
  appwrite-cache
  appwrite-uploads
  appwrite-imports
  appwrite-certificates
  appwrite-functions
  appwrite-sites
  appwrite-builds
  appwrite-config
)

for VOLUME in "${APPWRITE_VOLUMES[@]}"; do
  FULL_VOLUME_NAME="${VOLUME_PREFIX}${VOLUME}"
  ARCHIVE="$BACKUP_DIR/${FULL_VOLUME_NAME}.tar.gz"
  if [ -f "$ARCHIVE" ]; then
    echo "Restoring volume: $FULL_VOLUME_NAME"
    docker run --rm -v "$FULL_VOLUME_NAME":/data -v "$BACKUP_DIR":/backup ubuntu sh -c "tar xzf /backup/${FULL_VOLUME_NAME}.tar.gz -C /data"
  else
    echo "[skip] No archive for $FULL_VOLUME_NAME."
  fi
done

# Restore docker-compose.yml
if [ -f "$BACKUP_DIR/docker-compose.yml" ]; then
  echo "Restoring docker-compose.yml..."
  cp "$BACKUP_DIR/docker-compose.yml" docker-compose.yml
else
  echo "No docker-compose.yml found in backup, skipping."
fi

# Restore .env
if [ -f "$BACKUP_DIR/.env" ]; then
  echo "Restoring .env..."
  cp "$BACKUP_DIR/.env" .env
else
  echo "No .env found in backup, skipping."
fi

# Optionally restart containers after restore
echo "Restarting Appwrite stack..."
docker compose up -d

echo "Restore complete from $BACKUP_DIR"
