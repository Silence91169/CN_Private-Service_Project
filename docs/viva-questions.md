# Viva preparation

1. **Why two DNS resolvers?** Resolver redundancy preserves name resolution when one dnsmasq instance is unavailable.
2. **Does a second DNS server make nginx highly available?** No. It enables resolution continuity and controlled cutover; nginx remains the active edge until DNS points elsewhere.
3. **Why use a short TTL?** It limits how long caches retain an old edge address, reducing planned-migration convergence time at the cost of more DNS queries.
4. **Why is `/healthz` uncached?** Each response must reach nginx and an upstream so backend selection and failover evidence are genuine.
5. **How does open-source nginx detect backend failure?** Passively, from connection/request failures; `max_fails` and `fail_timeout` temporarily suppress a failing upstream.
6. **Why can round-robin appear non-alternating?** Failure state, keepalive behavior, retries, multiple workers, and cached responses can alter observations; the goal is use of both healthy servers, not strict alternation.
7. **What does PF isolation protect?** It prevents arbitrary LAN clients from directly reaching backend ports while authorizing the known edge IPs.
8. **Why use a PF anchor?** It scopes project rules so they can be inspected and removed without replacing the host's entire ruleset.
9. **Why test DNS before HTTP?** HTTP depends on lower prerequisite stages; layered diagnosis identifies the first broken dependency.
10. **Why is `curl -k` unacceptable for TLS proof?** It disables certificate verification and therefore cannot prove trusted identity.
11. **What is the edge-migration limitation?** Clients may use cached DNS answers until TTL expiry, so old and new edges must overlap safely.
12. **Which layer does each feature affect?** DNS/HTTP are application layer, TCP ports and connection failover are transport behavior, IP addressing/routing is internet/network layer, and LAN/Wi-Fi carries frames at link/physical layers.
