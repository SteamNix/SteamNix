{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

 
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree         = true;

  ####################
  # Boot & Kernel    #
  ####################
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout                  = 0;
  boot.loader.limine.maxGenerations    = 5;
  hardware.amdgpu.initrd.enable = false;

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
  systemd.settings.Manager = {DefaultTimeoutStopSec="5s";};

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
  # Graphical & Jovian   #
  ########################
  services.xserver.enable            = false;
  #services.logind.extraConfig = ''HandlePowerKey=poweroff''; #set power button to shutdown on press
  jovian = {
    steam.enable = true;
    steam.autoStart = true;
    steam.user = "steamos";
    hardware.has.amd.gpu = true;
    decky-loader.enable = true;
    steamos.useSteamOSConfig = true;
    steam.desktopSession = "gamescope-wayland";
    
  };


  ########################
  # Programs & Services    #
  ########################
  services.automatic-timezoned.enable = true;
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  #Allow code-server to run properly
  programs.nix-ld.enable = true;
  services.code-server.enable = true;
  #services.flatpak.enable = true;
  
  
  programs = {
    appimage = { enable = true; binfmt = true; };
    fish     = { enable = true; };
    mosh     = { enable = true; };
    tmux     = { enable = true; };
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
    extraGroups  = [ "networkmanager" "wheel" "docker" "video" "seat" "audio" "libvirtd" "code-server"];
    password     = "steamos";
  };

  #################
  # Security      #
  #################
  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable           = true;
  services.seatd.enable            = true;
  services.openssh.enable          = true;

  ######################
  ######################

  ########################
  # System State Version #
  ########################
  system.stateVersion = "24.11";
}
