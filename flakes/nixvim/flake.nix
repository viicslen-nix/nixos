{
  description = "NixVim-based Neovim configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mcphub-nvim = {
      url = "github:ravitemer/mcphub.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    self,
    nixvim,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./apps.nix
        ./packages.nix
      ];

      systems = ["x86_64-linux"];

      perSystem = {
        config,
        pkgs,
        system,
        ...
      }: let
        # Import custom plugin packages
        laravel-nvim = import ./pkgs/laravel-nvim.nix {inherit pkgs;};
        worktrees-nvim = import ./pkgs/worktrees-nvim.nix {inherit pkgs;};
        neotest-pest = import ./pkgs/neotest-pest.nix {inherit pkgs;};
        mcp-hub = import ./pkgs/mcp-hub.nix {
          inherit pkgs;
          inherit (pkgs) lib fetchFromGitHub;
        };
        mcphub-nvim = inputs.mcphub-nvim.packages.${system}.default;

        # Create nixpkgs with allowUnfree for intelephense
        nixpkgsWithUnfree = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Build NixVim with our configuration
        nixvimLib = nixvim.lib.${system};
        nixvimModule = {
          inherit pkgs;
          module = import ./config {
            inherit pkgs laravel-nvim worktrees-nvim neotest-pest mcphub-nvim mcp-hub;
            inherit (pkgs) lib;
          };
        };
      in {
        # Default package is the configured Neovim
        packages = {
          default = nixvim.legacyPackages.${system}.makeNixvimWithModule {
            pkgs = nixpkgsWithUnfree;
            module = import ./config {
              pkgs = nixpkgsWithUnfree;
              inherit laravel-nvim worktrees-nvim neotest-pest mcphub-nvim mcp-hub;
              lib = nixpkgsWithUnfree.lib;
            };
          };

          # Expose custom packages
          inherit laravel-nvim worktrees-nvim neotest-pest mcphub-nvim mcp-hub;
        };

        # Provide the default formatter
        formatter = pkgs.alejandra;

        # Check if codebase is properly formatted
        checks = {
          nix-fmt = pkgs.runCommand "nix-fmt-check" {nativeBuildInputs = [pkgs.alejandra];} ''
            alejandra --check ${self} < /dev/null | tee $out
          '';
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nix-output-monitor
            alejandra
          ];
          shellHook = ''
            echo "NixVim development shell"
            echo "Use 'nom build' or 'nom run' for better build output"
          '';
        };
      };
    };
}
