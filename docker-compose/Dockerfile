# Inspired from https://dev.to/pwd9000/create-a-docker-based-self-hosted-github-runner-linux-container-48dh
FROM ubuntu:22.04

#input GitHub runner version argument
ARG RUNNER_VERSION='2.305.0'
ARG RUNNER_USER_UID=1001
ARG DOCKER_GROUP_GID=121
ENV DEBIAN_FRONTEND=noninteractive

# update the base packages
RUN apt-get update -y && apt-get upgrade -y

# install the packages and dependencies along with jq so we can parse JSON (add additional packages as necessary)
RUN apt-get install -y --no-install-recommends \
    software-properties-common curl nodejs wget unzip vim git jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip sudo ca-certificates git-lfs iptables jq software-properties-common unzip zip gnupg acl \
    && rm -rf /var/lib/apt/lists/*

# Runner user
RUN adduser --disabled-password --gecos "" --uid $RUNNER_USER_UID runner \
    && groupadd docker --gid $DOCKER_GROUP_GID \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

ENV HOME=/home/runner

# Install docker
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

VOLUME /var/lib/docker

USER runner

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/runner && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
RUN sudo /home/runner/actions-runner/bin/installdependencies.sh

# add over the start.sh script
ADD start.sh start.sh

# make the script executable
RUN sudo chmod +x start.sh

# set the user to "docker" so all subsequent commands are run as the docker user
#USER docker

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
