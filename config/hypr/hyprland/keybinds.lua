local vars = require("variables")
local fn   = require("hyprland.functions")

-- Shell globals — shell:<name>: registered by the active Quickshell instance (demonshot, glyph)
-- Deck & Bar: Tapping Super opens the bottom deck and left bar on key release.
-- To prevent Super+<key> shortcuts (e.g. Super+1) from accidentally triggering on release,
-- every Super+<key> sends launcherInterrupt without consuming the keypress.
hl.bind("SUPER + SUPER_L", hl.dsp.global("shell:deckTap"), { release = true })
-- After Super+<key>, the release bind above does not fire and interrupt stays stuck — reset it on Super press down
hl.bind("SUPER_L", hl.dsp.global("shell:launcherArm"), { ignore_mods = true, non_consuming = true })
for _, key in ipairs({
    -- secondary modifiers: cover every Super+Mod+key combo
    "Control_L", "Control_R", "Shift_L", "Shift_R", "Alt_L", "Alt_R",
    -- workspaces
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    -- Super+<key> binds below
    "Q", "W", "E", "R", "T", "A", "D", "F", "G", "J", "K", "L", "C", "V", "M", "N", "P",
    "Z", "X", "U", "S", "H", "I", "space", "Escape",
    "Comma", "Period", "Minus", "Equal", "Backslash", "slash", "question",
    "left", "right", "up", "down",
    "Page_Up", "Page_Down", "F12",
    "mouse:272", "mouse:273", "mouse:274", "mouse:275", "mouse:276", "mouse:277",
    "mouse_up", "mouse_down",
}) do
    hl.bind("SUPER + " .. key, hl.dsp.global("shell:launcherInterrupt"), { non_consuming = true })
end

-- New Rice Panels & Tools (triggered by your preferred keybinds)
hl.bind(vars.kbLauncher or "SUPER + Space", hl.dsp.global("shell:launcherToggle")) -- App Launcher (SUPER + Space)
hl.bind(vars.kbPower, hl.dsp.global("shell:power"))            -- New rice power menu (SUPER + SHIFT + Q)
hl.bind("SUPER + Escape", hl.dsp.global("shell:power"))        -- Alternate power menu
hl.bind(vars.kbSession, hl.dsp.global("shell:power"))          -- CTRL + ALT + Delete power
hl.bind("SUPER + I", hl.dsp.global("shell:settings"))          -- New rice settings / prefs
hl.bind("SUPER + A", hl.dsp.global("shell:quick"))             -- New rice quick settings
hl.bind("SUPER + SHIFT + W", hl.dsp.global("shell:wall"))      -- New rice wallpaper picker
hl.bind("SUPER + V", hl.dsp.global("shell:clip"))              -- New rice clipboard history
hl.bind("SUPER + Period", hl.dsp.global("shell:charms"))        -- New rice emoji / symbols
hl.bind("SUPER + ALT + P", hl.dsp.global("shell:pact"))        -- New rice VPN panel
hl.bind("SUPER + ALT + N", hl.dsp.global("shell:ward"))
hl.bind(vars.kbLock, hl.dsp.exec_cmd(vars.lockCmd))            -- New rice lockscreen (SUPER + L)
hl.bind(vars.kbRestoreLock, hl.dsp.exec_cmd(vars.lockCmd), { locked = true })

-- Keybind Helper (Super + Shift + Slash / Super + ?) -> Native Quickshell Panel
hl.bind("SUPER + SHIFT + slash", hl.dsp.global("shell:binds"))
hl.bind("SUPER + question", hl.dsp.global("shell:binds"))

-- Screenshots (New Rice Screenshot tool on Print)
hl.bind("Print", hl.dsp.global("shell:shot"))

-- Apps
hl.bind(vars.kbTerminal, hl.dsp.exec_cmd(vars.terminal))             -- SUPER + T -> kitty
hl.bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer))     -- SUPER + E -> thunar (new rice file manager)
hl.bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser))               -- SUPER + B -> chromium
hl.bind(vars.kbEditor, hl.dsp.exec_cmd(vars.apps.editor or "code"))  -- SUPER + C -> code
hl.bind("SUPER + N", hl.dsp.exec_cmd(vars.notion))                   -- SUPER + N -> Notion
hl.bind("SUPER + M", hl.dsp.exec_cmd(vars.musicPlayer))              -- SUPER + M -> musicPlayer

-- Layout / Window actions
hl.bind(vars.kbCloseWindow, hl.dsp.window.close())                   -- SUPER + Q -> close window
hl.bind(vars.kbToggleWindowFloating, hl.dsp.window.float({ action = "toggle" })) -- SUPER + SHIFT + T -> toggle float
hl.bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" })) -- SUPER + SHIFT + F -> maximize
hl.bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))         -- SUPER + F -> fullscreen
hl.bind("SUPER + P", hl.dsp.window.pseudo())                         -- SUPER + P -> pseudo
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))                   -- SUPER + J -> togglesplit

-- Focus and Move with arrow keys
hl.bind("SUPER + left",  hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up",    hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down",  hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Move/resize windows with SUPER + LMB/RMB and dragging
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true }) -- LMB drag
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- RMB resize
hl.bind(vars.kbMoveWindow, hl.dsp.window.drag(), { mouse = true })
hl.bind(vars.kbResizeWindow, hl.dsp.window.resize(), { mouse = true })

-- Window resize with keyboard
hl.bind("SUPER + Minus", hl.dsp.window.resize(fn.resize_active_window(-10, 0)), { repeating = true })
hl.bind("SUPER + Equal", hl.dsp.window.resize(fn.resize_active_window(10, 0)), { repeating = true })
hl.bind("SUPER + SHIFT + Minus", hl.dsp.window.resize(fn.resize_active_window(0, -10)), { repeating = true })
hl.bind("SUPER + SHIFT + Equal", hl.dsp.window.resize(fn.resize_active_window(0, 10)), { repeating = true })
hl.bind("SUPER + ALT + left", hl.dsp.window.resize(fn.resize_active_window(-10, 0)), { repeating = true })
hl.bind("SUPER + ALT + right", hl.dsp.window.resize(fn.resize_active_window(10, 0)), { repeating = true })
hl.bind("SUPER + ALT + up", hl.dsp.window.resize(fn.resize_active_window(0, -10)), { repeating = true })
hl.bind("SUPER + ALT + down", hl.dsp.window.resize(fn.resize_active_window(0, 10)), { repeating = true })

-- Extra window utilities
hl.bind(vars.kbPinWindow, hl.dsp.window.pin())
hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.center())
hl.bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))
        for _, x in ipairs(pip) do hl.dispatch(x) end
    end
end)

-- Switch workspaces with SUPER + [0-9]
-- Move active window to workspace with SUPER + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(vars.kbGoToWs .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(vars.kbMoveWinToWs .. " + " .. key, hl.dsp.window.move({ workspace = i }))
    hl.bind(vars.kbGoToWsGroup .. " + " .. key, fn.wsaction("focus", "group", i))
    hl.bind(vars.kbMoveWinToWsGroup .. " + " .. key, fn.wsaction("move", "group", i))
end

-- Scroll through existing workspaces with SUPER + scroll
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + Page_down", hl.dsp.focus({ workspace = "+1" }), { repeating = true })

-- Special workspace (magic)
hl.bind(vars.kbSpecialWs, hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:special" }))

-- Window groups
hl.bind(vars.kbWindowGroupCycleNext, hl.dsp.window.cycle_next(), { repeating = true })
hl.bind(vars.kbWindowGroupCyclePrev, hl.dsp.window.cycle_next({ next = false }), { repeating = true })
hl.bind("CTRL + ALT + Tab", hl.dsp.group.next(), { repeating = true })
hl.bind("CTRL + SHIFT + ALT + Tab", hl.dsp.group.prev(), { repeating = true })
hl.bind(vars.kbToggleGroup, hl.dsp.group.toggle())
hl.bind(vars.kbUngroup, hl.dsp.window.move({ out_of_group = true }))
local kbLockGroup = hl.version():match("^0%.5[0-6]%.") and hl.dsp.group.lock_active() or hl.dsp.group.lock()
hl.bind("SUPER + SHIFT + Comma", kbLockGroup)

-- Special workspace app toggles & Peek Desktop
hl.bind(vars.kbToggleDesktop or "SUPER + D", fn.toggle_desktop)
hl.bind(vars.kbSystemMonitorWs, fn.toggle_special("sysmon"))
hl.bind(vars.kbMusicWs, fn.toggle_special("music"))
if vars.kbCommunicationWs and vars.kbCommunicationWs ~= "" then
    hl.bind(vars.kbCommunicationWs, fn.toggle_special("communication"))
end
hl.bind(vars.kbTodoWs, fn.toggle_special("todo"))

-- Audio settings
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd(vars.audioSettings))

-- Screen recording
hl.bind("SUPER + ALT + R", fn.record(false, true))
hl.bind("CTRL + ALT + R", fn.record(false, false))
hl.bind("SUPER + SHIFT + ALT + R", fn.record(true, false))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind("SUPER + SHIFT + U", hl.dsp.exec_cmd("hyprctl kill"))

-- Kill/restart rice
hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd(vars.rice .. " kill"), { release = true })
hl.bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd(vars.rice .. " restart"), { release = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("SUPER + SHIFT + M",    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Media player keys (playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioStop",  hl.dsp.exec_cmd("playerctl stop"),        { locked = true })
hl.bind("CTRL + SUPER + Space", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("CTRL + SUPER + Equal", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("CTRL + SUPER + Minus", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Sleep
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd(vars.sleepGestureCmd), { locked = true })

-- Daedalus Optics: Real-time GLSL screen shaders
hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd("shader toggle red"))
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("shader toggle crt"))
hl.bind("CTRL + SUPER + O", hl.dsp.exec_cmd("shader off"))
