# use zshell for shell commands
set shell := ["zsh", "-c"]

# Where `gh skill` vendors upstream skill collections
SKILLS_DIR := "hosts/_shared/presets/personal/ai/skills"

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

# Search the omniflake index for a flake, at the rev this flake pins. Prints
# the attribute names — what goes on the right of the `omniInputs` mapping in
# flake.nix. No TERM lists all ~12k. Forces no fetch: it only reads index.json.
# Usage: just omniflake-search sops
omniflake-search *TERM:
  @rev=$(jq -r '.nodes.omniflake.locked.rev' flake.lock); \
  nix eval --json "github:fzakaria/omniflake/$rev#lib.names" \
    | jq -r '.[]' \
    | grep -i -- "{{TERM}}" \
    || echo "no flake matching '{{TERM}}' in the index"

# Update flake lock file of a specific subflake and refresh the root flake input
# Usage: just update-subflake nixvim
update-subflake NAME *ARGS:
  nix flake update --flake "path:flakes/{{NAME}}"
  nix flake update "{{NAME}}" {{ARGS}}

# Vendor upstream AI skills into the personal preset, for repos too large to
# carry as a flake input. Commit the result. Name a skill (or its path in the
# repo) to take just that one, `--all` for the whole collection, neither to pick
# interactively. `gh` takes one name per run and refuses `--all` beside it, so
# picking several means repeating the recipe.
# Usage: just vendor-skills plannotator/effective-html --all
#        just vendor-skills plannotator/effective-html html-plan
#        just vendor-skills google-labs-code/stitch-skills --all --pin v1.0
vendor-skills REPO *ARGS:
  gh skill install {{REPO}} --force --dir {{SKILLS_DIR}} {{ARGS}}
  git add {{SKILLS_DIR}}

# Pull upstream changes into every vendored skill. `gh skill` tracks each one's
# origin in its own SKILL.md frontmatter, so there is no manifest to keep.
# Usage: just update-skills [--dry-run]
update-skills *ARGS:
  gh skill update --all --dir {{SKILLS_DIR}} {{ARGS}}
  git add {{SKILLS_DIR}}

# Regenerate flake.nix's nixConfig block from caches.nix. Needed because nix
# rejects a computed flake config value — the list and its strings must both be
# syntactic — so this is the one place the table cannot simply be imported.
sync-caches:
  #!/usr/bin/env bash
  set -euo pipefail
  block=$(nix eval --impure --raw --expr \
    'let lib = (builtins.getFlake "nixpkgs").lib;
     in (import ./caches.nix { inherit lib; checkDrift = false; }).nixConfigBlock')
  awk -v block="$block" '
    /# BEGIN generated from caches.nix/ { print; printf "%s\n", block; skip = 1; next }
    /# END generated/                   { skip = 0 }
    !skip                               { print }
  ' flake.nix > flake.nix.new
  mv flake.nix.new flake.nix
  echo "flake.nix nixConfig regenerated from caches.nix"

# Hand-written skills have no origin, and are omitted
# List the vendored skills with the repo and ref each came from
skills:
  @gh skill list --dir {{SKILLS_DIR}} --json skillName,sourceURL,version \
    --jq '["SKILL","REPO","REF"], (.[] | select(.sourceURL != "") | [.skillName, (.sourceURL | sub("https://github.com/"; "")), .version]) | @tsv' \
    | column -t -s $'\t'

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
