#!/bin/sh
set -eu
. "$(dirname "$0")/../lib/common.sh"
edge_ip=${1:?usage: check-http.sh EDGE_IP HTTPS_PORT [CA_FILE]}
port=${2:?usage: check-http.sh EDGE_IP HTTPS_PORT [CA_FILE]}
ca_file=${3:-}
validate_ipv4 "$edge_ip"
validate_port "$port"
require_command curl
set -- --silent --show-error --fail --resolve "app.team1.test:$port:$edge_ip"
if [ -n "$ca_file" ]; then
    [ -f "$ca_file" ] || die "CA file not found: $ca_file"
    set -- "$@" --cacert "$ca_file"
fi
headers=$(curl "$@" --dump-header - --output /dev/null "https://app.team1.test:$port/healthz")
printf '%s\n' "$headers"
printf '%s\n' "$headers" | grep -Eiq '^X-Backend: [AB]\r?$' || die "missing valid X-Backend header"
printf '%s\n' "$headers" | grep -Eiq '^Cache-Control: no-store\r?$' || die "health route is not marked no-store"
printf 'PASS: uncached HTTPS health request succeeded through %s:%s\n' "$edge_ip" "$port"
