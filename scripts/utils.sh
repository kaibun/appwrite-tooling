#!/bin/bash
# Utility functions for Appwrite backup/restore scripts

# Load .env file and export variables
load_env() {
  local env_file="$(dirname "$0")/../.env"
  if [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$env_file"
    set +a
    export COMPOSE_PROJECT_NAME
  fi
}

# Start all Appwrite services
start_appwrite_services() {
  echo "[INFO] Starting all Appwrite services..."
  docker compose up -d --remove-orphans
}

# Stop all Appwrite services
stop_appwrite_services() {
  echo "[INFO] Stopping all Appwrite services..."
  docker compose down
}

# Get Docker Compose project name (default: current working directory name)
get_compose_project_name() {
  if [ -n "$COMPOSE_PROJECT_NAME" ]; then
    echo "$COMPOSE_PROJECT_NAME"
  else
    basename "$PWD"
  fi
}

# Get Docker Compose volume prefix
get_volume_prefix() {
  local project_name
  project_name="$(get_compose_project_name)"
  echo "${project_name}_"
}

# Get MariaDB root password (Appwrite convention)
get_mariadb_root_password() {
  if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
    echo "$MYSQL_ROOT_PASSWORD"
  elif [ -n "$_APP_DB_ROOT_PASS" ]; then
    echo "$_APP_DB_ROOT_PASS"
  else
    echo "" # empty string if not found
  fi
}

# Find running MariaDB container (by partial name)
# Outputs: id name (space-separated)
# The id is more reliable than the name for further docker commands
find_mariadb_container() {
  local id name
  id=$(docker ps --filter 'name=appwrite-mariadb' --format '{{.ID}}' | head -n1)
  name=$(docker ps --filter "id=$id" --format '{{.Names}}')
  echo "$id $name"
}
