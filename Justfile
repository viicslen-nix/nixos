# use zshell for shell commands
set shell := ["zsh", "-c"]

############################################################################
#
#  Development Commands
#
############################################################################

# Generate a new NixOS or Home Manager module
# Usage: just new-module nixos programs my-program
new-module TYPE CATEGORY NAME:
  #!/usr/bin/env bash
  ./tools/generate-module.sh {{TYPE}} {{CATEGORY}} {{NAME}}

# Validate configuration syntax and host builds
validate:
  ./tools/validate-config.sh

# Update auto-generated documentation
update-docs:
  ./tools/update-docs.sh

# Run validation and update docs
check: validate update-docs
  #!/usr/bin/env bash
  if ! git diff --quiet docs/ modules/*/README.md hosts/README.md 2>/dev/null; then
    echo "⚠️  Documentation changes detected. Review and commit."
  fi

# Open a nix shell with the flake
repl:
  nixos-rebuild repl --flake .

# Check the syntax of a nix file
check-file FILE:
  nix-instantiate --parse-only {{FILE}}

# Lint for dead code
lint FILE='.':
  nix run github:astro/deadnix -- -eq {{FILE}}

# Format the nix files in this repo
fmt PATH='.':
  nix fmt {{PATH}}

############################################################################
#
#  Build Commands
#
############################################################################

# Build a specific host configuration
# Usage: just build home-desktop
build HOST:
  nix build .#nixosConfigurations.{{HOST}}.config.system.build.toplevel --print-build-logs

# Build all host configurations
build-all:
  #!/usr/bin/env bash
  for host in $(ls hosts/ | grep -v default.nix | grep -v README.md | grep -v _shared); do
    if [[ -d "hosts/$host" && -f "hosts/$host/default.nix" ]]; then
      echo "Building $host..."
      just build "$host"
    fi
  done

# Run eval tests
test:
  nix eval .#evalTests --show-trace --print-build-logs --verbose

############################################################################
#
#  Update Commands
#
############################################################################

# Update all flake inputs
update:
  nix flake update

# Update specific flake input
# Usage: just update-input nixpkgs
update-input INPUT:
  nix flake lock --update-input {{INPUT}}

# Full system update (flake + rebuild)
full-upgrade:
  just update
  just upgrade boot

############################################################################
#
#  Deployment Commands
#
############################################################################

# Rebuild and switch to new configuration
# Usage: just switch
rebuild COMMAND='switch':
  sudo nixos-rebuild {{COMMAND}} --flake .

# Rebuild using path: prefix (for dirty trees)
rebuild-path COMMAND='switch':
  sudo nixos-rebuild {{COMMAND}} --flake path:.

# Rebuild using nh helper utility
upgrade COMMAND='switch':
  nh os {{COMMAND}} --ask

# Commit changes and upgrade system
commit-and-upgrade MESSAGE COMMAND='switch':
  git add .
  git commit -m "{{MESSAGE}}"
  nh os {{COMMAND}}

############################################################################
#
#  Maintenance Commands
#
############################################################################

# Remove all generations older than 7 days
clean:
  ng clean all -K 7d
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Garbage collect all unused nix store entries
gc:
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

# Optimize nix store (deduplicate)
optimize:
  nix-store --optimise

# List all generations of the system profile
history:
  nix profile history --profile /nix/var/nix/profiles/system

############################################################################
#
#  Git Commands
#
############################################################################

# Commit pending changes
commit MESSAGE:
  git add .
  git commit -m "{{MESSAGE}}"

# Commit and push changes
push MESSAGE:
  git add .
  git commit -m "{{MESSAGE}}"
  git push
