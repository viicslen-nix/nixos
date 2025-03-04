{
  description = "Nixos config flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Flakes
    flake-parts.url = "github:hercules-ci/flake-parts";
    easy-hosts.url = "github:tgirlcloud/easy-hosts";
    mission-control.url = "github:Platonic-Systems/mission-control";
    flake-root.url = "github:srid/flake-root";

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

    # Community packages
    nur.url = "github:nix-community/NUR";
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

    # NuShell
    nu-scripts = {
      url = "github:nushell/nu_scripts";
      flake = false;
    };

    # Tmux
    tmux-1password = {
      url = "github:yardnsm/tmux-1password";
      flake = false;
    };
    tmux-tokyo-night = {
      url = "github:janoamaral/tokyo-night-tmux";
      flake = false;
    };

    # Zellij
    zjstatus.url = "github:dj95/zjstatus";

    # Nvim
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nvchad-starter.follows = "nvchad-config";
    };
    nvchad-config = {
      url = "github:viicslen/neovim";
      flake = false;
    };

    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    pyprland.url = "github:hyprland-community/pyprland";
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
    hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };
    hyprsplit = {
      url = "github:shezdy/hyprsplit";
      inputs.hyprland.follows = "hyprland";
    };
    hyprchroma = {
      url = "github:alexhulbert/Hyprchroma";
      inputs.hyprland.follows = "hyprland";
    };

    # Astal
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags = {
      url = "github:aylur/ags";
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

    # Tools
    agenix.url = "github:ryantm/agenix";
    nix-alien.url = "github:thiagokokada/nix-alien";
    lan-mouse.url = "github:feschber/lan-mouse";
    zen-browser.url = "github:MarceColl/zen-browser-flake";
    one-password-shell-plugins.url = "github:1Password/shell-plugins";
    ghostty.url = "github:ghostty-org/ghostty";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    self,
    ...
  }: let
    inherit (self) outputs;

    # Use our custom lib enhanced with nixpkgs and hm one
    lib = import ./nix/lib {lib = nixpkgs.lib;} // nixpkgs.lib;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.easy-hosts.flakeModule
        inputs.mission-control.flakeModule
        inputs.flake-root.flakeModule
      ];
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = {
        pkgs,
        system,
        config,
        inputs',
        ...
      }: {
        # make pkgs available to all `perSystem` functions
        module.args.pkgs = inputs'.nixpkgs.legacyPackages;

        # make custom lib available to all `perSystem` functions
        module.args.lib = lib;

        # Formatter for your nix files, available through 'nix fmt'
        # Other options beside 'alejandra' include 'nixpkgs-fmt'
        formatter = pkgs.alejandra;

        # Your custom packages
        # Accessible through 'nix build', 'nix shell', etc
        packages = import ./pkgs {inherit inputs pkgs;};

        # Your custom dev shells
        devShells = import ./dev-shells {inherit inputs system;};
      };
      flake = {
        # Your custom packages and modifications, exported as overlays
        overlays = import ./overlays {inherit inputs;};

        # Reusable nixos modules you might want to export
        # These are usually stuff you would upstream into nixpkgs
        nixosModules = import ./modules/nixos;

        # Reusable home-manager modules you might want to export
        # These are usually stuff you would upstream into home-manager
        homeManagerModules = import ./modules/home-manager;
      };
      easyHosts = import ./hosts {inherit inputs outputs;};
    };
}
