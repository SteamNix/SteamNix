# Display block devices
echo "Available block devices:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Prompt user to pick a device
read -p "Enter the NAME of the device you want to install to (e.g., sda, nvme0n1): " selected_device_name

# Construct the full path and store it in the 'disk' variable
disk="/dev/${selected_device_name}"

# Verify the selected device is a block device
if [[ ! -b "$disk" ]]; then
    echo "Error: '$disk' is not a valid block device or does not exist."
    exit 1
fi

echo "You selected: $disk"

sgdisk --zap-all $disk
parted -s "$disk" mklabel gpt
parted -s "$disk" mkpart ESP fat32 1MiB 1000MiB
parted -s "$disk" set 1 esp on
parted -s "$disk" mkpart primary btrfs 1000MiB 100%
mkfs.fat -F32 "$disk""p1"
mkfs.btrfs -f "$disk""p2"
mount "$disk""p2" /mnt
mkdir -p /mnt/boot
mount "$disk""p1" /mnt/boot
mkdir -p /mnt/etc/nixos
curl -L -o /mnt/etc/nixos/configuration.nix 'https://raw.githubusercontent.com/SteamNix/SteamNix/refs/heads/main/configuration.nix'
curl -L -o /mnt/etc/nixos/flake.nix 'https://raw.githubusercontent.com/SteamNix/SteamNix/refs/heads/main/flake.nix'
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update
nixos-generate-config --root /mnt
export NIX_CONFIG="experimental-features = flakes"
export NIX_PATH="nixpkgs=/root/.nix-defexpr/channels/nixos"
nixos-install --flake /mnt/etc/nixos/flake.nix#nixos --no-root-password
poweroff
