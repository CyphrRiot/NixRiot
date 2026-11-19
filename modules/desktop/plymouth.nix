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
    nixriot.sprite = Sprite(nixriot.image.Scale(Window.GetWidth(), Window.GetHeight()));
    nixriot.sprite.SetPosition(Window.GetX(), Window.GetY(), -1000);
    nixriot.sprite.SetOpacity(1);

    # --- NixRiot: the passphrase prompt ------------------------------------
    # Drawn here rather than with the upstream dialogue, whose box, lock and
    # entry art lands in the middle of the splash. This is one line of text
    # and a row of dots.
    nixriot.label = Sprite();
    nixriot.label.SetPosition(0, 0, 10001);
    nixriot.label.SetOpacity(0);

    nixriot.dot_image = Image("bullet.png");

    fun nixriot_place_label (text)
      {
        nixriot.label_image = Image.Text(text, 1, 1, 1);
        nixriot.label.SetImage(nixriot.label_image);
        nixriot.label.SetX(Window.GetX() + Window.GetWidth() / 2 - nixriot.label_image.GetWidth() / 2);
        nixriot.label.SetY(Window.GetY() + Window.GetHeight() * 0.72);
        nixriot.label.SetOpacity(1);
      }

    fun nixriot_place_dots (bullets)
      {
        local gap = nixriot.dot_image.GetWidth() + 6;
        local start = Window.GetX() + Window.GetWidth() / 2 - (bullets * gap) / 2;
        for (index = 0; index < 8; index++)
          {
            if (!nixriot.dot[index])
              {
                nixriot.dot[index].sprite = Sprite(nixriot.dot_image);
                nixriot.dot[index].sprite.SetZ(10002);
              }
            if (index < bullets)
              {
                nixriot.dot[index].sprite.SetX(start + index * gap);
                nixriot.dot[index].sprite.SetY(Window.GetY() + Window.GetHeight() * 0.78);
                nixriot.dot[index].sprite.SetOpacity(1);
              }
            else
              {
                nixriot.dot[index].sprite.SetOpacity(0);
              }
          }
      }

    fun nixriot_password_callback (prompt, bullets)
      {
        nixriot_place_label(prompt);
        nixriot_place_dots(bullets);
      }

    fun nixriot_prompt_callback (prompt)
      {
        nixriot_place_label(prompt);
      }

    Plymouth.SetDisplayPasswordFunction(nixriot_password_callback);
    Plymouth.SetDisplayPromptFunction(nixriot_prompt_callback);
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

    boot.kernelParams = [ "quiet" ];
    boot.consoleLogLevel = lib.mkForce 3;
  };
}
