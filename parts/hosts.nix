# NixOS configurations for every host, and standalone home-manager ones for `kind = "home"` hosts.
{
  inputs,
  lib,
  presetModules,
  diskoLayouts,
  # Namespaced module trees, mirroring the modules/ directory layout
  # (see parts/modules.nix).
  nixosModules,
  homeModules,
  ...
}: let
  hostsPath = ../hosts;
  hostsConfig = import hostsPath {};
  shared = hostsConfig.shared or {};
  hosts = hostsConfig.hosts or {};

  isHome = hostConfig: (hostConfig.kind or "nixos") == "home";

  # This is what puts the option helpers in every module's ordinary `lib` — don't drop it.
  extendedLib = lib.extend (_final: _prev: inputs.viicslen-lib.lib.options);

  hostPathOf = hostName: hostConfig: hostConfig.path or (hostsPath + "/${hostName}");

  mkHost = hostName: hostConfig: let
    hostPath = hostPathOf hostName hostConfig;
    hostHome = hostPath + "/home.nix";
  in
    inputs.nixpkgs.lib.nixosSystem {
      lib = extendedLib;

      # No blanket module import: presets and hosts pull in exactly the modules
      # they want, via the `nixosModules` / `homeModules` specialArgs.
      modules =
        (shared.modules or [])
        ++ map (name: presetModules.${name}) (hostConfig.presets or [])
        ++ [
          hostPath
          {nixpkgs.hostPlatform.system = hostConfig.system;}
        ]
        ++ lib.optional (builtins.pathExists hostHome) {
          _file = hostPath;
          home-manager.sharedModules = [hostHome];
        };

      specialArgs = {
        inherit inputs hostName nixosModules homeModules diskoLayouts;
        outputs = inputs.self.outputs;
        users = shared.users or {};
      };
    };

  # No osConfig here, so only presets whose home.nix never reads it (`ai`) work on a home host.
  mkHome = hostName: hostConfig: let
    hostPath = hostPathOf hostName hostConfig;
    home =
      if hostConfig.user == "root"
      then "/root"
      else "/home/${hostConfig.user}";
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      lib = extendedLib;
      pkgs = import inputs.nixpkgs {
        inherit (hostConfig) system;
        config.allowUnfree = true;
        overlays = [inputs.self.overlays.flake-inputs];
      };
      extraSpecialArgs = {inherit inputs hostName homeModules;};
      modules =
        map (name: presetModules.${name} + "/home.nix") (hostConfig.presets or [])
        ++ [
          (hostPath + "/home.nix")
          {
            home = {
              username = hostConfig.user;
              homeDirectory = home;
            };
          }
        ];
    };

  nixosHosts = lib.filterAttrs (_: h: !isHome h) hosts;
  homeHosts = lib.filterAttrs (_: isHome) hosts;
in {
  flake = {
    nixosConfigurations = lib.mapAttrs mkHost nixosHosts;
    homeConfigurations = lib.mapAttrs' (name: h: lib.nameValuePair "${h.user}@${name}" (mkHome name h)) homeHosts;
  };
}
