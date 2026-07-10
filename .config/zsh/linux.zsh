export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
export PATH="$HOME/.local/bin:/usr/bin:$PATH"
alias nrs="home-manager switch --flake $HOME/nix-arch#rogue"
alias logout="hyprctl dispatch exit"
alias cc="claude --permission-mode auto"
export GTK_THEME=Dracula
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_TYPE=wayland
export TERMINAL=ghostty

case "$(cat /etc/hostname)" in
    "hunter")
        export HYPRIDLE_CONFIG="$HOME/.config/hypr/hypridle-hunter.conf"
        echo "hunter"
        ;;
    *)
        export HYPRIDLE_CONFIG="$HOME/.config/hypr/hypridle.conf"
        ;;
esac

