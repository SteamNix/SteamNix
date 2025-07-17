![steamos](https://github.com/SteamNix/SteamNix/blob/ffd51a9ad11f225e2530e8d01b1f37224f8e92e9/steamos.jpg)

# ❄️ SteamNix OS ❄️
SteamOS like experience on NixOS. Clean quiet boot like on SteamDeck. Two second shutdown time. Meant for those who primarily use SSH, but would like a SteamOS experience for games.

# Requirements
* Desktop or laptop PC, preferably with AMD GPU or iGPU. (For SteamDeck, see https://github.com/Jovian-Experiments/Jovian-NixOS)
* Disable Secure Boot

# Features
* Zero Desktop Bloat. Gamescope is used as window manager.
* Latest CachyOS Kernel and BORE Kernel Scheduler
* Clean, textless boot. Similar to SteamDeck bootup. Minus the Splash logo.
* Read-only system files and binaries to prevent corruption or malware.
* Boot menu with previous system states, incase update breaks system, allowing you to boot to a previous good state.
* Automated updates and new features pushed via Github
* Latest ProtonGE automatically installed

# Download ISO
https://nixos.org/download/

# Install From Empty Drive using NixOS Minimal  (Do not use GUI Version)
Run the following commands once the iso boots up. Use lsblk to find your /dev/ and update first line in install.sh to reflect the target drive.
```
git clone https://github.com/SteamNix/SteamNix
chmod +x SteamNix/install.sh
sudo su
./SteamNix/install.sh
```

# How to build on NixOS Base System
```
git clone https://github.com/SteamNix/SteamNix
mv SteamNix/configuration.nix /etc/nixos/
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nixos-rebuild boot --flake --upgrade 
sudo reboot now
```
# Keeping System Up-to-date
```
sudo nix flake update --flake /etc/nixos/
sudo nixos-rebuild boot --flake /etc/nixos/
sudo reboot now
```

All Further changes to configuration.nix for the system need to be done through this command and configuration file!
# Flatpak Setup
```
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```
Reboot.

# Retrodeck (Batteries included Emulation with ES-DE)
```
flatpak install flathub net.retrodeck.retrodeck
```
# How to use Steam VDF (Add Non-Steam Games)
```
pipx install steam-vdf

usage: steam-vdf [-h] [-d] [-v] [-o {json,text}] {info,list-shortcuts,view,add-shortcut,delete-shortcut,restart-steam} ...

Steam VDF Tool

positional arguments:
  {info,list-shortcuts,view,add-shortcut,delete-shortcut,restart-steam}
    info                Display Steam library information
    list-shortcuts      List existing non-Steam game shortcuts
    view                View contents of a VDF file
    add-shortcut        Add a new non-Steam game shortcut
    delete-shortcut     Delete an existing non-Steam game shortcut
    restart-steam       Restart Steam

options:
  -h, --help            show this help message and exit
  -d, --debug           Enable debug output
  -v, --dump-vdfs       Enable dumping of VDFs to JSON
  -o {json,text}, --output {json,text}
                        Output type format

```

Restart Steam from power menu

# Installing Epic Games
SSH into PC and run:
```
pipx install legendary-gl
legendary install gameid
```
* https://github.com/derrod/legendary

# Running Epic Games with Steam's Proton
* Create script such as godlike.sh
```
#!/usr/bin/env bash

GAME_ID=...

PROTON=$(find $HOME/.steam/steam/steamapps/common/ -maxdepth 1 -name *Experimental | sort | sed -e '$!d')

export STEAM_GAME_PATH=<Your game install folder>
export STEAM_COMPAT_DATA_PATH="$STEAM_GAME_PATH" # Or point to where your pfx folder is
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_GAME_PATH"
legendary launch $GAME_ID --no-wine --wrapper "'$PROTON/proton' run"
```
* Fill in STEAM_GAME_PATH with path to game, default ~/Games/GameFolder
* Fill in GAME_ID with gameid
* Create a shortcut and add the full script path to the target field in parentheses: "/home/steamos/godlike.sh"

NixOS uses hashes as paths and are subject to change. /run/current-system contains static paths to hashed folders. 

# Password/Login
```
Username: steamos
Password: steamos
```

# Custom Password and other local customization
```
/etc/nixos/configuration.nix
-------------------------

{ config, pkgs, ... }:

{
  # Set a custom password
  users.users.steamos = {
    hashedPassword = "$6$TclE7a.../uEI7b."; # Substitute your hash here!
    # You can generate a hash with: mkpasswd -m sha-512
  };

  # Any other overrides or settings...
}
```
# Adding another drive
Find device such as /dev/sda
```
[steamos@nixos:~]$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0 596.2G  0 disk /run/media/steamos/HDD
sdb      8:16   0 931.5G  0 disk
├─sdb1   8:17   0 930.8G  0 part /nix/store
│                                /
└─sdb2   8:18   0   750M  0 part /boot
```
```
[steamos@nixos:~]$ ls -l /dev/disk/by-uuid/
total 0
lrwxrwxrwx 1 root root 10 Apr 20 03:02 08D6-57BE -> ../../sda2
lrwxrwxrwx 1 root root 10 Apr 20 03:02 bf255b33-3103-444a-8c0f-57b5a6759ef0 -> ../../sda1
lrwxrwxrwx 1 root root  9 Apr 20 03:02 c8c86bd3-eb06-4010-8309-5724bd18e381 -> ../../sdb
```
Add drive to configuration.nix and rebuild and reboot.
```
/etc/nixos/configuration.nix
-------------------------
fileSystems."/run/media/steamos/HDD" = {
   device = "/dev/disk/by-uuid/c8c86bd3-eb06-4010-8309-5724bd18e381";
   fsType = "btrfs";
   options = [
     "users"  "nofail" "compress=zstd" "nosuid" "nodev" ];
 };
```
Comment out Gnome desktop lines in configuration.nix and reboot into desktop and add folder via Desktop steam in storage menu.

# Controller Support (2.4Ghz)
https://www.8bitdo.com/ultimate-2-wireless-controller/

      

  









