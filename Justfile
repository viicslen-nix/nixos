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

# List the local package attrs in flakes/packages (as `just bump` takes them)
packages:
  #!/usr/bin/env bash
  cd flakes/packages
  find by-name -name '*.nix' | while read -r f; do
    d=${f%/*}
    if [[ -f $d/package.nix ]]; then a=${d#by-name/}; else a=${f#by-name/}; a=${a%.nix}; fi
    echo "${a//\//.}"
  done | sort -u

# Compare each GitHub-sourced local package against the latest release upstream
# Read-only: no downloads, no file edits — feed the results to `just bump <attr>`
outdated:
  #!/usr/bin/env bash
  cd flakes/packages
  printf '%-24s %-14s %-14s\n' ATTR CURRENT LATEST
  other=()
  while read -r f; do
    d=${f%/*}
    if [[ -f $d/package.nix ]]; then attr=${d#by-name/}; else attr=${f#by-name/}; attr=${attr%.nix}; fi
    [[ $f == */package.nix || ! -f $d/package.nix ]] || continue
    attr=${attr//\//.}

    owner=$(sed -n 's/.*owner = "\([^"]*\)".*/\1/p' "$f" | head -1)
    repo=$(sed -n 's/.*repo = "\([^"]*\)".*/\1/p' "$f" | head -1)
    if [[ -z $owner || -z $repo ]]; then
      read -r owner repo < <(sed -n 's|.*github\.com/\([^/"]*\)/\([^/"]*\)/releases/download.*|\1 \2|p' "$f" | head -1)
    fi
    if [[ -z $owner || -z $repo ]]; then other+=("$attr"); continue; fi

    current=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$f" | head -1)

    # tag template -> release-tag prefix ("cli-v${version}" -> "cli-v"); ignore pinned revs
    tag=$(sed -n -e 's|.*releases/download/\([^/]*\)/.*|\1|p' -e 's/.*\(rev\|tag\) = "\([^"]*\)".*/\2/p' "$f" | head -1)
    [[ $tag =~ ^[0-9a-f]{40}$ ]] && tag=''
    prefix=${tag%%[0-9$]*}

    # newest tag with that prefix followed by a digit; stable preferred, prerelease as fallback
    latest=$(gh api "repos/$owner/$repo/releases?per_page=50" --jq "
      (\"$prefix\") as \$p
      | [.[] | select(.tag_name | startswith(\$p)) | select(.tag_name[(\$p | length):] | test(\"^[0-9]\"))] as \$c
      | (([\$c[] | select(.prerelease == false)] | .[0]) // \$c[0]).tag_name // \"-\"" 2>/dev/null) || latest='?'
    latest=${latest#"$prefix"}

    # only flag a real forward move (upstream's newest stable can be behind a pinned prerelease)
    mark=''
    if [[ $latest != "$current" && $latest != - && $latest != '?' ]] &&
       [[ $(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -1) == "$latest" ]]; then
      mark='  <- update'
    fi
    printf '%-24s %-14s %-14s%s\n' "$attr" "$current" "$latest" "$mark"
  done < <(find by-name -name '*.nix' ! -path 'by-name/scripts/*' | sort)
  # ponytail: '-' means the repo publishes no matching release (rev-pinned or tagless)
  [[ ${#other[@]} -eq 0 ]] || printf 'not GitHub-sourced: %s\n' "${other[*]}"

# Bump version + hash of a local package in flakes/packages
# Attr = its path under by-name/, e.g. app-images.t3code, superset.cli, coderabbit
# Usage: just bump coderabbit --version 0.4.5   (or --version skip for hash only)
bump ATTR *ARGS:
  cd flakes/packages && nix run nixpkgs#nix-update -- --flake {{ATTR}} {{ARGS}}

# Bump every package `just outdated` reports as behind, to that exact version
# Usage: just bump-outdated [--commit]
bump-outdated *ARGS:
  #!/usr/bin/env bash
  mapfile -t rows < <(just outdated | awk '/<- update/ {print $1, $3}')
  if [[ ${#rows[@]} -eq 0 ]]; then echo 'everything up to date'; exit 0; fi
  printf 'bumping %d package(s)\n' "${#rows[@]}"
  failed=()
  for row in "${rows[@]}"; do
    read -r attr latest <<<"$row"
    echo "==> $attr -> $latest"
    just bump "$attr" --version "$latest" {{ARGS}} || failed+=("$attr")
  done
  [[ ${#failed[@]} -eq 0 ]] || printf 'failed: %s\n' "${failed[*]}"

# Try to bump every local package; prints the ones nix-update can't resolve
bump-all *ARGS:
  #!/usr/bin/env bash
  cd flakes/packages
  # ponytail: attrs derived from by-name/ layout, only files carrying a src hash
  attrs=$(grep -rlE '(hash|sha256|sha512) = "' by-name --include='*.nix' | while read -r f; do
    d=${f%/*}
    if [[ -f $d/package.nix ]]; then a=${d#by-name/}; else a=${f#by-name/}; a=${a%.nix}; fi
    echo "${a//\//.}"
  done | sort -u)
  skipped=()
  for a in $attrs; do
    echo "==> $a"
    nix run nixpkgs#nix-update -- --flake "$a" {{ARGS}} || skipped+=("$a")
  done
  # ponytail: no auto-retry with --version skip; run `just bump <attr> --version <x>` for these
  [[ ${#skipped[@]} -eq 0 ]] || printf 'skipped (no version detected): %s\n' "${skipped[*]}"

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
