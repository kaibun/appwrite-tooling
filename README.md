@see https://appwrite.io/docs/advanced/self-hosting/installation

# Appwrite: a local stack for agile development

## Prerequisites

- [Docker](https://docker.io/)

<details>
<summary>Initial installation (one-time setup, has already been done)</summary>

```sh
docker run -it --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
    --entrypoint="install" \
    appwrite/appwrite:1.7.4
```

It generates ./docker-compose.yml.

I added ./.env (https://appwrite.io/install/env).

</details>

## Your job

Clone this repository.

Run `npm run up` (basically `docker compose up -d --remove-orphans`).

Run `npm run:recreate` if need be, eg. when modifying docker-compose.yml with settings that require destroying and recreating the containers (for instance, bound networks).

Run `npm run down` (basically `docker compose down`) to shutdown all containers.

## Upgrading to a newer version

### Manual backup before upgrade

> https://appwrite.io/docs/advanced/self-hosting/production/backups

To perform a full backup (database, volumes, .env) before an Appwrite upgrade:

```sh
npm run backup
```

Dumps will be created in `./backups/YYYYMMDD_HHMMSS/`:

- `mariadb.sql` as a full SQL dump
- `uploads.tar.gz`, `functions.tar.gz`, etc. for Docker volume archives
- `.env`

### Upgrading the Appwrite dockerized stack

> https://appwrite.io/docs/advanced/self-hosting/production/updates

> **Dependency: yq (YAML CLI)**
>
> The `bump` script described below relies on [yq](https://github.com/mikefarah/yq) (Go version) to safely update YAML files. We use yq because:
>
> - YAML is a complex format (indentation, anchors, merges, comments).
> - yq ensures the structure remains valid and avoids breaking your compose file.
> - Text-based tools (sed, awk) are risky and can corrupt YAML.
>
> **Important:**
>
> - Do not install yq from your system package manager (it may install the Python version, which is incompatible).
> - Always follow the install instructions from the official yq GitHub: https://github.com/mikefarah/yq#install
>
> Check your yq version:
>
> ```sh
> yq --version # should show yq version 4.x.x (Go)
> ```

Run `npm run bump [VERSION]`, where VERSION is the name of version branch available on https://github.com/appwrite/appwrite/branches:

```sh
npm run bump 1.8.0-RC4
```

> Warning: this script does not preserve empty lines and comments in the .yml file.
>
> Note: The bump script uses yq with `--yaml-fix-merge-anchor-to-spec=true` to ensure correct YAML anchor/merge behavior and suppress related warnings.

This command automates the process described below, updating all Docker image tags in your local `docker-compose.yml` to match the official Appwrite release.

<details>
<summary>How to choose the right Docker image tags for each Appwrite service?</summary>

**General rule:**

Always use the image tags recommended in the official docker-compose file for the target Appwrite version.

**How to proceed:**

1. Go to the official docker-compose file for your target Appwrite version, for instance for 1.8.0-RC4:
   https://github.com/appwrite/appwrite/blob/1.8.0-RC4/docker-compose.yml
2. For each service, use the exact image tag specified in this file.
   - For example, for Appwrite 1.8.0-RC4, use `appwrite/appwrite:1.8.0-RC4` for all services that use `appwrite-dev` in the official compose.
   - For other services (console, openruntimes, traefik, etc.), use the exact tag shown (e.g. `appwrite/console:7.4.7`, `openruntimes/executor:0.11.0`).

**Why?**

- Appwrite services are versioned to work together. Mixing tags ("latest", "major", etc.) with a specific Appwrite version can cause bugs or subtle incompatibilities.
- Always follow the official compose file for your release to guarantee compatibility.

**Summary:**

- Never mix "latest" or "major" tags with a specific Appwrite version.
- Always align your images with the tags from the official compose file for your Appwrite version.

You can update your `docker-compose.yml` based on the official file for your target version. This is the recommended method by Appwrite.

</details>

## Restore from backup

To restore the database, Docker volumes, and .env from a backup directory:

```sh
npm run restore -- ./backups/YYYYMMDD_HHMMSS
```

This will restore:

- MariaDB SQL dump
- All Appwrite Docker volumes (if present in the backup)
- The .env file

You can adapt the script if you add or remove volumes in your stack.

---

## TODO

- Create @kaibun/appwrite-tooling as a copy of this project, no Carto Chasse left
- Publish on npmjs.com, GitHub, etc.
- Fork it to carto-chasse/appwrite-local and add specific/private config
