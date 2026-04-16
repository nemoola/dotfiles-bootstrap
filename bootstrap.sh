#!/usr/bin/env bash

set -e

if [ "${1:-}" = "--continue" ]; then
  export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

  NIX_CONFIG='experimental-features = nix-command flakes' \
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

  exit 0
fi

case "$(uname -s)" in
  Darwin)
    curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
    ;;
  Linux)
    curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
    ;;
  *)
    printf 'unsupported OS: %s\n' "$(uname -s)" >&2
    exit 1
    ;;
esac

exec "$SHELL" -lc "$0 --continue"
