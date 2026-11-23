# Phase 2 DNS deployment

The primary and secondary resolvers use equivalent templates and the same active hosts record. Render them with `scripts/render-configs.sh`. Generated files are never committed.

## Deployment

1. Create `config/inventory.env`, render, and review `generated/dns/`.
2. On Shitanshu's DNS Mac, install the rendered primary configuration and selected record file as `/usr/local/etc/team1-primary.hosts`.
3. On the backup-DNS Mac, install the secondary configuration and the same selected record as `/usr/local/etc/team1-secondary.hosts`.
4. Run `dns/scripts/validate.sh` before restarting either resolver.
5. Configure the test client manually with primary DNS first and secondary DNS second. Record the exact macOS network service and previous DNS settings for rollback.

Homebrew paths differ between Intel and Apple Silicon Macs. Use `brew --prefix` and the local service configuration rather than copying an assumed path.

## Backup resolver demonstration

Capture successful direct queries to both resolver IPs, a normal client query, the primary service stop, a client query that succeeds through the secondary, and primary recovery. `dig @resolver-ip` proves a particular resolver; a normal `dig name` demonstrates client resolver behavior.

macOS may not immediately try the second resolver in deterministic order. Use `scutil --dns` to document the effective resolver list, allow timeout, and distinguish direct-resolver proof from OS failover proof.

## TTL migration

Both templates publish `local-ttl=DNS_TTL`. Start with `primary-edge.hosts`, query with `dig` and record the TTL, replace the installed hosts file on both resolvers with `standby-edge.hosts`, then reload/restart both resolvers. Existing cache entries may retain the old answer until their remaining TTL reaches zero. Use `dns/scripts/flush-macos-cache.sh --apply` only during the explicit cache-flush part.

## Rollback

Restore the primary-edge hosts file on both resolvers, validate, restart or reload dnsmasq, wait one TTL, and verify both direct resolver answers. Restore the client's previous DNS list after all experiments.
