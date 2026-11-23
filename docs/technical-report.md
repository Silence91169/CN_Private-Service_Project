# Technical report

## Abstract

This project implements a private service platform across four macOS laptops on one LAN. Two dnsmasq resolvers publish private `.test` names, nginx terminates TLS and distributes traffic to two Node.js backends, and a second nginx instance provides a manually selected standby edge. The repository also implements controlled DNS TTL migration, passive backend failover checks, scoped PF rule templates, reproducible validation scripts, rollback guidance, and a layered troubleshooting method.

## System design

The verified 24 November 2026 snapshot used Shitanshu at `10.7.30.125` for primary DNS/integration, Keshav at `10.7.2.149` for primary nginx, Shivam at `10.7.6.134` for Backend A and secondary DNS, and Yash at `10.7.18.193` for Backend B and standby nginx. These values remain local inventory data rather than reusable template constants.

Normal requests resolve `app.team1.test` or `api.team1.test` to the primary edge. nginx terminates TLS on `8443`, exposes HTTP on `8080`, and uses default round robin plus passive retry across ports `3001` and `3002`. `/healthz` is intentionally uncached. Exact HTTPS `/api/status` uses a ten-second nginx cache. Edge recovery is a manual DNS record change with a 30-second configured TTL.

## Implementation controls

- Machine-specific configuration is rendered from ignored `config/inventory.env`.
- Private keys, generated files, raw captures and environment files are ignored.
- Mutation-capable scripts default to dry-run or require explicit `--apply`.
- PF rules are confined to a named anchor and do not enable PF globally.
- Test claims are separated by evidence quality.

## Results

### Verified with committed evidence

The timestamped `evidence/final-verification/live-health-check.txt` shows both DNS servers returning `10.7.2.149`, primary HTTP returning `200` with `X-Backend: A`, standby HTTP returning `200` with `X-Backend: B`, and primary HTTPS returning `200`.

### Reported during live team testing

The team reports successful trusted HTTPS using a local CA, reverse proxying, round-robin use of A and B, backend failure/recovery, DNS redundancy, manual DNS switchover, primary outage with standby accessibility, primary recovery, and nginx cache behavior. Dedicated sanitized transcripts/screenshots are not yet committed for every item, so these are not presented as evidence-complete results.

### Implemented but requiring additional validation

PF backend isolation and the complete DNS → TCP → TLS → HTTP fault challenge have code and procedures but lack committed live proof. Wireshark DNS/TCP/TLS captures are not present and are not claimed as completed.

## Availability analysis

Two DNS resolvers remove a single resolver dependency, but they do not automatically select a healthy edge. nginx handles backend failures passively using request/connect outcomes, `max_fails`, `fail_timeout`, and retry policy. Edge migration is operator-controlled and depends on TTL/cache convergence. Therefore, the design demonstrates practical resilience without claiming automatic end-to-end high availability.

## Security and rollback

TLS private keys stay outside Git. Evidence must be sanitized. PF changes require review of the existing host ruleset and have anchor-scoped rollback. DNS changes are applied to both resolvers and rolled back to primary records. Client DNS and certificate trust are never modified automatically by repository scripts.

## Limitations and remaining work

- Collect dedicated load-balancing, failure/recovery, DNS cutover, cache, PF and troubleshooting transcripts.
- Capture and sanitize Wireshark evidence only if required by the assignment.
- Reconfirm IPs and interfaces for every new lab session.
- Compare the final repository against the official assignment PDF when available.

## Conclusion

The repository provides a reproducible, security-conscious implementation and a truthful evidence model. The core private DNS and edge paths are demonstrated by committed results; remaining evidence gaps are explicitly identified rather than inferred.
