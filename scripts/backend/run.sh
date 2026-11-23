#!/bin/sh
set -eu
role=${1:-}
case "$role" in
    A|a) exec node backend-a/server.js ;;
    B|b) exec node backend-b/server.js ;;
    *) printf 'usage: %s A|B\n' "$0" >&2; exit 2 ;;
esac
