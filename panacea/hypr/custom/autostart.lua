-- Custom Autostart Programs & Daemons (Lua)
--
-- API: hl.exec_cmd(command) inside the "hyprland.start" event

hl.on("hyprland.start", function ()
  hl.exec_cmd("hypridle")
end)
