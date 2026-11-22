{ config, lib, pkgs, ... }:
let
  cfg = config.nixriot;

  upstreamTheme = "${pkgs.plymouth}/share/plymouth/themes/script";

  # Standalone theme, like ArchRiot's. It draws its own splash and passphrase
  # dialog instead of borrowing Plymouth's stock script, whose hidden dialog
  # left the prompt invisible until Escape. The images still come from
  # Plymouth's script theme.
  themeScript = ''
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

    lock.image = Image("lock.png");
    entry.image = Image("entry.png");
    bullet.image = Image("bullet.png");

    entry_scale = 1.5;
    scaled_entry = entry.image.Scale(entry.image.GetWidth() * entry_scale, entry.image.GetHeight());
    entry.sprite = Sprite(scaled_entry);
    entry.x = Window.GetX() + Window.GetWidth() / 2 - (entry.image.GetWidth() * entry_scale) / 2;
    entry.y = Window.GetY() + Window.GetHeight() * 0.72;
    entry.sprite.SetPosition(entry.x, entry.y, 10001);
    entry.sprite.SetOpacity(0);

    lock_height = entry.image.GetHeight() * 0.8;
    lock_scale = lock_height / lock.image.GetHeight();
    lock_width = lock.image.GetWidth() * lock_scale;
    scaled_lock = lock.image.Scale(lock_width, lock_height);
    lock.sprite = Sprite(scaled_lock);
    lock.x = entry.x - lock_width - 15;
    lock.y = entry.y + entry.image.GetHeight() / 2 - lock_height / 2;
    lock.sprite.SetPosition(lock.x, lock.y, 10001);
    lock.sprite.SetOpacity(0);

    bullet.sprites = [];

    nixriot.label = Sprite();
    nixriot.label.SetPosition(0, 0, 10003);
    nixriot.label.SetOpacity(0);

    fun nixriot_place_label (text)
      {
        nixriot.label_image = Image.Text(text, 1, 1, 1);
        nixriot.label.SetImage(nixriot.label_image);
        nixriot.label.SetX(Window.GetX() + Window.GetWidth() / 2 - nixriot.label_image.GetWidth() / 2);
        nixriot.label.SetY(entry.y - 40);
        nixriot.label.SetOpacity(1);
      }

    fun nixriot_show_prompt (prompt, bullets)
      {
        lock.sprite.SetOpacity(1);
        entry.sprite.SetOpacity(1);
        nixriot_place_label(prompt);
        for (index = 0; bullet.sprites[index]; index++)
          bullet.sprites[index].SetOpacity(0);
        for (index = 0; index < bullets; index++)
          {
            if (!bullet.sprites[index])
              {
                scaled_bullet = bullet.image.Scale(7, 7);
                bullet.sprites[index] = Sprite(scaled_bullet);
                bullet.x = entry.x + 30 + index * (7 + 6);
                bullet.y = entry.y + entry.image.GetHeight() / 2 - 3.5;
                bullet.sprites[index].SetPosition(bullet.x, bullet.y, 10002);
              }
            bullet.sprites[index].SetOpacity(1);
          }
      }

    fun nixriot_hide_prompt ()
      {
        lock.sprite.SetOpacity(0);
        entry.sprite.SetOpacity(0);
        nixriot.label.SetOpacity(0);
        for (index = 0; bullet.sprites[index]; index++)
          bullet.sprites[index].SetOpacity(0);
      }

    fun nixriot_normal_callback ()
      {
        nixriot_hide_prompt();
      }

    fun nixriot_password_callback (prompt, bullets)
      {
        nixriot_show_prompt(prompt, bullets);
      }

    fun nixriot_refresh_callback ()
      {
        nixriot_fit_splash();
      }

    Plymouth.SetDisplayNormalFunction(nixriot_normal_callback);
    Plymouth.SetDisplayPasswordFunction(nixriot_password_callback);
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
