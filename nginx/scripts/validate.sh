#!/bin/sh
set -eu
config_file=${1:?usage: validate.sh RENDERED_NGINX_CONF}
snippet=${2:-nginx/proxy-common.conf}
[ -f "$config_file" ] || { printf 'ERROR: file not found: %s\n' "$config_file" >&2; exit 1; }
[ -f "$snippet" ] || { printf 'ERROR: snippet not found: %s\n' "$snippet" >&2; exit 1; }
if grep -Eq '__[A-Z0-9_]+__|CHANGE_ME' "$config_file"; then
    printf 'ERROR: unresolved configuration value\n' >&2
    exit 1
fi
grep -q 'proxy_next_upstream_tries 2;' "$snippet"
grep -q 'location = /healthz' "$config_file"
if command -v nginx >/dev/null 2>&1; then
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM
    cp "$snippet" "$temp_dir/proxy-common.conf"
    # nginx resolves relative include files from its prefix.
    nginx -t -p "$temp_dir/" -c "$(cd "$(dirname "$config_file")" && pwd)/$(basename "$config_file")"
else
    printf 'SKIP: nginx is not installed; performed static checks only\n'
fi
printf 'PASS: nginx configuration validation completed\n'
