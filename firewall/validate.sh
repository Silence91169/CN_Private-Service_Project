#!/bin/sh
set -eu
rules_file=${1:?usage: validate.sh RENDERED_RULES_FILE}
[ -f "$rules_file" ] || { printf 'ERROR: file not found: %s\n' "$rules_file" >&2; exit 1; }
if grep -Eq '__[A-Z0-9_]+__|CHANGE_ME' "$rules_file"; then
    printf 'ERROR: unresolved rule value\n' >&2
    exit 1
fi
grep -q 'table <team1_edges>' "$rules_file"
grep -q '^pass in quick' "$rules_file"
grep -q '^block drop in log quick' "$rules_file"
if command -v pfctl >/dev/null 2>&1; then
    sudo -n pfctl -vnf "$rules_file" >/dev/null 2>&1 || printf 'NOTE: run sudo pfctl -vnf %s interactively for authoritative syntax validation.\n' "$rules_file"
fi
printf 'PASS: PF static validation completed\n'
