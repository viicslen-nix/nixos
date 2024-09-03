{
  description = "Nixos config flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Community packages
    nur.url = github:nix-community/NUR;
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";

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

    # NvChad
    nvchad = {
      url = "github:NvChad/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvchad-config = {
      url = "github:viicslen/neovim";
      flake = false;
    };

    # Hyprland
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs.hyprlang.follows = "hyprland/hyprlang";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
      inputs.systems.follows = "hyprland/systems";
    };
    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.hyprlang.follows = "hyprland/hyprlang";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
      inputs.systems.follows = "hyprland/systems";
    };
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
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
    tokyo-night-tmux = {
      url = "github:janoamaral/tokyo-night-tmux";
      flake = false;
    };

    nix-alien.url = "github:thiagokokada/nix-alien";
    lan-mouse.url = "github:feschber/lan-mouse";
    one-password-shell-plugins.url = "github:1Password/shell-plugins";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-hardware,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # Your custom dev shells
    devShells = forAllSystems (
      system:
        import ./dev-shells {inherit inputs system;}
    );

    # Reusable nixos modules you might want to export
    # These are usually stuff you would upstream into nixpkgs
    nixosModules = import ./modules/nixos;

    # Reusable home-manager modules you might want to export
    # These are usually stuff you would upstream into home-manager
    homeManagerModules = import ./modules/home-manager;

    # Your nixos configurations
    nixosConfigurations = {
      asus-zephyrus-gu603 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [./hosts/asus-zephyrus-gu603];
        specialArgs = {
          inherit inputs outputs;
          user = "neoscode";
          name = "Victor R";
          password = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
        };
      };

      acer-aspire-tc780 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [./hosts/acer-aspire-tc780];
        specialArgs = {
          inherit inputs outputs;
          user = "dostov-02";
          name = "Dostov";
        };
      };

      neoscode-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [./hosts/neoscode-server];
        specialArgs = {
          inherit inputs outputs;
          user = "neoscode";
          name = "Victor R";
          password = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
        };
      };
    };

    colmena = {
      meta = {
        # Override to pin the Nixpkgs version (recommended). This option
        # accepts one of the following:
        # - A path to a Nixpkgs checkout
        # - The Nixpkgs lambda (e.g., import <nixpkgs>)
        # - An initialized Nixpkgs attribute set
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [];
        };
      };

      acer-aspire-tc780 = {
        # Like NixOps and Morph, Colmena will attempt to connect to
        # the remote host using the attribute name by default. You
        # can override it like:
        deployment.targetHost = "host-b.mydomain.tld";

        # You can filter hosts by tags with --on @tag-a,@tag-b.
        # In this example, you can deploy to hosts with the "web" tag using:
        #    colmena apply --on @web
        # You can use globs in tag matching as well:
        #    colmena apply --on '@infra-*'
        deployment.tags = ["web" "infra-lax"];
      };
    };
  };
}
