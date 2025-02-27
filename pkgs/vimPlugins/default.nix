{pkgs}: {
  laravel-nvim = pkgs.callPackage ./laravel-nvim.nix {};
  neotest-pest = pkgs.callPackage ./neotest-pest.nix {};
}
