#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$repo_root"
printf '[JavaScript syntax]\n'
node --check backend-a/server.js
node --check backend-b/server.js
printf '[Shell syntax]\n'
find scripts dns nginx firewall -type f -name '*.sh' -print | while IFS= read -r file; do sh -n "$file"; done
printf '[Templates]\n'
scripts/validate-templates.sh
scripts/tests/test-rendering.sh
printf '[Backend unit tests]\n'
scripts/tests/test-backends.sh
printf '[Secrets and stale addresses]\n'
if rg -n '(BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|password\s*=|secret\s*=)' . -g '!README.md' -g '!docs/**' -g '!scripts/run-static-tests.sh'; then
    printf 'FAIL: potential secret material found\n' >&2
    exit 1
fi
if rg -n '10\.7\.[0-9]+\.[0-9]+' . -g '!README.md' -g '!docs/**' -g '!dns/dnsmasq.conf' -g '!nginx/cn-project.conf' -g '!scripts/run-static-tests.sh' -g '!evidence/**'; then
    printf 'FAIL: stale LAN address outside documented Phase 1 compatibility files\n' >&2
    exit 1
fi
printf 'PASS: all available static and local tests passed\n'
