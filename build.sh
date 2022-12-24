#!/usr/bin/env sh

docker build --network=host --platform linux/amd64 --tag rebornos/rebornos:latest-amd64 . "$@"
