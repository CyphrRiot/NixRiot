-- 24-hour time, with the interface language left as English.
--
-- Applications take their clock format from LC_TIME, not from their own
-- settings: en_US means "12 hours and AM/PM", and Telegram, calendars and
-- everything else showed 12:02 AM instead of 00:02. A separate variable rather
-- than changing LANG: we change exactly the time format, not the interface
-- language.
hl.env("LC_TIME", "en_GB.UTF-8")

-- Cursor: Bibata Modern Classic, black, without outline or shadow, a match for
-- the dark shell. The theme name is needed both in the variables (read by
-- Xwayland and GTK/Qt programs) and in Hyprland itself, which draws the cursor
-- on its own.
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_SCALE", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
