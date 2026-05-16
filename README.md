# Bludit-Docker

Docker setup for [Bludit Flat File CMS](https://www.bludit.com/).

The goal of this project is to create a quick containerized environment with a Bludit installation for testing and development purposes. This is the Docker counterpart of [Bludit-Vagrant](https://github.com/jeremehancock/Bludit-Vagrant) and behaves as closely to it as possible — you can stop and start the container without overwriting your Bludit install.

The following technologies are automatically installed for you:

* Debian (slim, via the official `php:8.2-apache` image)
* Apache 2
* PHP 8
* [Bludit](https://www.bludit.com/) (Latest Version)

## Pre-Installation

1. Install [Docker](https://docs.docker.com/get-docker/)
2. Install [Docker Compose](https://docs.docker.com/compose/install/) (bundled with Docker Desktop)

## Installation Instructions

1. Find a directory on your computer where you'd like to install this repo
2. Run `git clone https://github.com/jeremehancock/Bludit-Docker.git`
3. Run `cd Bludit-Docker`
4. Run `docker compose up -d --build`

On the first start the container will:

* Query the GitHub API for the **latest** Bludit release
* Download and extract the zip into `localhost/www/html/bludit`
* Drop a marker file (`.bludit-installed`) so subsequent starts skip the download
* Configure Apache (`mod_rewrite`, virtual host with `DocumentRoot` pointing at the Bludit directory)
* Start Apache in the foreground

## Usage

1. Wait for the container to finish provisioning. You can follow along with:
   ```
   docker compose logs -f
   ```
2. Point your web browser to [http://localhost:8080](http://localhost:8080) to view your Bludit site
3. Follow the steps to complete the Bludit installation
4. If you'd like a shell inside the running container:
   ```
   docker compose exec bludit bash
   ```
5. Bludit files are located in `localhost/www/html/bludit` on your local machine and are bind-mounted to `/var/www/html/bludit` inside the container

## Start / Stop

Because Bludit lives in a bind-mounted directory on your host, you can stop and start the container freely without losing your site.

* Stop the container (keep data):
  ```
  docker compose stop
  ```
* Start it again later:
  ```
  docker compose start
  ```
* Or bring it down and back up (image stays cached):
  ```
  docker compose down
  docker compose up -d
  ```

## Upgrade

Bludit is only downloaded and copied on the **first** `docker compose up`. After that, recreating the container will re-apply the Apache/PHP configuration but will **not** touch your existing Bludit install. This is tracked by the marker file `localhost/www/html/bludit/.bludit-installed`.

To force a fresh Bludit download (overwriting your site):

1. Back up `localhost/www/html/bludit` first
2. Delete the marker file:
   ```
   rm localhost/www/html/bludit/.bludit-installed
   ```
3. Restart the container so the entrypoint re-runs:
   ```
   docker compose restart
   ```

> A forced re-install will overwrite custom modifications to Bludit. It will not overwrite the content or settings that you have applied in the Bludit admin panel (those live under `bl-content/` which `rsync -a` preserves), but you should still back up first.

## Rebuilding the Image

If you change the `Dockerfile`, `setup/bludit.conf`, or `setup/entrypoint.sh`, rebuild with:

```
docker compose up -d --build
```

## Cleanup

* Stop and remove the container but keep your Bludit site on disk:
  ```
  docker compose down
  ```
* Remove the container, image, **and** your local Bludit install:
  ```
  docker compose down --rmi local
  rm -rf localhost/www/html/bludit
  ```

## Project Layout

```
Bludit-Docker/
├── Dockerfile               # PHP 8 + Apache + required extensions
├── docker-compose.yml       # Service definition, port mapping, bind mount
├── setup/
│   ├── bludit.conf          # Apache virtual host for Bludit
│   └── entrypoint.sh        # Downloads latest Bludit on first run; chowns and starts Apache
└── localhost/
    └── www/
        └── html/            # Bind-mounted to /var/www/html inside the container
            └── bludit/      # Bludit lives here after first start (gitignored)
```

## How It Differs From the Vagrant Setup

The behavior is intentionally as close to Bludit-Vagrant as possible:

* Same host port: [http://localhost:8080](http://localhost:8080)
* Same on-disk location for your Bludit files: `localhost/www/html/bludit`
* Same "latest release via GitHub API" download method
* Same `.bludit-installed` marker file to prevent re-downloading
* Same Apache vhost configuration with `mod_rewrite` enabled

The main differences are operational: you use `docker compose up/stop/start/down` instead of `vagrant up/halt/up/destroy`, and the underlying OS is the slim Debian base from the official `php:8.2-apache` image rather than a full Ubuntu Jammy VM.

## AI Disclaimer

This Docker port of the Bludit-Vagrant project was created with the help of AI.

## Disclaimer

All code is provided as-is without any warranty. Use at your own risk.
