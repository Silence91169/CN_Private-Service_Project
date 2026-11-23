# Architecture and request flow

## Verified lab-session inventory — 24 November 2026

| Member | IP | Services |
| --- | --- | --- |
| Shitanshu | `10.7.30.125` | Primary dnsmasq, integration client |
| Keshav | `10.7.2.149` | Primary nginx on `8080`/`8443` |
| Shivam | `10.7.6.134` | Backend A on `3001`, secondary dnsmasq |
| Yash | `10.7.18.193` | Backend B on `3002`, standby nginx on `8080`/`8443` |

These are verified historical session values, not permanent configuration. Templates obtain current values from ignored `config/inventory.env`.

```text
                           normal DNS answer: 10.7.2.149
Shitanshu/client ──DNS──┬── Primary DNS, Shitanshu 10.7.30.125:53
                       └── Secondary DNS, Shivam   10.7.6.134:53

Client ── HTTP/HTTPS ──> Primary nginx, Keshav 10.7.2.149:8080/8443
                              │ default round robin + passive retry
                              ├──> Backend A, Shivam 10.7.6.134:3001
                              └──> Backend B, Yash  10.7.18.193:3002

Client -. manual DNS cutover .-> Standby nginx, Yash 10.7.18.193:8080/8443
                                      ├──> Backend A
                                      └──> Backend B
```

## Availability model

- Resolver redundancy: the client can be configured with both DNS servers.
- Backend availability: nginx passively detects upstream request/connect failures and retries eligible requests.
- Edge recovery: operators manually change both DNS record files to the standby edge and wait for TTL/cache convergence.
- This design does not provide automatic nginx-edge failover.

## Protocol and layer mapping

| Function | Protocol/layer |
| --- | --- |
| Private name resolution | DNS over UDP/TCP at application layer |
| Edge/backend reachability | IP routing and TCP transport |
| Backend isolation | macOS PF packet filtering at network/transport boundaries |
| Encrypted client session | TLS over TCP |
| Proxy, caching and health routes | HTTP/application layer |
