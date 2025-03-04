#!/bin/bash

# Check if the required arguments are passed
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <host> <disk>"
  exit 1
fi

# Assign input arguments to variables
HOST=$1
DISK=$2

# Function to ask for user confirmation
confirm() {
  echo "$1"
  read -p "Proceed with this command? (y/n): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Skipping command."
    return 1
  fi
  return 0
}

# Set ulimit
if confirm "Set ulimit to 2048"; then
  ulimit -n 2048
fi

# Run nix command with the provided host and disk
if confirm "Format disk '$DISK' using disko"; then
  sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko "hosts/$HOST/disko.nix" --arg device '"/dev/$DISK"'
fi

# Copy config to /mnt/etc/
if confirm "Copy config to /mnt/etc/"; then
  sudo mkdir -p /mnt/etc
  sudo cp -r . /mnt/etc/nixos
fi

# Run nixos-install with the provided host
if confirm "Run nixos-install for host '$HOST'"; then
  sudo nixos-install --root /mnt --flake "/mnt/etc/nixos#$HOST"
fi

echo "NixOS installation completed."
