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
        # Grep the generated files, not the option values — a serializer change must fail this too.
        worktrunk-tmux =
          pkgs.runCommand "check-worktrunk-tmux" {
            wt = neoscode.xdg.configFile."worktrunk/config.toml".source;
            tmux = pkgs.writeText "tmux.conf" neoscode.programs.tmux.extraConfig;
            dashboard = ../modules/home-manager/programs/worktrunk/dashboard.sh;
            workmux = neoscode.xdg.configFile."workmux/config.yaml".source or "";
          } ''
            set -eu

            fail() { echo "worktrunk tmux wiring: $1" >&2; exit 1; }

            grep -qF 'worktree-path = "../.worktrees/{{ repo }}/{{ branch | sanitize }}"' "$wt" \
              || fail 'worktrunk must create under ../.worktrees/<repo>'

            # The alias creates the session and pre-remove kills it; the dashboard derives the same name in jq.
            session='{{ repo }}@{{ branch | sanitize }}'
            [ "$(grep -cF "$session" "$wt")" -ge 2 ] || fail 'the tmux alias and pre-remove must share the session template'
            grep -qF '"\($repo)@\($branch | sanitize)"' "$dashboard" || fail 'dashboard.sh must derive the same session name'

            # A popup, not a window: the dashboard switches the client and exits.
            grep -qF 'bind-key W display-popup -E' "$tmux" || fail 'prefix+W must open the dashboard as a popup'
            grep -qF 'wt-dashboard' "$tmux" || fail 'prefix+W must open wt-dashboard'

            [ -z "$workmux" ] || fail 'workmux must stay disabled'
            ! grep -qF 'workmux' "$tmux" || fail 'no workmux key may remain bound'

            touch "$out"
          '';
      }
    );
  };
}
