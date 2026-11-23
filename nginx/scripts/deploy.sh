#!/bin/sh
set -eu
config_file=${1:-}
role=${2:-}
if [ -z "$config_file" ] || { [ "$role" != primary ] && [ "$role" != standby ]; }; then
    printf 'usage: %s RENDERED_CONFIG primary|standby [--apply]\n' "$0" >&2
    exit 2
fi
"$(dirname "$0")/validate.sh" "$config_file"
brew_prefix=$(brew --prefix)
target="$brew_prefix/etc/nginx/team1-$role.conf"
if [ "${3:-}" != "--apply" ]; then
    printf 'DRY RUN: would install %s as %s and proxy-common.conf beside it.\n' "$config_file" "$target"
    printf 'Re-run with --apply only on the intended edge Mac after review.\n'
    exit 0
fi
printf 'Installing nginx configuration requires administrator privileges.\n'
sudo install -m 0644 "$config_file" "$target"
sudo install -m 0644 nginx/proxy-common.conf "$brew_prefix/etc/nginx/proxy-common.conf"
printf 'Installed files but did not start or reload nginx. Run nginx -t again, then reload manually.\n'
