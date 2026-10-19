#!/usr/bin/env bash
# Build the allowlisted derivations the given hosts would compile, and push their closures.
# usage: cache.sh <cachix-cache> <host>...
set -euo pipefail

cache=$1
shift
allowlist="$(dirname "$0")/../cache-allowlist"
pattern=$(grep -Ev '^[[:space:]]*(#|$)' "$allowlist" | paste -sd'|')
logs=$(mktemp -d)

for host in "$@"; do
  echo "::group::dry-run $host"
  nix build --dry-run ".#nixosConfigurations.$host.config.system.build.toplevel" 2>&1 | tee "$logs/$host.log"
  echo "::endgroup::"
done

# Only the "will be built" section lists .drv paths; fetched ones are outputs.
mapfile -t drvs < <(
  grep -ohE '/nix/store/[a-z0-9]{32}-[^[:space:]]+\.drv' "$logs"/*.log |
    sort -u |
    grep -E "^/nix/store/[a-z0-9]{32}-($pattern)-[0-9][^/]*\.drv$" || true
)

if ((${#drvs[@]} == 0)); then
  echo "Nothing allowlisted needs building."
  exit 0
fi

printf 'Caching %d derivations:\n' "${#drvs[@]}"
printf '  %s\n' "${drvs[@]}"

status=0
nix build --no-link --keep-going "${drvs[@]/%/^*}" || status=$?

# Push whatever built, even if some derivations failed.
mapfile -t outs < <(nix-store --query --outputs "${drvs[@]}" | while read -r p; do
  if [[ -e $p ]]; then echo "$p"; fi
done)
if ((${#outs[@]} > 0)); then
  cachix push "$cache" "${outs[@]}"
fi

exit "$status"
