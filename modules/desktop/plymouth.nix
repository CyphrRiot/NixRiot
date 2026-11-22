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

    # The script runs before the display mode is necessarily known, so scaling
    # once here can produce a 0x0 image and abort the rest of the script.
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

    fun nixriot_hide_prompt ()
      {
        nixriot.label.SetOpacity(0);
        if (!nixriot.dot)
          return;
        for (index = 0; nixriot.dot[index]; index++)
          nixriot.dot[index].sprite.SetOpacity(0);
      }

    # Delegate to the upstream callbacks so Plymouth's own state and sprite
    # bookkeeping stay intact, then draw the prompt text over the stock
    # dialogue. Do not hide the dialogue: if the text drawing fails, the
    # passphrase entry must still be visible.
    fun nixriot_password_callback (prompt, bullets)
      {
        display_password_callback(prompt, bullets);
        nixriot_place_label(prompt);
      }

    fun nixriot_prompt_callback (prompt)
      {
        display_password_callback(prompt, 0);
        nixriot_place_label(prompt);
      }

    fun nixriot_normal_callback ()
      {
        display_normal_callback();
        nixriot_hide_prompt();
      }

    fun nixriot_refresh_callback ()
      {
        refresh_callback();
        nixriot_fit_splash();
      }

    Plymouth.SetDisplayNormalFunction(nixriot_normal_callback);
    Plymouth.SetDisplayPasswordFunction(nixriot_password_callback);
    Plymouth.SetDisplayPromptFunction(nixriot_prompt_callback);
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

    boot.kernelParams = [ "quiet" ];
    boot.consoleLogLevel = lib.mkForce 3;
  };
}
