# Four-Mac deployment and rollback

This runbook prepares commands; it does not authorize changing a live host. Record existing DNS, PF, service, and certificate state before any supervised change.

## 1. Common preparation

On each Mac:

```bash
git clone --branch codex/phase-2 --single-branch \
  https://github.com/Silence91169/CN_Private-Service_Project.git
cd CN_Private-Service_Project
cp config/inventory.example.env config/inventory.env
nano config/inventory.env
scripts/render-configs.sh
bash scripts/run-static-tests.sh
```

Use current session values. The 24 November snapshot is: primary DNS `10.7.30.125`, secondary DNS/backend A `10.7.6.134`, primary edge `10.7.2.149`, standby edge/backend B `10.7.18.193`, TTL `30`.

## 2. Shivam — Backend A and secondary DNS

Terminal 1:

```bash
scripts/backend/run.sh A
```

Terminal 2:

```bash
curl -i http://127.0.0.1:3001/healthz
dns/scripts/validate.sh "$PWD/generated/dns/secondary/dnsmasq.conf"
```

For supervised DNS deployment, install `generated/dns/primary-edge.hosts` at the `addn-hosts` path shown in the rendered secondary config, then start dnsmasq with that rendered config. Do not overwrite an existing resolver configuration without a backup.

## 3. Yash — Backend B and standby nginx

Terminal 1:

```bash
scripts/backend/run.sh B
```

Terminal 2:

```bash
curl -i http://127.0.0.1:3002/healthz
nginx/scripts/validate.sh "$PWD/generated/nginx/standby.conf"
nginx/scripts/deploy.sh "$PWD/generated/nginx/standby.conf" standby
```

The deploy command is a dry run. After explicit approval, rerun with `--apply`, validate the installed configuration, and start/reload nginx manually. The standby needs the same certificate identity, with its private key transferred outside Git.

## 4. Keshav — Primary nginx

```bash
nginx/scripts/validate.sh "$PWD/generated/nginx/primary.conf"
nginx/scripts/deploy.sh "$PWD/generated/nginx/primary.conf" primary
```

After explicit approval, deploy with `--apply`, run authoritative `nginx -t`, then start/reload manually. Validate both upstreams from Keshav before blaming nginx:

```bash
curl -i http://10.7.6.134:3001/healthz
curl -i http://10.7.18.193:3002/healthz
```

## 5. Shitanshu — Primary DNS and integration

```bash
dns/scripts/validate.sh "$PWD/generated/dns/primary/dnsmasq.conf"
scripts/verify/check-dns.sh 10.7.30.125 10.7.2.149
scripts/verify/check-dns.sh 10.7.6.134 10.7.2.149
```

Install record files and change client resolver settings only during a supervised test. Save the original output of:

```bash
networksetup -getdnsservers "Wi-Fi"
scutil --dns
```

## 6. Non-destructive service checks

```bash
scripts/verify/check-http.sh 10.7.2.149 8443
scripts/verify/check-tls.sh 10.7.2.149 8443
scripts/verify/check-http.sh 10.7.18.193 8443
scripts/verify/check-failover.sh 10.7.2.149 8443 10
```

If the local CA is not in the default trust store, pass its public certificate as the final argument supported by the verification script. Never use a private key or `curl -k` as proof.

## 7. Manual edge switchover

1. Prove the standby directly with `check-http.sh` and `check-tls.sh`.
2. Back up the installed hosts files on both resolvers.
3. Install the rendered `standby-edge.hosts` file on both resolvers.
4. Validate and reload each resolver manually.
5. Query each resolver directly; then observe client cache/TTL behavior.
6. Verify normal HTTP/HTTPS through the standby.
7. Restore `primary-edge.hosts` on both resolvers unless the team deliberately retains standby.

This is manual DNS switchover, not automatic failover.

## 8. PF isolation safety gate

PF is not required for the non-destructive viva demonstration. Before a later PF test, back up `/etc/pf.conf`, validate the complete ruleset, confirm console access, and use the dedicated `team1/backend` anchor. `firewall/apply.sh` is dry-run by default and does not enable PF globally.

## Rollback

- DNS: restore primary-edge records on both resolvers, validate/reload, wait one TTL, and restore original client DNS settings.
- nginx: validate the previous config and reload it manually; do not delete certificate material.
- backend: restart the correct `scripts/backend/run.sh A|B` process.
- PF: run `firewall/rollback.sh --apply` only with approval; it flushes the project anchor, not global PF.
- Evidence: retain failed outputs as genuine diagnostic evidence; never rewrite them as passes.
