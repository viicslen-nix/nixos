# App outputs for the NixVim flake
# This file is imported by flake.nix via flake-parts
{
  perSystem = {config, ...}: {
    apps.default = {
      type = "app";
      program = "${config.packages.default}/bin/nvim";
    };
  };
}
