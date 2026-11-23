# Deployment order

## Safety baseline

Work only on the authorized LAN. Record current IPs, interfaces, macOS network-service DNS values, PF state, Homebrew prefixes, and service state. Keep TLS private keys outside Git. Render into `generated/`, inspect every output, and validate before installation.

## Machine order

1. **Shivam / Backend A:** clone the branch, run static tests, start `scripts/backend/run.sh A`, verify locally, then verify from both edge Macs.
2. **Yash / Backend B:** repeat with `scripts/backend/run.sh B`.
3. **Keshav / primary nginx:** render or securely receive its generated config, install certificate/key locally, validate, start/reload manually, and test `/healthz` plus `/api/status`.
4. **Standby-edge Mac:** deploy the standby template and same TLS identity, validate directly with `--resolve`, but do not change DNS yet.
5. **Shitanshu / primary DNS:** deploy the primary resolver with primary-edge records and verify direct queries.
6. **Backup-DNS Mac:** deploy equivalent records and verify direct queries.
7. **Test client:** manually record and configure both DNS resolver IPs; then execute Extensions A, B, D, C, E, and F in that order.

Exact live commands depend on the current inventory and Homebrew installation paths. The operator must paste actual command output before a test is marked successful.

## Global rollback

Restore the primary-edge DNS record on both resolvers, flush/wait only on the designated test client, remove the `team1/backend` PF anchor, restore prior client DNS values, stop the standby edge if it was only temporary, and confirm both backends and the primary edge are healthy.
