# Backend isolation with macOS PF

The rendered rules authorize both edge IPs to the one backend port and block other inbound clients to that port. Each backend uses its own interface and port. The rules are loaded into the isolated `team1/backend` anchor and do not replace the global PF ruleset.

Before applying, confirm current IPs, active interface, remote/local console access, `sudo pfctl -vnf`, and the current PF state. The main `/etc/pf.conf` must explicitly invoke the project anchor; loading rules into a named anchor alone does not make them part of packet evaluation. After backing up `/etc/pf.conf`, manually add one of these reviewed forms:

```pf
anchor "team1/*"
```

or a persistent file-based form:

```pf
anchor "team1/backend"
load anchor "team1/backend" from "/etc/pf.anchors/team1.backend"
```

Validate the complete `/etc/pf.conf` before reloading it. `apply.sh` is a dry run unless `--apply` is supplied; it refuses to load rules unless it sees a matching anchor reference, and it deliberately does not enable PF globally. Editing/reloading the host ruleset and enabling PF remain manual, supervised actions because macOS services may already manage PF.

Test nginx-to-backend access from both authorized edges, then attempt direct access from Shitanshu's client. Capture timeout/blocked evidence and the edge's successful response. Finally run `rollback.sh --apply` and verify direct access returns to the pre-test state.
