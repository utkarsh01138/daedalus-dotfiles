local scheme = require("scheme.demonshot")
local home   = os.getenv("HOME")

-- DEMONSHOT_NESTED=1 Hyprland -c …/rice/config/hypr/hyprland.lua — nested session for debugging:
-- system daemons are already running in the outer host session
local nested = os.getenv("DEMONSHOT_NESTED") ~= nil
-- The active quickshell theme (demonshot, glyph, etc.) is managed by `rice`: via `rice switch <name>` or Rice app.
-- Full path required because ~/.local/bin is not in Hyprland's PATH
local rice   = home .. "/.config/quickshell/rice/rice"

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    nested                     = nested,

    -- Shell
    rice                       = rice,
    lockCmd                    = rice .. " lock", -- Lockscreen for the active shell (prevents duplicate instances)

    -- Apps
    terminal                   = "kitty",
    browser                    = "chromium",
    fileExplorer               = "thunar",
    audioSettings              = "pavucontrol",
    notion                     = "chromium --app=https://notion.so",
    musicPlayer                = "TBA",
    -- Programs for special workspaces (launched if the workspace is empty) and default editor.
    -- Keybinds read these at press time, so override in user.lua: require("variables").apps.editor = "codium"
    -- If not installed, toggling will open an empty special workspace.
    apps                       = {
        editor        = "code",
        sysmon        = "kitty --class btop -T btop btop",
        music         = "TBA",
        communication = "Telegram",
        agy           = "kitty --class agy-term -e /home/utki/.local/bin/agy",
    },

    -- Touchpad
    touchpadDisableTyping      = false,
    touchpadScrollFactor       = 0.3,
    gestureFingers             = 4,
    workspaceSwipeFingers      = 3,
    gestureFingersMore         = 5,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 8,
    blurPasses                 = 2,
    blurXray                   = false,

    -- Shadow
    -- Subtle crimson glow around active focused window
    shadowEnabled              = true,
    shadowRange                = 10,
    shadowRenderPower          = 4,
    shadowColour               = "rgba(" .. scheme.crimson .. "20)",

    -- Gaps
    workspaceGaps              = 15,
    windowGapsIn               = 6,
    windowGapsOut              = 14,

    -- Window styling
    windowOpacity              = 1,
    windowRounding             = 0,
    windowBorderSize           = 2,
    activeWindowBorderColour   = {
        colors = { "rgb(" .. scheme.crimson .. ")", "rgb(" .. scheme.rose .. ")", "rgb(" .. scheme.crimson .. ")" },
        angle = 135,
    },
    inactiveWindowBorderColour = "rgb(" .. scheme.wine .. ")",

    -- Misc
    volumeStep                 = 5,
    volumeMax                  = 100,
    cursorTheme                = "Bibata-Modern-Classic",
    cursorSize                 = 20,
    sleepGestureCmd            = "systemctl suspend-then-hibernate || systemctl suspend", -- Fallback to suspend if hibernation is unavailable

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Workspaces
    kbMoveWinToWs              = "SUPER + SHIFT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + SHIFT",
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",
    kbNextWs                   = "CTRL + SUPER + Right",
    kbPrevWs                   = "CTRL + SUPER + Left",

    -- Window Group
    kbWindowGroupCycleNext     = "ALT + TAB",
    kbWindowGroupCyclePrev     = "SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + U",
    kbToggleGroup              = "SUPER + Comma",

    -- Window Action
    kbMoveWindow               = "SUPER + Z",
    kbResizeWindow             = "SUPER + X",
    kbWindowPip                = "SUPER + ALT + backslash",
    kbPinWindow                = "SUPER + SHIFT + P",
    kbWindowFullscreen         = "SUPER + F",
    kbWindowBorderedFullscreen = "SUPER + SHIFT + F",
    kbToggleWindowFloating     = "SUPER + SHIFT + T",
    kbCloseWindow              = "SUPER + Q",

    -- Special workspaces toggles
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + ALT + M",
    kbToggleDesktop            = "SUPER + D",
    kbCommunicationWs          = "",
    kbTodoWs                   = "SUPER + R",
    kbAgy                      = "SUPER + G",

    -- Apps
    kbTerminal                 = "SUPER + T",
    kbBrowser                  = "SUPER + B",
    kbEditor                   = "SUPER + C",
    kbFileExplorer             = "SUPER + E",

    -- Misc
    kbSession                  = "CTRL + ALT + Delete",
    kbPower                    = "SUPER + SHIFT + Q",
    kbLauncher                 = "SUPER + Space",
    kbAltar                    = "SUPER",
    kbLock                     = "SUPER + L",
    kbRestoreLock              = "SUPER + ALT + L",
}
