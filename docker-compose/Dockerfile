# Inspired from https://dev.to/pwd9000/create-a-docker-based-self-hosted-github-runner-linux-container-48dh
FROM ghcr.io/actions/actions-runner-controller/actions-runner-dind:v2.299.1-ubuntu-20.04-aa6dab5

# add over the start.sh script
ADD start.sh start.sh

RUN sudo mkdir /runner

# make the script executable
RUN sudo chmod +x start.sh

# set the entrypoint to the start.sh script
CMD ["./start.sh"]
