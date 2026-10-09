def pad($n): . + ((" " * ($n - length)) // "");

def c($code): if $color and $code != "" then "\u001b[\($code)m\(.)\u001b[0m" else . end;

# Presets in the host's own order, then hosts, users, modules, subflakes, other repo files, upstream.
def srckey($presets):
  .source as $s
  | ($s | split("/")) as $p
  | if .upstream then [6, 0, $s]
    elif $p[0] == "presets" then [0, (($presets | index($p[1])) // 99), $s]
    elif $p[0] == "hosts" then [1, 0, $s]
    elif $p[0] == "users" then [2, 0, $s]
    elif $p[0] == "modules" then [3, 0, $s]
    elif $p[0] == "flakes" then [4, 0, $s]
    else [5, 0, $s]
    end;

def sources: if .sources == [] then "default" else .sources | map(.source) | join(", ") end;

def from_repo: (.sources | any(.upstream | not));

# Packages defined in more than one place (file or scope), at least one of them in the repo.
def duplicates:
  [(.system.packages[] | . + {scope: "system"}),
   (.users | to_entries[] | .key as $u | .value.packages[] | . + {scope: $u})]
  | group_by(.name)
  | map(select(any(.upstream | not) and (map([.scope, .source]) | unique | length) > 1))
  | map({name: .[0].name, defs: (map({scope, source, upstream}) | unique | sort_by(.upstream, .source))});

def deflabel: "\(.source) (\(.scope)\(if .upstream then "; upstream" else "" end))";

def md: tostring | gsub("\\|"; "\\|");

def code: if . == "" then "" else "`\(md)`" end;
