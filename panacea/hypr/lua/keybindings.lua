local p = require("lua.programs")
local mainMod = "SUPER"

-- Overrides of the combinations from the settings panel (Super+I).
-- The file is generated automatically; if it is absent the defaults below
-- apply.
local ok, ov = pcall(require, "lua.binds_data")
if not ok or type(ov) ~= "table" then ov = {} end

-- B(id, default combination, action [, options])
-- An empty string in an override disables the combination.
local function B(id, def, action, opts)
    local combo = ov[id]
    if combo == nil then combo = def end
    if combo == "" then return end
    hl.bind(combo, action, opts)
end

-- Absolute path for the same reason as programs.bar: "~" survives as-is into
-- qs when the command is not launched through a shell.
local QS = "qs -c " .. os.getenv("HOME") .. "/.config/panacea ipc call pill "


-- ---------------------------------------------------------------- the pill
B("pillLauncher", mainMod .. " + A",             hl.dsp.exec_cmd(QS .. "launcher"))
B("launchpad",    mainMod .. " + G",             hl.dsp.exec_cmd(QS .. "launchpad"))
B("overview",     mainMod .. " + Tab",           hl.dsp.exec_cmd(QS .. "overview"))
B("pillControls", mainMod .. " + Z",             hl.dsp.exec_cmd(QS .. "controls"))
B("pillSettings", mainMod .. " + I",             hl.dsp.exec_cmd(QS .. "settings"))
B("pillShortcuts",mainMod .. " + slash",         hl.dsp.exec_cmd(QS .. "shortcuts"))
B("pillWifi",     mainMod .. " + SHIFT + W",     hl.dsp.exec_cmd(QS .. "wifi"))
B("pillBt",       mainMod .. " + SHIFT + B",     hl.dsp.exec_cmd(QS .. "bluetooth"))
B("pillClip",     mainMod .. " + V",             hl.dsp.exec_cmd(QS .. "clipboard"))
B("pillPower",    "CTRL + ALT + delete",         hl.dsp.exec_cmd(QS .. "powermenu"))
B("pillNotif",    mainMod .. " + SHIFT + N",     hl.dsp.exec_cmd(QS .. "notifications"))
B("pillRecord",   mainMod .. " + P",             hl.dsp.exec_cmd(QS .. "record"))
B("pillVault",    mainMod .. " + SHIFT + P",     hl.dsp.exec_cmd(QS .. "passwords"))

-- Voice to text (voxtype): hold the key, speak, release, and the text is
-- inserted into the active field. One key, two binds: pressing starts the
-- recording, releasing transcribes and pastes. The voxtype.sh wrapper also
-- shows an indicator in the island. The default is right Alt. The id
-- voxDictate shows up in the Super+/ window like the other combinations and
-- can be overridden from the settings.
-- Deliberately wrapped in pcall: on some Hyprland/hl versions the bind options
-- (release, description) or releasing a modifier may be unsupported, and a bare
-- error here took down the WHOLE Hyprland config, resetting every combination
-- to the emergency defaults and taking qs down with it. Better that only voice
-- input breaks.
pcall(function()
    local VOX = os.getenv("HOME") .. "/.config/panacea/scripts/voxtype.sh"
    local combo = ov["voxDictate"]
    if combo == nil or combo == "" or combo == "Alt_R" or combo == "code:108" then
        hl.bind("code:108", hl.dsp.exec_cmd(VOX .. " start"), { description = "Voice to text", ignore_mods = true, locked = true })
        hl.bind("code:108", hl.dsp.exec_cmd(VOX .. " stop"), { release = true, ignore_mods = true, locked = true })
    else
        hl.bind(combo, hl.dsp.exec_cmd(VOX .. " start"), { description = "Voice to text", ignore_mods = true, locked = true })
        hl.bind(combo, hl.dsp.exec_cmd(VOX .. " stop"), { release = true, ignore_mods = true, locked = true })
    end
end)

-- Basic binds
-- Letters are case-insensitive in Hyprland: SUPER+f == SUPER+F
local CLOSE = os.getenv("HOME") .. "/.config/panacea/scripts/smart_close.sh"
B("terminal",     mainMod .. " + T",         hl.dsp.exec_cmd(p.terminal))
B("terminalAlt",  mainMod .. " + Return",    hl.dsp.exec_cmd(p.terminal))
B("closeWindow",  mainMod .. " + Q",         hl.dsp.exec_cmd(CLOSE))
B("browser",      mainMod .. " + F",         hl.dsp.exec_cmd(p.browser))
B("fullscreen",   mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())
B("exitHypr",     mainMod .. " + SHIFT + M", hl.dsp.exit())
B("lockScreen",   mainMod .. " + L",         hl.dsp.exec_cmd(p.lock))
B("themeSwitch",  mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(QS .. "theme"))
-- window into "floating" and back
B("floatToggle",  mainMod .. " + W",         hl.dsp.window.float({ action = "toggle" }))
-- settings panel: the dynamic island unfolds in the centre
B("floatCenter", mainMod .. " + SHIFT + Space", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 800, y = 600, relative = false }))
    hl.dispatch(hl.dsp.window.center())
end)
B("fileManager",  mainMod .. " + E",         hl.dsp.exec_cmd(QS .. "files"))
B("fileManagerTui", mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(p.fileManagerTui))
B("toggleSplit",  mainMod .. " + J",         hl.dsp.layout("togglesplit"))
B("notes",        mainMod .. " + O",         hl.dsp.exec_cmd(p.note))
B("screenshot",   mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(p.screenshot))
B("screenOff",    mainMod .. " + SHIFT + F12", hl.dsp.exec_cmd("brightnessctl s 0"))
B("closeMouse", "mouse:277", hl.dsp.window.close())
-- Super+B was removed along with the shell's power-saving mode: power profiles
-- now live in the panel (hover the pill).


-- Workspace Packing (SUPER+A)
B("packWorkspaces", mainMod .. " + SHIFT + A", function()
    local workspaces = hl.get_workspaces()
    local windows = hl.get_windows()
    local active_ws = hl.get_active_workspace()
    if not workspaces or not windows or not active_ws then return end
    local active_ids = {}
    for _, ws in pairs(workspaces) do
        if ws.id and ws.id > 0 and ws.windows and ws.windows > 0 then
            table.insert(active_ids, ws.id)
        end
    end
    table.sort(active_ids)
    local target = 1
    local curr_ws_id = active_ws.id
    local new_active_ws_id = curr_ws_id
    for _, ws_id in ipairs(active_ids) do
        if ws_id ~= target then
            for _, win in pairs(windows) do
                if win.workspace and win.workspace.id == ws_id then
                    hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false, window = win }))
                end
            end
            if ws_id == curr_ws_id then new_active_ws_id = target end
        end
        target = target + 1
    end
    hl.dispatch(hl.dsp.focus({ workspace = new_active_ws_id }))
end)

-- Movement
B("focusLeft", mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
B("focusRight", mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
B("focusUp", mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
B("focusDown", mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
B("moveLeft", mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
B("moveRight", mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
B("moveUp", mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
B("moveDown", mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Resize
B("resizeRight", "ALT + right", hl.dsp.window.resize({ x = 30,  y = 0,  relative = true }), { repeating = true })
B("resizeLeft", "ALT + left",  hl.dsp.window.resize({ x = -30, y = 0,  relative = true }), { repeating = true })
B("resizeUp", "ALT + up",    hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
B("resizeDown", "ALT + down",  hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })

-- Workspaces
B("emptyWorkspace", mainMod .. " + Space",   hl.dsp.focus({ workspace = "empty" }))
for i = 1, 10 do
    local key = i % 10
    B("workspace" .. i, mainMod .. " + " .. key, hl.dsp.focus({ workspace = i}))
    B("moveWorkspace" .. i, mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
B("specialWorkspace", mainMod .. " + S",     hl.dsp.workspace.toggle_special("magic"))
B("workspaceNext", mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
B("workspacePrevious", mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse
B("dragWindow", mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
B("resizeWindowMouse", mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media
B("micMute", "XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
local HOME = os.getenv("HOME")
B("volumeUp", "XF86AudioRaiseVolume", hl.dsp.exec_cmd(HOME .. "/.local/bin/smart_volume.sh up"), { locked = true, repeating = true })
B("volumeDown", "XF86AudioLowerVolume", hl.dsp.exec_cmd(HOME .. "/.local/bin/smart_volume.sh down"), { locked = true, repeating = true })
B("volumeMute", "XF86AudioMute", hl.dsp.exec_cmd(HOME .. "/.local/bin/smart_volume.sh mute"), { locked = true })
B("brightnessUp", "XF86MonBrightnessUp", hl.dsp.exec_cmd(HOME .. "/.local/bin/smart_brightness.sh up"), { locked = true, repeating = true })
B("brightnessDown", "XF86MonBrightnessDown", hl.dsp.exec_cmd(HOME .. "/.local/bin/smart_brightness.sh down"), { locked = true, repeating = true })
B("mediaNextAlt", mainMod .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("playerctl next"), { locked = true })
B("mediaPreviousAlt", mainMod .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

B("mediaNext", "XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
B("mediaPause", "XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
B("mediaPlay", "XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
B("mediaPrevious", "XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Switch
B("lidOn", "switch:on:Lid Switch", hl.dsp.exec_cmd(p.lock), { locked = true })
B("lidOff", "switch:off:Lid Switch", hl.dsp.exec_cmd(p.lock), { locked = true })


-- The pill: panels open inside it

-- An empty submap to capture combinations in the settings panel.
-- While it is active Hyprland has no bindings at all and keys go entirely to
-- the application; otherwise trying to assign a combination fires an existing
-- action.
hl.define_submap("capture", function()
    -- emergency exit, in case the panel somehow fails to restore normal mode
    hl.bind("SUPER + SHIFT + Escape",
        hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/panacea/scripts/capture.sh off"))
end)
