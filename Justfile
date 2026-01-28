# use zshell for shell commands
set shell := ["zsh", "-c"]

############################################################################
#
#  Development Commands
#
############################################################################

[group('development')]
# Generate a new NixOS or Home Manager module
# Usage: just new-module nixos programs my-program
new-module TYPE CATEGORY NAME:
  #!/usr/bin/env bash
  ./tools/generate-module.sh {{TYPE}} {{CATEGORY}} {{NAME}}

[group('development')]
# Validate configuration syntax and host builds
validate:
  ./tools/validate-config.sh

[group('development')]
# Update auto-generated documentation
update-docs:
  ./tools/update-docs.sh

[group('development')]
# Run validation and update docs
check: validate update-docs
  #!/usr/bin/env bash
  if ! git diff --quiet docs/ modules/*/README.md hosts/README.md 2>/dev/null; then
    echo "⚠️  Documentation changes detected. Review and commit."
  fi

[group('development')]
# Open a nix shell with the flake
repl:
  nixos-rebuild repl --flake .

[group('development')]
# Check the syntax of a nix file
check-file FILE:
  nix-instantiate --parse-only {{FILE}}

[group('development')]
# Lint for dead code
lint FILE='.':
  nix run github:astro/deadnix -- -eq {{FILE}}

[group('development')]
# Format the nix files in this repo
fmt:
  nix fmt .

############################################################################
#
#  Build Commands
#
############################################################################

[group('build')]
# Build a specific host configuration
# Usage: just build home-desktop
build HOST:
  nix build .#nixosConfigurations.{{HOST}}.config.system.build.toplevel --print-build-logs

[group('build')]
# Build all host configurations
build-all:
  #!/usr/bin/env bash
  for host in $(ls hosts/ | grep -v default.nix | grep -v README.md | grep -v _shared); do
    if [[ -d "hosts/$host" && -f "hosts/$host/default.nix" ]]; then
      echo "Building $host..."
      just build "$host"
    fi
  done

[group('build')]
# Run eval tests
test:
  nix eval .#evalTests --show-trace --print-build-logs --verbose

############################################################################
#
#  Update Commands
#
############################################################################

[group('update')]
# Update all flake inputs
update:
  nix flake update

[group('update')]
# Update specific flake input
# Usage: just update-input nixpkgs
update-input INPUT:
  nix flake lock --update-input {{INPUT}}

[group('update')]
# Full system update (flake + rebuild)
full-upgrade:
  just update
  just upgrade boot

############################################################################
#
#  Deployment Commands
#
############################################################################

[group('deploy')]
# Rebuild and switch to new configuration
# Usage: just switch
switch COMMAND='switch':
  sudo nixos-rebuild {{COMMAND}} --flake .

[group('deploy')]
# Rebuild using path: prefix (for dirty trees)
switch-path COMMAND='switch':
  sudo nixos-rebuild {{COMMAND}} --flake path:.

[group('deploy')]
# Rebuild using nh helper utility
upgrade COMMAND='switch':
  nh os {{COMMAND}} --ask

[group('deploy')]
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

[group('maintenance')]
# Remove all generations older than 7 days
clean:
  ng clean all -K 7d
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

[group('maintenance')]
# Garbage collect all unused nix store entries
gc:
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

[group('maintenance')]
# Optimize nix store (deduplicate)
optimize:
  nix-store --optimise

[group('maintenance')]
# List all generations of the system profile
history:
  nix profile history --profile /nix/var/nix/profiles/system

############################################################################
#
#  Git Commands
#
############################################################################

[group('git')]
# Commit pending changes
commit MESSAGE:
  git add .
  git commit -m "{{MESSAGE}}"

[group('git')]
# Commit and push changes
push MESSAGE:
  git add .
  git commit -m "{{MESSAGE}}"
  git push

############################################################################
#
#  Misc Commands
#
############################################################################

# Show PATH entries
path:
   $env.PATH | split row ":"
