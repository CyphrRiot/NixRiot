{ config, lib, pkgs, ... }:
let
  cfg = config.nixriot;
  stateDir = "/var/lib/nixriot";
  stateFile = "${stateDir}/features.json";
  featuresFile = "/etc/nixriot/hosts/installed/features.nix";
  statusFile = "/run/nixriot-features/status.json";

  nixriot-features = pkgs.writeShellScriptBin "nixriot-features" ''
    #!${pkgs.runtimeShell}
    set -euo pipefail
    export PATH=${lib.makeBinPath [
      pkgs.coreutils
      pkgs.git
      pkgs.jq
      pkgs.nix
      pkgs.nixos-rebuild
    ]}:$PATH

    state="${stateFile}"
    features="${featuresFile}"
    status="${statusFile}"
    mkdir -p "$(dirname "$status")"
    status_write() { printf '%s\n' "$1" > "$status"; chmod 644 "$status"; }

    usage() { echo "usage: nixriot-features apply <feature>-<on|off>" >&2; exit 1; }

    [ "$#" -eq 2 ] || usage
    [ "$1" = apply ] || usage
    request="$2"
    feature="''${request%-*}"
    action="''${request##*-}"

    case "$feature" in
      office|games|transmission|monero|bitcoin|glyphriot) ;;
      *) echo "unknown feature: $feature" >&2; exit 1 ;;
    esac
    case "$action" in on|off) ;; *) usage ;; esac

    if [ ! -f "$state" ]; then
      echo '{"office":false,"games":false,"transmission":false,"monero":false,"bitcoin":false,"glyphriot":false}' > "$state"
    fi

    desired="$state.desired"
    if [ "$action" = on ]; then value=true; else value=false; fi
    jq --arg k "$feature" --argjson v "$value" '.[$k] = $v' "$state" > "$desired"

    status_write "{\"busy\":true,\"feature\":\"$feature\",\"action\":\"$action\",\"step\":\"write\"}"

    {
      echo '{'
      jq -r 'to_entries[] | "  \(.key) = \(.value);"' "$desired"
      echo '}'
    } > "$features"
    chown root:root "$features"
    chmod 644 "$features"

    status_write "{\"busy\":true,\"feature\":\"$feature\",\"action\":\"$action\",\"step\":\"build\"}"
    if ! nixos-rebuild switch --flake /etc/nixriot#installed; then
      {
        echo '{'
        jq -r 'to_entries[] | "  \(.key) = \(.value);"' "$state"
        echo '}'
      } > "$features"
      chown root:root "$features"
      chmod 644 "$features"
      rm -f "$desired"
      status_write "{\"busy\":false,\"feature\":\"$feature\",\"action\":\"$action\",\"step\":\"failed\"}"
      exit 1
    fi
    mv "$desired" "$state"
    status_write "{\"busy\":false,\"feature\":\"$feature\",\"action\":\"$action\",\"step\":\"done\"}"
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.desktop.enable) {
    environment.systemPackages = [ nixriot-features ];

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 root root -"
      "d /run/nixriot-features 0755 root root -"
    ];

    systemd.services."nixriot-features@" = {
      description = "Install or remove optional NixRiot features";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${nixriot-features}/bin/nixriot-features apply %i";
      };
    };

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        var unit = action.lookup("unit") || "";
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            unit.indexOf("nixriot-features@") == 0 &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
