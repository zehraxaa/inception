# Developer Documentation

This document describes how to set up, build, and work with the Inception
project as a developer — i.e. how to go from an empty VM to a running,
modifiable stack.

## Setting up the environment from scratch

### Prerequisites
- A virtual machine running Debian or Alpine (penultimate stable version)
- Docker Engine + the `docker compose` plugin (installed via Docker's
  official apt/apk repository — **not** via `snap`, which sandboxes the
  filesystem in ways that interfere with bind-mounted volume paths)
- `make`
- `openssl` on the host only if you want to inspect/verify certificates
  manually (the containers generate their own at build/run time)

### Repository layout
```
.
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

### Configuration files to create before first run

1. **`srcs/.env`** — example content:
   ```
   DOMAIN_NAME=<login>.42.fr

   MYSQL_DATABASE=wordpress
   MYSQL_USER=<non-admin db user>

   WP_TITLE=<site title>
   WP_ADMIN_USER=<admin username, must NOT contain admin/administrator>
   WP_ADMIN_EMAIL=<email>
   WP_USER=<second, non-admin WordPress user>
   WP_USER_EMAIL=<email>
   ```
   No passwords in this file.

2. **`secrets/`** — create these three files locally (they are gitignored):
   - `secrets/db_password.txt` → password for `MYSQL_USER`
   - `secrets/db_root_password.txt` → MariaDB root password
   - `secrets/credentials.txt` → WordPress admin + secondary user passwords

3. **Host `/etc/hosts`** — add:
   ```
   127.0.0.1   <login>.42.fr
   ```

## Building and launching with the Makefile and Docker Compose

The `Makefile` at the repository root wraps `docker compose` calls:

| Target | Effect |
|---|---|
| `make` / `make up` | Builds images (if needed) and starts all containers, creating the `/home/<login>/data` directories if missing |
| `make down` | Stops and removes containers, keeps volumes |
| `make stop` | Stops containers without removing them |
| `make start` | Restarts previously stopped containers |
| `make clean` | Removes containers and images |
| `make fclean` | `clean` + removes named volumes and their host data |
| `make re` | `fclean` + `up` — full rebuild |

Under the hood, `make` runs something equivalent to:
```
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up --build -d
```

## Managing containers and volumes

- **Rebuild a single service** (after editing its Dockerfile/config):
  ```
  docker compose -f srcs/docker-compose.yml build <service>
  docker compose -f srcs/docker-compose.yml up -d <service>
  ```
- **Shell into a running container** (for debugging):
  ```
  docker exec -it <service> sh
  ```
- **List volumes:**
  ```
  docker volume ls
  ```
- **Inspect a volume's mount point on the host:**
  ```
  docker volume inspect <volume_name>
  ```

## Where project data is stored and how it persists

Both required named volumes (`wordpress_data`, `db_data`) are declared in
`docker-compose.yml` with a `local` driver and `driver_opts` pinning their
actual storage location on the host to `/home/<login>/data/wordpress` and
`/home/<login>/data/mariadb` respectively — satisfying the subject's
requirement that data lives under `/home/<login>/data` while still being a
Docker-managed named volume rather than a raw bind mount.

Because these are named volumes (not bind mounts, and not container
filesystem layers), their content survives:
- container restarts (`make down` / `make up`)
- container removal and rebuild (`make clean` / `make re` as long as
  `fclean` — which explicitly deletes volumes — is not used)

Data is only lost if you explicitly run `make fclean` or manually run
`docker volume rm`.