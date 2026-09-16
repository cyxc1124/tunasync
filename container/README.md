# Container deployment

The root Dockerfile builds both tunasync and tunasynctl, then packages them with rsync, curl, wget, git, an SSH client, and Python 3. The image runs as UID/GID 10001 and uses tini to forward signals and reap processes.

Build locally:

```sh
docker build -t ghcr.io/cyxc1124/tunasync:cyxc-v0.2.0 .
```

The default command starts a manager on port 14242 with a BoltDB database in `/data/manager`. Mount persistent storage there. A worker uses the same image with different arguments:

```sh
docker run --rm --mount type=bind,src=/absolute/worker.conf,dst=/etc/tunasync/worker.conf,readonly \
  --mount type=bind,src=/absolute/mirrors,dst=/data/mirrors \
  ghcr.io/cyxc1124/tunasync:cyxc-v0.2.0 worker --config /etc/tunasync/worker.conf
```

Ensure the mounted directories are writable by UID/GID 10001. Configure the worker's advertised hostname so the manager can reach its control API. Disable native cgroup and Docker integration when using the standard Kubernetes deployment; use Pod resource limits instead. Mount custom scripts or derive another image for providers that need additional dependencies.

The workspace's `charts/` collection supplies three independent charts and Helm releases: tunasync, worker, and web. Install them in that order, using each chart's own values-production.yaml. The worker and web explicitly configure manager.url; the worker owns the mirror PVC and web mounts it read-only using persistence.existingClaim. The production manager uses an external Redis instance without a database PVC; the standalone image still defaults to BoltDB. Each worker owns a distinct set of mirror jobs.

Fork releases use the independent `cyxc-vMAJOR.MINOR.PATCH` Git tag namespace, starting with `cyxc-v0.2.0`. Keep upstream `v*` tags unchanged and never move or reuse a published fork tag.

`.github/workflows/container.yml` validates image builds for pull requests and publishes `linux/amd64` and `linux/arm64` images to GHCR on master pushes, `cyxc-v*` tags, and manual runs. Release image tags preserve the complete Git tag, for example `ghcr.io/cyxc1124/tunasync:cyxc-v0.2.0`. Master builds also publish `latest` and `sha-<short SHA>` for development. Charts pin the fork release tag and use `IfNotPresent`.

The separate release workflow publishes Linux amd64, arm64, riscv64, and loong64 binary archives for the same fork tag. For a manual binary release, select an existing `cyxc-vMAJOR.MINOR.PATCH` tag, not a branch. The workspace tunasync and worker chart sources use version `0.2.0` and appVersion `cyxc-v0.2.0`; deploy them directly from their source directories.

The original manager and worker APIs are intended for a trusted control network. Do not expose them directly through a public Ingress. The web frontend only needs the manager's read-only `/jobs` response.
