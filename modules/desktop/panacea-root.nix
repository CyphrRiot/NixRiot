{ config, lib, pkgs, panaceaSrc, ... }:
let
  binPath = lib.makeBinPath [
    pkgs.coreutils
    pkgs.diffutils
    pkgs.efibootmgr
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.systemd
  ];

  helper = pkgs.runCommand "panacea-root" {
    nativeBuildInputs = [ pkgs.bash pkgs.makeWrapper ];
  } ''
    mkdir -p $out/bin
    install -m755 ${panaceaSrc}/panacea/root/panacea-root $out/bin/panacea-root
    install -m755 ${panaceaSrc}/panacea/scripts/locale.sh $out/bin/locale.sh
    install -m755 ${panaceaSrc}/panacea/scripts/bootos.sh $out/bin/bootos.sh
    patchShebangs $out/bin
    for f in panacea-root locale.sh bootos.sh; do
      wrapProgram $out/bin/$f --prefix PATH : ${binPath}
    done
  '';
in
{
  config = lib.mkIf (config.nixriot.enable && config.nixriot.desktop.enable) {
    environment.systemPackages = [ helper ];

    security.polkit.enablePkexecWrapper = true;

    environment.etc."polkit-1/actions/org.panacea.root.policy".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE policyconfig PUBLIC
       "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
       "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
      <policyconfig>
        <vendor>Panacea</vendor>
        <action id="org.panacea.root">
          <description>Change system settings from Panacea</description>
          <message>Panacea needs administrator rights to change system settings</message>
          <defaults>
            <allow_any>auth_admin</allow_any>
            <allow_inactive>auth_admin</allow_inactive>
            <allow_active>auth_admin_keep</allow_active>
          </defaults>
          <annotate key="org.freedesktop.policykit.exec.path">${helper}/bin/panacea-root</annotate>
        </action>
      </policyconfig>
    '';
  };
}
