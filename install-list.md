# Installed Programs

Generated from `pacman -Qeq` on 2026-07-09. This is an Omarchy-based Arch install.

## Duplicating onto another machine

1. Install [Omarchy](https://omarchy.org) (brings in most of the Hyprland ecosystem below).
2. Review the **Hardware-Specific** section — the desktop entries there won't apply to a laptop.
3. Install everything else:

   ```sh
   yay -S --needed $(grep -oP '^\- \*\*\K[^*]+' install-list.md)
   ```

4. Install the non-pacman tools listed at the bottom (Claude Code, flatpaks, etc.).
5. `stow` this repo to link the dotfiles.

Every `- **name**` line below is an exact pacman/AUR package name. To regenerate the raw list: `pacman -Qeq`.

## System Base
- **base** - Minimal Arch Linux base system
- **base-devel** - Development tools for building packages
- **linux** - Linux kernel
- **linux-firmware** - Firmware files for Linux
- **linux-headers** - Headers for building kernel modules
- **btrfs-progs** - Btrfs filesystem utilities
- **dosfstools** - FAT filesystem utilities
- **exfatprogs** - exFAT filesystem utilities
- **zram-generator** - Compressed RAM block device
- **kernel-modules-hook** - Keeps modules for the running kernel after upgrades

## Hardware-Specific (review before installing on the laptop)
- **amd-ucode** - AMD CPU microcode (use `intel-ucode` on Intel machines)
- **nvidia-open-dkms** - Open-source Nvidia kernel modules
- **nvidia-utils** - Nvidia graphics utilities
- **lib32-nvidia-utils** - 32-bit Nvidia utilities
- **libva-nvidia-driver** - VA-API driver for Nvidia
- **egl-wayland** - EGL external platform for Wayland (needed with Nvidia)
- **cuda** - Nvidia CUDA toolkit (large; Nvidia GPUs only)
- **asdcontrol** - Apple Studio Display brightness control
- **bolt** - Thunderbolt 3 device manager

## Boot & System Management
- **limine** - Modern UEFI/BIOS bootloader
- **limine-mkinitcpio-hook** - Mkinitcpio hook for Limine
- **limine-snapper-sync** - Sync Limine with Snapper snapshots
- **snapper** - Filesystem snapshot management
- **plymouth** - Graphical boot splash screen

## Terminal & Shell
- **ghostty** - Fast GPU-accelerated terminal emulator
- **alacritty** - GPU-accelerated terminal emulator
- **zsh** - Advanced shell with features
- **bash-completion** - Bash completion scripts
- **starship** - Cross-shell prompt customizer
- **zellij** - Terminal workspace manager
- **tmux** - Terminal multiplexer
- **gum** - Shell script UI components

## CLI Tools & Utilities
- **bat** - Cat clone with syntax highlighting
- **eza** - Modern ls replacement with colors
- **fzf** - Fuzzy finder for command line
- **zoxide** - Smarter cd command that learns
- **vivid** - LS_COLORS generator
- **thefuck** - Command correction tool
- **tree** - Directory tree viewer
- **btop** - Resource monitor with graphs
- **dust** - Disk usage analyzer (du replacement)
- **fd** - Fast alternative to find
- **ripgrep** - Fast recursive grep tool
- **plocate** - Fast file locator
- **tldr** - Simplified man pages
- **jq** - JSON processor
- **less** - Pager for viewing files
- **rsync** - File synchronization tool
- **wget** - File downloader
- **whois** - Domain lookup tool
- **unzip** - ZIP archive extractor
- **xmlstarlet** - XML processing toolkit
- **man-db** - Manual page database
- **inetutils** - Network utilities collection
- **inxi** - System information script
- **socat** - Multipurpose data relay
- **expac** - Pacman database extraction utility
- **tobi-try** - Fresh directories for every vibe (experiment dir manager)
- **cliphist** - Clipboard manager for Wayland
- **wl-clipboard** - Wayland clipboard utilities
- **wl-clip-persist** - Keep Wayland clipboard persistent
- **fastfetch** - System information tool
- **stow** - Symlink manager for dotfiles
- **python-terminaltexteffects** - Terminal text effects

## Development Tools
- **neovim** - Hyperextensible Vim-based text editor
- **omarchy-lazyvim** - Omarchy's LazyVim-based Neovim configuration
- **vim** - Classic text editor
- **git** - Distributed version control system
- **github-cli** - GitHub command line tool
- **lazygit** - Terminal UI for git
- **lazydocker** - Terminal UI for Docker
- **docker** - Container platform
- **docker-buildx** - Docker CLI plugin for BuildKit
- **docker-compose** - Multi-container Docker applications
- **npm** - Node.js package manager
- **mise** - Polyglot runtime manager
- **usage** - CLI spec tool (mise companion)
- **rust** - Rust programming language
- **ruby** - Ruby programming language
- **clang** - C/C++/Objective-C compiler
- **llvm** - Compiler infrastructure
- **cmake** - Cross-platform build system
- **dotnet-runtime-9.0** - .NET 9 runtime
- **python-poetry-core** - Python packaging utilities
- **luarocks** - Lua package manager
- **tree-sitter-cli** - Parser generator tool
- **opencode** - Terminal AI coding agent

## Hyprland Ecosystem
- **hyprland** - Dynamic tiling Wayland compositor
- **hyprland-guiutils** - GUI utilities for Hyprland (dialogs, wizards)
- **hyprland-preview-share-picker** - Screen-share window picker with previews
- **hypridle** - Idle management daemon
- **hyprlock** - Screen locker
- **hyprpicker** - Color picker
- **hyprshot** - Screenshot utility
- **hyprsunset** - Blue light filter
- **waybar** - Customizable status bar
- **walker-bin** - Application launcher
- **omarchy-walker** - Omarchy integration for Walker
- **swaybg** - Wallpaper manager
- **swayosd** - On-screen display for keys
- **mako** - Notification daemon
- **xdg-desktop-portal-hyprland** - Desktop portal for Hyprland
- **xdg-desktop-portal-gtk** - GTK desktop portal backend
- **xdg-terminal-exec** - Standard for launching Terminal=true desktop apps
- **uwsm** - Universal Wayland session manager

## System Utilities
- **brightnessctl** - Brightness control tool
- **playerctl** - Media player controller
- **pamixer** - PulseAudio mixer
- **power-profiles-daemon** - Power profile management
- **ufw** - Uncomplicated firewall
- **ufw-docker** - UFW integration for Docker
- **polkit-gnome** - GNOME PolicyKit authentication
- **gnome-keyring** - Password and secrets manager
- **tzupdate** - Automatic timezone updater

## Network
- **iwd** - Wireless daemon (no NetworkManager on this system)
- **impala** - TUI for managing Wi-Fi via iwd
- **wireless-regdb** - Wireless regulatory database
- **gvfs-smb** - SMB/CIFS support for GVFS
- **gvfs-mtp** - MTP support for GVFS
- **nss-mdns** - NSS module for mDNS

## Bluetooth & Audio
- **bluetui** - TUI Bluetooth manager
- **pipewire** - Modern audio/video server
- **pipewire-alsa** - ALSA support for PipeWire
- **pipewire-jack** - JACK support for PipeWire
- **pipewire-pulse** - PulseAudio replacement
- **wireplumber** - PipeWire session manager
- **wiremix** - PipeWire mixer utility
- **gst-plugin-pipewire** - GStreamer PipeWire plugin
- **libpulse** - PulseAudio client library

## Fonts
- **noto-fonts** - Google Noto fonts
- **noto-fonts-cjk** - CJK (Chinese/Japanese/Korean) fonts
- **noto-fonts-emoji** - Emoji fonts
- **noto-fonts-extra** - Additional Noto fonts
- **ttf-cascadia-mono-nerd** - Cascadia Mono Nerd Font
- **ttf-jetbrains-mono-nerd** - JetBrains Mono Nerd Font
- **ttf-ia-writer** - iA Writer font family
- **woff2-font-awesome** - Font Awesome icons
- **fontconfig** - Font configuration library

## Applications - Productivity
- **obsidian** - Knowledge base and note-taking
- **typora** - Markdown editor
- **xournalpp** - Handwriting note-taking app
- **libreoffice-fresh** - Office suite
- **gnome-calculator** - Desktop calculator
- **libqalculate** - Advanced calculator library
- **evince** - Document viewer
- **1password** - Password manager
- **1password-cli** - Password manager CLI

## Applications - File Management
- **nautilus** - GNOME file manager
- **nautilus-python** - Python extension support for Nautilus
- **sushi** - File previewer for Nautilus

## Applications - Graphics & Media
- **imv** - Image viewer for Wayland
- **pinta** - Simple image editor
- **imagemagick** - Image manipulation suite
- **mpv** - Media player
- **kdenlive** - Video editor
- **obs-studio** - Screen recording and streaming
- **wf-recorder** - Wayland screen recorder
- **wl-screenrec** - Hardware-accelerated Wayland screen recorder
- **satty** - Screenshot annotation tool
- **slurp** - Screen area selector for Wayland
- **ffmpegthumbnailer** - Video thumbnail generator
- **tesseract** - OCR engine
- **tesseract-data-eng** - English data for Tesseract
- **espeak-ng** - Text-to-speech engine

## Music Ripping & Library
- **abcde** - CD ripping frontend
- **cd-discid** - CD disc ID reader
- **beets** - Music library manager and tagger
- **kid3** - Audio tag editor
- **sox** - Audio processing swiss-army knife
- **mediainfo** - Media file metadata reader
- **cliamp** - Retro terminal music player (Winamp-style)
- **perl-musicbrainz-discid** - MusicBrainz DiscID Perl bindings
- **perl-webservice-musicbrainz** - MusicBrainz web service Perl module

## Applications - Internet & Communication
- **zen-browser-bin** - Privacy-focused web browser
- **brave-bin** - Chromium-based privacy browser
- **chromium** - Open-source Chromium browser
- **signal-desktop** - Private messaging app
- **zoom** - Video conferencing
- **localsend** - Local file sharing

## Applications - Entertainment
- **spotify** - Music streaming client
- **steam** - Gaming platform

## Applications - Utilities
- **filebot** - Media file organizer
- **virtualbox-bin** - Virtualization software

## Package Managers
- **yay** - AUR helper
- **flatpak** - Universal package manager
- **omarchy-keyring** - Omarchy repository signing keys

## Security
- **clamav** - Antivirus scanner
- **rkhunter** - Rootkit hunter
- **yara** - Malware research tool

## Printing
- **cups** - Printing system
- **cups-browsed** - Printer discovery service
- **cups-filters** - Additional CUPS filters
- **cups-pdf** - PDF printer for CUPS
- **system-config-printer** - Printer configuration tool

## Theming
- **gnome-themes-extra** - Extra GTK themes
- **kvantum-qt5** - SVG-based Qt theme engine
- **yaru-icon-theme** - Ubuntu Yaru icon theme
- **qt5-wayland** - Qt5 Wayland support

## System Libraries
- **mariadb-libs** - MySQL/MariaDB client libraries
- **postgresql-libs** - PostgreSQL client libraries
- **python-gobject** - Python GObject bindings
- **libyaml** - YAML parser library
- **crypto++** - C++ cryptography library

## Input Methods
- **fcitx5** - Input method framework
- **fcitx5-gtk** - GTK support for Fcitx5
- **fcitx5-qt** - Qt support for Fcitx5

## Not from pacman

Installed via their own installers (into `~/.local/bin`), not covered by the list above:

- `claude` - Claude Code (`curl -fsSL https://claude.ai/install.sh | bash`)
- `codex` - OpenAI Codex CLI
- `copilot` - GitHub Copilot CLI
- `gemini` - Google Gemini CLI
- `pi` - pi CLI
- `ghui` - GitHub TUI
- `playwright-cli` - Playwright browser automation CLI

Flatpak apps:

- Pika Backup (`flatpak install org.gnome.World.PikaBackup`)
