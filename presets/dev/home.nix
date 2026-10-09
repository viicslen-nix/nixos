{pkgs, ...}: {
  home.packages = with pkgs;
    [
      # Toolchains
      gcc

      # Git
      lazygit
    ]
    ++ import ./scripts.nix {inherit pkgs;};
}
