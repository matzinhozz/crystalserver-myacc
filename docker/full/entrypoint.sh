#!/usr/bin/env bash
set -euo pipefail

cd /var/www/html

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

# system/logs is not part of the repository, but MyAAC needs it to write logs
if [ ! -d system/logs ]; then
  install -d -o "$run_uid" -g "$run_gid" system/logs
fi

exec "$@"
