# Evidence register

Evidence status is based only on committed, reviewable artifacts. Team-reported tests are documented separately and are not silently promoted to evidence-backed passes.

| ID | Status | What it supports | Artifact |
| --- | --- | --- | --- |
| FV-01 | Verified with committed evidence | Primary DNS returned `10.7.2.149` | `final-verification/live-health-check.txt` |
| FV-02 | Verified with committed evidence | Secondary DNS returned `10.7.2.149` | `final-verification/live-health-check.txt` |
| FV-03 | Verified with committed evidence | Primary HTTP `200`, `X-Backend: A` | `final-verification/live-health-check.txt` |
| FV-04 | Verified with committed evidence | Standby HTTP `200`, `X-Backend: B` | `final-verification/live-health-check.txt` |
| FV-05 | Verified with committed evidence | Primary HTTPS returned `200` | `final-verification/live-health-check.txt` |
| A | Reported live; evidence incomplete | Resolver outage and recovery | `extension-a-backup-dns/README.md` |
| B | Reported live; evidence incomplete | TTL/manual DNS switchover | `extension-b-dns-ttl/README.md` |
| C | Implemented; not fully validated | PF backend isolation | `extension-c-firewall/README.md` |
| D | Reported live; evidence incomplete | Backend failure/recovery | `extension-d-failover/README.md` |
| E | Partially evidenced | Standby accessibility proven; cutover transcript missing | `extension-e-edge-migration/README.md` |
| F | Implemented; not fully validated | Layered fault scenarios | `extension-f-troubleshooting/README.md` |
| PCAP | Not verified | DNS/TCP/TLS Wireshark observations | No reviewed capture committed |

The original final-verification transcript and its timestamp must remain unchanged. It records `Tue Nov 24 02:38:28 IST 2026` and commit `58cd58a` at collection time.

Raw PCAP/PCAPNG files and `raw/` directories are ignored by default. Add only sanitized exports or explicitly approved captures after checking for unrelated personal traffic and sensitive material.
