# User Documentation

This document explains, in simple terms, how to use the Inception stack once
it has been set up — no Docker or development knowledge required.

## What services does this stack provide?

| Service | What it does |
|---|---|
| **NGINX** | The only door into the infrastructure. Handles HTTPS (port 443) and forwards requests to WordPress. |
| **WordPress** | The actual website / blog you visit and manage. Includes the WordPress admin dashboard. |
| **MariaDB** | Stores all WordPress content (posts, pages, users, settings) behind the scenes. You never access it directly. |

## Starting and stopping the project

From the root of the repository:

- **Start everything:**
  ```
  make
  ```
- **Stop everything (containers stay, data is kept):**
  ```
  make down
  ```
- **Stop and remove containers, but keep your data (volumes):**
  ```
  make stop
  ```
- **Full clean reset (removes containers, images, AND volumes/data):**
  ```
  make fclean
  ```
  ⚠️ Only use `fclean` if you actually want to wipe the database and site
  files — this cannot be undone.

- **Rebuild everything from scratch:**
  ```
  make re
  ```

## Accessing the website and the administration panel

- **Website:** open `https://aaydogdu.42.fr` in your browser.
  - Your browser will show a security warning because the TLS certificate is
    self-signed (this is expected and normal for a local project — click
    "Advanced" → "Proceed anyway", or the equivalent in your browser).
- **Admin panel:** `https://aaydogdu.42.fr/wp-admin`
  - Log in with the administrator account (see "Locating credentials" below).

## Locating and managing credentials

Credentials are never stored in plain sight in the repository. They live in
two places:

1. **`srcs/.env`** — non-sensitive configuration only (domain name, database
   name, usernames). No passwords here.
2. **`secrets/`** (at the repository root) — actual passwords, one per file:
   - `secrets/db_password.txt` — MariaDB application user password
   - `secrets/db_root_password.txt` — MariaDB root password
   - `secrets/wp_admin_password.txt` — wordpress admin password
   - `secrets/wp_user_password.txt` — wordpress user password


These files are excluded from Git (`.gitignore`) and must be created locally
before running `make` for the first time — see `DEV_DOC.md` for the exact
list of files to create.

To change a password, edit the relevant file in `secrets/` and restart the
affected container with `make re` (a full rebuild is the simplest safe way
to pick up new secrets, since secrets are only read on container startup).

## Checking that the services are running correctly

- **List running containers:**
  ```
  docker ps
  ```
  You should see exactly three containers (`nginx`, `wordpress`, `mariadb`)
  with status `Up`.
- **Check a specific container's logs** (useful if something looks wrong):
  ```
  docker logs nginx
  docker logs wordpress
  docker logs mariadb
  ```
- **Quick health check:** visiting `https://aaydogdu.42.fr` and seeing the
  WordPress homepage load is the simplest end-to-end confirmation that all
  three services are working together correctly.
- If a container has restarted unexpectedly, `docker ps` will show a recent
  "Up X seconds" instead of a long uptime — check its logs first.