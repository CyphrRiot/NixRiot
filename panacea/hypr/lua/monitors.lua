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
--
-- Only an output that is not already on its saved mode gets a rule. Setting a
-- mode the output is already using is still a modeset, and a modeset on every
-- config load is the black frame at the end of an update. For the same reason
-- there is no catch-all rule: Hyprland already puts an unknown output on its
-- preferred mode, so a catch-all only ever added a second modeset.
local ok, saved = pcall(require, "lua.monitors_data")
if not ok or type(saved) ~= "table" then saved = {} end

local function saved_for(name)
    for _, m in ipairs(saved) do
        if m.output == name then return m end
    end
    return nil
end

local function mode_of(mon)
    local rr = mon.refresh_rate
    if not rr and mon.mode then rr = mon.mode.refresh_rate end
    return tonumber(mon.width), tonumber(mon.height), tonumber(rr)
end

local function already_set(mon, m)
    local w, h, rr = mode_of(mon)
    local sw, sh, srr = tostring(m.mode):match("^(%d+)x(%d+)@([%d%.]+)")
    if not w or not h or not rr or not sw then return false end
    if w ~= tonumber(sw) or h ~= tonumber(sh) then return false end
    if math.abs(rr - tonumber(srr)) > 0.6 then return false end

    local scale = tonumber(m.scale) or 1.0
    if mon.scale and math.abs(tonumber(mon.scale) - scale) > 0.001 then return false end

    local transform = tonumber(m.transform) or 0
    if mon.transform and tonumber(mon.transform) ~= transform then return false end

    return true
end

for _, mon in ipairs(hl.get_monitors()) do
    local m = saved_for(mon.name)
    if m and mon.enabled ~= false and not already_set(mon, m) then
        hl.monitor({
            output    = m.output,
            mode      = m.mode,
            position  = m.position or "auto",
            scale     = tonumber(m.scale) or 1.0,
            transform = tonumber(m.transform) or 0,
            vrr       = m.vrr or 0,
        })
    end
end

-- The lid has the last word: a saved entry for the internal panel would switch
-- it back on while the lid is shut with an external display attached.
pcall(function()
    local lid = require("lua.lid")
    if lid and lid.apply then lid.apply() end
end)
