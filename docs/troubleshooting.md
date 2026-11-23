# DNS → TCP → TLS → HTTP/Application

| Stage | Command | Success | Common failure interpretation | Recovery focus |
| --- | --- | --- | --- | --- |
| DNS | `dig @RESOLVER app.team1.test A` | Current edge IP and expected TTL | Resolver down, wrong record/listener, UDP/TCP 53 blocked | Validate config, service, direct reachability, both record files |
| TCP | `nc -G 3 -zv EDGE 8443` | Connection succeeds | Route, listener, wrong IP/port, PF | Check IP, `lsof -nP -iTCP:8443`, PF and nginx state |
| TLS | `openssl s_client -connect EDGE:8443 -servername app.team1.test -verify_hostname app.team1.test` | Verify code 0 | Wrong SAN, chain, trust, SNI, expired/not-yet-valid cert, clock | Inspect certificate, CA trust and local time; never use `-k` as proof |
| HTTP | `curl --resolve app.team1.test:8443:EDGE https://app.team1.test:8443/healthz` | 200 and `X-Backend` | nginx location/upstream/backend failure | Inspect nginx error log, direct backend health, upstream IP/port |

`scripts/verify/diagnose.sh` stops at the first failed layer. This prevents an HTTP symptom from being misdiagnosed before DNS or TCP has been established.

For nginx upstream failure, test each backend directly from the edge, inspect the error log, confirm PF authorizes that edge, and verify `max_fails`, `fail_timeout`, and retry policy. Restore the failed backend and allow the passive failure window to expire before expecting it in samples.
