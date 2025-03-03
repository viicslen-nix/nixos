{
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.vscode-server.nixosModules.default
    ../../users/neoscode
  ];

  system.stateVersion = "25.05";

  networking = {
    hostName = "wsl";
    firewall.enable = mkForce false;
  };

  wsl = {
    enable = true;
    defaultUser = "neoscode";
    interop.register = true;
    docker-desktop.enable = true;
    startMenuLaunchers = true;
    useWindowsDriver = true;
    extraBin = [
      {
        src = lib.getExe pkgs.git;
      }
      {
        src = lib.getExe pkgs.bash;
      }
    ];
  };

  environment = {
    shellAliases = {
      ssh = "ssh.exe";
      ssh-add = "ssh-add.exe";
    };

    systemPackages = with pkgs; [
      jetbrains.webstorm
      jetbrains.phpstorm
      jetbrains.jdk
    ];
  };

  programs = {
    nix-ld.enable = true;
    git.config.programs.core.sshCommand = "ssh.exe";
  };

  services.vscode-server.enable = true;

  modules = {
    presets = {
      base.enable = true;
      work.enable = true;
      personal.enable = true;
    };

    functionality = {
      theming.enable = true;
      appImages.enable = true;
    };

    containers.settings.log-driver = "local";
  };

  nixpkgs.overlays = [
    (final: prev:
    let
      toolNames = ["phpstorm" "webstorm"];
      makeToolOverlay = toolName: {
        ${toolName} = prev.jetbrains.${toolName}.overrideAttrs (old: {
          patches = (old.patches or []) ++ [ ./JetbrainsRemoteDev.patch ];
          installPhase = (old.installPhase or "") + ''
            makeWrapper "$out/$pname/bin/remote-dev-server.sh" "$out/bin/$pname-remote-dev-server" \
              --prefix PATH : "$out/libexec/$pname:${final.lib.makeBinPath [ final.jdk final.coreutils final.gnugrep final.which final.git ]}" \
              --prefix LD_LIBRARY_PATH : "${final.lib.makeLibraryPath ([ final.stdenv.cc.cc.lib final.libsecret final.e2fsprogs final.libnotify ])}" \
              --set-default JDK_HOME "${final.jetbrains.jdk}" \
              --set-default JAVA_HOME "${final.jetbrains.jdk}"
          '';
        });
      };
    in { jetbrains = prev.jetbrains // builtins.foldl' (acc: toolName: acc // makeToolOverlay toolName) {} toolNames; })
  ];
}
