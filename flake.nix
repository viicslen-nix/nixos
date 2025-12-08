{
  description = "Nixos config flake";

  inputs = {
    # Enable submodules
    self.submodules = true;

    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Systems
    systems.url = "github:nix-systems/default";
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

    # Nvim
    neovim = {
      url = ./flakes/neovim;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 1Password
    tmux-1password = {
      url = "github:yardnsm/tmux-1password";
      flake = false;
    };
    one-password-shell-plugins.url = "github:1Password/shell-plugins";

    # Niri
    niri = {
      url = ./flakes/niri;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland = {
      url = ./flakes/hyprland;
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
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";

    # Community packages
    agenix.url = "github:ryantm/agenix";
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
  };

  outputs = inputs @ {
    flake-parts,
    systems,
    nixpkgs,
    self,
    ...
  }:
    with self.lib; let
      inherit (self) outputs;
    in {
      lib = import ./lib {inherit inputs;};

      # Formatter for your nix files, available through 'nix fmt'
      # Other options beside 'alejandra' include 'nixpkgs-fmt'
      formatter = pkgFromSystem "alejandra";

      # Your custom dev shells
      devShells = genSystems (system:
        import ./dev-shells {
          inherit inputs system;
          pkgs = pkgsFor system;
        });

      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages = genSystems (system:
        packagesFromDirectoryRecursive {
          callPackage = callPackageForSystem system;
          directory = ./packages/by-name;
        });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays {inherit inputs;};

      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      # Flake-parts does some weird stuff with the output of flake.nixosModules
      nixosModules = import ./modules/nixos;

      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configurations for all your hosts
      nixosConfigurations = mkNixosConfigurations (import ./hosts {inherit inputs outputs;});
    };
}
