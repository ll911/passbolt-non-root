#!/bin/bash

sed -e "s/^www-data:x:[^:]*:[^:]*:/www-data:x:$(id -u):$(id -u):/" /etc/passwd > /tmp/passwd
cat /tmp/passwd > /etc/passwd
rm /tmp/passwd

set -eo pipefail

passbolt_config="/etc/passbolt"
gpg_private_key="/etc/passbolt/gpg/serverkey_private.asc"
gpg_public_key="/etc/passbolt/gpg/serverkey.asc"
ssl_key="/etc/passbolt/certs/certificate.key"
ssl_cert="/etc/passbolt/certs/certificate.crt"

source /passbolt/entrypoint-rootless.sh
source /passbolt/entropy.sh
source /passbolt/env.sh
source /passbolt/deprecated_paths.sh

manage_docker_env

check_deprecated_paths

if [ ! -f "$gpg_private_key" ] || \
   [ ! -f "$gpg_public_key" ]; then
  gpg_gen_key
  gpg_import_key
else
  gpg_import_key
fi

if [ ! -f "$ssl_key" ] && [ ! -L "$ssl_key" ] && \
   [ ! -f "$ssl_cert" ] && [ ! -L "$ssl_cert" ]; then
  gen_ssl_cert
fi

install

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /etc/environment

exec /usr/bin/supervisord -n
