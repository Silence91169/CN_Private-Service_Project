#!/usr/bin/env bash

set -u
REPO_ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$REPO_ROOT" || exit 1

ROLE=${1:-}
case "$ROLE" in
    shitanshu|keshav|shivam|yash|all) ;;
    *) printf 'Usage: bash scripts/demo-preflight.sh shitanshu|keshav|shivam|yash|all\n' >&2; exit 2 ;;
esac

if [[ -f config/inventory.env ]]; then
    if grep -Ev '^[A-Z0-9_]+=[A-Za-z0-9_./:-]+$|^[[:space:]]*(#.*)?$' config/inventory.env | grep -q .; then
        printf 'ERROR: config/inventory.env contains an invalid line; refusing to source it.\n' >&2
        exit 1
    fi
    # shellcheck disable=SC1091
    source config/inventory.env
fi
PRIMARY_DNS_IP=${DEMO_PRIMARY_DNS_IP:-${PRIMARY_DNS_IP:-}}
SECONDARY_DNS_IP=${DEMO_SECONDARY_DNS_IP:-${SECONDARY_DNS_IP:-}}
PRIMARY_EDGE_IP=${DEMO_PRIMARY_EDGE_IP:-${PRIMARY_EDGE_IP:-}}
STANDBY_EDGE_IP=${DEMO_STANDBY_EDGE_IP:-${STANDBY_EDGE_IP:-}}
BACKEND_A_IP=${DEMO_BACKEND_A_IP:-${BACKEND_A_IP:-}}
BACKEND_B_IP=${DEMO_BACKEND_B_IP:-${BACKEND_B_IP:-}}

for value in "$PRIMARY_DNS_IP" "$SECONDARY_DNS_IP" "$PRIMARY_EDGE_IP" "$STANDBY_EDGE_IP" "$BACKEND_A_IP" "$BACKEND_B_IP"; do
    if [[ -z $value || $value == CHANGE_ME ]]; then
        printf 'ERROR: complete config/inventory.env or set DEMO_* IP overrides before preflight.\n' >&2
        exit 1
    fi
done

heading() { printf '\n=== %s ===\n' "$1"; }
attempt() { printf '\n$ %s\n' "$*"; "$@"; local status=$?; printf 'exit=%s\n' "$status"; return "$status"; }

heading 'Common read-only checks'
date
scutil --get ComputerName 2>/dev/null || true
printf 'en0 IP: %s\n' "$(ipconfig getifaddr en0 2>/dev/null || printf unavailable)"
printf 'en1 IP: %s\n' "$(ipconfig getifaddr en1 2>/dev/null || printf unavailable)"
git status --short --branch
git log -1 --oneline

preflight_shitanshu() {
    heading 'Shitanshu — primary DNS and integration'
    attempt bash scripts/verify/check-dns.sh "$PRIMARY_DNS_IP" "$PRIMARY_EDGE_IP" || true
    attempt bash scripts/verify/check-dns.sh "$SECONDARY_DNS_IP" "$PRIMARY_EDGE_IP" || true
    attempt bash scripts/verify/check-http.sh "$PRIMARY_EDGE_IP" 8443 || true
    printf '\nReview only (no changes made):\n'
    networksetup -getdnsservers "Wi-Fi" 2>/dev/null || true
}

preflight_keshav() {
    heading 'Keshav — primary nginx'
    attempt curl --silent --show-error --fail --max-time 5 "http://${BACKEND_A_IP}:3001/healthz" || true
    attempt curl --silent --show-error --fail --max-time 5 "http://${BACKEND_B_IP}:3002/healthz" || true
    attempt bash scripts/verify/check-http.sh "$PRIMARY_EDGE_IP" 8443 || true
    pgrep -lf nginx || true
}

preflight_shivam() {
    heading 'Shivam — Backend A and secondary DNS'
    attempt curl --silent --show-error --fail --max-time 5 http://127.0.0.1:3001/healthz || true
    attempt bash scripts/verify/check-dns.sh "$SECONDARY_DNS_IP" "$PRIMARY_EDGE_IP" || true
    lsof -nP -iTCP:3001 -sTCP:LISTEN 2>/dev/null || true
}

preflight_yash() {
    heading 'Yash — Backend B and standby nginx'
    attempt curl --silent --show-error --fail --max-time 5 http://127.0.0.1:3002/healthz || true
    attempt bash scripts/verify/check-http.sh "$STANDBY_EDGE_IP" 8443 || true
    lsof -nP -iTCP:3002 -sTCP:LISTEN 2>/dev/null || true
    pgrep -lf nginx || true
}

case "$ROLE" in
    shitanshu) preflight_shitanshu ;;
    keshav) preflight_keshav ;;
    shivam) preflight_shivam ;;
    yash) preflight_yash ;;
    all) preflight_shitanshu; preflight_keshav; preflight_shivam; preflight_yash ;;
esac

printf '\nPreflight completed read-only. A failed check is not hidden; inspect its output before the viva.\n'
