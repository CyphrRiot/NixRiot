local theme = require("theme")

-- Is the NVIDIA driver in use. The two settings below are only needed on it and
-- make things worse on other cards, so we ask the kernel rather than the
-- person: the module directory exists exactly when the driver is loaded.
-- We read /proc/modules rather than /sys/module/nvidia_drm/parameters/*: the
-- latter is opened only for root, and a check through it would always answer
-- "not NVIDIA" for an ordinary user.
local nvidia = (function ()
    local f = io.open("/proc/modules", "r")
    if not f then return false end
    for line in f:lines() do
        if line:match("^nvidia_drm") then f:close(); return true end
    end
    f:close()
    return false
end)()

hl.config({
    general = {
        gaps_in  = theme.gaps_in,
        gaps_out = theme.gaps_out,
        border_size = theme.border_size,
        col = {
            active_border   = theme.active_border,
            inactive_border = theme.inactive_border,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding       = theme.rounding,
        rounding_power = theme.rounding_power,
        active_opacity   = theme.active_opacity,
        inactive_opacity = theme.inactive_opacity,
        shadow = {
            enabled      = theme.shadow_enabled,
            range        = theme.shadow_range,
            render_power = theme.shadow_render_power,
            color        = theme.shadow_color,
        },
        blur = {
            enabled   = theme.blur_enabled,
            size      = theme.blur_size,
            passes    = theme.blur_passes,
            vibrancy  = theme.blur_vibrancy,
        },
    },
    animations = {
        enabled = true,
    },
})

-- Animations are now handled in lua/animations.lua
require("lua.animations").apply()

-- Layout Config
hl.config({
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    scrolling = { fullscreen_on_one_column = true },
    debug = { damage_tracking = 0 },
    misc = {
        force_default_wallpaper = 0,
        disable_splash_rendering = true,
        disable_hyprland_logo   = true,
        background_color        = "rgb(000000)",
        animate_manual_resizes  = true,
        -- GTK4 surfaces on this GPU leave stale damage while scrolling when
        -- variable refresh is on; a fixed repaint tick clears it.
        vrr                     = 0,
    },
    xwayland = { force_zero_scaling = true },
    cursor = {
        sync_gsettings_theme = true,
        inactive_timeout     = 5,
        -- We draw the cursor ourselves rather than with a separate GPU layer.
        --
        -- In "auto" on the NVIDIA driver the cursor goes through a hardware
        -- layer, and its buffer is moved into KMS on every movement; the log
        -- shows this as an unbroken run of "Cursor buffer imported into KMS".
        -- Now and then the move gets stuck and the pointer freezes for a second
        -- or two, although the system itself is alive.
        --
        -- A software cursor is drawn together with the frame: the extra layer
        -- and its moves disappear entirely. At 144 Hz the difference in latency
        -- is invisible, since the frame changes every 7 ms anyway.
        no_hardware_cursors = nvidia and true or 2,
    },
})
