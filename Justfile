# use zshell for shell commands
set shell := ["zsh", "-c"]

############################################################################
#
#  Development Commands
#
############################################################################

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

# Runs parts/checks.nix, which skips the hosts known not to evaluate.
# Heavy — see the resource-safety notes in AGENTS.md before running.
# Build every host configuration
build-all *ARGS:
  nix flake check --print-build-logs {{ARGS}}

############################################################################
#
#  Update Commands
#
############################################################################

# Update all subflakes then all root flake inputs
update *ARGS:
  for d in flakes/*/; do nix flake update --flake "path:$d"; done
  nix flake update {{ARGS}}

# Update root flake inputs only
update-main *ARGS:
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

# Re-vendor upstream AI skill collections (scripts/skill-sources.tsv) via sparse
# checkout, for repos too large to carry as a flake input. Commit the result.
# Usage: just vendor-skills [collection]
vendor-skills *NAME:
  ./scripts/vendor-skills.sh {{NAME}}

# List the local package attrs in flakes/packages (as `just bump` takes them)
packages:
  @cd flakes/packages && just packages

# Compare each local package against the latest version upstream (GitHub
# releases, npm, PyPI, or the vendor's own endpoint)
# Read-only: no downloads, no file edits — feed the results to `just bump <attr>`
outdated:
  @cd flakes/packages && just outdated

# Bump version + hash of a local package in flakes/packages
# Attr = its path under by-name/, e.g. app-images.t3code, superset.cli, coderabbit
# Usage: just bump coderabbit --version 0.4.5   (or --version skip for hash only)
bump ATTR *ARGS:
  @cd flakes/packages && just bump {{ATTR}} {{ARGS}}

# Bump every package `just outdated` reports as behind, to that exact version
# Usage: just bump-outdated [--commit]
bump-outdated *ARGS:
  @cd flakes/packages && just bump-outdated {{ARGS}}

# Try to bump every local package; prints the ones nix-update can't resolve
bump-all *ARGS:
  @cd flakes/packages && just bump-all {{ARGS}}

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
