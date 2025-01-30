{ config, lib, pkgs, ... }:
let
  # ARCHITECTURE CONFIGS
  arch = builtins.currentSystem;
  hardwareConfig = if arch == "x86_64-linux" then
    ./hardware-configuration__x86_64.nix
  else 
    ./hardware-configuration__aarch64.nix;

  # CHECK HOST LOCAL
  hostLocalConfig = ./host__local.nix;
  hostLocalExists = builtins.pathExists hostLocalConfig;

  # HOST CONFIGS
  hostname = if hostLocalExists then (import hostLocalConfig).networking.hostName else null;
  hostSpecificConfig = if hostname == "rogue" then
    ./host__rogue.nix
  else if hostname == "hunter" then
    ./host__hunter.nix
  else if hostname == "knight" then
    ./host__knight.nix
  else
    null;
in

if !hostLocalExists then
  throw "Error: host__local.nix not found. Please create it and set your hostname."
else if hostSpecificConfig == null then
  throw "Error: Unknown hostname. Please set a valid hostname in host__local.nix."
else
{
  imports =
    [ 
      hardwareConfig
      hostLocalConfig
      hostSpecificConfig
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.enable = true;

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };


  # -----------------------------------------
  # system
  # -----------------------------------------

  services.libinput.enable = true;

  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  users.users.jbiggs = {
    isNormalUser = true;
    description = "Jason Biggs";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  fonts.packages =  with pkgs; [
    pkgs.nerdfonts
    pkgs.font-awesome
  ];

  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  
  # -----------------------------------------
  # programs
  # -----------------------------------------

  programs.hyprland.enable = true;

  programs.hyprlock.enable = true;

  programs.firefox.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "jbiggs" ];
  };
  environment.systemPackages = with pkgs; [
    # basics
    wget
    _1password-cli
    _1password-gui
    stow 
    zsh
    nodejs
    python3

    # terminal
    ghostty
    kitty
    oh-my-zsh
    fzf
    starship
    zoxide    
    eza

    # development
    gh
    github-desktop
    git
    vscode
    docker

    # neovim
    neovim
    lazygit
    lazydocker
    ripgrep
    wayclip
    vimPlugins.nvim-treesitter
    
    # ricing
    hyprland
    hyprlock
    wofi
    waybar
    hyprpaper
    # swaynotificationcenter
    hyprnotify
    hyprshot
    libnotify
    wlogout
    hypridle
    hyprcursor
    hyprsunset
    hyprpicker
    hyprlandPlugins.hyprgrass
    waypaper
    brightnessctl
  ];

  system.stateVersion = "24.11"; # Did you read the comment?
}
