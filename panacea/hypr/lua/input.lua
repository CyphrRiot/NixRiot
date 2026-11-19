local input_ok, input_data = pcall(require, "lua.input_data")
if not input_ok or type(input_data) ~= "table" then input_data = {} end

hl.config({
    input = {
        kb_layout  = input_data.layouts or "us",
        kb_variant = input_data.variants or ",",
        kb_model   = "",
        -- Alt+Shift switches the layout
        kb_options = input_data.options or "grp:alt_shift_toggle",
        kb_rules   = "",
        follow_mouse = 0,
        sensitivity = 0,
        touchpad = {
            -- natural_scroll = true: the content follows the fingers.
            -- Fingers up means the page scrolls down.
            -- If it feels backwards, set false; it is the only line involved.
            natural_scroll = true,
            scroll_factor = 1.0,
            disable_while_typing = true,
            tap_to_click = true,
            -- drag_lock left the button "held" after the finger was lifted: the
            -- selection kept going by itself until you tapped again
            drag_lock = false,
            clickfinger_behavior = true,
        },
    },
})

-- ---------------------------------------------------------------- gestures
--
-- We use Hyprland's BUILT-IN actions, not our own Lua handlers.
-- The difference matters: a handler fires once, after the fingers are already
-- lifted, so the window stayed put until then. The built-in gestures
-- (CCloseTrackpadGesture, CFullscreenTrackpadGesture and others) update on
-- every movement, and the window follows the fingers in real time.
--
-- The reverse works too: if you do not complete the gesture, the window
-- returns to its place.

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "move" })

-- 3 fingers down -> the window follows the fingers down and closes
hl.gesture({ fingers = 3, direction = "down", action = "close" })

-- 3 fingers up -> fullscreen
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })

-- 4 fingers down -> unfloat the window and drag it
hl.gesture({ fingers = 4, direction = "down", action = "float" })

-- The hl.device block was removed on purpose: it is the example device from the
-- stock Hyprland config, which nobody has. Worse, a device setting overrides
-- the general one, so if your mouse were ever named the same, the speed slider
-- in the settings would silently do nothing. Speed and acceleration now live in
-- the settings window (Mouse section).
