-- Displays.
--
-- Saved settings arrive here from settings.json through
-- panacea/scripts/genmonitors.sh, the same way the key bindings do. No file
-- (first install, someone else's machine) means "preferred" stays and
-- everything works as before.
--
-- Why the mode is set here and not only by the shell: it applies its own
-- settings roughly half a second after it starts, and Qt binds the animation
-- timer to the refresh rate once, when it creates its first window. At that
-- moment the monitor is still on "preferred", which over HDMI is very often
-- 60 Hz even on a 144 Hz panel. So the shell spends the whole session running
-- animations at 60 Hz on a monitor that switched long ago. The mode has to be
-- set before the shell starts.
local ok, saved = pcall(require, "lua.monitors_data")
if not ok or type(saved) ~= "table" then saved = {} end

for _, m in ipairs(saved) do
    hl.monitor({
        output    = m.output,
        mode      = m.mode,
        position  = m.position or "auto",
        scale     = m.scale or 1.0,
        transform = m.transform or 0,
        vrr       = m.vrr or 0,
    })
end

-- Everything else that gets attached: the panel's preferred resolution.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.0,
})
