include "common";

def styled($style; $dim): if $dim then c("2") else c($style) end;

def pct($p): sort | .[(length - 1) * $p | floor];

# Input: array of {cols, dim}; dim rows are greyed out whole. Rows are indented by 4.
# When the table is wider than $width (0 = unlimited), the leading columns are capped to fit 90% of rows,
# and a row that still doesn't fit stacks: leading columns on one line, the source on the next.
def aligned($styles):
  if length == 0 then empty
  else
    (.[0].cols | length) as $n
    | ([range(0; $n) as $i | map(.cols[$i] | length) | max]) as $full
    | (if $width == 0 or 4 + ($full | add) + 2 * ($n - 1) <= $width
       then $full
       else [range(0; $n - 1) as $i | map(.cols[$i] | length) | pct(0.9)] + [$full[-1]]
       end) as $w
    | (4 + ($w[:-1] | add) + 2 * ($n - 1)) as $srcAt
    | .[]
    | .dim as $dim
    | .cols as $cols
    | if ($width == 0 or $srcAt + ($cols[-1] | length) <= $width)
         and all(range(0; $n - 1); ($cols[.] | length) <= $w[.])
      then
        [$cols | to_entries[]
          | .key as $k
          | (if $k < $n - 1 then .value | pad($w[$k]) else .value end)
          | styled($styles[$k]; $dim)]
        | "    " + join("  ")
      else
        ([$cols[:-1] | to_entries[] | select(.value != "") | $styles[.key] as $style | .value | styled($style; $dim)]
          | "    " + join("  ")),
        ($cols[-1] | split(", ")) as $srcs
        | (if all($srcs[]; $srcAt + length <= $width) then $srcAt else 6 end) as $at
        | $srcs[]
        | ("" | pad($at)) + styled($styles[-1]; $dim)
      end
  end;

def section($title; $rows; $styles):
  if ($rows | length) == 0 then empty
  else "", ("  \($title) (\($rows | length))" | c("1")), ($rows | aligned($styles))
  end;

def enables: sort_by(.option) | map({cols: [.option, sources], dim: (from_repo | not)});

def scope($presets):
  section("Packages"; .packages | sort_by(srckey($presets), .name) | map({cols: [.name, .version, .source], dim: .upstream}); ["", "2", "36"]),
  section("Modules"; .modules | enables; ["", "36"]),
  section("Programs"; .programs | enables; ["", "36"]),
  section("Services"; .services | enables; ["", "36"]),
  section("Containers"; .containers | sort_by(.name) | map({cols: [.name, .image, .source], dim: .upstream}); ["", "2", "36"]),
  section("Units"; .units | sort_by(srckey($presets), .name) | map({cols: [.name, .scope, .source], dim: false}); ["", "2", "36"]);

def dupes:
  section("Duplicates, defined in more than one place"; duplicates | map({cols: [.name, (.defs | map(deflabel) | join(", "))], dim: false}); ["", "36"]);

.presets as $presets
| (.host | c("1;35")) + "  " + ("presets: \($presets | join(" "))" | c("2")),
  if $dupesOnly then dupes
  else
    "",
    ("System" | c("1;4")),
    (.system | scope($presets)),
    (.users | to_entries[] | "", ("User \(.key)" | c("1;4")), (.value | scope($presets))),
    dupes
  end
