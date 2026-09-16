# tunasync

![Build Status](https://github.com/tuna/tunasync/workflows/tunasync/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/tuna/tunasync/badge.svg?branch=master)](https://coveralls.io/github/tuna/tunasync?branch=master)
[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)
![GPLv3](https://img.shields.io/badge/license-GPLv3-blue.svg)

## Get Started

- [中文文档](https://github.com/tuna/tunasync/blob/master/docs/zh_CN/get_started.md)

## Download

CYXC fork releases use `cyxc-vMAJOR.MINOR.PATCH` tags, separate from upstream `v*` tags. Linux amd64, arm64, riscv64, and loong64 binaries are available from [GitHub releases](https://github.com/cyxc1124/tunasync/releases).

The `cyxc-v0.2.0` container image is `ghcr.io/cyxc1124/tunasync:cyxc-v0.2.0`. Its manager and worker charts use chart version `0.2.0`, appVersion `cyxc-v0.2.0`, and the `IfNotPresent` pull policy.

## Design

```text
# Architecture

- Manager: Central instance for status and job management
- Worker: Runs mirror jobs

+------------+ +---+                  +---+
| Client API | |   |    Job Status    |   |    +----------+     +----------+ 
+------------+ |   +----------------->|   |--->|  mirror  +---->|  mirror  | 
+------------+ |   |                  | w |    |  config  |     | provider | 
| Worker API | | H |                  | o |    +----------+     +----+-----+ 
+------------+ | T |   Job Control    | r |                          |       
+------------+ | T +----------------->| k |       +------------+     |       
| Job/Status | | P |   Start/Stop/... | e |       | mirror job |<----+       
| Management | | S |                  | r |       +------^-----+             
+------------+ |   |   Update Status  |   |    +---------+---------+         
+------------+ |   <------------------+   |    |     Scheduler     |
|   BoltDB   | |   |                  |   |    +-------------------+
+------------+ +---+                  +---+


# Job Run Process


PreSyncing                           Syncing                               Success
+-----------+     +----------+    +-----------+    +-------------+     +--------------+
|  pre-job  +--+->| pre-exec +--->|  job run  +--->|  post-exec  +-+-->| post-success |
+-----------+  ^  +----------+    +-----------+    +-------------+ |   +--------------+
               |                                                   |
               |                +-----------------+                | Failed
               +----------------+    post-fail    |<---------------+
                                +-----------------+
```

## Building

Container deployment is supported through the root `Dockerfile`; the manager and worker share one image. See [container deployment](container/README.md) for GHCR publishing and runtime configuration. The workspace's `charts/` collection provides Helm charts for the complete mirror service.

Go version: 1.26

```shell
# for native arch
> make all
# for other arch
> make ARCH=linux-arm64 all
```

Binaries are in `build-$ARCH/`, e.g., `build-linux-amd64/`.
