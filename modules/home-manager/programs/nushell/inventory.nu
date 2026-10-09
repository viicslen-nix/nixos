# `just inventory` from the NixOS flake, as a nushell table: one row per entry, so it fits the
# window and stays queryable (`just inventory | where kind == service and not upstream`).
# --dupes gives the packages defined in more than one place. --markdown/--save/--json/--help keep
# the script's own output; `^just inventory` gets the terminal view.

# The justfile `just` would pick: the nearest ancestor holding one.
def inventory-justfile-dir [] {
  mut dir = $env.PWD
  loop {
    if ([Justfile justfile .justfile] | any {|f| $dir | path join $f | path exists }) { return $dir }
    let parent = $dir | path dirname
    if $parent == $dir { return null }
    $dir = $parent
  }
}

def inventory-rows [inv: record] {
  let enables = {|kind|
    each {|e| {
      kind: $kind
      name: $e.option
      detail: ""
      source: (if ($e.sources | is-empty) { "default" } else { $e.sources.source | str join ", " })
      upstream: ($e.sources | all {|s| $s.upstream })
    } } | sort-by name
  }
  [{scope: system, data: $inv.system}] ++ ($inv.users | transpose scope data)
  | each {|s|
    let d = $s.data
    [
      ($d.packages | each {|p| {kind: package, name: $p.name, detail: $p.version, source: $p.source, upstream: $p.upstream} } | sort-by upstream source name)
      ($d.modules | do $enables module)
      ($d.programs | do $enables program)
      ($d.services | do $enables service)
      ($d.containers | each {|c| {kind: container, name: $c.name, detail: $c.image, source: $c.source, upstream: $c.upstream} } | sort-by name)
      ($d.units | each {|u| {kind: unit, name: $u.name, detail: $u.scope, source: $u.source, upstream: $u.upstream} } | sort-by source name)
    ]
    | flatten
    | each {|row| {scope: $s.scope} | merge $row }
  }
  | flatten
}

# Packages defined in more than one place (file or scope), at least one of them in the repo.
def inventory-dupes [inv: record] {
  let rows = [{scope: system, data: $inv.system}] ++ ($inv.users | transpose scope data)
    | each {|s| $s.data.packages | each {|p| {name: $p.name, scope: $s.scope, source: $p.source, upstream: $p.upstream} } }
    | flatten | uniq
  let names = $rows | group-by name | items {|name, defs|
    if ($defs | any {|d| not $d.upstream }) and ($defs | length) > 1 { $name }
  } | compact
  $rows | where name in $names | sort-by name upstream source
}

def --wrapped "just inventory" [...rest] {
  let root = inventory-justfile-dir
  let ours = $root != null and ($root | path join parts inventory inventory.sh | path exists)
  let raw = $rest | any {|a| $a in [--markdown --save --json -h --help] }
  if not $ours or $raw { return (^just inventory ...$rest) }

  let dupes = "--dupes" in $rest
  let rows = if $dupes { {|inv| inventory-dupes $inv } } else { {|inv| inventory-rows $inv } }
  let data = ^just inventory --json ...($rest | where $it != "--dupes") | from json
  if "--all" in $rest {
    $data | transpose host inv | each {|h| do $rows $h.inv | each {|row| {host: $h.host} | merge $row } } | flatten
  } else {
    do $rows $data
  }
}
