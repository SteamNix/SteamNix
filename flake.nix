{
  description = "Auto-install minimal NixOS ISO, config from GitHub, BTRFS, largest disk";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        configurationNixUrl = "https://raw.githubusercontent.com/SteamNix/SteamNix/refs/heads/main/configuration.nix";

        autoInstaller = (import nixpkgs { inherit system; }).writeShellScriptBin "auto-nixos-installer" ''
          set -eux
          export PATH="/run/current-system/sw/bin:$PATH"

          # Find largest disk by size; exclude loops, cdroms, etc
          disk="/dev/$(lsblk -brndo NAME,TYPE,SIZE | grep 'disk' | sort -nk3 | tail -n1 | awk '{print $1}')"
          echo "Selected disk: $disk"
          lsblk "$disk"

          # Zap and wipe disk
          sgdisk --zap-all "$disk"
          wipefs -a "$disk"

          # Partition: 512M EFI, rest BTRFS
          parted -s "$disk" mklabel gpt
          parted -s "$disk" mkpart ESP fat32 1MiB 513MiB
          parted -s "$disk" set 1 esp on
          parted -s "$disk" mkpart primary btrfs 513MiB 100%

          # Determine partition suffixes
          if [[ "$disk" =~ ^/dev/nvme ]]; then
            p1="${disk}p1"
            p2="${disk}p2"
          else
            p1="${disk}1"
            p2="${disk}2"
          fi

          # Format partitions
          mkfs.fat -F32 "$p1"
          mkfs.btrfs -f "$p2"

          # Mount partitions
          mount "$p2" /mnt
          mkdir -p /mnt/boot
          mount "$p1" /mnt/boot

          # Fetch configuration.nix to /mnt/etc/nixos
          mkdir -p /mnt/etc/nixos
          curl -L -o /mnt/etc/nixos/configuration.nix '${configurationNixUrl}'
          nix-channel --add https://nixos.org/channels/nixos-unstable nixos
          nix-channel --update

          # Generate hardware-configuration.nix
          nixos-generate-config --root /mnt

          # Install with no root password
          export NIX_CONFIG="experimental-features = flakes"
          export NIX_PATH="nixpkgs=/root/.nix-defexpr/channels/nixos"
          nixos-install --no-root-password

          poweroff
        '';

        installerService = {
          description = "Autoinstall NixOS on boot";
          wants = [ "network-online.target" ];
          after = [ "getty@tty1.service" "network-online.target" ];
          wantedBy = [ "getty@tty1.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${autoInstaller}/bin/auto-nixos-installer";
            StandardOutput = "journal+console";
          };
        };

        iso = nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ({ pkgs, ... }: {
              networking.useDHCP = true;
              systemd.network.wait-online.anyInterface = true;

              systemd.services."auto-nixos-installer" = installerService;

              environment.systemPackages = with pkgs; [
                parted gptfdisk btrfs-progs dosfstools curl util-linux coreutils gnugrep gawk
              ];

              users.users.root.password = "";
              boot.initrd.kernelModules = [ "nvme" "ahci" ];
              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
            })
          ];
        };
      in {
        packages.install-iso = iso.config.system.build.isoImage;
        configurationNixUrl = configurationNixUrl;
      }
    );
}
