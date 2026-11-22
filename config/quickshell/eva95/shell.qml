//@ pragma IconTheme Rice
// Custom icon theme: fallback hicolor only contains basic icons, which leaves tools like kcalc with blank circles
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "bar"
import "buds"
import "cal"
import "charms"
import "clip"
import "deck"
import "glyph"
import "home"
import "launcher"
import "power"
import "prefs"
import "quick"
import "settings"
import "shot"
import "vpn"
import "wall"
import "binds"

// Glyph: Nothing OS-inspired desktop shell. Bento home widgets on wallpaper, auto-hiding status bar, launcher,
// Quick Settings panel, edge Glyph lighting strips instead of OSD popups, dynamic notification island, power menu,
// settings prefs, bottom deck dashboard, clipboard history, charms (emoji & symbols), screenshots, VPN, and wallpapers.
// Lockscreen runs as an independent process (lock.qml).
// Switched via `rice switch <name>` or Rice GUI app — Hyprland global binds (shell:*) map dynamically to the active shell.
ShellRoot {
    id: shell

    Launcher { id: launcher }
    Quick { id: quick; onPowerRequested: power.open(); onSettingsRequested: prefs.open() }
    Power { id: power }
    Prefs { id: prefs; onWallRequested: walls.open() }
    Glyph {}
    Buds {}
    Cal { id: cal }
    Clip { id: clip }
    Charms { id: charms }
    Deck { id: deck }
    Shot { id: shot }
    Vpn { id: vpn }
    Walls { id: walls }
    Binds { id: binds }

    Variants {
        model: Quickshell.screens
        Scope {
            id: s
            required property var modelData
            Back { screen: s.modelData }
            // Bar and Home widgets can be toggled per monitor in Settings -> Display; wallpaper remains intact.
            // Evaluated here in Scope to prevent window recreation loops when monitor properties change.
            Home { screen: s.modelData; visible: Theme.scr(s.modelData.name, "home") }
            HudOverlay { screen: s.modelData }
            Hot { screen: s.modelData; onTriggered: quick.peek() }
            Bar {
                screen: s.modelData
                visible: Theme.scr(s.modelData.name, "bar")
                quickOpen: quick.open
                deckOpen: Sys.deckOpen
                calOpen: cal.open
                onMarkClicked: launcher.toggle()
                onTrayClicked: quick.toggle()
                onPowerClicked: power.visible ? power.close() : power.open()
                onClockClicked: cal.toggle()
            }
        }
    }

    // Hyprland integration: Rules.qml (~/.config/demonshot/rules.json) applies monitor profiles, input settings,
    // cursor animations, night light, and hypridle. Theme.apply applies custom border colors, corner rounding, and kitty theme.
    Component.onCompleted: {
        hypr();
        if (Theme.state.paint) Theme.apps(); // rice start sets symlinks to term/ — restore theme colors
        Rules.night();
        Rules.idle();
    }
    // Re-apply shell styling when Hyprland reloads: editing any Hyprland config file triggers `hyprctl reload`,
    // resetting variables.lua defaults. We re-apply our dynamic theme overrides cleanly on configreloaded events.
    function hypr() {
        Rules.monitor();
        Rules.input();
        Rules.motion();
        Theme.apply();
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "configreloaded") shell.hypr(); }
    }
    // Screen connected/changed: re-apply scale and refresh rate from Settings -> Display (Rules.store.outs)
    Connections {
        target: Quickshell
        function onScreensChanged() { Rules.monitor(true); }
    }
    Connections {
        target: Theme
        function onGreysChanged() { paint.restart(); }
    }
    // Theme or color palette change: re-apply styling to windows, kitty, GTK, and Qt after 300ms debounce
    Timer { id: paint; interval: 300; onTriggered: { Theme.apply(); Theme.apps(); } }
    // Wallpaper color extraction (Theme.pick): quantized directly from the active wallpaper image
    ColorQuantizer {
        source: Theme.url(Theme.wallSrc(Theme.wall))
        depth: 4
        rescaleSize: 64
        onColorsChanged: {
            if (!colors.length) return;
            const t = Theme.pick(colors);
            if (t.join() === Theme.state.tones.join()) return;
            Theme.state.tones = t;
            Theme.state.paintAt = 0;
        }
    }
    Connections {
        target: Theme.state
        function onRoundingChanged() { Theme.apply(); }
    }
    // Ultra mode toggles blur and shadows; Game mode disables heavy compositor animations for lower latency
    Connections {
        target: Rules.store
        function onUltraChanged() { Theme.apply(); }
        function onGameChanged() { Rules.motion(); Theme.apply(); }
    }

    // Tap Super: bottom deck and left bar on key release; any Super+<key> cancels the tap action
    property bool interrupted: false
    Shortcut {
        name: "deckTap"
        description: "Deck dashboard & left bar (tap Super)"
        onReleased: {
            if (!shell.interrupted) deck.toggle();
            shell.interrupted = false;
        }
    }
    Shortcut {
        name: "launcher"
        description: "Tap Super (opens deck and left bar)"
        onReleased: {
            if (!shell.interrupted) deck.toggle();
            shell.interrupted = false;
        }
    }
    Shortcut { name: "launcherArm"; description: "Super press — reset interrupt flag"; onPressed: shell.interrupted = false }
    Shortcut { name: "launcherInterrupt"; description: "Super+<key> — cancel deck tap trigger"; onPressed: shell.interrupted = true }
    // Super+Space: App launcher
    Shortcut { name: "launcherToggle"; description: "App launcher"; onPressed: launcher.toggle() }
    // Deck dashboard
    Shortcut { name: "altar"; description: "Deck dashboard"; onPressed: deck.toggle() }
    Shortcut { name: "quick"; description: "Quick settings"; onPressed: quick.toggle() }
    Shortcut { name: "ward"; description: "Quick settings (secondary bind)"; onPressed: quick.toggle() }
    Shortcut { name: "settings"; description: "Rice settings & preferences"; onPressed: prefs.toggle() }
    Shortcut { name: "power"; description: "Power menu"; onPressed: power.visible ? power.close() : power.open() }
    Shortcut { name: "shot"; description: "Screenshot tool"; onPressed: shot.open() }
    Shortcut { name: "pact"; description: "vpn: clash verge"; onPressed: vpn.toggle() }
    Shortcut { name: "clip"; description: "Clipboard history"; onPressed: clip.toggle() }
    Shortcut { name: "charms"; description: "Emoji, kaomoji, and symbols"; onPressed: charms.toggle() }
    Shortcut { name: "wall"; description: "Wallpaper picker"; onPressed: walls.toggle() }
    Shortcut { name: "binds"; description: "Keybindings helper panel"; onPressed: binds.toggle() }
    Shortcut { name: "game"; description: "Toggle game mode"; onPressed: Rules.store.game = !Rules.store.game }

    component Shortcut: GlobalShortcut { appid: "shell" }
}
