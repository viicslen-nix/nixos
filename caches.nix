# Single source of truth for the extra binary caches this repo trusts.
#
# Three things read this table:
#
#   1. `hosts/_shared/presets/{base,desktop}` — `nix.settings.substituters` and
#      `trusted-public-keys`, split by `scope`.
#   2. `flake.nix` — `ownNixpkgs` names the omniflake index attributes that must
#      keep their author's nixpkgs pin, because unifying nixpkgs changes the
#      derivation hash and voids exactly the cache listed here. Adding a name
#      there is all it takes; the loader routing is derived from it.
#   3. `flake.nix`'s `nixConfig` — by hand, see `drift` at the bottom.
#
# `scope`:  "base"    every host, including headless/WSL
#           "desktop" graphical hosts only (see the desktop preset)
{lib}: let
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
      # codex is a rustPlatform build of codex-rs whose own package.nix notes
      # late-stage rustc peaking at ~12 GiB. numtide publishes it prebuilt, so
      # llm-agents.nix must keep its own nixpkgs or every rebuild compiles it.
      ownNixpkgs = ["llm-agents-nix"];
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

  # nix refuses a computed `nixConfig` outright: the set must be a literal and
  # so must every value — a `let … in` there fails with "expected a set but got
  # a thunk", and even a literal set whose values are computed fails with
  # "flake configuration setting 'extra-substituters' is a thunk". So flake.nix
  # cannot import this file for it, and its nixConfig is a hand-kept copy.
  # `drift` names anything this table has that flake.nix's text does not, so the
  # copy cannot rot silently. readFile on a sibling path is plain text — no IFD,
  # and no cycle, since it never evaluates flake.nix.
  flakeText = builtins.readFile ./flake.nix;
  drift = lib.filter (c: !lib.hasInfix c.url flakeText) all;
in
  assert drift == []
  || throw ''
    caches.nix and flake.nix's nixConfig have drifted — missing from flake.nix:
      ${lib.concatMapStringsSep "\n  " (c: c.url) drift}
    nixConfig cannot be generated (nix rejects a thunk), so add them by hand.
  ''; {
    inherit caches;

    substituters = scope: map (c: c.url) (inScope scope);
    trustedKeys = scope: map (c: c.key) (inScope scope);

    # omniflake index attributes that must keep their author's nixpkgs pin.
    ownNixpkgs = lib.concatMap (c: c.ownNixpkgs or []) all;
  }
