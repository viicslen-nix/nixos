{
  description = "Nixos config flake";

  inputs = {
    # Enable submodules
    self.submodules = true;

    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
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

    # OpenCode
    opencode.url = "path:./flakes/opencode";

    # Nvim
    neovim.url = "path:./flakes/neovim";
    nixvim.url = "path:./flakes/nixvim";

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
    worktrunk = {
      url = "github:max-sixty/worktrunk";
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
    worktree-manager = {
      url = "github:viicslen/worktree-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghost-backup = {
      url = "github:FmTod/ghost-backup";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    self,
    ...
  }: let
    vlib = inputs.viicslen-lib.lib;
  in {
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = vlib.pkgFromSystem "alejandra";

    # Your custom dev shells
    devShells = vlib.genSystems (system:
      import ./dev-shells {
        inherit inputs system;
        pkgs = vlib.pkgsFor system;
      });

    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = vlib.genSystems (system:
      nixpkgs.lib.packagesFromDirectoryRecursive {
        callPackage = vlib.callPackageForSystem system;
        directory = ./packages/by-name;
      });

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # Reusable nixos modules you might want to export
    nixosModules = vlib.modules.autoImportRecursive ./modules/nixos;

    # Reusable home-manager modules you might want to export
    homeManagerModules = vlib.modules.autoImportRecursive ./modules/home-manager;

    # NixOS configurations for all your hosts
    nixosConfigurations = vlib.hosts.mkNixosConfigurations {inherit inputs; outputs = self.outputs;} ./hosts;
  };
}
