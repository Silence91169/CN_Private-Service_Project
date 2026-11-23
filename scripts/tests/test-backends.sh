#!/bin/sh
set -eu
require() { command -v "$1" >/dev/null 2>&1 || { printf 'SKIP: %s not installed\n' "$1"; exit 0; }; }
require node
require curl
tmp_dir=$(mktemp -d)
pid_a=
pid_b=
cleanup() {
    [ -z "$pid_a" ] || kill "$pid_a" 2>/dev/null || true
    [ -z "$pid_b" ] || kill "$pid_b" 2>/dev/null || true
    rm -rf "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM
HOST=127.0.0.1 PORT=13001 node backend-a/server.js >"$tmp_dir/a.log" 2>&1 & pid_a=$!
HOST=127.0.0.1 PORT=13002 node backend-b/server.js >"$tmp_dir/b.log" 2>&1 & pid_b=$!
i=0
ready=0
while [ "$i" -lt 20 ]; do
    if curl -fsS http://127.0.0.1:13001/healthz >/dev/null 2>&1 && curl -fsS http://127.0.0.1:13002/healthz >/dev/null 2>&1; then ready=1; break; fi
    sleep 0.1
    i=$((i + 1))
done
[ "$ready" -eq 1 ] || { printf 'FAIL: backends did not become ready\n' >&2; exit 1; }
[ "$(curl -fsS http://127.0.0.1:13001/healthz)" = '{"backend":"A","status":"ok"}' ]
[ "$(curl -fsS http://127.0.0.1:13002/healthz)" = '{"backend":"B","status":"ok"}' ]
curl -fsSI http://127.0.0.1:13001/healthz | grep -Eiq '^Cache-Control: no-store\r?$'
[ "$(curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:13002/missing)" = 404 ]
[ "$(curl -sS -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:13001/healthz)" = 405 ]
printf 'PASS: backend local tests passed\n'
