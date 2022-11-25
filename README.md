# RebornOS-Docker

A Docker Container for RebornOS x86_64

The docker image is uploaded at https://hub.docker.com/r/rebornos/rebornos

The `build.sh`, `run.sh`, and `build_and_run.sh` scripts are self explanatory. They build an image and run the container using the local `Dockerfile`.

## Using the image from Docker Hub

> **Note:** The container is already configured to additionally start a shell in the `/home/rebornos-shared` directory (within the container)

To run this container while mounting a custom local directory `~/rebornos-shared` (on your host computer) for use as `/home/rebornos-shared` (within the container), it is convenient to make an executable script that has the following contents:
```sh
#!/usr/bin/env sh

docker pull rebornos/rebornos:latest
mkdir -p ~/rebornos-shared

xhost +local:root \
    && docker run \
        --net=host \
        --ipc=host \
        --pid=host \
        --privileged=true \
        --volume /tmp/.X11-unix:/tmp/.X11-unix \
        --volume ~/rebornos-shared:/home/rebornos-shared \
        --env DISPLAY=${DISPLAY} \
        --interactive \
        --tty \
        --rm \
        rebornos-shared:latest

xhost -local:root
```
Otherwise just run the above commands in the same order, without the `#!` line

