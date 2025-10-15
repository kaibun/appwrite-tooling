@see https://appwrite.io/docs/advanced/self-hosting/installation

# Appwrite: a local stack for agile development

## Prerequisites

- [Docker](https://docker.io/)

## Initial installation (one-time setup, has already been done)

``` sh
docker run -it --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
    --entrypoint="install" \
    appwrite/appwrite:1.7.4
```

It generates ./docker-compose.yml.

I added ./.env (https://appwrite.io/install/env).

## Your job

Clone and run `docker compose up -d --remove-orphans`.
