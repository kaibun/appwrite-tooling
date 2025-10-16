#!/bin/bash
# Utility functions for Appwrite backup/restore scripts

# Get Compose project name (default: current folder name)
get_compose_project_name() {
  if [ -n "$COMPOSE_PROJECT_NAME" ]; then
    echo "$COMPOSE_PROJECT_NAME"
  else
    basename "$PWD"
  fi
}

# Get Compose volume prefix
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
find_mariadb_container() {
  local id name
  id=$(docker ps --filter 'name=appwrite-mariadb' --format '{{.ID}}' | head -n1)
  name=$(docker ps --filter "id=$id" --format '{{.Names}}')
  echo "$id $name"
}
