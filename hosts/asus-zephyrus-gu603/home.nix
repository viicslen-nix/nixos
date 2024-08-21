{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  user,
  ...
}: {
  feature.persistence = {
    enable = true;
    inherit user;
    share = [
      "keyrings"
      "direnv"
      "JetBrains"
      "mkcert"
    ];
    config = [
      "1Password"
      "direnv"
      "composer"
      "JetBrains"
      "Insomnia"
      "microsoft-edge"
      "Mullvad VPN"
      "op"
      "Slack"
      "traefik"
    ];
    directories = [
      ".gnupg"
      ".ssh"
      ".nixops"
      ".nix"
      ".docker"
      ".tmux/resurrect"
      ".kube"
    ];
    files = [
      ".gitconfig"
      ".zsh_history"
      ".wakatime.cfg"
    ];
  };
}