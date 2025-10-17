#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"
load_env

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Find or start MariaDB container
read MARIADB_CONTAINER MARIADB_CONTAINER_NAME < <(find_mariadb_container)
if [ -z "$MARIADB_CONTAINER" ]; then
  echo "Starting MariaDB service for backup..."
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

echo "Waiting for MariaDB to be ready..."
for i in {1..30}; do
  if docker exec "$MARIADB_CONTAINER" mysqladmin ping -u root -p"$MYSQL_ROOT_PASSWORD" --silent &>/dev/null; then
    echo "MariaDB is ready."
    break
  fi
  sleep 2
done

# Backup MariaDB (dump SQL complet)
echo "Backup MariaDB..."
docker exec "$MARIADB_CONTAINER" mysqldump --all-databases --add-drop-database --single-transaction --routines --triggers -uroot -p"$MYSQL_ROOT_PASSWORD" > "$BACKUP_DIR/mariadb.sql"
echo "MariaDB backup saved to $BACKUP_DIR/mariadb.sql"

# Stop all containers before backing up volumes (to ensure consistency)
echo "Stopping all Appwrite containers for docker volume backup..."
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
  if docker volume inspect "$FULL_VOLUME_NAME" >/dev/null 2>&1; then
    echo "Backing up volume: $FULL_VOLUME_NAME"
    docker run --rm -v "$FULL_VOLUME_NAME":/data -v "$BACKUP_DIR":/backup ubuntu sh -c "tar czf /backup/${FULL_VOLUME_NAME}.tar.gz -C /data ."
  else
    echo "[skip] Volume $FULL_VOLUME_NAME does not exist."
  fi
done


# Backup .env
echo "Backup .env..."
cp .env "$BACKUP_DIR/.env"

# Backup docker-compose.yml
echo "Backup docker-compose.yml..."
cp docker-compose.yml "$BACKUP_DIR/docker-compose.yml"

# Optionally restart containers after backup
# echo "Restarting Appwrite stack..."
# docker compose up -d

echo "Backup has been placed in $BACKUP_DIR"