#!/bin/bash

REG_TOKEN=$(curl -sX POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/registration-token | jq .token --raw-output)

RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)

export RUNNER_ALLOW_RUNASROOT=true
export RUNNER_ORG=$GH_OWNER
export RUNNER_REPO=$GH_REPOSITORY
export RUNNER_TOKEN=$REG_TOKEN
# Hack to get to this block:
# https://github.com/actions/actions-runner-controller/blob/d134dee14b5ecd76ecbd2b3b2e1bc79fe3f4a95d/runner/startup.sh#L36
export RUNNER_ENTERPRISE="dummy"
export RUNNER_NAME="dockerNode-${RUNNER_SUFFIX}"
export RUNNER_EPHEMERAL=true

entrypoint-dind.sh
