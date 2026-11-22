{ config, lib, pkgs, ... }:
let
  cfg = config.nixriot;

  upstreamTheme = "${pkgs.plymouth}/share/plymouth/themes/script";
  upstreamScript = builtins.readFile "${upstreamTheme}/script.script";

  themeScript = upstreamScript + ''

    # --- NixRiot: full-screen splash ---------------------------------------
    Window.SetBackgroundTopColor(0, 0, 0);
    Window.SetBackgroundBottomColor(0, 0, 0);

    nixriot.image = Image("nixriot-splash.png");
    nixriot.sprite = Sprite();
    nixriot.sprite.SetPosition(Window.GetX(), Window.GetY(), -1000);
    nixriot.sprite.SetOpacity(1);
    nixriot.fit_width = -1;
    nixriot.fit_height = -1;

    fun nixriot_fit_splash ()
      {
        local w = Window.GetWidth();
        local h = Window.GetHeight();
        if (w <= 0 || h <= 0)
          return;
        if (w == nixriot.fit_width && h == nixriot.fit_height)
          return;
        nixriot.sprite.SetImage(nixriot.image.Scale(w, h));
        nixriot.sprite.SetX(Window.GetX());
        nixriot.sprite.SetY(Window.GetY());
        nixriot.fit_width = w;
        nixriot.fit_height = h;
      }

    fun nixriot_refresh_callback ()
      {
        refresh_callback();
        nixriot_fit_splash();
      }

    Plymouth.SetRefreshFunction(nixriot_refresh_callback);
  '';

  nixriotTheme = pkgs.runCommand "plymouth-theme-nixriot" { } ''
    dir="$out/share/plymouth/themes/nixriot"
    mkdir -p "$dir"
    cp ${upstreamTheme}/*.png "$dir/"
    cp ${./plymouth/nixriot-splash.png} "$dir/nixriot-splash.png"

    cat > "$dir/nixriot.script" <<'NIXRIOT_SCRIPT'
    ${themeScript}
    NIXRIOT_SCRIPT

    cat > "$dir/nixriot.plymouth" <<EOF
    [Plymouth Theme]
    Name=NixRiot
    Description=NixRiot boot splash
    ModuleName=script

    [script]
    ImageDir=$dir
    ScriptFile=$dir/nixriot.script
    ConsoleLogBackgroundColor=0x00000000
    EOF
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.desktop.enable && cfg.plymouth) {
    boot.plymouth = {
      enable = true;
      theme = "nixriot";
      themePackages = [ nixriotTheme ];
      logo = cfg.plymouthLogo;
    };

    boot.initrd.systemd.paths.systemd-ask-password-plymouth.wantedBy = [
      "sysinit.target"
      "cryptsetup.target"
    ];
    boot.initrd.systemd.services.systemd-ask-password-plymouth.wantedBy = [
      "cryptsetup.target"
    ];
    boot.initrd.systemd.services.plymouth-start.before = [ "cryptsetup.target" ];

    boot.kernelParams = [ "quiet" ];
    boot.consoleLogLevel = lib.mkForce 3;
  };
}
