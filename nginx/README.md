# Primary and standby edges

Both edge templates use the same upstreams, TLS identity, timeouts, passive failure policy, cache behavior, and uncached `/healthz` route. Render locally, copy only the appropriate role configuration to each edge, copy `proxy-common.conf`, and validate before any reload.

The standby must receive the same public certificate chain and a securely transferred private key outside Git. Confirm the certificate SAN covers both `app.team1.test` and `api.team1.test`. Never place the private key in this repository or evidence.

Validate the standby directly before DNS cutover with curl's `--resolve` option. This changes only one request and does not depend on DNS. After both resolvers publish the standby record, observe TTL behavior, verify normal HTTPS, and retain the primary edge for rollback.

Rollback consists of restoring the primary-edge record on both DNS resolvers, reloading them, waiting one TTL or explicitly flushing the designated test client, then verifying normal HTTPS resolves to the primary. nginx is still a single point of failure until DNS cutover occurs; passive upstream checks protect backend availability, not edge availability.
