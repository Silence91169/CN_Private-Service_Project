# Evidence and screenshot checklist

Every artifact should show the machine role, command, relevant output and timestamp. Crop notifications and unrelated traffic. Never expose private keys, tokens, passwords, full personal paths, unrelated packets, or certificate key material.

## Already committed

- `evidence/final-verification/live-health-check.txt`: both DNS answers, primary HTTP, standby HTTP and primary HTTPS.

## High-priority missing evidence

- Round robin: one uncached sample set containing both `X-Backend: A` and `B`.
- Backend failure/recovery: both-up, A stopped/B serving, A restarted/both serving.
- DNS redundancy: primary unavailable, client continues via secondary, primary restored.
- TTL/cutover: old record/TTL, authoritative new record, client convergence, primary rollback.
- Cache: timestamped `MISS`, immediate `HIT`, and optional `EXPIRED`.
- TLS: certificate subject/SAN, issuer and successful verification code without bypass.

## Not yet claimed as passed

- PF: full syntax check, anchor contents, edge allowed, client blocked, rollback.
- Troubleshooting: one isolated failure and recovery at each DNS/TCP/TLS/HTTP stage.
- Wireshark: DNS query/answer, TCP three-way handshake, TLS ClientHello/ServerHello and encrypted application data.

Start screen recording immediately before a controlled state change; narrate expected behavior, show the command, perform recovery, prove recovery, and stop. For the normal viva, use non-destructive checks and existing evidence instead of stopping working services.
