# A worktrees dashboard over `wt list`, opened by tmux `prefix + W`.
# The fzf key bindings call back into this same script's subcommands.

self=$0

usage() {
  echo "usage: wt-dashboard [list [full] | preview <path> | switch <branch> | create <branch> | remove <branch> <session> | close <session> | prune]" >&2
  exit 2
}

# Same tmux session name the `wt tmux` alias and the pre-remove hook derive
# from `{{ repo }}@{{ branch | sanitize }}`; keep the three in step.
jq_rows=$(cat <<'JQ'
def color(c): "[" + c + "m" + . + "[0m";
def width: length + ([scan("[\\x{1F300}-\\x{1FAFF}]")] | length);
def pad(n): if width < n then . + (" " * (n - width)) else . end;
def cut(n): if width > n then .[0:n - 1] + "…" else . end;
def cell(n): cut(n) | pad(n);
def sanitize: gsub("[/\\\\]"; "-");
def age:
  if . == null then ""
  else (now - fromdate)
    | if . < 3600 then "\(. / 60 | floor)m"
      elif . < 86400 then "\(. / 3600 | floor)h"
      elif . < 2592000 then "\(. / 86400 | floor)d"
      else "\(. / 2592000 | floor)mo" end
  end;
def counts(a; b):
  [(if a > 0 then "↑\(a)" else empty end), (if b > 0 then "↓\(b)" else empty end)] | join(" ");
def signed(a; b):
  [(if a > 0 then "+\(a)" else empty end), (if b > 0 then "-\(b)" else empty end)] | join(" ");
# `branch → dir` when the directory is not the sanitized branch (t3code's `t3code-<hash>` worktrees).
def name:
  (.branch // "(detached)") as $branch
  | (.worktree.path | split("/") | last) as $dir
  | if .worktree.main or $dir == ($branch | sanitize) then $branch else "\($branch) → \($dir)" end;

(.items | map(select(.worktree.main)) | first | .worktree.path | split("/") | last) as $repo
# The list gets the whole popup below $narrow columns and ~55% of it beside the preview above.
| (if $cols < $narrow then $cols else $cols * 0.55 | floor end) as $w
| ($w >= 90) as $wide
# Fixed columns take 33 (compact) or 47 (wide) cells. The branch column grows to its longest
# name within what is left (wide mode reserves 20 for the commit), never below 20.
| ([.items[] | name | width] | max // 20) as $longest
| ([$w - (if $wide then 67 else 33 end), 20] | max) as $avail
| ([[$longest, $avail] | min, 20] | max) as $bw
| ($w - $bw - 47) as $sw
| ([" ", ("branch" | pad($bw)), ("status" | pad(6)), ("main" | pad(9)),
    (if $wide then "diff" | pad(11) else empty end),
    ("pr" | pad(6)), " ", ("age" | pad(4)),
    (if $wide then "commit" else empty end)] | join(" ") | color("1;4")) as $header
| (["", "", "", "", $header] | @tsv),
  (.items[]
    | (.branch // "(detached)") as $branch
    | (.worktree.path | split("/") | last) as $dir
    | "\($repo)@\($branch | sanitize)" as $session
    | .worktree.current as $current_wt
    | .display.state as $state
    | (.default_branch // {}) as $main
    | name as $name
    | (if .checks.status == "passed" then "32" elif .checks.status == "failed" then "31"
       elif .checks.status == "running" then "33" else "2" end) as $pr_color
    | [
        $branch,
        .worktree.path,
        $session,
        (.dev_server.url // ""),
        ([
          (if $current_wt then "*" | color("1;32") else " " end),
          ($name | cell($bw) | if $current_wt then color("1") elif $state == "integrated" then color("2") else . end),
          ((.display.symbols // "") | cell(6)),
          (counts($main.ahead // 0; $main.behind // 0) | cell(9) | color("36")),
          (if $wide then signed($main.diff.added // 0; $main.diff.deleted // 0) | cell(11) | color("2") else empty end),
          ((if .pr then "#\(.pr.number)" else "" end) | cell(6) | color($pr_color)),
          (if ($sessions | index($session)) != null
             then (if $session == $current then "●" | color("1;36") else "●" | color("32") end)
             else " " end),
          (.head.committed_at | age | pad(4) | color("2")),
          (if $wide then (.head.subject // "") | cut($sw) else empty end)
        ] | join(" "))
      ] | @tsv)
JQ
)

sessions_json() {
  tmux list-sessions -F '#S' 2>/dev/null | jq -R . | jq -s .
}

current_session() {
  tmux display -p '#S' 2>/dev/null || true
}

# Below this many columns the preview moves under the list; keep in step with --preview-window.
narrow=110

# Not FZF_COLUMNS: it is 0 in the `start` reload, and `tput cols` on a pipe says 80.
# Minus what a row cannot use: the border and its inner padding (4) and the pointer gutter (2).
columns() {
  local cols
  cols=$(stty size </dev/tty 2>/dev/null || true)
  cols=${cols##* }
  echo $(( ${cols:-0} > 6 ? cols - 6 : ${COLUMNS:-80} ))
}

list() {
  local full=()
  [ "${1:-}" = full ] && full=(--full)
  NO_COLOR=1 wt list --format=json --no-progressive "${full[@]}" \
    | jq -r --argjson sessions "$(sessions_json)" --arg current "$(current_session)" \
        --argjson cols "$(columns)" --argjson narrow "$narrow" "$jq_rows"
}

preview() {
  git -C "$1" -c color.status=always status --short --branch | head -n 12
  echo
  git -C "$1" log --color=always --graph --decorate --oneline -n 40
}

# Move this client off <session> first: killing the session the popup runs in
# would take the dashboard — and whatever `wt` it is running — down with it.
leave() {
  [ "$(current_session)" = "$1" ] || return 0
  local other
  other=$(tmux list-sessions -F '#S' | grep -vxF "$1" | head -n 1)
  [ -n "$other" ] && tmux switch-client -t "=$other"
}

pause() {
  printf '%s — press enter ' "$1"
  read -r
}

remove() {
  local branch=$1 session=$2 answer flags
  printf 'Remove %s? [y]es, [k]eep branch, [N]o ' "$branch"
  read -r -n 1 answer
  echo
  case $answer in
    y | Y) flags=(--force --force-delete) ;;
    k | K) flags=(--force --no-delete-branch) ;;
    *) return 0 ;;
  esac
  leave "$session"
  wt remove "${flags[@]}" "$branch" || pause 'remove failed'
}

close() {
  leave "$1"
  tmux kill-session -t "=$1" 2>/dev/null || true
}

# Removes every worktree `wt list` marks integrated, via the `wt prune` alias.
prune() {
  local repo branches branch
  { read -r repo; branches=$(cat); } < <(NO_COLOR=1 wt list --format=json --no-progressive \
    | jq -r '(.items | map(select(.worktree.main)) | first | .worktree.path | split("/") | last),
             (.items[] | select(.display.state == "integrated") | .branch)')
  if [ -z "$branches" ]; then
    pause 'nothing is integrated'
    return 0
  fi
  printf 'Prune integrated worktrees?\n%s\n[y/N] ' "$branches"
  read -r -n 1 answer
  echo
  case $answer in
    y | Y) ;;
    *) return 0 ;;
  esac
  for branch in $branches; do
    branch=${branch//\//-}
    leave "$repo@${branch//\\/-}"
  done
  wt prune || pause 'prune failed'
}

dashboard() {
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    pause 'not inside a git repository'
    exit 1
  fi
  list | fzf --ansi --delimiter '\t' --with-nth 5 --header-lines 1 \
    --layout reverse --no-sort --no-info --prompt '  ' --pointer '▶' \
    --border rounded --border-label ' worktrees ' \
    --header '↵ switch · ^n new (query) · ^x remove · ^p prune · ^k close · ^o url · ^r refresh' \
    --preview "$self preview {2}" --preview-window "right,45%,border-left,<$narrow(down,40%,border-top)" \
    --bind "start:reload-sync($self list full)" \
    --bind "ctrl-r:reload($self list full)" \
    --bind "resize:reload($self list full)" \
    --bind "enter:become($self switch {1})" \
    --bind "ctrl-n:become($self create {q})" \
    --bind "ctrl-x:execute($self remove {1} {3})+reload($self list)" \
    --bind "ctrl-k:execute-silent($self close {3})+reload($self list)" \
    --bind "ctrl-p:execute($self prune)+reload($self list)" \
    --bind "ctrl-o:execute-silent(xdg-open {4})"
}

case "${1:-}" in
  '') dashboard ;;
  list) list "${2:-}" ;;
  preview) preview "$2" ;;
  switch) exec wt tmux "$2" ;;
  create)
    [ -n "${2:-}" ] || { pause 'type the branch name as the query first'; exit 1; }
    exec wt tmux --create "$2"
    ;;
  remove) remove "$2" "$3" ;;
  close) close "$2" ;;
  prune) prune ;;
  *) usage ;;
esac
