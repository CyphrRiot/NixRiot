{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.nixriot.enable {
    networking.firewall.enable = true;

    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = false;
    services.openssh.settings.PermitRootLogin = "no";

    networking.networkmanager.wifi.macAddress = "random";
    networking.networkmanager.ethernet.macAddress = "random";

    boot.kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.tcp_syncookies" = 1;
    };
  };
}
