-- Internal panel handling when the lid is closed.
--
-- logind decides whether a closed lid suspends or stays awake because an
-- external display is attached. It does not know anything about outputs, so
-- the internal panel stays on and keeps drawing the desktop. This module owns
-- that half: disable the internal panel while the lid is closed and an
-- external monitor is enabled, and put it back when either condition ends.

local internal_prefixes = { "eDP", "LVDS", "DSI" }

local function is_internal(name)
    for _, prefix in ipairs(internal_prefixes) do
        if name:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

local function lid_closed()
    local handle = io.popen("cat /proc/acpi/button/lid/*/state 2>/dev/null")
    if not handle then
        return false
    end
    local text = handle:read("*a") or ""
    handle:close()
    return text:find("closed", 1, true) ~= nil
end

local function external_attached()
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.enabled and not is_internal(monitor.name) then
            return true
        end
    end
    return false
end

local ok, saved = pcall(require, "lua.monitors_data")
if not ok or type(saved) ~= "table" then
    saved = {}
end

local function restore(name)
    for _, entry in ipairs(saved) do
        if entry.output == name then
            hl.monitor({
                output = entry.output,
                mode = entry.mode,
                position = entry.position or "auto",
                scale = entry.scale or 1.0,
                transform = entry.transform or 0,
                vrr = entry.vrr or 0,
            })
            return
        end
    end
    hl.monitor({ output = name, mode = "preferred", position = "auto", scale = 1.0 })
end

local function apply()
    local docked = lid_closed() and external_attached()
    for _, monitor in ipairs(hl.get_monitors()) do
        if is_internal(monitor.name) then
            if docked and monitor.enabled then
                hl.monitor({ output = monitor.name, disabled = true })
            elseif not docked and not monitor.enabled then
                restore(monitor.name)
            end
        end
    end
end

hl.on("monitor.added", apply)
hl.on("monitor.removed", apply)
hl.on("hyprland.start", apply)

return { apply = apply }
