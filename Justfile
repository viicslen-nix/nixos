# use zshell for shell commands
set shell := ["zsh", "-c"]

############################################################################
#
#  Development Commands
#
############################################################################

# Generate a new NixOS or Home Manager module
# Usage: just new-module nixos programs my-program
new-module TYPE CATEGORY NAME *ARGS:
  #!/usr/bin/env bash
  ./tools/generate-module.sh {{TYPE}} {{CATEGORY}} {{NAME}} {{ARGS}}

# Validate configuration syntax and host builds
validate *ARGS:
  ./tools/validate-config.sh {{ARGS}}

# Update auto-generated documentation
update-docs *ARGS:
  ./tools/update-docs.sh {{ARGS}}

# Run validation and update docs
check: validate update-docs
  #!/usr/bin/env bash
  if ! git diff --quiet docs/ modules/*/README.md hosts/README.md 2>/dev/null; then
    echo "⚠️  Documentation changes detected. Review and commit."
  fi

# Open a nix shell with the flake
repl *ARGS:
  nixos-rebuild repl --flake . {{ARGS}}

# Check the syntax of a nix file
check-file FILE *ARGS:
  nix-instantiate --parse-only {{FILE}} {{ARGS}}

# Lint for dead code
lint FILE='.' *ARGS:
  nix run github:astro/deadnix -- -eq {{FILE}} {{ARGS}}

# Format the nix files in this repo
fmt PATH='.' *ARGS:
  nix fmt {{PATH}} {{ARGS}}

############################################################################
#
#  Build Commands
#
############################################################################

# Build a specific host configuration
# Usage: just build home-desktop
build HOST *ARGS:
  nix build .#nixosConfigurations.{{HOST}}.config.system.build.toplevel --print-build-logs {{ARGS}}

# Build all host configurations
build-all *ARGS:
  #!/usr/bin/env bash
  for host in $(ls hosts/ | grep -v default.nix | grep -v README.md | grep -v _shared); do
    if [[ -d "hosts/$host" && -f "hosts/$host/default.nix" ]]; then
      echo "Building $host..."
      just build "$host" {{ARGS}}
    fi
  done

# Run eval tests
test *ARGS:
  nix eval .#evalTests --show-trace --print-build-logs --verbose {{ARGS}}

############################################################################
#
#  Update Commands
#
############################################################################

# Update all flake inputs
update *ARGS:
  nix flake update {{ARGS}}

# Update specific flake input
# Usage: just update-input nixpkgs
update-input INPUT *ARGS:
  nix flake update {{INPUT}} {{ARGS}}

# Update flake lock file of a specific subflake and refresh the root flake input
# Usage: just update-subflake nixvim
update-subflake NAME *ARGS:
  nix flake update --flake "path:flakes/{{NAME}}"
  nix flake update "{{NAME}}" {{ARGS}}

# Full system update (flake + rebuild)
full-upgrade *ARGS:
  just update
  just upgrade boot {{ARGS}}

############################################################################
#
#  Deployment Commands
#
############################################################################

# Rebuild and switch to new configuration
# Usage: just switch
rebuild COMMAND='switch' *ARGS:
  sudo nixos-rebuild {{COMMAND}} --flake . {{ARGS}}

# Rebuild using path: prefix (for dirty trees)
rebuild-path COMMAND='switch' *ARGS:
  sudo nixos-rebuild {{COMMAND}} --flake path:. {{ARGS}}

# Rebuild using nh helper utility
upgrade COMMAND='switch' *ARGS:
  nh os {{COMMAND}} --ask "path:." {{ARGS}}

# Commit changes and upgrade system
commit-and-upgrade MESSAGE COMMAND='switch' *ARGS:
  git add .
  git commit -m "{{MESSAGE}}"
  nh os {{COMMAND}} {{ARGS}}

############################################################################
#
#  Maintenance Commands
#
############################################################################

# Remove all generations older than 7 days
clean *ARGS:
  ng clean all -K 7d {{ARGS}}
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Garbage collect all unused nix store entries
gc *ARGS:
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old {{ARGS}}

# Optimize nix store (deduplicate)
optimize *ARGS:
  nix-store --optimise {{ARGS}}

# List all generations of the system profile
history *ARGS:
  nix profile history --profile /nix/var/nix/profiles/system {{ARGS}}

############################################################################
#
#  Git Commands
#
############################################################################

# Commit pending changes
commit MESSAGE *ARGS:
  git add .
  git commit -m "{{MESSAGE}}" {{ARGS}}

# Commit and push changes
push MESSAGE *ARGS:
  git add .
  git commit -m "{{MESSAGE}}"
  git push {{ARGS}}
