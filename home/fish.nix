{ pkgs, lib, panaceaSrc, ... }:
{
  home.packages = with pkgs; [
    fish
    starship
    zoxide
    ripgrep
    fd
    fzf
    btop
    fastfetch
    lsd
    bat
  ];

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    PAGER = "less";
  };

  xdg.configFile."fish/config.fish".source = pkgs.writeText "nixriot-fish-config.fish" ''
    # =============================================================================
    # NixRiot Fish Shell Configuration
    # Adapted from OpenRiot for NixOS
    # =============================================================================

    # Disable core dumps
    ulimit -c 0

    # =============================================================================
    # History Configuration (many concurrent terminals)
    # =============================================================================
    # Prevent corruption with many concurrent terminals
    set -U fish_history_limit 10000
    set -U fish_history_size 10000

    # Strip null bytes that corrupt the history parser (crashes, bad pipes)
    set -l __fish_hist_file $HOME/.local/share/fish/fish_history
    if test -s $__fish_hist_file
        tr -d '\000' <$__fish_hist_file >$__fish_hist_file.tmp
        mv $__fish_hist_file.tmp $__fish_hist_file
    end

    # Set UTF-8 locale
    set -gx LANG en_US.UTF-8
    set -gx LC_ALL en_US.UTF-8

    # XDG directories -- ensure history persists
    set -gx XDG_DATA_HOME $HOME/.local/share
    if not test -d $XDG_DATA_HOME/fish
        mkdir -p $XDG_DATA_HOME/fish
    end

    if not set -q XDG_RUNTIME_DIR
        set -gx XDG_RUNTIME_DIR /run/user/(id -u)
    end

    # No greeting -- use fastfetch instead
    set -g fish_greeting ""

    # Show motd then fastfetch (interactive shells only; sshd already prints motd)
    if status is-interactive
        if test -z "$SSH_CONNECTION"
            if test -f /etc/motd
                cat /etc/motd
            end
        end
        fastfetch
    end

    # =============================================================================
    # Path Configuration
    # =============================================================================

    fish_add_path --prepend $HOME/.local/bin

    # Go workspace
    set -gx GOPATH "$HOME/.go"
    set -gx GOMODCACHE "$HOME/.go/pkg/mod"
    fish_add_path $GOPATH/bin

    # =============================================================================
    # Git Prompt Configuration
    # =============================================================================

    set -g __fish_git_prompt_showdirtystate yes
    set -g __fish_git_prompt_showstashstate yes
    set -g __fish_git_prompt_showuntrackedfiles yes
    set -g __fish_git_prompt_showupstream yes
    set -g __fish_git_prompt_color_branch 8BB85A
    set -g __fish_git_prompt_color_upstream_ahead 9ECE6A
    set -g __fish_git_prompt_color_upstream_behind red
    set -g __fish_git_prompt_color_dirtystate 565f89
    set -g __fish_git_prompt_char_dirtystate "●"
    set -g __fish_git_prompt_char_stagedstate "→"
    set -g __fish_git_prompt_char_untrackedfiles "☡"
    set -g __fish_git_prompt_char_stashstate "↩"
    set -g __fish_git_prompt_char_upstream_ahead "+"
    set -g __fish_git_prompt_char_upstream_behind -
    set -g __fish_git_prompt_char_upstream_equal ""

    # =============================================================================
    # Enhanced Prompt Function
    # =============================================================================

    function fish_prompt
        set -l last_status $status
        set -l host (hostname -s 2>/dev/null; or echo unknown)

        # Accent follows the palette, grafted by conf.d/theme_colors.fish.
        # Fall back to the OpenRiot green when the palette value is unusable.
        set -l accent
        if set -q fish_color_command
            set accent $fish_color_command[1]
        end
        string match -qr '^(#?[0-9a-fA-F]{6}|[a-z_]+)$' -- "$accent"; or set accent 9ECE6A

        set_color $accent
        printf '\uf17c  '
        printf "%s " $host
        set_color normal
        printf "%s" (string replace $HOME "~" (pwd))
        if command git rev-parse --git-dir >/dev/null 2>&1
            printf "%s" (__fish_git_prompt)
        end
        if test $last_status -ne 0
            set_color red
            printf " [%d]" $last_status
            set_color normal
        end
        set_color $accent
        printf " ❯ "
        set_color normal
    end

    function fish_right_prompt
        # Disabled -- uncomment to enable
        # printf "%s" (date "+%H:%M:%S")
    end

    # Control terminal title
    function fish_title
        printf '%s' (string replace $HOME "~" (pwd))
    end

    # =============================================================================
    # Aliases & Functions
    # =============================================================================

    # Vim/Vi aliases to helix (only if vim is not installed)
    if not type -q vim
        alias vim='hx'
        alias vi='hx'
    end

    alias helix='hx'

    # Signal Messenger
    alias signal gurk

    # Directory listing with lsd (better ls)
    alias ls='lsd'
    alias ll='lsd -l'
    alias la='lsd -la'

    # Music
    alias music='lollypop'

    # Disk usage -- top 10 largest items by size
    function dum
        du -sm * | sort -nr | head -10
    end

    # =============================================================================
    # Abbreviations & Bindings
    # =============================================================================

    abbr -a -g !! --position anywhere 'commandline -t -- (history | head -n 1)'

    # Ctrl+O for !!
    bind \co 'commandline -i (history | head -1)'
  '';

  # Panacea's theme colors and key bindings must stay writable files, because
  # palette.sh rewrites conf.d/theme_colors.fish when the theme changes.
  home.activation.panaceaFishTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/fish/conf.d"
    for f in ${panaceaSrc}/fish/conf.d/*.fish; do
      [ -e "$f" ] || continue
      dest="$HOME/.config/fish/conf.d/$(basename "$f")"
      [ -e "$dest" ] && continue
      run cp "$f" "$dest"
    done
    run chmod -R u+w "$HOME/.config/fish/conf.d" 2>/dev/null || true
  '';
}
