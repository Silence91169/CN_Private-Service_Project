#!/bin/sh
set -eu
. "$(dirname "$0")/../lib/common.sh"
inventory_file=${1:-config/inventory.env}
load_inventory "$inventory_file"
validate_inventory
printf '\n[1/4 DNS]\n'
if scripts/verify/check-dns.sh "$PRIMARY_DNS_IP" "$PRIMARY_EDGE_IP"; then :; else printf 'STOP: investigate resolver reachability, records, service, and client cache.\n'; exit 1; fi
printf '\n[2/4 TCP]\n'
if scripts/verify/check-tcp.sh "$PRIMARY_EDGE_IP" "$PRIMARY_EDGE_HTTPS_PORT"; then :; else printf 'STOP: investigate route, listener, and firewall.\n'; exit 1; fi
printf '\n[3/4 TLS]\n'
if scripts/verify/check-tls.sh "$PRIMARY_EDGE_IP" "$PRIMARY_EDGE_HTTPS_PORT"; then :; else printf 'STOP: investigate certificate chain, SAN, trust, SNI, and clock.\n'; exit 1; fi
printf '\n[4/4 HTTP/Application]\n'
scripts/verify/check-http.sh "$PRIMARY_EDGE_IP" "$PRIMARY_EDGE_HTTPS_PORT"
