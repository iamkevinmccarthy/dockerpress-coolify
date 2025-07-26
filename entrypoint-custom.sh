#!/bin/bash
set -e
if [ ! -f "/root/.acme.sh/acme.sh" ]; then
  curl https://get.acme.sh | sh
  /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
fi
if [ -n "${VIRTUAL_HOST}" ] && [ ! -f "/usr/local/lsws/conf/certs/${VIRTUAL_HOST}/fullchain.cer" ]; then
  /root/.acme.sh/acme.sh --issue -d ${VIRTUAL_HOST} -d www.${VIRTUAL_HOST} -w /var/www/html --force --email ${ADMIN_EMAIL}
fi
/root/.acme.sh/acme.sh --install-cronjob
exec /entrypoint.sh "$@"
