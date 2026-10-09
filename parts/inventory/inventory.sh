#!/usr/bin/env bash
# What each host installs and enables, and which file put it there. Reads `flake.inventory.<host>`.
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
out_dir="$root/docs/inventory"

usage() {
  cat <<'EOF'
Usage: just inventory [HOST | --all] [--markdown] [--save] [--json]

  HOST        host to inventory (default: this machine)
  --all       every host, one after another; hosts that fail to evaluate are skipped
  --markdown  print markdown instead of the terminal view
  --save      write docs/inventory/<host>.md (with --all, also docs/inventory/README.md)
  --json      print the raw data
EOF
}

host="" all=false format=text save=false
for arg in "$@"; do
  case $arg in
  --all) all=true ;;
  --markdown) format=markdown ;;
  --json) format=json ;;
  --save) save=true ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "error: unknown option $arg" >&2
    usage >&2
    exit 2
    ;;
  *)
    [[ -z $host ]] || {
      echo "error: only one host at a time; use --all for every host" >&2
      exit 2
    }
    host=$arg
    ;;
  esac
done

if $all && [[ -n $host ]]; then
  echo "error: pass a host or --all, not both" >&2
  exit 2
fi
if $save && [[ $format == json ]]; then
  echo "error: --save writes markdown; drop --json" >&2
  exit 2
fi
$save && format=markdown

command -v jq >/dev/null || {
  echo "error: jq not found" >&2
  exit 1
}

info() { [[ -t 2 ]] && echo "$*" >&2 || true; }

# A runaway eval can take the machine down; let the kernel kill it instead.
if systemd-run --user --scope -q -p MemoryMax=8G -p MemorySwapMax=0 true 2>/dev/null; then
  capped() { systemd-run --user --scope -q -p MemoryMax=8G -p MemorySwapMax=0 "$@"; }
else
  capped() { GC_MAXIMUM_HEAP_SIZE=8G "$@"; }
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

hosts_json=$(capped nix eval --json "$root#nixosConfigurations" --apply builtins.attrNames 2>"$tmp/err") || {
  grep -v 'is dirty$' "$tmp/err" >&2
  exit 1
}
mapfile -t known < <(jq -r '.[]' <<<"$hosts_json")

if $all; then
  targets=("${known[@]}")
else
  host=${host:-$(</proc/sys/kernel/hostname)}
  if ! printf '%s\n' "${known[@]}" | grep -qxF -- "$host"; then
    echo "error: no host named '$host'. Hosts: ${known[*]}" >&2
    exit 1
  fi
  targets=("$host")
fi

evaluated=() skipped=()
for h in "${targets[@]}"; do
  info "evaluating $h…"
  if capped nix eval --json "$root#inventory.$h" >"$tmp/$h.json" 2>"$tmp/$h.err"; then
    evaluated+=("$h")
  else
    rm -f "$tmp/$h.json"
    if $all; then
      echo "warning: skipping $h, it failed to evaluate: $(grep -E '^\s*error:' "$tmp/$h.err" | tail -1 | sed 's/^\s*//')" >&2
      skipped+=("$h")
    else
      sed -n '/^error:/,$p' "$tmp/$h.err" >&2
      exit 1
    fi
  fi
done

if ((${#evaluated[@]} == 0)); then
  echo "error: no host evaluated" >&2
  exit 1
fi

color=false
[[ $format == text && -t 1 && -z ${NO_COLOR:-} ]] && color=true

# Only a terminal gets the stacked narrow layout; piped output keeps one line per entry for grep.
width=0
[[ $format == text && -t 1 ]] && width=${COLUMNS:-$(tput cols 2>/dev/null || echo 0)}

render() { jq -L "$here" -r --argjson color "$color" --argjson width "$width" -f "$here/$1.jq" "${@:2}"; }

if $save; then
  mkdir -p "$out_dir"
  for h in "${evaluated[@]}"; do
    render markdown "$tmp/$h.json" >"$out_dir/$h.md"
    echo "${out_dir#"$root"/}/$h.md"
  done
  if $all; then
    skipped_json=$(printf '%s\n' "${skipped[@]}" | jq -R . | jq -sc 'map(select(. != ""))')
    files=()
    for h in "${evaluated[@]}"; do files+=("$tmp/$h.json"); done
    render matrix --slurp --argjson skipped "$skipped_json" "${files[@]}" >"$out_dir/README.md"
    echo "${out_dir#"$root"/}/README.md"
  fi
  exit 0
fi

case $format in
json)
  if $all; then
    for h in "${evaluated[@]}"; do jq -c --arg h "$h" '{($h): .}' "$tmp/$h.json"; done | jq -s 'add'
  else
    jq . "$tmp/${evaluated[0]}.json"
  fi
  ;;
*)
  first=true
  for h in "${evaluated[@]}"; do
    $first || echo
    first=false
    render "$format" "$tmp/$h.json"
  done
  ;;
esac
