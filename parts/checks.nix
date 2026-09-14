# `nix flake check` builds each host's toplevel, plus the assertions below.
{
  lib,
  self,
  ...
}: let
  # These two currently fail to evaluate; drop them from the list once fixed.
  excluded = ["wsl" "lenovo-legion-go"];

  hostToplevels =
    # Filter on the host name only — never the evaluated config, or excluded hosts evaluate anyway.
    lib.mapAttrs'
    (name: cfg: lib.nameValuePair "host-${name}" cfg.config.system.build.toplevel)
    (lib.filterAttrs (name: _: !(builtins.elem name excluded)) self.nixosConfigurations);

  neoscode = self.nixosConfigurations.dostov-dev.config.home-manager.users.neoscode;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    checks = lib.optionalAttrs (system == "x86_64-linux") (
      hostToplevels
      // {
        # Grep the generated files, not the option values — these are the bytes the two
        # tools actually read, so a change in either serializer is caught too.
        workmux-worktrunk =
          pkgs.runCommand "check-workmux-worktrunk" {
            wm = neoscode.xdg.configFile."workmux/config.yaml".source;
            wt = neoscode.xdg.configFile."worktrunk/config.toml".source;
            tmux = pkgs.writeText "tmux.conf" neoscode.programs.tmux.extraConfig;
          } ''
            set -eu

            fail() { echo "workmux/worktrunk wiring: $1" >&2; exit 1; }

            # Session mode, because `workmux open` outside tmux cannot pick a parent window.
            grep -qxF 'mode: session' "$wm" || fail 'workmux must run in session mode'

            # The triple quote below is nix's escape for an empty YAML string; do not
            # "fix" it. A non-empty prefix renames the target and workmux then stops
            # adopting worktrunk's session and opens a duplicate beside it.
            grep -qxF "window_prefix: '''" "$wm" || fail 'window_prefix must stay empty'

            # Both tools create into one tree beside the repo, never inside it. The two
            # templates differ in syntax, so each is pinned rather than compared.
            grep -qxF 'worktree_dir: ../worktrees/{project}' "$wm" \
              || fail 'workmux must create under ../worktrees/<project>'

            grep -qF 'worktree-path = "../worktrees/{{ repo }}/{{ branch | sanitize }}"' "$wt" \
              || fail 'worktrunk must create under ../worktrees/<repo>'

            # Dropping the key does not disable the hook — it restores upstream's
            # node_modules fast-delete, which runs behind worktrunk's own pre-remove.
            grep -qxF 'pre_remove: []' "$wm" || fail 'pre_remove must stay explicitly empty'

            # By branch, not by the sanitized dir name — only a branch match finds the primary worktree.
            grep -qF 'workmux open "{% raw %}{{ branch }}{% endraw %}"' "$wt" \
              || fail 'the wt tmux alias must hand the branch to workmux open'

            grep -qF 'workmux close' "$wt" || fail 'pre-remove must close the workmux target'

            # Dropping -s is silent: the sidebar still works, it just adds a pane to
            # every window of every session, including ones with no worktree at all.
            grep -qF "workmux sidebar -s'" "$tmux" || fail 'the sidebar key must stay session-scoped'

            touch "$out"
          '';
      }
    );
  };
}
