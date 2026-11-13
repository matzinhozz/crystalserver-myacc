# Docker README

There are two docker setups in this folder:

* Minimal
  * Based on @ranisalt work ([slawkens/myaac#313](https://github.com/slawkens/myaac/pull/313)). Contains only 1 image - web server. The rest (database, Crystal Server) you need to carry yourself.

* Full
  * myaac + mariadb (with Crystal Server schema) + mailpit (SMTP server for debugging) + phpmyadmin + server data (config.lua, vocations.xml, groups.xml, items.xml, stages.lua & events.xml from Crystal Server).

Both images use PHP 8.3 - PHP 8.4+ is not supported by the bundled Twig version yet.

## How to?

First change to the aac folder after git clone:
`cd crystalserver-myacc`

### Minimal

First, change `mysqlHost` in your server `config.lua` to `"host.docker.internal"` if your database is running on the host, so myaac can connect to it.

```bash
docker build --tag 'myaac-minimal' -f docker/minimal/Dockerfile .
docker run --rm --name myaac -p 9000:80 -v "/path/to/crystalserver:/server:ro" -v "config:/config" -d myaac-minimal
```

On Windows use the Windows path, for example `-v "C:\PathToServer:/server:ro"`.

Access:
  * myaac: http://localhost:9000

Set server path to `/server` in the install page.

The installer accepts any IP in this image (`*` in `install/ip.txt`). If the port is reachable from other machines, finish the installation right away, or publish it only on localhost: `-p 127.0.0.1:9000:80`.

### Full

```bash
cd docker/full && docker compose up --build
```

Access:
  * myaac: http://localhost (if port 80 is already in use, change it: `MYAAC_HTTP_PORT=8001 docker compose up --build`)
  * phpmyadmin: http://localhost:8002 (you should be logged in automatically)
  * mailpit: http://localhost:8025 (here you can view emails sent, for testing purposes)
  * database: `127.0.0.1:8003`, user `myaac`, password `myaac`, database `myaac` - you can point a local Crystal Server to it

Server path will be set automatically (`/srv/server`).

To send email you can configure SMTP Mailing with following settings:
  * Option: SMTP
  * Host: mailpit
  * Port: 1025
  * Auth: no
  * Username & password: leave empty
  * Security: None

The full setup is good for local development without need to configure anything:
  * The project folder is mounted into the container, so changes are visible immediately.
  * `config.local.php` is saved in the `config` docker volume, not in the project folder. Run `docker compose down -v` to start from scratch (this also deletes the database).
  * On Linux/WSL2, Apache runs with the owner of the project folder, so MyAAC can write to `system/cache`, `images/`, `plugins/` etc.
  * The installer accepts any IP (`docker/full/ip.txt` is mounted over `install/ip.txt`), all ports are bound to localhost only.
  * The server data and the database schema are downloaded from [Crystal Server](https://github.com/zimbadev/crystalserver) at a fixed commit. To update them, change `CRYSTALSERVER_REF` in both `Dockerfile` and `Dockerfile-db`, then run `docker compose down -v && docker compose up --build`.

In the minimal setup you need to install mariadb/mysql, Crystal Server, phpmyadmin etc. separately.
