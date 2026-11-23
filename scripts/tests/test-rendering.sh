#!/bin/sh
set -eu
tmp_dir=$(mktemp -d)
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT HUP INT TERM
sed \
  -e 's/CHANGE_ME/192.0.2.10/' \
  -e '0,/192.0.2.10/s//192.0.2.11/' \
  -e '0,/192.0.2.10/s//192.0.2.20/' \
  -e '0,/192.0.2.10/s//192.0.2.21/' \
  -e '0,/192.0.2.10/s//192.0.2.30/' \
  -e '0,/192.0.2.10/s//192.0.2.31/' \
  config/inventory.example.env > "$tmp_dir/inventory.env"
scripts/render-configs.sh "$tmp_dir/inventory.env" "$tmp_dir/output"
if grep -REq '__[A-Z0-9_]+__|CHANGE_ME' "$tmp_dir/output"; then
    printf 'FAIL: unresolved rendered value\n' >&2
    exit 1
fi
dns/scripts/validate.sh "$tmp_dir/output/dns/primary/dnsmasq.conf"
firewall/validate.sh "$tmp_dir/output/firewall/backend-a.pf.conf"
printf 'PASS: rendering tests passed\n'
