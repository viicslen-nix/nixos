{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: {
  imports = [ ./dconf.nix ];

  features.impermanence = {
    enable = true;
    inherit user;
    share = [
      "JetBrains"
      "keyrings"
      "direnv"
      "mkcert"
    ];
    config = [
      "Slack"
      "Insomnia"
      "JetBrains"
      "1Password"
      "Mullvad VPN"
      "microsoft-edge"
      "composer"
      "traefik"
      "direnv"
      "op"
    ];
    directories = [
      ".ssh"
      ".nix"
      ".kube"
      ".gnupg"
      ".nixops"
      ".docker"
      ".tmux/resurrect"
    ];
    files = [
      ".gitconfig"
      ".zsh_history"
      ".wakatime.cfg"
      ".config/monitors.xml"
    ];
  };
}