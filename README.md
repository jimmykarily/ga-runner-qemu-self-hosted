This repository allows one to spin up GitHub Action runners inside a VM.
The runners are ephemeral, meaning they only run one job and then exit and de-register and
a new runner takes their place with no previous state saved anywhere.

It is heavily inspired by:

- This blog post https://dev.to/pwd9000/create-a-docker-based-self-hosted-github-runner-linux-container-48dh
- This repository: https://github.com/Pwd9000-ML/docker-github-runner-linux
- The actions-runner-controller project: https://github.com/actions/actions-runner-controller

Compared to the first project, it add on top:

- the ability to run everything inside a VM using qemu, thus limiting the amount of resources taken from the host and making it secure enough to be run on a workstation.
- the ability to have run KVM

Compared to actions-runner-controller project:

- it doesn't require Kubernetes. Runners can be started in just 2 steps/commands (start the vm, start the runners)

## Preparation

[As described in the blog post](https://dev.to/pwd9000/create-a-docker-based-self-hosted-github-runner-linux-container-48dh), you first
need to [create a Personal Access Token](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).
with the full `repo` scope and `read:org`.

You'll need the token in the next step.

## Usage

```bash
export GH_TOKEN=<token_goes_here>
export GH_OWNER=jimmykarily # Point this to your org
export GH_REPOSITORY=ga-runner-qemu-self-hosted # point this to the repository
export RUNNER_INSTANCES=2 # The number of runners to spin up in parallel

./start.sh
```

If everything works, you'll be prompted to login to the Ubuntu VM (credentials `root/root`).
Then:

```bash
cd /
./run.sh
```

The script will install `docker`, will build the needed image and will start `RUNNER_INSTANCES` number of runners.
Each time a job is completed, the runner gets deleted and de-registered and a new one replaces it.
