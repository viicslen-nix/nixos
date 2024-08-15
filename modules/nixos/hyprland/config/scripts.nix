{pkgs}: {
  handleMonitorConnect = pkgs.writeShellScript "handle-monitor-connect" ''
    handle() {
      case $1 in monitoradded*)
        for i in $(seq 1 10); do
          hyprctl dispatch moveworkspacetomonitor "$i 1"
        done
      esac
    }

    socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" | while read -r line; do handle "$line"; done
  '';
}
