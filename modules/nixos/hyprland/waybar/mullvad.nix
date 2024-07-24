{pkgs}:
pkgs.writeShellScript "mullvad-status" ''
  set -e

  # https://blog.dhampir.no/content/sleeping-without-a-subprocess-in-bash-and-how-to-sleep-forever
  snore() {
      local IFS
      [[ -n "''${_snore_fd:-}" ]] || exec {_snore_fd}<> <(:)
      read -r ''${1:+-t "$1"} -u $_snore_fd || :
  }

  DELAY=0.2

  while snore $DELAY; do
      MV_OUTPUT=$(${pkgs.mullvad}/bin/mullvad status)

      if [[ $MV_OUTPUT =~ "Connected" ]]; then
        echo " ";
      else
        echo " "
      fi
  done

  exit 0
''
