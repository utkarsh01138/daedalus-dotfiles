-- Monitor: Hyprland decides initial scale (the active shell updates it later via Rules.monitor)
hl.monitor({ output = "", mode = "highres", position = "auto", scale = "auto" })

-- XWayland scaling: Hyprland scales XWayland apps by default (blurry on HiDPI fractional scale, but correct size). For crisp integer scaling, configure in user.lua:
--   hl.config({ xwayland = { force_zero_scaling = true } }); hl.env("GDK_SCALE", "2")

-- Configs
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- User-defined keybinds and overrides: hypr/user.lua (gitignored, safe from repo updates)
local user = io.open(os.getenv("HOME") .. "/.config/hypr/user.lua")
if user then user:close(); require("user") end

-- HyprMod managed settings
require("hyprland-gui")
