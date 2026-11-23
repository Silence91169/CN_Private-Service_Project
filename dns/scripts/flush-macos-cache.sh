#!/bin/sh
set -eu
if [ "${1:-}" != "--apply" ]; then
    printf 'This script does not change the host by default.\n'
    printf 'To flush the macOS DNS cache, review and run: %s --apply\n' "$0"
    exit 0
fi
printf 'Flushing macOS DNS caches requires administrator privileges.\n'
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
printf 'DNS cache flush requested. Confirm with a new dig query.\n'
