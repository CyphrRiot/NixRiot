{ lib, config, pkgs, ... }:
let
  cfg = config.nixriot;
in
{
  imports = [
    ./desktop/panacea.nix
    ./desktop/theme.nix
    ./desktop/sddm.nix
    ./apps/shell.nix
    ./apps/editors.nix
    ./apps/media.nix
    ./apps/office.nix
    ./apps/games.nix
    ./crypto/monero.nix
    ./crypto/bitcoin.nix
    ./crypto/wireguard.nix
    ./security/hardening.nix
    ./security/backup.nix
  ];

  options.nixriot = {
    enable = lib.mkEnableOption "the NixRiot system profile";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixriot";
      description = "Hostname for the installed system.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "user";
      description = "Primary desktop user.";
    };

    desktop.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the Panacea desktop stack.";
    };

    crypto = {
      monero = lib.mkEnableOption "the Monero GUI wallet";
      bitcoin = lib.mkEnableOption "Bitcoin Core and Bitcoin Qt";
    };

    media.transmission = lib.mkEnableOption "the Transmission BitTorrent client";

    games = lib.mkEnableOption "the curated OpenRiot game collection";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "26.05";

    networking.hostName = cfg.hostName;
    time.timeZone = "UTC";
    i18n.defaultLocale = "en_US.UTF-8";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.systemPackages = with pkgs; [
      git
      curl
      wget
      rsync
      unzip
      zip
      xz
    ];
  };
}
