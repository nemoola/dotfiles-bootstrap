#!/usr/bin/env bash

set -e

curl -fsSL https://install.determinate.systems/nix | sh -s -- install

. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

nix shell \
  nixpkgs#git \
  nixpkgs#chezmoi \
  nixpkgs#bitwarden-desktop \
  nixpkgs#openssh \
  -c bash -c '
    bitwarden >/tmp/bitwarden-bootstrap.log 2>&1 &

    printf "%s" "BitwardenをログインしてSSH Agentを有効化した後ウィンドウを閉じずにEnter"
    read -r _

    if ! ssh-add -L >/dev/null 2>&1; then
      printf "%s\n" "SSH Agentに鍵が見えていません。BitwardenのSSH Agentと鍵を確認してください。"
      ssh-add -L || true
      exit 1
    fi

    ssh -T git@github.com || true
    chezmoi init git@github.com:nemoola/dotfiles.git
  '
