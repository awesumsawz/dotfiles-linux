{ config, lib, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "rogue"; # Define your hostname.
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
  ];

  nixpkgs.config.allowUnfree = true;
  
  # programs.zsh = {
  #   enable = true;
  #   
  #   autosuggestion.enable = true;
  #   syntaxHighlighting.enable = true;
  #   history.size = 5000;
  #   ohMyZsh = {
  #     enable = true;
  #     plugins = [ "git" "docker" "docker-compose" ];
  #   };
  # };
  programs.firefox.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "jbiggs" ];
  };
  environment.systemPackages = with pkgs; [
    wget
    pkgs.github-desktop
    pkgs.ghostty
    pkgs.git
    pkgs.neovim
    pkgs.vscode
    pkgs._1password-gui
    pkgs._1password-cli
    pkgs.stow 
    pkgs.zsh
    pkgs.oh-my-zsh
    pkgs.fzf
    pkgs.gh
    pkgs.starship
    pkgs.zoxide    
    pkgs.eza
    pkgs.nodejs_23
  ];

  system.stateVersion = "24.11"; # Did you read the comment?
}
