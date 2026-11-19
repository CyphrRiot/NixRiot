return {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 1,
    -- Active window border. The red end of the former gradient crept into the
    -- frame as a stripe under the island and clashed with the black and white
    -- shell; here it marked nothing, it was simply a colour.
    active_border = { colors = { "rgba(ffffffff)","rgba(8a8a8aff)" }, angle = 45 },
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
