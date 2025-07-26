#!/bin/bash
set -e
if [ -n "${VIRTUAL_HOST}" ] && [ ! -f "/usr/local/lsws/conf/certs/${VIRTUAL_HOST}/fullchain.pem" ]; then
  /usr/local/lsws/admin/misc/acme.sh --issue -d ${VIRTUAL_HOST} -d www.${VIRTUAL_HOST} -w /var/www/html --force --email ${ADMIN_EMAIL}
fi
/usr/local/lsws/admin/misc/acme.sh --install-cronjob
exec /entrypoint.sh "$@"
