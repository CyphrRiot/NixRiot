{ config, lib, pkgs, ... }:
let
  cfg = config.nixriot.update;

  statusDir = "/var/lib/nixriot";

  nixriot-update = pkgs.writeScriptBin "nixriot-update" ''
    #!${pkgs.runtimeShell}
    set -euo pipefail
    export PATH=${pkgs.lib.makeBinPath [
      pkgs.curl
      pkgs.git
      pkgs.jq
      pkgs.nix
      pkgs.coreutils
    ]}:$PATH

    dir="${statusDir}"
    status="$dir/status.json"
    notes="$dir/release-notes.txt"
    repo="''${NIXRIOT_REPO:-${cfg.remoteRepo}}"
    api="https://api.github.com/repos/$repo/commits/main"

    installed_rev() {
      sed 's/-dirty$//' /etc/nixriot-revision 2>/dev/null || echo unknown
    }

    case "''${1:-check}" in
      check)
        mkdir -p "$dir"
        now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        body=$(curl -fsS --max-time 10 "$api" 2>/dev/null) || exit 0
        remote=$(printf '%s' "$body" | jq -r .sha 2>/dev/null) || exit 0
        [ -n "$remote" ] && [ "$remote" != "null" ] || exit 0
        subject=$(printf '%s' "$body" | jq -r '.commit.message' 2>/dev/null | head -n1)
        cur=$(installed_rev)
        if [ "$cur" = "$remote" ]; then avail=false; else avail=true; fi
        jq -n --arg i "$cur" --arg a "$remote" --arg s "$subject" --argjson u "$avail" --arg t "$now" \
          '{installed:$i,available:$a,subject:$s,updateAvailable:$u,lastChecked:$t}' > "$status.tmp"
        mv "$status.tmp" "$status"
        chmod 644 "$status"
        ;;

      apply)
        old=$(installed_rev)
        cd /etc/nixriot
        git pull --rebase --autostash >/dev/null 2>&1 || true
        nix flake update
        nixos-rebuild switch --flake /etc/nixriot#installed
        if [ -n "$old" ] && [ "$old" != unknown ] && git rev-parse --verify --quiet "$old" >/dev/null 2>&1; then
          git log --pretty=format:'%s' "$old..HEAD" > "$notes" 2>/dev/null || true
          chmod 644 "$notes" 2>/dev/null || true
        fi
        ;;

      *)
        echo "usage: nixriot-update [check|apply]" >&2
        exit 1
        ;;
    esac
  '';
in
{
  options.nixriot.update = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the NixRiot update check and apply service.";
    };

    remoteRepo = lib.mkOption {
      type = lib.types.str;
      default = "CyphrRiot/NixRiot";
      description = "GitHub repository to compare the installed revision against.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "4h";
      description = "How often to check for an update.";
    };
  };

  config = lib.mkIf (config.nixriot.enable && cfg.enable) {
    environment.systemPackages = [ nixriot-update ];

    systemd.tmpfiles.rules = [
      "d ${statusDir} 0755 root root -"
    ];

    systemd.services.nixriot-update-check = {
      description = "Check for a NixRiot update";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${nixriot-update}/bin/nixriot-update check";
      };
    };

    systemd.timers.nixriot-update-check = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = cfg.interval;
        RandomizedDelaySec = "10min";
        Persistent = false;
      };
    };

    systemd.services.nixriot-update = {
      description = "Apply a NixRiot update";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${nixriot-update}/bin/nixriot-update apply";
      };
    };

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "nixriot-update.service" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
