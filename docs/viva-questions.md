# Viva questions and concise answers

1. **Why use private `.test` domains?** They provide controlled names for the authorized LAN without publishing records to public DNS.
2. **Why have two DNS resolvers?** Resolver redundancy preserves a second query path if one dnsmasq instance is unavailable.
3. **Does secondary DNS automatically fail over nginx?** No. Both resolvers normally return the primary edge; edge migration requires a manual record change on both.
4. **Why use TTL 30?** It shortens planned migration convergence while remaining long enough to observe caching. Client behavior can still exceed the apparent TTL.
5. **Why is `/healthz` uncached?** Every sample must reach nginx and an upstream to prove backend selection and failover.
6. **Which endpoint is cached?** Exact HTTPS `/api/status`, with nginx exposing `X-Cache-Status` and a ten-second validity period.
7. **How does nginx choose backends?** Default round robin among available upstreams; strict alternation is not guaranteed.
8. **How is a failed backend detected?** Passively from connection/request failures. `max_fails=1` and `fail_timeout=10s` temporarily suppress it.
9. **Why can a sequence show A, A, B?** Retries, failure state, keepalive, workers and earlier caching can affect observations. Presence of both healthy backends is the relevant proof.
10. **What does the standby edge provide?** A separately running nginx instance that can be selected through controlled DNS cutover.
11. **Is edge failover automatic?** No; it is manual DNS switchover and depends on caches/TTL.
12. **Why use PF anchors?** They scope project rules for inspection and rollback without replacing the whole host ruleset.
13. **Has PF isolation been proven?** The implementation exists, but no committed live PF evidence currently supports a pass claim.
14. **Why diagnose DNS before HTTP?** HTTP depends on name resolution, TCP and TLS. Finding the first failed prerequisite avoids misleading symptoms.
15. **Why not use `curl -k`?** It disables certificate verification and cannot prove trusted server identity.
16. **What does committed evidence prove?** Both resolvers returned the primary edge, primary and standby HTTP responded with backend identities, and primary HTTPS returned 200.
17. **What is still an evidence gap?** Dedicated load-balancing, failure/recovery, DNS cutover, cache, PF, troubleshooting and Wireshark artifacts.
18. **How are secrets protected?** Private-key and environment patterns, local inventory and generated files are ignored; keys remain outside Git.
19. **What are the relevant layers?** DNS/HTTP are application protocols, TLS secures application data over TCP, TCP is transport, IP handles addressing/routing, and Wi-Fi/Ethernet provide link/physical delivery.
20. **What is the biggest architectural limitation?** The primary edge is the active entry point until operators complete DNS switchover.
