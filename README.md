This repository allows one to spin up ephemeral GitHub Action runners inside
a VM.

It is heavily inspired by this blog post: https://dev.to/pwd9000/create-a-docker-based-self-hosted-github-runner-linux-container-48dh

and this repository: https://github.com/Pwd9000-ML/docker-github-runner-linux

What it adds on top is the ability to run everything inside a VM using qemu, thus
limiting the amount of resources taken from the host and making it secure enough
to be run on a workstation.

## Preparation

[As described in the original blog post](https://dev.to/pwd9000/create-a-docker-based-self-hosted-github-runner-linux-container-48dh), you first
need to [create a Personal Access Token](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).
with the full `repo` scope and `read:org`.

You'll need the token in the next step.

## Usage

```

export GH_TOKEN=<token_goes_here>
export GH_OWNER=jimmykarily # Point this to your org
export GH_REPOSITORY=ga-runner-qemu-self-hosted # point this to the repository
export RUNNER_INSTANCES=2 # The number of runners to spin up in parallel

./start.sh
```

If everything works, you'll be prompted to login to the Ubuntu VM (credentials `root/root`).
Then:

```
cd /
./run.sh
```

The script will install `docker`, will build the needed image and will start `RUNNER_INSTANCES` number of runners.
Each time a job is completed, the runner gets deleted and de-registered and a new one replaces it.

TODO:

- Ensure nested KVM works (and inside the containers too)
