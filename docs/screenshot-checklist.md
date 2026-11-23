# Evidence and screenshot checklist

Every screenshot must show the machine role, command, complete relevant output, and visible timestamp where practical. Crop personal notifications and unrelated traffic; never expose private keys, passwords, tokens, full browsing traffic, or certificate key material.

- A: both direct DNS answers, client resolver list, primary stop, successful secondary resolution, primary recovery.
- B: initial answer/TTL, authoritative changed record, cached old answer with remaining TTL, updated answer after expiry, cache-flush command and recovery.
- D: both backends before failure, Backend A stop, only B during failure, Backend A restart, both after recovery.
- C: PF syntax check, anchor rules, authorized edge success, unauthorized direct failure, anchor rollback, recovered baseline.
- E: standby direct TLS/HTTP validation, DNS record cutover, TTL transition, service via standby, restored primary record.
- F: one failure and successful recovery for DNS, TCP, TLS, and HTTP/application.

Start screen recording immediately before the controlled state change, narrate the expected result, show the verification command, perform recovery, show the recovered result, then stop. Do not record long installation or waiting periods.
