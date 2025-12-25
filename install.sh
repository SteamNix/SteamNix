#!/usr/bin/env bash
set -e # Exit immediately if a command exits with a non-zero status

# --- Root Privilege Check ---
# If the script is not run as root, re-execute it with sudo
if [ "$EUID" -ne 0 ]; then
  echo "This script requires root privileges. Attempting to elevate..."
  exec sudo "$0" "$@"
fi

# --- Device Selection ---
echo "Available block devices:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

read -p "Enter the NAME of the device you want to install to (e.g., sda, nvme0n1): " selected_device_name

# Construct the full path
disk="/dev/${selected_device_name}"

# Verify the selected device is a block device
if [[ ! -b "$disk" ]]; then
    echo "Error: '$disk' is not a valid block device or does not exist."
    exit 1
fi

echo "You selected: $disk"

# --- Partition Naming Logic ---
# If the disk name ends in a number (like nvme0n1), add 'p' before the partition number.
# Otherwise (like sda), just append the number.
if [[ "$selected_device_name" =~ [0-9]$ ]]; then
    part_prefix="${disk}p"
else
    part_prefix="${disk}"
fi

echo "Partition prefix set to: $part_prefix"

# --- Partitioning ---
echo "WARNING: All data on $disk will be WIPED."
echo "Wiping and partitioning $disk..."
sgdisk --zap-all "$disk"
parted -s "$disk" mklabel gpt
parted -s "$disk" mkpart ESP fat32 1MiB 1000MiB
parted -s "$disk" set 1 esp on
parted -s "$disk" mkpart primary btrfs 1000MiB 100%

# Inform kernel of partition changes and wait
partprobe "$disk"
sleep 2

# --- Filesystems ---
echo "Formatting filesystems..."
mkfs.fat -F32 "${part_prefix}1"
mkfs.btrfs -L nixos "${part_prefix}2

# --- Mounting ---
echo "Mounting filesystems..."
# Mount the mapper device (decrypted), not the raw partition
mount -t btrfs /dev/mapper/enc /mnt

mkdir -p /mnt/boot
mount "${part_prefix}1" /mnt/boot

# --- NixOS Configuration ---
echo "Generating hardware config..."
mkdir -p /mnt/etc/nixos

# Configure channels
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update

# Generate hardware-configuration.nix
nixos-generate-config --root /mnt
curl -L -o /mnt/etc/nixos/configuration.nix 'https://raw.githubusercontent.com/SteamNix/SteamNix/refs/heads/main/configuration.nix'
curl -L -o /mnt/etc/nixos/flake.nix 'https://raw.githubusercontent.com/SteamNix/SteamNix/refs/heads/main/flake.nix'

# --- Installation ---
echo "Installing NixOS..."
# Since we are running as root (via sudo), this handles permissions correctly
export NIX_CONFIG="experimental-features = flakes"
export NIX_PATH="nixpkgs=/root/.nix-defexpr/channels/nixos"
nixos-install --flake /mnt/etc/nixos/flake.nix#nixos --no-root-password

echo "Installation complete. You can now reboot."
