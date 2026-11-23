#!/bin/sh
set -eu
config_file=${1:?usage: validate.sh RENDERED_DNSMASQ_CONF}
[ -f "$config_file" ] || { printf 'ERROR: file not found: %s\n' "$config_file" >&2; exit 1; }
if command -v dnsmasq >/dev/null 2>&1; then
    dnsmasq --test --conf-file="$config_file"
else
    printf 'SKIP: dnsmasq is not installed; performed static checks only\n'
    grep -Eq '^listen-address=127\.0\.0\.1,([0-9]{1,3}\.){3}[0-9]{1,3}$' "$config_file"
    grep -Eq '^local-ttl=[0-9]+$' "$config_file"
    grep -Eq '^addn-hosts=/' "$config_file"
fi
if grep -Eq '__[A-Z0-9_]+__|CHANGE_ME' "$config_file"; then
    printf 'ERROR: unresolved configuration value\n' >&2
    exit 1
fi
printf 'PASS: DNS configuration validation completed\n'
