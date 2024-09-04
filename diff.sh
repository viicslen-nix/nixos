#!/usr/bin/env bash
# fs-diff.sh
set -euo pipefail

# Variables
SUBVOL="persist/snapshots/root-blank"
UUID="5167ff03-ac2a-4e13-83f5-6da3359f446e"
MOUNT_POINT="/mnt/root-blank"
IGNORE_DIRS=()
USER_HOME="/home/$USER"
MOUNTED_BY_SCRIPT=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage information
usage() {
  echo -e "${YELLOW}Usage: $0 [-i dir1,dir2,...]${NC}"
  echo -e "${YELLOW}  -i  Comma-separated list of directories to ignore (other than those specified by default)${NC}"
  exit 1
}

# Function to check if the subvolume is already mounted
is_mounted() {
  mount | grep -q "on $MOUNT_POINT type btrfs"
}

# Request sudo access if not running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${BLUE}This script requires root privileges. Please provide your password.${NC}"
  sudo -v
fi

# Parse options
while getopts "i:" opt; do
  case $opt in
    i)
      IFS=',' read -r -a IGNORE_DIRS <<< "$OPTARG"
      ;;
    *)
      usage
      ;;
  esac
done

# Add default ignored directory
IGNORE_DIRS+=("$USER_HOME/.cache")

# Create the mount point directory if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
  echo -e "${BLUE}Creating mount point directory: $MOUNT_POINT${NC}"
  sudo mkdir -p "$MOUNT_POINT"
fi

# Check if the subvolume is already mounted
if is_mounted; then
  echo -e "${GREEN}Subvolume is already mounted at $MOUNT_POINT${NC}"
else
  # Mount the subvolume
  echo -e "${BLUE}Mounting subvolume $SUBVOL${NC}"
  sudo mount -t btrfs -o subvol=$SUBVOL,defaults,nodatacow /dev/disk/by-uuid/$UUID $MOUNT_POINT
  MOUNTED_BY_SCRIPT=true
fi

# Finding old file system
echo -e "${GREEN}Listing files in blank root${NC}"
OLD_TRANSID=$(sudo btrfs subvolume find-new $MOUNT_POINT 9999999)
OLD_TRANSID=${OLD_TRANSID#transid marker was }

# Finding new files
echo -e "${GREEN}Listing files in current root${NC}"
sudo btrfs subvolume find-new "/" "$OLD_TRANSID" |
sed '$d' |
cut -f17- -d' ' |
sort |
uniq |
while read path; do
  path="/$path"
  
  # Skip the directories specified in IGNORE_DIRS
  for ignore_dir in "${IGNORE_DIRS[@]}"; do
    if [[ "$path" == "$ignore_dir"* ]]; then
      continue 2
    fi
  done
  
  # Check if path is a directory and skip if needed
  if [ -d "$path" ]; then
    continue
  elif [ -L "$path" ]; then
    : # The path is a symbolic link, so is probably handled by NixOS already
  else
    echo $path
  fi
done

# Unmount the subvolume if it was mounted by the script
if [ "$MOUNTED_BY_SCRIPT" = true ]; then
  echo -e "${BLUE}Unmounting $MOUNT_POINT${NC}"
  sudo umount "$MOUNT_POINT"
else
  # Prompt to unmount if the subvolume was not mounted by the script
  echo -e "${YELLOW}Subvolume was already mounted. Do you want to unmount it? [y/N]${NC}"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Unmounting $MOUNT_POINT${NC}"
    sudo umount "$MOUNT_POINT"
  else
    echo -e "${GREEN}Subvolume left mounted.${NC}"
  fi
fi

echo -e "${GREEN}Done!${NC}"
