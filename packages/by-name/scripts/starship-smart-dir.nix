{
  writeShellApplication,
  git,
  ...
}:
writeShellApplication {
  name = "starship-smart-dir";
  runtimeInputs = [git];

  # Mirrors the directory settings in starship's config.toml:
  #   truncation_length = 3
  #   fish_style_pwd_dir_length = 1
  #   substitutions: Development -> dev
  #
  # Smart git-aware behaviour:
  #   - At the root of a normal repo        → show the repo directory name
  #   - At the root of a linked worktree    → show the *bare repo* directory name
  #   - At the root of a bare repo itself   → show the bare repo directory name
  #   - Everywhere else                     → fish-style truncated path
  text = ''
    TRUNCATION_LENGTH=3
    FISH_LEN=1

    # ── Path helpers ──────────────────────────────────────────────────────────

    # Apply non-home substitutions (keep in sync with config.toml [directory.substitutions])
    apply_subs() {
      local p="$1"
      p="''${p//Development/dev}"
      printf '%s' "$p"
    }

    fish_path() {
      [[ "$PWD" == "/" ]] && { printf '/'; return; }

      local prefix parts_str
      if [[ "$PWD" == "$HOME" ]]; then
        printf '~'
        return
      elif [[ "$PWD" == "$HOME/"* ]]; then
        prefix="~"
        parts_str=$(apply_subs "''${PWD#"$HOME/"}")
      else
        prefix=""
        parts_str=$(apply_subs "''${PWD#/}")
      fi

      IFS='/' read -ra parts <<< "$parts_str"
      local n=''${#parts[@]}
      local result="$prefix"

      for ((i = 0; i < n; i++)); do
        local part="''${parts[$i]}"
        [[ -z "$part" ]] && continue
        if (( n - i > TRUNCATION_LENGTH )); then
          result+="/''${part:0:$FISH_LEN}"
        else
          result+="/''${part}"
        fi
      done

      printf '%s' "$result"
    }

    # ── Git detection ─────────────────────────────────────────────────────────

    git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null) || { fish_path; exit 0; }
    is_bare=$(git rev-parse --is-bare-repository 2>/dev/null)
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || true

    # Case 1: We are sitting directly inside a bare repo (no working tree).
    #         git-dir == PWD because the bare repo IS its own git directory.
    if [[ "$is_bare" == "true" && "$git_dir" == "$PWD" ]]; then
      basename "$PWD"
      exit 0
    fi

    # Case 2: We are at the root of a working tree (normal clone or linked worktree).
    if [[ -n "$toplevel" && "$toplevel" == "$PWD" ]]; then
      # Resolve the "common" git directory (the main .git / bare repo).
      # For linked worktrees git writes a `commondir` file inside the
      # per-worktree git dir that points (relatively) back to the main dir.
      common=""
      if [[ -f "$git_dir/commondir" ]]; then
        common_rel=$(<"$git_dir/commondir")
        if [[ "$common_rel" == /* ]]; then
          common="$common_rel"
        else
          common="$(cd "$git_dir" && cd "$common_rel" && pwd)"
        fi
      else
        common="$git_dir"
      fi

      # Strip trailing "/.git" to obtain the checkout root (normal repos).
      # Bare repos don't have this suffix — the common dir IS the repo root.
      if [[ "$common" == */.git ]]; then
        repo_root="''${common%/.git}"
      else
        repo_root="$common"
      fi

      basename "$repo_root"
      exit 0
    fi

    # Fallback: fish-style truncated path
    fish_path
  '';
}
