*This project has been created as part of the 42 curriculum by aaydogdu.*

# Inception

## Description

Inception is a system administration project that consists of setting up a small
web infrastructure entirely orchestrated with Docker Compose, inside a virtual
machine. The goal is to understand containerization in depth: writing custom
Dockerfiles from scratch (no pre-built images from Docker Hub, except the base
Alpine/Debian layer), configuring inter-container networking, managing
persistent data through named volumes, and handling secrets safely instead of
hardcoding credentials.

The final result is a WordPress website served over HTTPS (TLSv1.2/TLSv1.3
only), backed by a MariaDB database, with NGINX as the single public entry
point of the infrastructure.

### Architecture overview

| Container | Role |
|---|---|
| `nginx` | Reverse proxy / TLS termination. Only container exposed on the host, port 443 |
| `wordpress` | WordPress + php-fpm, no web server inside |
| `mariadb` | Database engine, no web server inside |

All three containers communicate through a single dedicated Docker network
(`inception`). Two named volumes persist data across restarts:
- `wordpress_data` — WordPress site files (`/var/www/wordpress`)
- `db_data` — MariaDB data directory (`/var/lib/mysql`)

Both volumes are bind-configured to live under `/home/aaydogdu/data` on the
host, as required by the subject.

## Instructions

### Prerequisites
- A Linux virtual machine (Debian/Alpine based host is not required, only the
  containers need to be)
- Docker Engine + the `docker compose` plugin installed (see `DEV_DOC.md` for
  exact install steps)
- `make`

### Setup
1. Clone this repository.
2. Create your `secrets/` files (see `DEV_DOC.md` for the exact list) — these
   are **not** committed to Git.
3. Fill in `srcs/.env` with your own values (domain name, database name, user
   names — never passwords, those live in `secrets/`).
4. Add your domain to `/etc/hosts` on the host machine:
   ```
   127.0.0.1   <login>.42.fr
   ```
5. Run:
   ```
   make
   ```
6. Visit `https://aaydogdu.42.fr` in your browser.

For day-to-day usage (starting, stopping, checking status) see `USER_DOC.md`.
For a full developer setup walkthrough see `DEV_DOC.md`.

## Resources

Documentation and references used while building this project:
- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WordPress CLI (wp-cli) documentation](https://developer.wordpress.org/cli/commands/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)

### AI usage disclosure

AI was used as a **learning and mentoring tool** throughout this
project, not as a code generator. Specifically:
- Explaining core concepts I had no prior background in: what a Docker
  container is, the difference from a VM, the PID 1 problem and why
  `tail -f` / `sleep infinity` style entrypoints are forbidden, how
  php-fpm and NGINX communicate over FastCGI.
- Breaking down, service by service, what each of the four required files
  (Dockerfile, config file, entrypoint script, docker-compose.yml entry)
  is responsible for, so I could write them myself.
- Helping me debug environment/installation issues (e.g. a broken Docker
  installation via snap).
- Reviewing my `.env` structure and pointing out the difference between
  MariaDB's `root` user and the subject's WordPress-level "administrator"
  requirement.



## Project description — design choices

### Virtual Machines vs Docker
A virtual machine virtualizes an entire hardware stack, including its own
kernel, and is booted/managed by a hypervisor. This makes VMs heavier
(minutes to boot, gigabytes of disk, full OS overhead) but gives complete
isolation. Docker containers, by contrast, share the host kernel and only
package the application plus its userspace dependencies; they start in
milliseconds and use a fraction of the resources. This project runs *inside*
a VM (per the subject's requirement) but each service *inside* that VM is a
lightweight container rather than a separate VM, which is the appropriate
trade-off here: we don't need kernel-level isolation between nginx, WordPress
and MariaDB, we need fast, reproducible, independently restartable services.

### Secrets vs Environment Variables
Environment variables (`.env`, passed via `env_file` in Compose) are
convenient for non-sensitive configuration (domain name, database name,
usernames) but they end up visible in `docker inspect`, in the container's
process environment, and potentially in logs. Docker secrets are mounted as
files under `/run/secrets/<name>` inside the container at runtime, are never
part of the image layers, and are not exposed through `docker inspect` the
way env vars are. For this project, non-sensitive configuration went into
`.env`, while all passwords (`db_password.txt`, `db_root_password.txt`,
WordPress admin credentials) were stored as Docker secrets, read from files
in `secrets/` that are excluded from Git via `.gitignore`.

### Docker Network vs Host Network
`network_mode: host` makes a container share the host's network namespace
directly — no isolation, no per-container IP, and it is explicitly forbidden
by the subject. A user-defined Docker network (bridge driver), as used here,
gives each container its own network namespace and IP, with Docker's
embedded DNS resolving service names (e.g. `wordpress`, `mariadb`) to the
right container automatically. This keeps the three services isolated from
each other and from the host except through the exact ports we choose to
publish (only 443 on nginx).

### Docker Volumes vs Bind Mounts
A bind mount maps an arbitrary host path directly into the container; Docker
has no management over it, and its content/permissions depend entirely on
the host filesystem's state. A named volume is created and managed by
Docker itself, has a defined lifecycle independent of any specific host
path, and is the recommended mechanism for persisting stateful data such as
a database or uploaded files. The subject explicitly requires named volumes
here (bind mounts are forbidden) for exactly this reason: predictable,
Docker-managed persistence for `wordpress_data` and `db_data`, even though
under the hood they are still configured to store their files at a specific
host path (`/home/<login>/data`) via the volume's `driver_opts`.