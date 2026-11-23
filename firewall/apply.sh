#!/bin/sh
set -eu
rules_file=${1:-}
[ -n "$rules_file" ] || { printf 'usage: %s RENDERED_RULES_FILE [--apply]\n' "$0" >&2; exit 2; }
"$(dirname "$0")/validate.sh" "$rules_file"
if [ "${2:-}" != "--apply" ]; then
    printf 'DRY RUN: no PF state changed.\n'
    printf 'Requires an existing anchor reference in /etc/pf.conf, then loads team1/backend from %s.\n' "$rules_file"
    exit 0
fi
if ! grep -Eq '^[[:space:]]*anchor[[:space:]]+"team1/(\*|backend)"' /etc/pf.conf; then
    printf 'ERROR: /etc/pf.conf does not reference anchor "team1/*" or "team1/backend".\n' >&2
    printf 'Review firewall/README.md and add the anchor manually before loading rules. No PF state changed.\n' >&2
    exit 1
fi
printf 'Current PF information will be saved to ./generated/firewall/pre-apply-info.txt.\n'
mkdir -p generated/firewall
sudo pfctl -s info > generated/firewall/pre-apply-info.txt
sudo pfctl -vnf "$rules_file"
sudo pfctl -a team1/backend -f "$rules_file"
printf 'Anchor loaded. PF was not enabled automatically. Inspect sudo pfctl -a team1/backend -sr.\n'
