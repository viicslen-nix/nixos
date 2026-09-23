{
  lib,
  stdenv,
  writeShellScriptBin,
  python3,
  wrapGAppsHook4,
  gobject-introspection,
  gtk4,
  libshumate,
  gtk4-layer-shell,
  glib-networking,
  cacert,
  curl,
  jq,
  coreutils,
  systemd,
  sudo,
  gawk,
  libnotify,
  getent,
  routeId,
  direction,
  stopId,
  notifyMinutes,
  activeTimeStart,
  activeTimeEnd,
  apiKey,
}: let
  api = "https://www.miamidade.gov/apps/dtpw/transitapps/api/bus";

  env = ''
    export MIAMI_BUS_API="${api}" MIAMI_BUS_KEY="${apiKey}"
    export ROUTE_ID="${routeId}" DIR="${direction}" STOP_ID="${stopId}" NOTIFY_MINUTES="${toString notifyMinutes}"
    PATH=${lib.makeBinPath [curl jq coreutils systemd sudo gawk libnotify getent]}:$PATH
    api() { curl -sSf -H "x-api-key: $MIAMI_BUS_KEY" "$MIAMI_BUS_API/$1"; }
    tracker() { api "tracker?routeID=$ROUTE_ID&directionId=$DIR&stopID=$STOP_ID&track=NO"; }
    stops() { api "routestops?routeID=$ROUTE_ID&directionId=$DIR"; }
  '';
in {
  tracker = writeShellScriptBin "miami-bus-tracker" ''
    set -euo pipefail
    ${env}
    echo "=== Miami-Dade Transit Bus Tracker ==="
    echo "Route: $ROUTE_ID $DIR   Stop: $STOP_ID   $(date)"
    echo
    data=$(tracker)
    [ "''${1:-}" = -v ] && jq . <<<"$data"
    jq -r 'if length == 0 then "No buses predicted" else
      to_entries[] | "\(.key + 1). \(.value.Estimate) min (\(.value.ArrivalTime[11:16]))  bus \(.value.VehicleName)  → \(.value.Headsign)  [\(.value.EstType)]" end' <<<"$data"
  '';

  findStop = writeShellScriptBin "miami-find-stop" ''
    set -euo pipefail
    ${env}
    stops | jq -r '.[] | "StopID: \(.StopID) | \(.StopName) | Seq: \(.Sequence)"' | grep -i -- "''${1:-}"
  '';

  notify = writeShellScriptBin "miami-bus-notify" ''
    set -euo pipefail
    ${env}
    # systemd has no ConditionTime, so the active window is checked here, in local time.
    in_window() {
      [ -n "${activeTimeStart}" ] || return 0
      now=$(date +%H:%M)
      if [[ "${activeTimeEnd}" < "${activeTimeStart}" ]]; then
        [[ ! "$now" < "${activeTimeStart}" ]] || [[ ! "${activeTimeEnd}" < "$now" ]]
      else
        [[ ! "$now" < "${activeTimeStart}" ]] && [[ ! "${activeTimeEnd}" < "$now" ]]
      fi
    }
    in_window || exit 0
    next=$(tracker | jq -c '.[0] // empty')
    [ -n "$next" ] || exit 0
    mins=$(jq -r '.TimeEst / 60 | floor' <<<"$next")
    [ "$mins" -le "$NOTIFY_MINUTES" ] || exit 0
    bus=$(jq -r .VehicleName <<<"$next")
    stop=$(stops | jq -r --argjson s "$STOP_ID" '.[] | select(.StopID == $s) | .StopName' || echo "stop $STOP_ID")

    for uid in $(loginctl list-users --no-legend | awk '{print $1}'); do
      user=$(loginctl show-user "$uid" -p Name --value)
      rt="/run/user/$uid"
      [ -d "$rt" ] || continue
      # Same file the overlay's "Not today" button writes; today's date in it silences the user for the day.
      skip="$(getent passwd "$user" | cut -d: -f6)/.local/state/miami-bus-tracker/skip"
      [ "$(cat "$skip" 2>/dev/null)" = "$(date +%F)" ] && continue
      as_user() { sudo -u "$user" XDG_RUNTIME_DIR="$rt" DBUS_SESSION_BUS_ADDRESS="unix:path=$rt/bus" "$@" || true; }
      as_user systemctl --user start miami-bus-overlay.service
      # notify-send blocks until the notification closes; the timeout guards servers that ignore -t.
      action=$(as_user timeout 60 notify-send -u normal -t 10000 -A skip="Not today" \
        "🚌 Bus $ROUTE_ID $DIR approaching" "Bus $bus arriving in $mins min at $stop")
      if [ "$action" = skip ]; then
        as_user sh -c "mkdir -p '$(dirname "$skip")' && date +%F > '$skip'"
        as_user systemctl --user stop miami-bus-overlay.service
      fi
    done
  '';

  overlay = stdenv.mkDerivation {
    name = "miami-bus-overlay";
    dontUnpack = true;
    nativeBuildInputs = [wrapGAppsHook4 gobject-introspection];
    buildInputs = [gtk4 libshumate gtk4-layer-shell glib-networking];
    installPhase = ''
      install -Dm755 ${./overlay.py} $out/bin/miami-bus-overlay
      sed -i '1c #!${python3.withPackages (ps: [ps.pygobject3])}/bin/python3' $out/bin/miami-bus-overlay
    '';
    # gi loads libwayland-client first, so layer-shell must be preloaded or every window is a normal toplevel.
    preFixup = ''
      gappsWrapperArgs+=(
        --prefix LD_PRELOAD : ${gtk4-layer-shell}/lib/libgtk4-layer-shell.so
        --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
        --set MIAMI_BUS_API "${api}" --set MIAMI_BUS_KEY "${apiKey}"
        --set-default ROUTE_ID "${routeId}" --set-default DIR "${direction}"
        --set-default STOP_ID "${stopId}" --set-default NOTIFY_MINUTES "${toString notifyMinutes}"
      )
    '';
  };
}
