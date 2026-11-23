# Extension procedures and evidence gates

## A — Backup DNS

Use Shitanshu (`10.7.30.125`) for primary DNS and integration, and Shivam (`10.7.6.134`) for secondary DNS. Prove each resolver directly, record `scutil --dns`, stop only the primary service during an approved failure test, run a normal client lookup, restore primary, and repeat direct checks. Capture commands and timestamps. Roll back client DNS settings. Both direct answers are committed; outage/recovery still needs a dedicated artifact.

## B — TTL and controlled record changes

Publish Keshav's primary edge (`10.7.2.149`) with TTL 30 on both resolvers. Capture initial answer and TTL. Replace both installed hosts files with Yash's standby record (`10.7.18.193`), reload, query the authoritative resolvers, observe the client's remaining cached TTL, wait for expiry, then demonstrate the explicit macOS cache flush. Roll back to primary. This is manual switchover.

## D — Backend failover

Run `check-failover.sh` against Keshav's primary edge while both backends are running and retain samples showing A and B. Only during an approved destructive demonstration, stop Backend A with Ctrl-C, repeat until all successful samples identify B, restart A, wait longer than `fail_timeout`, and retain samples showing A and B again. `/healthz` is uncached; do not use cached `/api/status` as failover proof. For the normal viva, explain this using evidence rather than stopping a service.

## C — Firewall isolation

Confirm edge-to-backend and client-to-backend reachability before PF. Validate and load the dedicated anchor on one backend at a time. Prove both edge IPs remain authorized and a non-edge client is blocked. Roll back the anchor immediately after evidence collection and confirm baseline recovery.

## E — Edge migration

Validate Yash's standby directly with edge-specific verification, including trusted TLS and both upstreams. Publish the standby IP on both DNS resolvers, capture authoritative and cached answers, wait one TTL, verify the normal service through standby, then restore Keshav's primary records unless the team explicitly chooses otherwise. Standby HTTP is committed; the cutover sequence still needs dedicated evidence.

## F — Troubleshooting

Introduce one authorized, reversible fault at a time. Start at DNS, then TCP, TLS, and HTTP. Record the failing command, diagnosis, correction, successful retry, and rollback. Never combine faults because the evidence becomes ambiguous.
