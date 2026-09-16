# Container deployment

The root Dockerfile builds both tunasync and tunasynctl, then packages them with rsync, curl, wget, git, an SSH client, and Python 3. The image runs as UID/GID 10001 and uses tini to forward signals and reap processes.

Build locally:

```sh
docker build -t ghcr.io/cyxc1124/tunasync:latest .
```

The default command starts a manager on port 14242 with a BoltDB database in `/data/manager`. Mount persistent storage there. A worker uses the same image with different arguments:

```sh
docker run --rm --mount type=bind,src=/absolute/worker.conf,dst=/etc/tunasync/worker.conf,readonly \
  --mount type=bind,src=/absolute/mirrors,dst=/data/mirrors \
  ghcr.io/cyxc1124/tunasync:latest worker --config /etc/tunasync/worker.conf
```

Ensure the mounted directories are writable by UID/GID 10001. Configure the worker's advertised hostname so the manager can reach its control API. Disable native cgroup and Docker integration when using the standard Kubernetes deployment; use Pod resource limits instead. Mount custom scripts or derive another image for providers that need additional dependencies.

The workspace's `charts/` collection supplies three independent charts and Helm releases: tunasync, worker, and web. Install them in that order, using each chart's own values-production.yaml. The worker and web explicitly configure manager.url; the worker owns the mirror PVC and web mounts it read-only using persistence.existingClaim. Manager data uses a separate volume. Each worker owns a distinct set of mirror jobs.

`.github/workflows/container.yml` validates image builds for pull requests and publishes `linux/amd64` and `linux/arm64` images to GHCR on master pushes, version tags, and manual runs. Tags include `latest` for master, `sha-<short SHA>`, and `X.Y.Z` for a `vX.Y.Z` Git tag. The workflow uses GITHUB_TOKEN with packages write permission. Existing binary releases remain available through the separate release workflow.

The original manager and worker APIs are intended for a trusted control network. Do not expose them directly through a public Ingress. The web frontend only needs the manager's read-only `/jobs` response.
