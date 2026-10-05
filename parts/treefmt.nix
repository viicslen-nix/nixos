# Formatting, via treefmt-nix. This owns `formatter` — don't set it in shells.nix too.
{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        deadnix.enable = true;
        statix.enable = true;
        alejandra.enable = true; # nix
        shfmt.enable = true; # shell scripts
      };
      settings = {
        # Lower runs first: the linters rewrite code, so alejandra must format after them.
        formatter = {
          deadnix.priority = 1;
          statix.priority = 2;
          alejandra.priority = 3;
        };
        global.excludes = [
          "*.age"
          "*.png"
          "*.lock"
          "flakes/*" # submodules format themselves
        ];
      };
    };
  };
}
