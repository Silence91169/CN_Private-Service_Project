# Five-minute demonstration script

1. **0:00–0:35:** Introduce the four roles and request flow using `docs/architecture.md`.
2. **0:35–1:10:** Show direct primary and secondary DNS answers, then the configured 30-second TTL.
3. **1:10–2:05:** Sample uncached `/healthz`, stop Backend A, show continued responses from B, restart A, and show recovery.
4. **2:05–2:45:** Show the PF anchor, successful nginx access, blocked direct client access, and rollback.
5. **2:45–3:40:** Validate standby directly, change both DNS records, show TTL convergence, and verify the service through standby.
6. **3:40–4:30:** Diagnose one reversible fault in DNS → TCP → TLS → HTTP order.
7. **4:30–5:00:** State security controls, single-point/TTL limitations, rollback, and evidence status.

Pre-stage terminals but perform real commands. If a step fails, say so, preserve the output, and follow the troubleshooting sequence rather than claiming success.
