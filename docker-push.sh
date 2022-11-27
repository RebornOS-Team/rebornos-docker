#!/usr/bin/env sh

docker manifest create \
    rebornos/rebornos:latest \
    --amend rebornos/rebornos:latest-amd64 \
    --amend rebornos/rebornos:latest-arm64

docker manifest push rebornos/rebornos:latest

docker push rebornos/rebornos:latest-amd64
