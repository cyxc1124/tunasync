#!/bin/bash
set -euo pipefail

test_user=$1
cd "/home/$test_user"

# hostfs exposes the result to the runner even if the remote shell is unavailable.
finish() {
    test_status=$?
    printf '%s\n' "$test_status" > cgroup-v1-tests.status.tmp
    mv cgroup-v1-tests.status.tmp cgroup-v1-tests.status
    exit "$test_status"
}
trap finish EXIT
exec > cgroup-v1-tests.log 2>&1

cat /proc/cmdline
cat /proc/self/cgroup
lssubsys -am
test -f /sys/fs/cgroup/systemd/tasks
cgcreate -a "$test_user" -t "$test_user" -g cpu:tunasync
cgcreate -a "$test_user" -t "$test_user" -g memory:tunasync

TERM=xterm-256color ./worker.test -test.v=true \
    -test.coverprofile profile3.gcov -test.run TestCgroup

cgexec -g '*:/' bash -ec '
    echo 0 > /sys/fs/cgroup/systemd/tasks
    exec sudo -u "$1" env USECURCGROUP=1 TERM=xterm-256color \
        cgexec -g cpu,memory:tunasync ./worker.test -test.v=true \
        -test.coverprofile profile4.gcov -test.run TestCgroup
' -- "$test_user"

test -s profile3.gcov
test -s profile4.gcov
