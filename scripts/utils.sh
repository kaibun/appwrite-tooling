#!/bin/bash
# Utility functions for Appwrite backup/restore scripts
set -e

# Load required env vars
load_env() {
  local env_file="$(dirname "$0")/../.env"
  local env_project_file="$(dirname "$0")/../.env.project"
  local env_local_file="$(dirname "$0")/../.env.local"
  if [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$env_file"
    set +a
  fi
  if [ ! -f "$env_project_file" ]; then
    echo "[ERROR] .env.project missing. Create this file with COMPOSE_PROJECT_NAME=unique-name" >&2
    exit 1
  fi
  . "$env_project_file"
  if [ -f "$env_local_file" ]; then
    . "$env_local_file"
  fi
  if [ -z "$COMPOSE_PROJECT_NAME" ]; then
    echo "[ERROR] COMPOSE_PROJECT_NAME must be set in either .env.project, .env.local or your shell" >&2
    exit 1
  fi
    export COMPOSE_PROJECT_NAME
  echo "[INFO] Using COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME"
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

# Get Docker Compose project name
get_compose_project_name() {
  if [ -n "$COMPOSE_PROJECT_NAME" ]; then
    echo "$COMPOSE_PROJECT_NAME"
  else
    echo "[ERROR] COMPOSE_PROJECT_NAME is not set. This variable must be defined in .env.project." >&2
    exit 1
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
