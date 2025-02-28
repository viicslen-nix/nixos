{
  lib,
  ...
}: let
  globalVariables = {
    # Allow unfree packages
    NIXPKGS_ALLOW_UNFREE = "1";

    # Wayland environment
    XDG_SESSION_TYPE = "wayland";
    CLUTTER_BACKEND = "wayland";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";

    # DPI scaling
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    GDK_SCALE = "1.6";

    # Nvidia
    # NVD_BACKEND = "direct";
    # LIBVA_DRIVER_NAME = "nvidia";
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # __GL_GSYNC_ALLOWED = "1";
    # __GL_VRR_ALLOWED = "1";
  };

  hyprVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    # AQ_DRM_DEVICES = "/dev/dri/by-path/pci-0000:01:00.0-card:/dev/dri/by-path/pci-0000:00:02.0-card";
  };
in {
  home.sessionVariables = globalVariables;

  xdg.configFile = {
    "uwsm/env".text = lib.concatMapAttrsStringSep "\n" (name: value: "export ${name}=${value}") globalVariables;
    "uwsm/env-hyprland".text = lib.concatMapAttrsStringSep "\n" (name: value: "export ${name}=${value}") hyprVariables;
  };

  wayland.windowManager.hyprland.settings.env = lib.concatLists [
    (lib.mapAttrsToList (name: value: "${name},${value}") globalVariables)
    (lib.mapAttrsToList (name: value: "${name},${value}") hyprVariables)
  ];
}
