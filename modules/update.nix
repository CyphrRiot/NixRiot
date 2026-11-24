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
      pkgs.openssh
      pkgs.coreutils
      pkgs.gawk
      pkgs.rsync
      pkgs.nixos-rebuild
    ]}:$PATH

    dir="${statusDir}"
    status="$dir/status.json"
    notes="$dir/release-notes.txt"
    repo="''${NIXRIOT_REPO:-${cfg.remoteRepo}}"
    raw="https://raw.githubusercontent.com/$repo/main"

    installed_rev() {
      sed 's/-dirty$//' /etc/nixriot-revision 2>/dev/null || echo unknown
    }

    case "''${1:-check}" in
      check)
        mkdir -p "$dir"
        now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        cur=$(tr -d ' \n' < /etc/nixriot/VERSION 2>/dev/null) || exit 0
        [ -n "$cur" ] || exit 0
        remote=$(curl -fsS --max-time 10 "$raw/VERSION" 2>/dev/null | tr -d ' \n') || exit 0
        [ -n "$remote" ] || exit 0
        if [ "$cur" = "$remote" ]; then avail=false; else avail=true; fi
        subject=$(curl -fsS --max-time 10 "$raw/CHANGELOG.md" 2>/dev/null \
          | awk -v h="## $remote" '$0 == h { found = 1; next } found && /^- / { sub(/^- /, ""); gsub(/\*\*/, ""); print; exit }')
        jq -n --arg i "$cur" --arg a "$remote" --arg s "$subject" --argjson u "$avail" --arg t "$now" \
          '{installed:$i,available:$a,subject:$s,updateAvailable:$u,lastChecked:$t}' > "$status.tmp"
        mv "$status.tmp" "$status"
        chmod 644 "$status"
        ;;

      apply)
        # A switch that was interrupted leaves its transient unit behind, and a
        # retry then fails to start one under the same name.
        systemctl stop nixos-rebuild-switch-to-configuration.service >/dev/null 2>&1 || true

        old=$(installed_rev)
        oldver=$(tr -d ' \n' < /etc/nixriot/VERSION 2>/dev/null) || oldver=unknown

        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        # $repo is the bare owner/name form, which the rest of this script needs
        # for raw.githubusercontent.com. git has no such shorthand, so the clone
        # gets the HTTPS URL built from it.
        git clone --quiet "https://github.com/$repo" "$tmp"

        # Keep the working tree the running system was built from. A failed
        # update restores this instead of leaving /etc/nixriot half replaced.
        previous="$dir/previous"
        rm -rf "$previous"
        mkdir -p "$previous"
        cp -a /etc/nixriot/. "$previous/"

        ver=$(tr -d ' \n' < "$tmp/VERSION")
        if [ "''${NIXRIOT_VERIFY:-1}" != 0 ]; then
          if [ ! -s "$previous/allowed_signers" ]; then
            echo "The running tree has no allowed_signers, so v$ver cannot be verified." >&2
            echo "To install it anyway: sudo env NIXRIOT_VERIFY=0 nixriot-update apply" >&2
            exit 1
          fi
          if ! git -C "$tmp" -c gpg.ssh.allowedSignersFile="$previous/allowed_signers" verify-tag "v$ver"; then
            echo "v$ver is not signed by a trusted key. Nothing was installed." >&2
            exit 1
          fi
        else
          echo "NIXRIOT_VERIFY=0: installing v$ver without checking its signature." >&2
        fi
        git -C "$tmp" checkout -q "$(git -C "$tmp" rev-parse "v$ver^{commit}")"
        rev="$(git -C "$tmp" rev-parse HEAD)"

        rsync -a --delete --exclude .git \
          --exclude hosts/installed/local.nix \
          --exclude hosts/installed/features.nix \
          --exclude hosts/installed/hardware-configuration.nix \
          "$tmp/" /etc/nixriot/
        chmod 755 /etc/nixriot

        local_nix="/etc/nixriot/hosts/installed/local.nix"
        if ! grep -q 'nixriotUser' "$local_nix" 2>/dev/null \
                || grep -q 'CHANGEME' "$local_nix" 2>/dev/null; then
          echo "local.nix is missing a real user; restoring the previous tree." >&2
          rsync -a --delete "$previous/" /etc/nixriot/
          chmod 755 /etc/nixriot
          exit 1
        fi

        # Evaluate and build before activating. A broken tree fails here, on
        # the running system, not after the display manager changes.
        if ! ( cd "$tmp" && nixos-rebuild build --flake /etc/nixriot#installed ); then
          echo "The new tree does not build; restoring the previous tree." >&2
          rsync -a --delete "$previous/" /etc/nixriot/
          chmod 755 /etc/nixriot
          exit 1
        fi

        # Apply live. The display manager is configured not to restart on a
        # switch, so the session survives. Kernel and initrd changes load on
        # the next normal reboot.
        if ! nixos-rebuild switch --flake /etc/nixriot#installed; then
          echo "The switch failed. The previous generation is still bootable:" >&2
          echo "  sudo nixos-rebuild switch --rollback" >&2
          echo "  previous tree: $previous" >&2
          exit 1
        fi

        printf '%s\n' "$rev" > /etc/nixriot-revision

        if [ -r /etc/nixriot/CHANGELOG.md ] && [ -n "$oldver" ] && [ "$oldver" != unknown ]; then
          awk -v stop="## $oldver" '
            /^## How to write these/ { exit }
            /^## / { if ($0 == stop) exit; started = 1; next }
            !started { next }
            /^$/ { next }
            /^>/ { next }
            /^###/ { next }
            { sub(/^- /, ""); gsub(/\*\*/, ""); print }
          ' /etc/nixriot/CHANGELOG.md > "$notes" 2>/dev/null || true
        elif [ -n "$old" ] && [ "$old" != unknown ] && git -C "$tmp" rev-parse --verify --quiet "$old" >/dev/null 2>&1; then
          git -C "$tmp" log --pretty=format:'%s' "$old..HEAD" > "$notes" 2>/dev/null || true
        fi
        chmod 644 "$notes" 2>/dev/null || true
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
      description = "GitHub repository to compare the installed version against.";
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
      # The unit changes whenever this script does, which would otherwise have
      # the switch restart the running updater.
      restartIfChanged = false;
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
      # This service runs the switch, and the switch replaces this unit because
      # the script path in ExecStart changes with every update script change.
      # Without this the switch stops the updater that is running it, the unit
      # is marked failed, and the pill says the installer failed.
      restartIfChanged = false;
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
