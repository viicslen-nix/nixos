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

    # ~12k pinned flakes behind one input; see the `omni` binding in `outputs`
    # for which of this repo's dependencies come through it. Bump them all with
    # `just update-input omniflake`.
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
    ambxst = {
      url = "github:Axenide/Ambxst";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenCode
    opencode = {
      url = "path:./flakes/opencode";
      # Share this flake's omniflake so opencode's home-manager is the same
      # copy as everything else, and no extra nodes are locked for it.
      inputs.omniflake.follows = "omniflake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.packages.follows = "packages";
    };

    # Upstream AI harness skills; bump with `just update-input mattpocock-skills`.
    # Collections too large to carry whole are vendored instead — see
    # scripts/skill-sources.tsv and `just vendor-skills`.
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };

    zed = {
      url = "path:./flakes/zed";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.packages.follows = "packages";
    };

    # Nvim. `flakes/neovim` is still a maintained subflake but nothing here
    # consumes it — 5556fbc replaced it with nixvim. Re-add as an input when
    # something needs it again.
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
    # Private. Resolvable because `access-tokens` is wired in the base preset;
    # deliberately does not follow nixpkgs — it ships a prebuilt AppImage and
    # pins its own nixpkgs for the autoPatchelf inputs.
    superset-desktop.url = "github:viicslen/superset-desktop";
    gitura = {
      url = "github:viicslen/gitura";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Left on its own nixpkgs on purpose: `ghostty.cachix.org` is a configured
    # substituter, and its builds are keyed to the nixpkgs ghostty pins. Ours
    # matches it today only by coincidence (one day apart), so following would
    # turn every future ghostty into a from-source zig build. Costs 7 lock nodes.
    ghostty.url = "github:ghostty-org/ghostty";
    lan-mouse = {
      url = "github:feschber/lan-mouse";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Left on its own nixpkgs: pinning it to ours forces a cargo re-vendor, and
    # crates.io 403s nix's curl User-Agent from here, so the rebuild dies on
    # `cannot download download-adler2-2.0.1 from any mirror`. Costs 7 lock nodes.
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
    # Every indexed flake under one override policy. Unification is by input
    # *name* at every depth — the job the `follows` lines used to do, done at
    # evaluation time instead of lock time. `systems` is the linux-only list
    # for the same reason `systems-linux` exists at all.
    #
    # `home-manager` overrides to omniflake's own copy, so the graph still
    # holds exactly one without home-manager being an input here. The self
    # reference resolves because overrides apply to a flake's *inputs*, never
    # to the flake being loaded — `omni.home-manager` is only forced while
    # loading something that has a home-manager input. Same shape as
    # omniflake's own `lib.unifyAll`.
    omni = inputs.omniflake.lib.withOverrides (
      inputs.omniflake.lib.foundations
      // {
        inherit (inputs) flake-parts;
        inherit (omni) home-manager;
        systems = inputs.systems-linux;
      }
    );

    # Local input name -> omniflake attribute name; the index keys on the
    # repository name, which is not always what this repo calls the input.
    # Merged into `inputs` below, so every `inputs.<name>` and
    # `pkgs.inputs.<name>` reference keeps working unchanged — and none of
    # these appear in flake.lock any more.
    omniInputs = builtins.mapAttrs (_: name: omni.${name}) {
      agenix = "agenix";
      base16 = "base16-nix";
      disko = "disko";
      git-hooks = "git-hooks-nix";
      home-manager = "home-manager";
      impermanence = "impermanence";
      jovian = "jovian-nixos";
      llm-agents = "llm-agents-nix";
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
  in
    flake-parts.lib.mkFlake {inputs = inputs // omniInputs;} {
      # Every file under ./parts is a flake-parts module and is picked up
      # automatically — drop a new file in to add a concern, no wiring needed.
      imports =
        map (name: ./parts + "/${name}")
        (builtins.filter (name: builtins.match ".*\\.nix" name != null)
          (builtins.attrNames (builtins.readDir ./parts)));
    };
}
