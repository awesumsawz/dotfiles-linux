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

## Terminal & Shell
- **ghostty** - Fast GPU-accelerated terminal emulator
- **zsh** - Advanced shell with features
- **starship** - Cross-shell prompt customizer
- **zellij** - Terminal workspace manager

## CLI Tools & Utilities
- **bat** - Cat clone with syntax highlighting
- **eza** - Modern ls replacement with colors
- **fzf** - Fuzzy finder for command line
- **zoxide** - Smarter cd command that learns
- **vivid** - LS_COLORS generator
- **thefuck** - Command correction tool
- **tree** - Directory tree viewer
- **btop** - Resource monitor with graphs
- **fd** - Fast alternative to find
- **ripgrep** - Fast recursive grep tool
- **plocate** - Fast file locator
- **tldr** - Simplified man pages
- **jq** - JSON processor
- **less** - Pager for viewing files
- **rsync** - File synchronization tool
- **wget** - File downloader
- **unzip** - ZIP archive extractor
- **xmlstarlet** - XML processing toolkit
- **man-db** - Manual page database
- **wl-clipboard** - Wayland clipboard utilities
- **wl-clip-persist** - Keep Wayland clipboard persistent
- **stow** - Symlink manager for dotfiles

## Development Tools
- **neovim** - Hyperextensible Vim-based text editor
- **git** - Distributed version control system
- **github-cli** - GitHub command line tool
- **lazygit** - Terminal UI for git
- **lazydocker** - Terminal UI for Docker
- **docker** - Container platform
- **docker-buildx** - Docker CLI plugin for BuildKit
- **docker-compose** - Multi-container Docker applications
- **npm** - Node.js package manager
- **luarocks** - Lua package manager
- **tree-sitter-cli** - Parser generator tool

## Applications - Productivity
- **1password** - Password manager
- **1password-cli** - Password manager CLI
- **claude-code** - claude ai

## Applications - Internet & Communication
- **zen-browser-bin** - Privacy-focused web browser
- **brave-bin** - Chromium-based privacy browser

## Applications - Entertainment
- **spotify** - Music streaming client

## Applications - Utilities
- **virtualbox-bin** - Virtualization software

## Package Managers
- **yay** - AUR helper
- **flatpak** - Universal package manager

## Security
- **clamav** - Antivirus scanner
- **rkhunter** - Rootkit hunter
- **yara** - Malware research tool

## Flatpak apps
- Pika Backup (`flatpak install org.gnome.World.PikaBackup`)
