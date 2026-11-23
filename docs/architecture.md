# Architecture and request flow

```text
Client
  ├─ DNS ──> Primary dnsmasq ─┐
  │          Secondary dnsmasq ├─ app.team1.test / api.team1.test
  │                            ┘
  └─ HTTPS ─> Active nginx edge ─┬─> Backend A :3001
                 │               └─> Backend B :3002
                 └─ DNS cutover target: standby nginx edge
```

DNS redundancy removes the primary resolver as the only name-resolution path. Backend redundancy lets nginx retry another upstream after passive failure detection. DNS cutover supplies a controlled recovery path for the edge, but it is not instantaneous HA: resolver/client caches and TTL determine convergence.

Layer mapping: DNS is application layer over UDP/TCP; reachability and PF filtering affect IP/transport; TLS protects the application session above TCP; nginx and Node.js implement HTTP/application behavior.
