#!/bin/sh
set -eu
. "$(dirname "$0")/../lib/common.sh"
edge_ip=${1:?usage: check-tls.sh EDGE_IP HTTPS_PORT [CA_FILE]}
port=${2:?usage: check-tls.sh EDGE_IP HTTPS_PORT [CA_FILE]}
ca_file=${3:-}
validate_ipv4 "$edge_ip"
validate_port "$port"
require_command openssl
if [ -n "$ca_file" ]; then
    [ -f "$ca_file" ] || die "CA file not found: $ca_file"
    verify_args="-CAfile $ca_file"
else
    verify_args=""
fi
# shellcheck disable=SC2086
output=$(printf '' | openssl s_client -connect "$edge_ip:$port" -servername app.team1.test -verify_hostname app.team1.test $verify_args 2>&1)
printf '%s\n' "$output" | grep -E 'subject=|issuer=|Verify return code|Protocol|Cipher' || true
printf '%s\n' "$output" | grep -q 'Verify return code: 0 (ok)' || die "TLS verification failed"
printf 'PASS: TLS identity verified for app.team1.test through %s:%s\n' "$edge_ip" "$port"
