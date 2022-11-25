#!/usr/bin/env sh

pacman-key --init
pacman -Sy --noconfirm archlinux-keyring
pacman -Sy --config /etc/pacman.conf.unsafe --noconfirm rebornos-keyring 
pacman-key --populate archlinux rebornos
pacman -Syu --noconfirm