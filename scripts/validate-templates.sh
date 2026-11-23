#!/bin/sh

set -eu
repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$repo_root"
. scripts/lib/common.sh

status=0
for file in $(find dns nginx firewall -type f -name '*.template' -print); do
    if grep -Eq '10\.7\.[0-9]+\.[0-9]+' "$file"; then
        printf 'FAIL: stale lab IP in %s\n' "$file" >&2
        status=1
    fi
done

for token in PRIMARY_DNS_IP SECONDARY_DNS_IP PRIMARY_EDGE_IP STANDBY_EDGE_IP BACKEND_A_IP BACKEND_B_IP; do
    if ! grep -R "__${token}__" dns nginx firewall >/dev/null 2>&1; then
        printf 'WARN: placeholder %s is not used by any template\n' "$token"
    fi
done

[ "$status" -eq 0 ] || exit "$status"
info "template static checks passed"
