#!/bin/bash
# Lays the single palette (~/.config/hypr/palette.conf) out across applications:
# fastfetch, foot, fish, zed, btop, neovim, obsidian and the login screen.
#
# switch_theme.sh used to do this, and colours changed along with the wallpaper.
# Now the palette is one: this script is needed by the installer and after
# editing palette.conf by hand. Changing the wallpaper does not call it.

PALETTE="$HOME/.config/hypr/palette.conf"
[ -f "$PALETTE" ] || { echo "no $PALETTE" >&2; exit 1; }

val() {
    grep -m1 "^\\\$$1[[:space:]]*=" "$PALETTE" \
        | cut -d= -f2- | sed 's/^ *//; s/ *$//'
}

ACCENT=$(val accent_color)
BG=$(val bg_color)
FG=$(val fg_color)
TERM_BG=$(val term_bg)

[[ ! $ACCENT =~ ^# ]] && ACCENT="#ffffff"
[[ ! $BG     =~ ^# ]] && BG="#000000"
[[ ! $FG     =~ ^# ]] && FG="#ffffff"
[[ ! $TERM_BG =~ ^# ]] && TERM_BG="$BG"

# ----------------------------------------------------------- fastfetch
# Labels and the logo are painted with the accent. In the config the lines are
# marked with a panacea:accent comment, and we rewrite exactly the one after it.
FF="$HOME/.config/fastfetch/config.jsonc"
if [ -f "$FF" ]; then
    R=$((16#${ACCENT:1:2})); G=$((16#${ACCENT:3:2})); B=$((16#${ACCENT:5:2}))
    awk -v rgb="38;2;$R;$G;$B" '
        prev ~ /panacea:accent/ { gsub(/38;2;[0-9]+;[0-9]+;[0-9]+/, rgb) }
        { print; prev = $0 }
    ' "$FF" > "$FF.new" && mv "$FF.new" "$FF"
fi

# ------------------------------------------------------------------- foot
# foot does not want '#' in colour values
if [ -d "$HOME/.config/foot" ]; then
    cat > "$HOME/.config/foot/theme" <<EOF
[colors-dark]
foreground=${FG#\#}
background=${TERM_BG#\#}
selection-foreground=${TERM_BG#\#}
selection-background=${FG#\#}
EOF
fi

# foot reads the [colors-dark] section only if the portal reports
# color-scheme=prefer-dark. The system default is "default", and the theme was
# silently ignored: the terminal stayed on the grey 242424 instead of our almost
# black background. Our palette is dark, so we declare that once, here.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

# ------------------------------------------ fish, zed, btop, neovim (python)
python3 <<EOF
import json, os, colorsys, re

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(rgb):
    return '{:02x}{:02x}{:02x}'.format(int(rgb[0]*255), int(rgb[1]*255), int(rgb[2]*255))

accent = "$ACCENT"
bg = "$BG"
fg = "$FG"

r, g, b = [x/255.0 for x in hex_to_rgb(accent)]
h, s, v = colorsys.rgb_to_hsv(r, g, b)

# Soft shades of the accent for syntax highlighting
syntax_accent = rgb_to_hex(colorsys.hsv_to_rgb(h, s * 0.55, v * 0.85))
color_param = rgb_to_hex(colorsys.hsv_to_rgb(h, s * 0.35, v * 0.7))
color_quote = rgb_to_hex(colorsys.hsv_to_rgb(h, s * 0.45, v * 0.8))

# 1. FISH
fish_dir = os.path.expanduser('~/.config/fish/conf.d')
if os.path.isdir(fish_dir):
    with open(os.path.join(fish_dir, 'theme_colors.fish'), 'w') as f:
        f.write("set -e fish_color_command\nset -e fish_color_param\n")
        f.write("set -g fish_color_command blue\n")
        f.write(f"set -g fish_color_param '{fg}'\n")
        f.write("set -g fish_color_quote cyan\n")
        f.write("set -g fish_color_redirection magenta\n")
        f.write("set -g fish_color_end magenta\n")
        f.write("set -g fish_color_error red\n")
        f.write("set -g fish_color_selection --background=cyan --foreground=black\n")
        f.write("set -g fish_color_autosuggestion 707070\n")

# 2. FOOT
# This used to write only foreground, background and selection, so foot kept
# its own stock 16-colour palette, and that is where the green came from.
# Derive the ANSI colours from the accent instead, so palette.conf stays the
# only source of truth.
foot_theme = os.path.expanduser('~/.config/foot/theme')
if os.path.isdir(os.path.dirname(foot_theme)):
    term_bg = "$TERM_BG"
    rf, gf, bf = [x / 255.0 for x in hex_to_rgb(fg)]
    grey = rgb_to_hex(((r + rf) / 2, (g + gf) / 2, (b + bf) / 2))
    base = v * 0.85
    bright = min(v * 1.1, 1.0)

    def wheel(deg, value):
        return rgb_to_hex(colorsys.hsv_to_rgb((h + deg / 360.0) % 1.0, min(s, 0.85), value))

    hues = {1: 0, 2: 120, 3: 55, 4: 225, 5: 300, 6: 180}
    with open(foot_theme, 'w') as f:
        f.write("[colors-dark]\n")
        f.write(f"foreground={fg.lstrip('#')}\n")
        f.write(f"background={term_bg.lstrip('#')}\n")
        f.write(f"selection-foreground={term_bg.lstrip('#')}\n")
        f.write(f"selection-background={fg.lstrip('#')}\n")
        f.write(f"regular0={term_bg.lstrip('#')}\n")
        f.write(f"regular7={fg.lstrip('#')}\n")
        f.write(f"bright0={grey}\n")
        f.write(f"bright7={fg.lstrip('#')}\n")
        for index, deg in hues.items():
            f.write(f"regular{index}={wheel(deg, base)}\n")
            f.write(f"bright{index}={wheel(deg, bright)}\n")

# 3. ZED
zed_path = os.path.expanduser('~/.config/zed/settings.json')
accent_mute = f"{accent}33"
accent_very_mute = f"{accent}15"
if os.path.exists(zed_path):
    with open(zed_path) as f:
        try: zed_data = json.load(f)
        except Exception: zed_data = {}
    zed_data['experimental.theme_overrides'] = {
        "background": bg, "editor.background": bg, "pane.background": bg,
        "pane.inactive_background": bg, "side_bar.background": bg,
        "status_bar.background": bg, "title_bar.background": bg,
        "toolbar.background": bg, "tab_bar.background": bg,
        "project_panel.background": bg, "terminal.background": bg,
        "panel.background": bg, "search.background": bg,
        "editor.gutter.background": bg, "menu.background": bg,
        "popover.background": bg, "picker.background": bg,
        "elevated_surface.background": bg, "context_menu.background": bg,
        "dropdown.background": bg, "border": accent_mute,
        "border.variant": accent_mute, "element.active": accent_mute,
        "element.selected": accent_mute, "element.hover": accent_very_mute,
        "tab.active_background": accent_very_mute, "active_tab.border": accent,
        "scrollbar.thumb.background": accent_mute, "text": fg,
        "editor.foreground": fg, "editor.active_line_number.foreground": accent,
        "editor.line_number.foreground": f"#{color_param}",
        "syntax": {
            "comment": {"color": "#606060"},
            "string": {"color": f"#{color_quote}"},
            "keyword": {"color": f"#{syntax_accent}"},
            "function": {"color": f"#{syntax_accent}"},
            "type": {"color": f"#{syntax_accent}"},
            "operator": {"color": f"#{syntax_accent}"},
            "property": {"color": f"#{color_param}"},
            "variable": {"color": fg}
        }
    }
    with open(zed_path, 'w') as f:
        json.dump(zed_data, f, indent=4)

# 4. BTOP
btop_theme_dir = os.path.expanduser('~/.config/btop/themes')
os.makedirs(btop_theme_dir, exist_ok=True)
with open(os.path.join(btop_theme_dir, 'dynamic.theme'), 'w') as f:
    f.write(f'theme[main_bg]="{bg}"\ntheme[main_fg]="{fg}"\ntheme[title]="{fg}"\n')
    f.write(f'theme[hi_fg]="{accent}"\ntheme[selected_bg]="{accent_mute}"\n')
    f.write(f'theme[selected_fg]="{accent}"\ntheme[inactive_fg]="#555555"\n')
    f.write(f'theme[proc_misc]="{accent}"\ntheme[cpu_box]="{accent}"\n')
    f.write(f'theme[mem_box]="{accent}"\ntheme[net_box]="{accent}"\n')
    f.write(f'theme[proc_box]="{accent}"\ntheme[div_line]="#333333"\n')
    f.write(f'theme[free_graph]="{accent}"\ntheme[cached_graph]="#{color_param}"\n')
    f.write(f'theme[available_graph]="#{color_quote}"\ntheme[used_graph]="{accent}"\n')
    f.write(f'theme[download_graph]="{accent}"\ntheme[upload_graph]="#{color_param}"\n')

btop_conf_path = os.path.expanduser('~/.config/btop/btop.conf')
if os.path.exists(btop_conf_path):
    with open(btop_conf_path) as f: content = f.read()
    content = re.sub(r'color_theme = .*', 'color_theme = "dynamic.theme"', content)
    with open(btop_conf_path, 'w') as f: f.write(content)

# 4. NEOVIM
nvim_dir = os.path.expanduser('~/.config/nvim/lua')
os.makedirs(nvim_dir, exist_ok=True)

def clean_hex(h):
    return h[:7] if h.startswith('#') else f"#{h[:6]}"

with open(os.path.join(nvim_dir, 'theme_colors.lua'), 'w') as f:
    f.write('return {\n')
    f.write(f'    bg = "{clean_hex(bg)}",\n')
    f.write(f'    fg = "{clean_hex(fg)}",\n')
    f.write(f'    accent = "{clean_hex(accent)}",\n')
    f.write(f'    syntax = "{clean_hex(syntax_accent)}",\n')
    f.write(f'    param = "{clean_hex(color_param)}",\n')
    f.write(f'    string = "{clean_hex(color_quote)}",\n')
    f.write(f'    selection = "{clean_hex(accent)}",\n')
    f.write('}\n')
EOF

# ------------------------------------------------------------- obsidian
OBSIDIAN_SNIPPET="$HOME/obsidian_vault/.obsidian/snippets/system-theme.css"
if [ -d "$HOME/obsidian_vault/.obsidian" ]; then
    mkdir -p "$(dirname "$OBSIDIAN_SNIPPET")"
    cat > "$OBSIDIAN_SNIPPET" <<EOF
:root { --system-accent: $ACCENT; --system-bg: $BG; --system-fg: $FG; }
.theme-dark, .theme-light {
    --accent-component: var(--system-accent) !important;
    --interactive-accent: var(--system-accent) !important;
    --background-primary: var(--system-bg) !important;
    --background-secondary: var(--system-bg) !important;
    --text-normal: var(--system-fg) !important;
}
EOF
fi

# --------------------------------------------------------- login screen
# The login screen palette is written by the shell itself, not by this script.
#
# What lives here is the palette of terminals, editors and btop. It is edited by
# hand and has nothing to do with the shell theme. While the login screen took
# its accent from here, on the black and white theme it greeted you with a
# terracotta circle: the colours matched only by accident, and as soon as the
# theme changed the mismatch showed.
#
# The shell knows the selected theme and writes its colours into
# /var/lib/panacea itself, with the same QML fragment and into the same file.

exit 0
