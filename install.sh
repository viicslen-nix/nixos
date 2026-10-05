#!/usr/bin/env bash
# Install a host from the NixOS live installer, run from a clone of this repo.
# Usage: ./install.sh <host> [agenix-key]
set -uo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <host> [agenix-key]"
  exit 1
fi

HOST=$1
AGENIX_KEY=${2:-}
INSTALL_USER=${INSTALL_USER:-neoscode}
NIX=(nix --experimental-features "nix-command flakes")

confirm() {
  echo "$1"
  read -r -p "Proceed? (y/n): " answer
  [[ $answer =~ ^[Yy]$ ]] || {
    echo "Skipping."
    return 1
  }
}

if [ ! -d "hosts/$HOST" ]; then
  echo "No such host: hosts/$HOST"
  exit 1
fi

ulimit -n 2048

# Only hosts that import a layout from disko/ declare their disks; partition the rest by hand.
if confirm "Partition, format and mount with the disko config of '$HOST' (ERASES the disks it declares)"; then
  sudo "${NIX[@]}" run github:nix-community/disko/latest -- --mode destroy,format,mount --flake ".#$HOST" ||
    exit 1
fi

if ! mountpoint -q /mnt; then
  echo "/mnt is not mounted; partition and mount the target first."
  exit 1
fi

if confirm "Copy this repo to /mnt/etc/nixos"; then
  sudo mkdir -p /mnt/etc
  sudo cp -a . /mnt/etc/nixos
fi

# Every secret is encrypted to this one key; without it nothing decrypts.
if [ -n "$AGENIX_KEY" ] && confirm "Install '$AGENIX_KEY' as /home/$INSTALL_USER/.ssh/agenix"; then
  sudo install -D -m 0600 "$AGENIX_KEY" "/mnt/home/$INSTALL_USER/.ssh/agenix"
fi

if confirm "Run nixos-install for '$HOST'"; then
  sudo nixos-install --root /mnt --flake "/mnt/etc/nixos#$HOST" || exit 1
  if [ -n "$AGENIX_KEY" ]; then
    sudo nixos-enter --root /mnt -c "chown -R $INSTALL_USER:users /home/$INSTALL_USER/.ssh"
  fi
fi

echo "Done."
