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

    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Lib
    viicslen-lib = {
      url = "path:./flakes/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Registry
    flake-registry = {
      url = "github:NixOS/flake-registry";
      flake = false;
    };

    # Disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # ISO builder
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Impermanence
    impermanence.url = "github:nix-community/impermanence";

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
    zjstatus.url = "github:dj95/zjstatus";

    # 1Password
    tmux-1password = {
      url = "github:yardnsm/tmux-1password";
      flake = false;
    };
    one-password-shell-plugins.url = "github:1Password/shell-plugins";

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
    ambxst.url = "github:Axenide/Ambxst";

    # OpenCode
    opencode = {
      url = "path:./flakes/opencode";
      inputs.packages.follows = "packages";
    };

    zed = {
      url = "path:./flakes/zed";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.packages.follows = "packages";
    };

    # Nvim
    neovim = {
      url = "path:./flakes/neovim";
      inputs.packages.follows = "packages";
    };
    nixvim = {
      url = "path:./flakes/nixvim";
      inputs.packages.follows = "packages";
    };
    packages = {
      url = "path:./flakes/packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Theming
    stylix.url = "github:danth/stylix";
    base16.url = "github:SenchoPens/base16.nix";
    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
    rofi-themes = {
      url = "github:newmanls/rofi-themes-collection";
      flake = false;
    };
    rofi-collections = {
      url = "github:Murzchnvok/rofi-collection";
      flake = false;
    };

    # Package sets
    nur.url = "github:nix-community/NUR";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";

    # Community packages
    agenix.url = "github:ryantm/agenix";
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.systems.follows = "systems-linux";
    };
    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitura = {
      url = "github:viicslen/gitura";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty.url = "github:ghostty-org/ghostty";
    lan-mouse.url = "github:feschber/lan-mouse";
    nix-alien.url = "github:thiagokokada/nix-alien";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
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

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      # Every file under ./parts is a flake-parts module and is picked up
      # automatically — drop a new file in to add a concern, no wiring needed.
      imports =
        map (name: ./parts + "/${name}")
        (builtins.filter (name: builtins.match ".*\\.nix" name != null)
          (builtins.attrNames (builtins.readDir ./parts)));
    };
}
