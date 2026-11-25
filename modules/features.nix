{ config, lib, pkgs, ... }:
let
  cfg = config.nixriot;
  stateDir = "/var/lib/nixriot";
  stateFile = "${stateDir}/features.json";
  featuresFile = "/etc/nixriot/hosts/installed/features.nix";
  statusFile = "/run/nixriot-features/status.json";

  # Every attribute name in the pinned nixpkgs, so the Installs page can offer a
  # package by name and hand the exact attribute to nixriot.packages. Names only:
  # reading a description means forcing every package, which is a full nixpkgs
  # evaluation on every build. The two patterns dropped are attribute sets, not
  # packages, so they cannot be installed.
  packageIndex = pkgs.writeText "nixriot-packages.txt" (
    (lib.concatStringsSep "\n" (
      lib.filter
        (n: !(lib.hasSuffix "Packages" n) && !(lib.hasSuffix "Extensions" n))
        (lib.attrNames pkgs)
    )) + "\n"
  );

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
    status_write() { printf '%s' "$1" | ${pkgs.jq}/bin/jq -c --argjson t "$(date +%s)" '. + {ts:$t}' > "$status"; chmod 644 "$status"; }

    usage() { echo "usage: nixriot-features apply <feature>-<on|off> | <package>-<add|remove>" >&2; exit 1; }

    [ "$#" -eq 2 ] || usage
    [ "$1" = apply ] || usage
    request="$2"
    feature="''${request%-*}"
    action="''${request##*-}"

    case "$action" in
      on|off)
        case "$feature" in
          office|games|transmission|monero|bitcoin|claude) ;;
          *) echo "unknown feature: $feature" >&2; exit 1 ;;
        esac
        ;;
      add|remove)
        # A package name from the Installs search box. It is not looked up here:
        # the rebuild is what proves the name, and nixriot.packages names the
        # attribute that is wrong.
        case "$feature" in
          '''|*[!A-Za-z0-9._+-]*) echo "invalid package name: $feature" >&2; exit 1 ;;
        esac
        ;;
      *) usage ;;
    esac

    if [ ! -f "$state" ]; then
      echo '{"office":false,"games":false,"transmission":false,"monero":false,"bitcoin":false,"claude":false,"packages":[]}' > "$state"
    fi

    desired="$state.desired"
    case "$action" in
      on)     jq --arg k "$feature" --argjson v true  '.[$k] = $v' "$state" > "$desired" ;;
      off)    jq --arg k "$feature" --argjson v false '.[$k] = $v' "$state" > "$desired" ;;
      add)    jq --arg n "$feature" '.packages = ((.packages // []) + [$n] | unique)' "$state" > "$desired" ;;
      remove) jq --arg n "$feature" '.packages = ((.packages // []) - [$n])' "$state" > "$desired" ;;
    esac

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

    # A stable path for the shell to read. /etc is not replaced by an update, and
    # the file is the same in every generation.
    environment.etc."nixriot-packages.txt" = {
      source = packageIndex;
      mode = "0644";
    };

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
          return polkit.Result.AUTH_ADMIN_KEEP;
        }
      });
    '';
  };
}
