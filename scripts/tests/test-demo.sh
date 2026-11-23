#!/bin/sh

set -eu

bash scripts/demo.sh --help >/dev/null
menu=$(bash scripts/demo.sh --list --no-color)
printf '%s\n' "$menu" | grep -q 'PRIVATE NETWORK SERVICE — LIVE DEMO'
printf '%s\n' "$menu" | grep -q '1. Verify both DNS servers'
printf '%s\n' "$menu" | grep -q '9. Show GitHub and project information'
printf '%s\n' "$menu" | grep -q '0. Exit'
bash scripts/demo.sh --run 9 --no-color >/dev/null
bash scripts/demo.sh --run 0 --no-color >/dev/null

capture_root=$(mktemp -d)
trap 'rm -rf "$capture_root"' EXIT HUP INT TERM
bash scripts/demo.sh --capture-dir "$capture_root/session" --run 9 --no-color >/dev/null
test -s "$capture_root/session/demo.log"
grep -q 'PASS: project information displayed' "$capture_root/session/demo.log"
test ! -e "$capture_root/session/.demo-output.pipe"

if bash scripts/demo.sh --unknown >/dev/null 2>&1; then
    printf 'FAIL: unknown argument unexpectedly succeeded\n' >&2
    exit 1
fi
if bash scripts/demo.sh --run 99 >/dev/null 2>&1; then
    printf 'FAIL: invalid menu selection unexpectedly succeeded\n' >&2
    exit 1
fi
if bash scripts/demo-preflight.sh invalid >/dev/null 2>&1; then
    printf 'FAIL: invalid preflight role unexpectedly succeeded\n' >&2
    exit 1
fi

printf 'PASS: demo menu and argument parsing tests passed\n'
