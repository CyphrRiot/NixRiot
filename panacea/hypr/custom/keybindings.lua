-- Custom Keybindings & Shortcuts (Lua)
--
-- API: hl.bind(combo, dispatcher [, options])
-- Dispatchers live in hl.dsp — hl.dsp.exec_cmd, hl.dsp.killactive, ...
--
-- NixRiot: restore OpenRiot's common shortcuts on top of Panacea's keymap.
-- OpenRiot used the same $mod (SUPER) with a different map. These rebind the
-- common actions to OpenRiot's keys. Panacea's own keys stay where they do not
-- conflict (SUPER+Return terminal, SUPER+V clipboard, CTRL+ALT+Delete power).

local HOME = os.getenv("HOME")

local function pill(cmd)
  return hl.dsp.exec_cmd("qs -c " .. HOME .. "/.config/panacea ipc call pill " .. cmd)
end

-- Launcher (OpenRiot: SUPER+D; Panacea: SUPER+A)
hl.bind("SUPER + D", pill("launcher"))

-- Browser (OpenRiot: SUPER+B; Panacea: SUPER+F)
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))

-- File manager (OpenRiot: SUPER+F opened Thunar)
hl.bind("SUPER + F", hl.dsp.exec_cmd("thunar"))

-- Process viewer (OpenRiot: SUPER+T ran btop in a terminal)
hl.bind("SUPER + T", hl.dsp.exec_cmd("foot -e btop"))

-- Text editor (OpenRiot: SUPER+O)
hl.bind("SUPER + O", hl.dsp.exec_cmd("gnome-text-editor"))

-- Crush (OpenRiot: SUPER+C)
hl.bind("SUPER + C", hl.dsp.exec_cmd("foot -e crush"))

-- Music player (OpenRiot: SUPER+Shift+K)
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("lollypop"))

-- Clipboard history (OpenRiot: SUPER+Shift+V; Panacea: SUPER+V)
hl.bind("SUPER + SHIFT + V", pill("clipboard"))

-- Power menu (OpenRiot: SUPER+Escape; Panacea: CTRL+ALT+Delete)
hl.bind("SUPER + Escape", pill("powermenu"))

-- Region screenshot (OpenRiot: SUPER+Shift+S and Print; Panacea: SUPER+Shift+S)
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(HOME .. "/.config/panacea/scripts/shot.sh"))
hl.bind("Print", hl.dsp.exec_cmd(HOME .. "/.config/panacea/scripts/shot.sh"))
