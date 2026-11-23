# Extension procedures and evidence gates

## A — Backup DNS

Use Shitanshu for primary DNS, one agreed second Mac for backup DNS, and a third Mac as client. Prove each resolver directly, record `scutil --dns`, stop only the primary service, run a normal client lookup, restore primary, and repeat direct checks. Capture commands and timestamps. Roll back client DNS settings.

## B — TTL and controlled record changes

Publish the primary edge with TTL 30 on both resolvers. Capture initial answer and TTL. Replace both installed hosts files with the standby record, reload, query the authoritative resolvers, observe the client's remaining cached TTL, wait for expiry, then demonstrate the explicit macOS cache flush. Roll back to primary.

## D — Backend failover

Run `check-failover.sh` while both backends are running and retain samples showing A and B. Start recording, stop Backend A with Ctrl-C, repeat until all successful samples identify B, restart A, wait longer than `fail_timeout`, and retain samples showing A and B again. `/healthz` is uncached; do not use cached `/api/status` as failover proof.

## C — Firewall isolation

Confirm edge-to-backend and client-to-backend reachability before PF. Validate and load the dedicated anchor on one backend at a time. Prove both edge IPs remain authorized and a non-edge client is blocked. Roll back the anchor immediately after evidence collection and confirm baseline recovery.

## E — Edge migration

Validate the standby directly with `--resolve`, including trusted TLS and both upstreams. Publish the standby IP on both DNS resolvers, capture authoritative and cached answers, wait one TTL, verify the normal service through standby, then restore primary records unless the team explicitly chooses otherwise.

## F — Troubleshooting

Introduce one authorized, reversible fault at a time. Start at DNS, then TCP, TLS, and HTTP. Record the failing command, diagnosis, correction, successful retry, and rollback. Never combine faults because the evidence becomes ambiguous.
