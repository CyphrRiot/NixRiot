{ nixriotApps ? true, ... }:
{
  programs.helix = {
    enable = nixriotApps;
    defaultEditor = nixriotApps;
    settings = {
      theme = "tokyonight";
      editor = {
        scrolloff = 8;
        scroll-lines = 3;
        line-number = "relative";
        cursorline = true;
        mouse = true;
        clipboard-provider = "wayland";
        auto-completion = true;
        auto-format = true;
        auto-save = false;
        idle-timeout = 400;
        soft-wrap.enable = true;
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
        statusline = {
          left = [ "mode" "spinner" "file-name" "diagnostics" ];
          center = [ "version-control" ];
          right = [ "selections" "position" "file-encoding" "file-line-ending" "file-type" ];
          separator = " │ ";
        };
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
          auto-signature-help = true;
          snippets = true;
        };
      };
      keys.normal = {
        D = [ "ensure_selections_forward" "extend_to_line_end" "delete_selection" ];
        G = "goto_last_line";
      };
    };
  };
}
