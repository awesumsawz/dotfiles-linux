export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
export PATH="$HOME/.local/bin:/usr/bin:$PATH"
alias logout="hyprctl dispatch exit"
export GTK_THEME=Dracula
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_TYPE=wayland

case "$(hostname)" in
    "hunter")
        export HYPRIDLE_CONFIG="$HOME/.config/hypr/hypridle-hunter.conf"
        ;;
    *)
        export HYPRIDLE_CONFIG="$HOME/.config/hypr/hypridle.conf"
        ;;
esac

