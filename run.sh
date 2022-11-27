#!/usr/bin/env sh

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
        rebornos/rebornos:latest-amd64

xhost -local:root
