#!/bin/sh
set -eu
if [ "${1:-}" != "--apply" ]; then
    printf 'DRY RUN: would flush only the team1/backend anchor.\n'
    printf 'Run %s --apply after the test.\n' "$0"
    exit 0
fi
sudo pfctl -a team1/backend -F rules
printf 'Flushed team1/backend anchor rules. PF global state was not changed.\n'
