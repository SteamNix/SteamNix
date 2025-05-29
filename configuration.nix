{ config, pkgs, lib, ... }:

let
  chaotic       = builtins.getFlake "github:chaotic-cx/nyx/nyxpkgs-unstable";
  nyxOverlay    = chaotic.overlays.default;
in {
  ######################
  # Imports & Overlays #
  ######################
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.overlays = [ nyxOverlay ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree         = true;

  ####################
  # Boot & Kernel    #
  ####################
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout                  = 0;
  boot.loader.limine.maxGenerations    = 5;

  boot.kernelParams = [ "quiet" ];
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;
    "kernel.nmi_watchdog"        = 0;
    "kernel.sched_bore"          = "1";
  };

  boot.initrd = {
    systemd.enable   = true;
    kernelModules    = [ ];
    verbose          = false;
  };
  boot.plymouth.enable     = true;
  boot.consoleLogLevel     = 0;
  systemd.extraConfig = "DefaultTimeoutStopSec=5s";

  ################
  # FileSystems  #
  ################
  fileSystems."/" = {
    options = [ "compress=zstd" ];
  };

  ############
  # Network  #
  ############
  networking = {
    networkmanager.enable = true;
    firewall.enable       = false;
    hostName              = "nixos";
  };

  #################
  # Bluetooth     #
  #################
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      MultiProfile     = "multiple";
      FastConnectable  = true;
    };
  };

  #################
  # Sound & RTKit #
  #################
  security.rtkit.enable = true;
  services.pipewire = {
    enable         = true;
    alsa.enable    = true;
    alsa.support32Bit = true;
    pulse.enable   = true;
  };

  ########################
  # Graphical & Greetd   #
  ########################
  services.xserver.enable            = false;
  services.getty.autologinUser       = "steamos";
  services.greetd = {
    enable   = true;
    settings.default_session = {
      user    = "steamos";
      command = "steam-gamescope > /dev/null 2>&1";
    };
  };

  ########################
  # Programs & Gaming    #
  ########################
  #Gamescope aurguments (1080P scaling for steam with native resolution of monitor)
  programs.steam.gamescopeSession.args = ["-w 1920" "-h 1080" "-r 120" "--xwayland-count 2" "-e" "--hdr-enabled" "--mangoapp" ];
  
  programs = {
    appimage = { enable = true; binfmt = true; };
    fish     = { enable = true; };
    mosh     = { enable = true; };
    tmux     = { enable = true; };
    gamescope.capSysNice  = true;
    steam = {
      enable                = true;
      gamescopeSession.enable = true;
      extraCompatPackages   = with pkgs; [ proton-ge-bin ];
      extraPackages         = with pkgs; [
        mangohud
        gamescope-wsi
      ];
    };
  };

  environment.sessionVariables = {
    PROTON_USE_NTSYNC       = "1";
    ENABLE_HDR_WSI          = "1";
    DXVK_HDR                = "1";
    PROTON_ENABLE_AMD_AGS   = "1";
    PROTON_ENABLE_NVAPI     = "1";
    ENABLE_GAMESCOPE_WSI    = "1";
    STEAM_MULTIPLE_XWAYLANDS = "1";
  };

  ###################
  # Virtualization  #
  ###################
  virtualisation.docker.enable      = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.libvirtd.enable = true;

  ###############
  # Users       #
  ###############
  users.users.steamos = {
    isNormalUser = true;
    description  = "SteamOS user";
    extraGroups  = [ "networkmanager" "wheel" "docker" "video" "seat" "audio" "libvirtd" ];
    password     = "steamos";
  };

  #################
  # Security      #
  #################
  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable           = true;
  services.seatd.enable            = true;
  services.openssh.enable          = true;

  ########################
  # System State Version #
  ########################
  system.stateVersion = "24.11";
}
