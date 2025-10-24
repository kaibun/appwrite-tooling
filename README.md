@see https://appwrite.io/docs/advanced/self-hosting/installation

# Appwrite: a local stack for agile development

This "template" repository holds a bunch of Unix scripts & logic making it easy (easier?) to manage a [self-hosted](https://appwrite.io/docs/advanced/self-hosting) (_including locally on your host machine, of course_) [Docker-based Appwrite stack](https://github.com/appwrite/appwrite).

It’s based of the official setup which leverages Docker Compose to run all of Appwrite’s services.

## Prerequisites

### Software

- [Docker](https://docker.io/)
- [yq](https://github.com/mikefarah/yq)
- curl
- diff

## Install

### 1. Get the code

A nice setup is to [fork this repository](https://github.com/kaibun/appwrite-tooling/fork), then clone your fork into or as your project:

Let’s say I ran "cd ~/myproject" which may contain other folders already (e.g. frontend and mobile apps, configs…) and now wish to use Appwrite as my backend platform. I decide to use the ./appwrite folder to store it:

```sh
git clone git@github.com:YOUR-ACCOUNT/appwrite-tooling.git appwrite
cd appwrite
git remote add upstream https://github.com/kaibun/appwrite-tooling.git
```

<details>
<summary>Keeping your fork up to date</summary>

If you have forked and cloned this template, you can fetch and merge the latest changes from the official repository ("upstream") at any time:

```sh
git fetch upstream
git merge upstream/main
# Or, if you would rather rebase your changes on top of upstream:
# git rebase upstream/main
```

This allows you to benefit from new features and fixes while keeping your own customizations.

If you encounter conflicts, resolve them manually, then commit the result.

</details>

<details>
<summary>Initial installation (<em>one-time setup, has already been done; don’t do it again!</em>)</summary>

```sh
# 1.7.4 at the time…
docker run -it --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
    --entrypoint="install" \
    appwrite/appwrite:1.7.4
```

It generated [./docker-compose.yml](https://github.com/appwrite/appwrite/blob/568f6fd2747dbb7adfcf846944e642830acf1617/docker-compose.yml); [./.env](https://github.com/appwrite/appwrite/blob/568f6fd2747dbb7adfcf846944e642830acf1617/.env) was then added.

</details>

### 2. Configure the env

You MUST either edit .env.project or create a .env.local file which **MUST define `COMPOSE_PROJECT_NAME` with a unique value**. It’s ["prepended along with the service name to the container’s name on startup"](https://docs.docker.com/compose/how-tos/environment-variables/envvars/#compose_project_name); basically it’s an ubiquitous prefix that effectively isolates your Docker Compose & Appwrite stacks (containers, volumes, networks…) from one another. **Not doing so may lead to data corruption/destruction**, for a Docker Compose project will erase another sharing the same name, in whole or in part.

```env
# Don’t use a generic name such as "appwrite".
# Use something like "my-unique-project".
COMPOSE_PROJECT_NAME=myproject-backend
```

.env.project and .env.local are the perfect places for you to override values from .env. Values from the latter override the former’s, but the more sound reason for using .env.local is that it’s .gitignore-d by default.

> It is best not to edit .env as it eases the version bumping process (no manual diff to manage).

> Wondering why volumes and networks get prefixed, but not containers? Docker Compose v2 use short names to make things easier on the command line, but internally binds containers to the compose project. Using `docker inspect <containerId> | grep com.docker.compose.project` reveals the prefix set by `COMPOSE_PROJECT_NAME`.

## Usage

**_Follow [install instructions](#install) above, including the env configuration._**

> appwrite-tooling currently only supports npm or direct scripts/\*.sh executions. Wish to use another tool? Head to https://github.com/kaibun/appwrite-tooling/issues/1

Run `npm run up` (basically `docker compose up -d --remove-orphans`).

Run `npm run:recreate` if need be, eg. when modifying docker-compose.yml with settings that require destroying and recreating the containers (for instance, bound networks).

Run `npm run fix-network` if your functions cannot access other services ("fetch failed" errors for instance). It will recreate all the containers.

Run `npm run down` (basically `docker compose down`) to shutdown all containers.

## Upgrading to a newer version

In a nutshell, the process is:

```sh
npm run backup
npm run bump [VERSION]
npm run upgrade
npm run migrate
# git add / git commit, etc.
```

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

### Bumping to a specific version

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

_You do not need to that manually; the `bump` command automates all of it. Information below left for reference and education._

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

### Upgrading the docker images

Run `npm run upgrade`.

### Migrating the datasets

Run `npm run migrate`.

## Restoring from a backup

To restore the database, Docker volumes, and .env from a backup directory:

```sh
npm run restore -- ./backups/YYYYMMDD_HHMMSS
```

This will restore:

- MariaDB SQL dump
- All Appwrite Docker volumes (if present in the backup)
- The .env file

You can adapt the script if you add or remove volumes in your stack.
