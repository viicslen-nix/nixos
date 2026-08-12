#!/usr/bin/env bash
#
# Vendor upstream skill collections into the personal AI preset.
#
# These skills are committed to this repo rather than pulled through a flake
# input. A non-flake input copies the *whole* upstream repo into the store, and
# some collections carry tens of megabytes of site/ and assets/ around a few
# hundred KB of skills — and there is no sparse fetch for a non-flake input.
# A sparse checkout takes only the subtree we install.
#
# Sources live in tools/skill-sources.tsv. Re-run to pull upstream changes:
#
#   just vendor-skills            # every collection
#   just vendor-skills effective-html
#
# Each vendored directory carries a .vendored-from stamp naming its collection,
# so a skill upstream has deleted or renamed is pruned on the next run rather
# than lingering forever.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
manifest="$root/tools/skill-sources.tsv"
dest="$root/hosts/_shared/presets/personal/ai/skills"
only=${1:-}

[ -f "$manifest" ] || {
  echo "no manifest at $manifest" >&2
  exit 1
}
[ -d "$dest" ] || {
  echo "no skills directory at $dest" >&2
  exit 1
}

sync_collection() {
  local name=$1 repo=$2 sub=$3
  local tmp rev count=0 skill target

  tmp=$(mktemp -d)
  # shellcheck disable=SC2064  # expand $tmp now, not at trap time
  trap "rm -rf '$tmp'" RETURN

  # --filter=blob:none defers blob download, --sparse limits the working tree,
  # so only $sub is ever materialised.
  git clone --quiet --depth 1 --filter=blob:none --sparse "$repo" "$tmp" </dev/null
  git -C "$tmp" sparse-checkout set "$sub" </dev/null
  rev=$(git -C "$tmp" rev-parse --short HEAD)

  if [ ! -d "$tmp/$sub" ]; then
    echo "$name: '$sub' does not exist in $repo" >&2
    return 1
  fi

  # Drop whatever this collection vendored last time before copying, so
  # upstream deletions and renames don't leave orphans behind.
  local stamp
  while IFS= read -r stamp; do
    rm -rf "$(dirname "$stamp")"
  done < <(grep -rlxF "$name" "$dest" --include='.vendored-from' 2>/dev/null || true)

  for skill in "$tmp/$sub"/*/; do
    [ -d "$skill" ] || continue
    target="$dest/$(basename "$skill")"
    cp -r "$skill" "$target"
    chmod -R u+w "$target"
    echo "$name" >"$target/.vendored-from"
    count=$((count + 1))
  done

  if [ "$count" -eq 0 ]; then
    echo "$name: no skill directories under '$sub' in $repo" >&2
    return 1
  fi

  echo "$name: $count skills from $repo @ $rev"
}

matched=0
while IFS=$'\t' read -r name repo sub || [ -n "${name:-}" ]; do
  case "${name:-}" in '' | '#'*) continue ;; esac
  [ -n "$only" ] && [ "$only" != "$name" ] && continue
  matched=1
  sync_collection "$name" "$repo" "$sub"
done <"$manifest"

if [ -n "$only" ] && [ "$matched" -eq 0 ]; then
  echo "no collection named '$only' in $manifest" >&2
  exit 1
fi
