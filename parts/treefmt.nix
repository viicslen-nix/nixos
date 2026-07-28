# Formatting, via treefmt-nix. Provides `nix fmt` (multi-language) and a
# `checks.formatting` gate. This owns `formatter`, so dev-shells.nix no longer
# sets it.
{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = {...}: {
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
        # Vendored AI skill/command content that is read verbatim into the home
        # config — reformatting it would change the home-manager generation.
        "hosts/_shared/presets/personal/ai/**"
      ];
    };
  };
}
