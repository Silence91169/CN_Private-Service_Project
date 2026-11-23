#!/bin/sh
set -eu
. "$(dirname "$0")/../lib/common.sh"
host=${1:?usage: check-tcp.sh HOST PORT}
port=${2:?usage: check-tcp.sh HOST PORT}
validate_port "$port"
require_command nc
nc -G 3 -zv "$host" "$port"
printf 'PASS: TCP connection to %s:%s succeeded\n' "$host" "$port"
