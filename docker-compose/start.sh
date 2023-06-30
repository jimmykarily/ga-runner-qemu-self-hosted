#!/bin/bash

GH_OWNER=$GH_OWNER
GH_REPOSITORY=$GH_REPOSITORY
GH_TOKEN=$GH_TOKEN

RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
RUNNER_NAME="dockerNode-${RUNNER_SUFFIX}"

export RUNNER_ALLOW_RUNASROOT=true

function wait_for_process () {
    local max_time_wait=30
    local process_name="$1"
    local waited_sec=0
    while ! pgrep "$process_name" >/dev/null && ((waited_sec < max_time_wait)); do
        echo "Process $process_name is not running yet. Retrying in 1 seconds"
        echo "Waited $waited_sec seconds of $max_time_wait seconds"
        sleep 1
        ((waited_sec=waited_sec+1))
        if ((waited_sec >= max_time_wait)); then
            return 1
        fi
    done
    return 0
}

REG_TOKEN=$(curl -sX POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/registration-token | jq .token --raw-output)

echo "Starting docker daemon"
sudo /usr/bin/dockerd &
echo "Waiting for dockerd to be running"
if ! wait_for_process "dockerd"; then
    echo "dockerd is not running after max time"
    exit 1
else
    echo "dockerd is running"
fi

cd /home/runner/actions-runner

echo "Starting runner with name ${RUNNER_NAME}"
./config.sh --unattended --ephemeral --url https://github.com/${GH_OWNER}/${GH_REPOSITORY} --token ${REG_TOKEN} --name ${RUNNER_NAME}

cleanup() {
    echo "Removing runner ${RUNNER_NAME}"
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Allow the "runner" user to access /dev/kvm
# Might not be the best solution but adding to the kvm group didn't work
# https://askubuntu.com/a/1081326
sudo setfacl -m u:runner:rwx /dev/kvm

./run.sh & wait $!
