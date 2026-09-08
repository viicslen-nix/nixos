# Single source of truth for the extra binary caches this repo trusts.
{
  lib,
  # Only `just sync-caches` may pass false — it must not be blocked by the drift it clears.
  checkDrift ? true,
}: let
  # scope: "base" every host, "desktop" graphical only — don't promote a bleeding-edge cache to base.
  caches = {
    nix-community = {
      scope = "base";
      url = "https://nix-community.cachix.org";
      key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    };

    lantian = {
      scope = "base";
      url = "https://attic.xuyh0120.win/lantian";
      key = "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=";
    };

    numtide = {
      scope = "base";
      url = "https://cache.numtide.com";
      key = "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
      # Serves llm-agents.nix, whose codex is a ~12 GiB rustc build from source
      # on a miss. No `ownNixpkgs`: it is a real input now, not an index entry.
    };

    nixos-cuda = {
      scope = "base";
      url = "https://cache.nixos-cuda.org";
      key = "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";
    };

    nixpkgs-wayland = {
      scope = "desktop";
      url = "https://nixpkgs-wayland.cachix.org";
      key = "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA=";
    };

    ghostty = {
      scope = "desktop";
      url = "https://ghostty.cachix.org";
      key = "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns=";
    };
  };

  all = lib.attrValues caches;
  inScope = scope: lib.filter (c: c.scope == scope) all;

  # Must stay a `readFile` of the text — importing flake.nix here would be IFD and a cycle.
  flakeText = builtins.readFile ./flake.nix;
  drift = lib.filter (c: !lib.hasInfix c.url flakeText) all;

  renderList = name: vals:
    "    ${name} = [\n"
    + lib.concatMapStrings (v: "      \"${v}\"\n") vals
    + "    ];\n";
in
  assert !checkDrift
  || drift == []
  || throw ''
    caches.nix and flake.nix's nixConfig have drifted — missing from flake.nix:
      ${lib.concatMapStringsSep "\n  " (c: c.url) drift}
    Run `just sync-caches` to regenerate it.
  ''; {
    inherit caches;

    # Rendered as literal text on purpose — nix cannot evaluate a computed `nixConfig`.
    nixConfigBlock =
      renderList "extra-substituters" (map (c: c.url) all)
      + renderList "extra-trusted-public-keys" (map (c: c.key) all);

    substituters = scope: map (c: c.url) (inScope scope);
    trustedKeys = scope: map (c: c.key) (inScope scope);

    # omniflake index attributes that must keep their author's nixpkgs pin.
    ownNixpkgs = lib.concatMap (c: c.ownNixpkgs or []) all;
  }
