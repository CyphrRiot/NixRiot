local programs = {}

-- What opens what. Everything here is actually called from keybindings.lua or
-- autostart.lua: entries nobody looks at drift away from the system silently,
-- which is how menus and a power menu ended up pointing at scripts that are not
-- in the repository.
programs.terminal = "footclient"
programs.terminalFloat = "footclient --app-id nixriot-float-term"
programs.fileManagerTui = "footclient yazi" -- in the terminal, on Super+Shift+E
-- Absolute path, no "~": exec without a shell does not expand a tilde, and the
-- island silently never started, leaving a black screen after login.
--
-- QSG_RENDER_LOOP=threaded is not decoration, it is frame rate. With the NVIDIA
-- driver Qt picks "basic" on its own, and that drives animations from a 16 ms
-- timer, that is exactly 60 frames, whatever the monitor: on 144 Hz the island
-- unfolding looks stepped. Threaded takes its tick from vsync and runs at the
-- screen rate (6.94 ms per frame at 144 Hz).
programs.bar = os.getenv("HOME") .. "/.config/panacea/scripts/start.sh"   -- the pill
-- Region screenshot from a freeze frame: the script freezes the screen into an
-- image and the selection runs against that. Otherwise menus and hints close
-- before you can draw a box around them. Absolute path: exec without a shell
-- does not expand a tilde.
programs.screenshot = os.getenv("HOME") .. "/.config/panacea/scripts/shot.sh"
programs.browser = "firefox"
programs.lock = os.getenv("HOME") .. "/.config/panacea/scripts/lock.sh"
programs.editor = "env GSK_RENDERER=cairo gnome-text-editor"
programs.processViewer = "foot -e btop"
programs.crush = "foot -e crush"
programs.music = "lollypop"
programs.mail = "firefox https://mail.proton.me/inbox"

return programs
