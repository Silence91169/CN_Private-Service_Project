#!/bin/sh
set -eu
. "$(dirname "$0")/../lib/common.sh"
edge_ip=${1:?usage: check-failover.sh EDGE_IP HTTPS_PORT [COUNT] [CA_FILE]}
port=${2:?usage: check-failover.sh EDGE_IP HTTPS_PORT [COUNT] [CA_FILE]}
count=${3:-8}
ca_file=${4:-}
validate_ipv4 "$edge_ip"
validate_port "$port"
case "$count" in ''|*[!0-9]*) die "COUNT must be numeric" ;; esac
require_command curl
i=1
while [ "$i" -le "$count" ]; do
    set -- --silent --show-error --fail --header 'Cache-Control: no-cache' --resolve "app.team1.test:$port:$edge_ip"
    if [ -n "$ca_file" ]; then set -- "$@" --cacert "$ca_file"; fi
    header=$(curl "$@" --dump-header - --output /dev/null "https://app.team1.test:$port/healthz?sample=$i")
    backend=$(printf '%s\n' "$header" | awk 'BEGIN{IGNORECASE=1} /^X-Backend:/ {gsub("\r", "", $2); print $2; exit}')
    case "$backend" in A|B) printf '%02d X-Backend: %s\n' "$i" "$backend" ;; *) die "request $i returned no valid backend header" ;; esac
    i=$((i + 1))
done
printf 'NOTE: interpret samples according to the controlled state (both up, A stopped, or A recovered).\n'
