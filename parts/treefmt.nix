# Formatting, via treefmt-nix. This owns `formatter` — don't set it in dev-shells.nix too.
{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true; # nix
        shfmt.enable = true; # shell scripts
      };
      settings.global.excludes = [
        "*.age"
        "*.png"
        "*.lock"
        "flakes/*" # submodules format themselves
      ];
    };
  };
}
