# Troubleshooting: DNS → TCP → TLS → HTTP/application

Always stop at the first failed dependency. Do not change multiple components simultaneously.

| Stage | Repository command | Success | Failure interpretation |
| --- | --- | --- | --- |
| DNS | `scripts/verify/check-dns.sh RESOLVER EXPECTED_EDGE` | Both private names return expected edge | resolver/listener down, wrong record, port 53 blocked |
| TCP | `scripts/verify/check-tcp.sh EDGE 8443` | connection succeeds | wrong IP/port, route, listener or PF problem |
| TLS | `scripts/verify/check-tls.sh EDGE 8443 [PUBLIC_CA]` | hostname and chain verify with code 0 | wrong SAN/chain/trust/SNI, expired certificate, incorrect clock |
| HTTP | `scripts/verify/check-http.sh EDGE 8443 [PUBLIC_CA]` | `200`, valid `X-Backend`, `no-store` | nginx route, upstream, backend or application failure |

The ordered wrapper is:

```bash
scripts/verify/diagnose.sh config/inventory.env
```

## DNS checks

```bash
dig @10.7.30.125 app.team1.test A
dig @10.7.6.134 app.team1.test A
sudo lsof -nP -iUDP:53 -iTCP:53
scutil --dns
```

Confirm both installed hosts files contain the same active edge. Restore primary records on both resolvers before concluding recovery.

## TCP checks

```bash
nc -G 3 -zv 10.7.2.149 8443
nc -G 3 -zv 10.7.6.134 3001
nc -G 3 -zv 10.7.18.193 3002
```

On the destination, inspect listeners with `lsof -nP -iTCP -sTCP:LISTEN`. Do not enable/disable PF merely to test a hypothesis.

## TLS checks

```bash
openssl s_client \
  -connect 10.7.2.149:8443 \
  -servername app.team1.test \
  -verify_hostname app.team1.test
```

Check SANs, issuer, validity dates, trust and system time. `curl -k` bypasses identity verification and is never acceptable as successful TLS evidence.

## HTTP and upstream checks

```bash
curl -i http://10.7.6.134:3001/healthz
curl -i http://10.7.18.193:3002/healthz
scripts/verify/check-http.sh 10.7.2.149 8443
```

If direct backend checks pass but edge HTTP fails, inspect nginx configuration and error logs. If only one backend fails, confirm its process, IP/port, PF authorization and the nginx passive-failure window. After recovery, wait longer than `fail_timeout` before expecting it in samples.

## Safe recovery order

1. Restore correct backend process.
2. Validate nginx config before reload.
3. Restore primary DNS records on both resolvers.
4. Wait one TTL or flush only the designated client cache with approval.
5. Remove only the project PF anchor if it was part of the test.
6. Repeat the complete diagnostic sequence and preserve both failing and recovered outputs.
