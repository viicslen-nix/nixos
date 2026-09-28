{
  description = "Nixos config flake";

  inputs = {
    # Enable submodules
    self.submodules = true;

    # Linux-only systems list, used to strip x86_64-darwin from transitive
    # flake-parts flakes (nixpkgs 26.11 throws when its darwin set is evaluated).
    systems-linux.url = "github:nix-systems/default-linux";

    # Flake framework
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    omniflake = {
      url = "github:fzakaria/omniflake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Lib
    viicslen-lib = {
      url = "path:./flakes/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Shell
    laravel-sail = {
      url = "github:ariaieboy/laravel-sail";
      flake = false;
    };
    fzf-tab = {
      url = "github:Aloxaf/fzf-tab";
      flake = false;
    };
    nu-scripts = {
      url = "github:nushell/nu_scripts";
      flake = false;
    };
    tmux-tokyo-night = {
      url = "github:janoamaral/tokyo-night-tmux";
      flake = false;
    };
    zjstatus = {
      url = "github:dj95/zjstatus";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 1Password
    tmux-1password = {
      url = "github:yardnsm/tmux-1password";
      flake = false;
    };
    one-password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland = {
      url = "path:./flakes/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.viicslen-lib.follows = "viicslen-lib";
    };

    # Niri
    niri = {
      url = "path:./flakes/niri";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.viicslen-lib.follows = "viicslen-lib";
    };
    dms = {
      url = "path:./flakes/dms";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nilastia = {
      url = "github:ST-SARAVANAPRIYAN/Nilastia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ignis = {
      url = "github:ignis-sh/ignis";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Ships no flake — the shell is an ignis config directory plus matugen templates.
    exo = {
      url = "github:debuggyo/Exo";
      flake = false;
    };
    ambxst = {
      url = "github:Axenide/Ambxst";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AI harnesses: shared config, per-harness modules, and the opencode
    # packages and web service it absorbed.
    ai = {
      url = "path:./flakes/ai";
      # Share this flake's omniflake so its home-manager is the same copy as
      # everything else, and no extra nodes are locked for it.
      inputs.omniflake.follows = "omniflake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.packages.follows = "packages";
      inputs.llm-agents.follows = "llm-agents";
      inputs.viicslen-lib.follows = "viicslen-lib";
    };

    # Leave `nixpkgs` un-overridden — it is what keeps cache.numtide.com hitting.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.systems.follows = "systems-linux";
    };

    zed = {
      url = "path:./flakes/zed";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.packages.follows = "packages";
    };

    nixvim = {
      url = "path:./flakes/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.packages.follows = "packages";
    };

    # Emacs
    emacs = {
      url = "path:./flakes/emacs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    packages = {
      url = "path:./flakes/packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Theming
    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };

    # Community packages
    # Don't make superset-desktop follow nixpkgs — it pins its own for the autoPatchelf inputs.
    superset-desktop.url = "github:viicslen/superset-desktop";
    gitura = {
      url = "github:viicslen/gitura";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Leave ghostty on its own nixpkgs — following ours makes every build a from-source zig build.
    ghostty.url = "github:ghostty-org/ghostty";
    lan-mouse = {
      url = "github:feschber/lan-mouse";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Leave tuicr on its own nixpkgs — pinning it to ours forces a cargo re-vendor crates.io 403s.
    tuicr.url = "github:agavra/tuicr";
    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jj-starship = {
      url = "github:dmmulroy/jj-starship";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghost-backup = {
      url = "github:FmTod/ghost-backup";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.bun2nix.inputs.systems.follows = "systems-linux";
    };
  };

  outputs = inputs @ {flake-parts, ...}: let
    inherit (inputs.nixpkgs) lib;

    caches = import ./caches.nix {inherit lib;};

    omniInputs = inputs.viicslen-lib.lib.omni.mkInputs {
      inherit (inputs) omniflake;
      inherit (caches) ownNixpkgs;

      # `flakes` is the loader's own set — don't swap `home-manager` for an input, there is none.
      overrides = flakes: {
        inherit (inputs) flake-parts;
        inherit (flakes) home-manager;
        systems = inputs.systems-linux;
      };

      # Right-hand side is the *repository* name, not ours; find it with `just omniflake-search <term>`.
      mapping = {
        agenix = "agenix";
        base16 = "base16-nix";
        disko = "disko";
        git-hooks = "git-hooks-nix";
        home-manager = "home-manager";
        impermanence = "impermanence";
        jovian = "jovian-nixos";
        nix-alien = "nix-alien";
        nix-cachyos-kernel = "nix-cachyos-kernel";
        nix-vite-plus = "nix-vite-plus";
        nixos-generators = "nixos-generators";
        nixos-hardware = "nixos-hardware";
        nixos-wsl = "nixos-wsl";
        nixpkgs-wayland = "nixpkgs-wayland";
        nur = "nur";
        plasma-manager = "plasma-manager";
        stylix = "stylix";
        treefmt-nix = "treefmt-nix";
        vscode-server = "nixos-vscode-server";
        zen-browser = "zen-browser-flake";
      };
    };
  in
    flake-parts.lib.mkFlake {inputs = inputs // omniInputs;} {
      # Keep `recursive = false` — a nested directory is imported by the part that owns it.
      imports = inputs.viicslen-lib.lib.umport {
        path = ./parts;
        recursive = false;
      };
    };

  # Generated from caches.nix by `just sync-caches` — do not edit by hand.
  nixConfig = {
    # BEGIN generated from caches.nix
    extra-substituters = [
      "https://ghostty.cachix.org"
      "https://hyprland.cachix.org"
      "https://attic.xuyh0120.win/lantian"
      "https://nix-community.cachix.org"
      "https://cache.nixos-cuda.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    # END generated
  };
}
