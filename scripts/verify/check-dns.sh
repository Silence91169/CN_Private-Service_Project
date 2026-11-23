#!/bin/sh
set -eu
. "$(dirname "$0")/../lib/common.sh"
resolver=${1:?usage: check-dns.sh RESOLVER_IP EXPECTED_EDGE_IP}
expected=${2:?usage: check-dns.sh RESOLVER_IP EXPECTED_EDGE_IP}
validate_ipv4 "$resolver"
validate_ipv4 "$expected"
require_command dig
for name in app.team1.test api.team1.test; do
    answer=$(dig +time=2 +tries=1 +short "@$resolver" "$name" A | tail -n 1)
    [ "$answer" = "$expected" ] || die "$name via $resolver returned '${answer:-no answer}', expected $expected"
    ttl=$(dig +time=2 +tries=1 +noall +answer "@$resolver" "$name" A | awk 'NR == 1 { print $2 }')
    printf 'PASS: %s via %s -> %s (TTL %s)\n' "$name" "$resolver" "$answer" "${ttl:-unknown}"
done
