# Mattermost on Planetary Quantum

Mattermost Team Edition + Postgres as a Swarm stack. TLS is handled by
quantum-caddy at the edge; all data is in named Docker volumes; one-off
jobs fix volume ownership before the app starts and setup the bucket.

> [!TIP]
> Check out our [website](https://www.planetary-quantum.com).

## Layout

```
compose.yml          # swarm stack
.envrc.example       # copy to .envrc, fill in, then `direnv allow`
Makefile             # deploy / logs / dev-down ...
```

## Deploy

1. Copy and edit env, then let direnv load it:
   ```sh
   cp .envrc.example .envrc
   # set QUANTUM_ENDPOINT, DOMAIN, POSTGRES_PASSWORD, S3_BUCKET, S3_ACCESS_KEY and S3_SECRET_KEY
   direnv allow
   ```
> [!TIP]
> We offer object storage, [customers get their account here](https://ostor-usage.pqapp.dev/).

2. Make sure the external `public` overlay exists on your endpoint. If deploying elsewhere:
   ```sh
   docker network create -d overlay --attachable public
   ```

3. Deploy with `quantum-cli`:
   ```sh
   make deploy
   ```

## How it works

- **setup** runs first: chowns the `mm-*` volumes to `2000:2000` (Mattermost's
  runtime user) and waits for Postgres. `restart_policy: none` -> runs once.
- **createbucket** creates the S3 bucket if it does not exist (via `mc`), then
  exits. `restart_policy: none` -> runs once.
- **postgres** stores data in the `mm-db` volume with a read-only rootfs, only on
  the internal `lan` overlay (never on `public`).
- **mattermost** mounts the `mm-*` volumes, joins both `lan` (to reach the DB)
  and `public` (so caddy can reach it on 8065). File uploads go to S3-compatible
  object storage. The `labels` tell quantum-caddy the hostname and upstream port.

## quantum-caddy labels

```yaml
deploy:
  labels:
    caddy: ${DOMAIN}
    caddy.reverse_proxy: "{{upstreams 8065}}"
```

> [!TIP]
> In Swarm, caddy reads labels from the **service** (`deploy.labels`), not the container. If your caddy install uses a non-default label prefix or an ingress-network setting, adjust accordingly.

## Day 2

Manage via [Quantum Console](https://console.planetary-quantum.com/) and [quantum-cli](https://docs.planetary-quantum.com/setup/quantum-cli-basics/).

## Dev

```sh
make logs        # tail app logs
make setup-logs  # see what the init job did
make dev-ps      # service status
make dev-down    # remove stack (volumes are kept)
```

Volumes persist across `make dev-down`. To wipe data, remove the `mm-*` volumes
explicitly with `docker volume rm`.
