disk="/dev/nvme0n1"

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
nixos-install --flake /etc/nixos/ --no-root-password
poweroff
