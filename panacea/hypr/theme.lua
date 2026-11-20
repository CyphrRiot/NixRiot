return {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 1,
    -- Active window border carries the accent at two brightnesses, the way
    -- OpenRiot frames a window. Upstream took this from the pill's own white
    -- (Themes.js), which leaked a black-and-white frame onto an accent-coloured
    -- desktop.
    active_border = { colors = { "rgba(a04232ff)", "rgba(c65a47ff)" }, angle = 45 },
    inactive_border = "rgba(2a2a2aaa)",
    rounding = 8,
    rounding_power = 4.0,
    active_opacity = 1.0,
    inactive_opacity = 0.90,
    shadow_enabled = false,
    shadow_range = 4,
    shadow_render_power = 3,
    shadow_color = "rgba(1a1a1aee)",
    blur_enabled = false,
    blur_size = 3,
    blur_passes = 1,
    blur_vibrancy = 0.1696,
}
