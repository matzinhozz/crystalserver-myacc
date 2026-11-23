#!/usr/bin/env bash
set -euo pipefail

cd /var/www/html

# On WSL2, Docker Desktop may start the containers (restart policy) before the distro is ready,
# and the bind mounts come up empty. Bind mounts are set up only when the container starts, so
# waiting here would not help: exit instead, and the restart policy (unless-stopped) starts the
# container again (with backoff, at most 1 minute apart) until the folders are mounted.
server_src="${MYAAC_SERVER_SRC:-/server-src}"
if [ ! -f index.php ]; then
  echo "myaac-entrypoint: /var/www/html is empty (bind mount not ready yet?), exiting so docker restarts the container" >&2
  exit 1
fi
if [ -d "$server_src" ] && [ -z "$(ls -A "$server_src")" ]; then
  echo "myaac-entrypoint: $server_src is empty (bind mount not ready yet?), exiting so docker restarts the container" >&2
  exit 1
fi

run_uid="$(id -u www-data)"
run_gid="$(id -g www-data)"

# On Linux (and WSL2) the bind-mounted source keeps the host owner (e.g. uid 1000),
# so www-data cannot write to system/cache, images/, plugins/ etc.
# Run Apache as the owner of the source instead. With Docker Desktop on
# Windows/macOS the owner shows up as root and the mount is writable anyway,
# so www-data is kept. Set APACHE_RUN_USER/APACHE_RUN_GROUP to skip this.
if [ -z "${APACHE_RUN_USER:-}" ]; then
  src_uid="$(stat -c %u .)"
  src_gid="$(stat -c %g .)"
  if [ "$src_uid" != "0" ]; then
    run_uid="$src_uid"
    run_gid="$src_gid"
    getent group "$run_gid" >/dev/null || groupadd -g "$run_gid" myaac
    getent passwd "$run_uid" >/dev/null || useradd -u "$run_uid" -g "$run_gid" -M -d /var/www -s /usr/sbin/nologin myaac
    APACHE_RUN_USER="$(getent passwd "$run_uid" | cut -d: -f1)"
    APACHE_RUN_GROUP="$(getent group "$run_gid" | cut -d: -f1)"
    export APACHE_RUN_USER APACHE_RUN_GROUP
    chown -R "${run_uid}:${run_gid}" "${MYAAC_CONFIG_DIR:-/config}"
  fi
fi

# A local Crystal Server checkout mounted at /server-src (see docker-compose.override.yml)
# replaces the server data baked into the image: its folders are linked into the server path
# and config.lua is copied with the database host of this compose project (last assignment wins).
server_path="${MYAAC_INSTALL_SERVER_PATH:-/srv/server}"
server_path="${server_path%/}"
if [ -f "$server_src/config.lua" ] || [ -f "$server_src/config.lua.dist" ]; then
  case "$server_path" in
    /srv/?*)
      find "$server_path" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
      mkdir -p "$server_path"
      for entry in "$server_src"/*; do
        name="$(basename "$entry")"
        case "$name" in config.lua | config.lua.dist) continue ;; esac
        ln -s "$entry" "$server_path/$name"
      done

      config_src="$server_src/config.lua"
      [ -f "$config_src" ] || config_src="$server_src/config.lua.dist"
      {
        cat "$config_src"
        printf '\n-- Docker overrides (written by myaac-entrypoint from %s)\n' "$config_src"
        printf 'mysqlHost = "%s"\nmysqlPort = %s\nmysqlSock = ""\n' "${MYAAC_DB_HOST:-db}" "${MYAAC_DB_PORT:-3306}"
      } > "$server_path/config.lua"
      chmod 644 "$server_path/config.lua"
      echo "myaac-entrypoint: using server data from $server_src ($config_src)"
      ;;
    *)
      echo "myaac-entrypoint: $server_src is mounted, but the server path $server_path is not under /srv, ignoring it" >&2
      ;;
  esac
fi

# system/logs is not part of the repository, but MyAAC needs it to write logs
if [ ! -d system/logs ]; then
  install -d -o "$run_uid" -g "$run_gid" system/logs
fi

exec "$@"
