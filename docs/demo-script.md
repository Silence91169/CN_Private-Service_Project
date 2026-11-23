# Five-minute teacher demonstration

The default viva path is non-destructive. Do not stop services, alter DNS, or load PF unless the teacher explicitly requests a live failure test and the team agrees.

## Before the teacher arrives

### Shitanshu — integration and primary DNS

- Open the GitHub README, `evidence/final-verification/live-health-check.txt`, and a terminal in the repository.
- Confirm both direct DNS queries work.
- Confirm client certificate trust and save original DNS settings.
- Keep commands in history but do not change resolver settings during the demo.

### Keshav — primary edge

- Confirm `nginx -t` and the primary nginx process.
- Confirm direct access to Backend A and Backend B.
- Keep access/error logs available without exposing private-key paths or contents.

### Shivam — Backend A and secondary DNS

- Confirm Backend A `/healthz` returns `X-Backend: A`.
- Confirm the secondary resolver returns the primary edge.
- Keep Backend A running; do not stop it for the default demo.

### Yash — Backend B and standby edge

- Confirm Backend B `/healthz` returns `X-Backend: B`.
- Confirm standby HTTP/HTTPS directly with an edge-specific verification command.
- Keep both services running.

## Timed presentation

1. **0:00–0:35 — Repository and objective**
   - Show the README status statement and architecture.
   - State that edge recovery is manual DNS switchover.

2. **0:35–1:05 — Roles and DNS**

   ```bash
   scripts/verify/check-dns.sh 10.7.30.125 10.7.2.149
   scripts/verify/check-dns.sh 10.7.6.134 10.7.2.149
   ```

3. **1:05–1:45 — Load balancing**

   ```bash
   scripts/verify/check-failover.sh 10.7.2.149 8443 10
   ```

   Explain that `/healthz` is uncached and strict A/B alternation is not promised.

4. **1:45–2:15 — Trusted HTTPS**

   ```bash
   scripts/verify/check-tls.sh 10.7.2.149 8443
   scripts/verify/check-http.sh 10.7.2.149 8443
   ```

5. **2:15–2:50 — Cache MISS/HIT**

   ```bash
   curl -sS -D - -o /dev/null https://app.team1.test:8443/api/status
   curl -sS -D - -o /dev/null https://app.team1.test:8443/api/status
   ```

   Point to `X-Cache-Status`. If the first response is already `HIT`, wait beyond ten seconds or explain that a prior request populated the cache; do not fake `MISS`.

6. **2:50–3:25 — Standby edge**

   ```bash
   scripts/verify/check-http.sh 10.7.18.193 8443
   ```

   Explain the 30-second TTL and manual record replacement; do not perform cutover by default.

7. **3:25–4:10 — Evidence and accuracy**
   - Open `evidence/final-verification/live-health-check.txt`.
   - Identify what it proves and what still lacks committed evidence.

8. **4:10–4:40 — Automation and troubleshooting**

   ```bash
   bash scripts/run-static-tests.sh
   ```

   Explain DNS → TCP → TLS → HTTP/application.

9. **4:40–5:00 — Git history and limitations**

   ```bash
   git log --oneline --decorate -10
   git status --short --branch
   ```

   State PF/Wireshark evidence gaps and that `main` is not merged yet.

If any live command fails, preserve the output and switch to the committed evidence plus troubleshooting explanation. Never claim a failed command succeeded.
