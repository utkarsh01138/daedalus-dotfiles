//@ pragma IconTheme Rice
// Custom icon theme: fallback hicolor only contains basic icons
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "bar"
import "buds"
import "cal"
import "charms"
import "clip"
import "deck"
import "dock"
import "glyph"
import "home"
import "launcher"
import "osd"
import "power"
import "prefs"
import "quick"
import "settings"
import "shot"
import "vpn"
import "wall"
import "binds"
import "battery"

// Profile 4: glass — Liquid Frosted Acrylic (The Creative Studio).
// Brings high-end macOS and visionOS material depth to bare-metal Wayland.
// Features floating top menu bar, bottom parabolic dock, Spotlight search,
// modular Control Center, and dynamic specular cursor glow.
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
    Osd { id: osd }
    Shot { id: shot }
    Vpn { id: vpn }
    Walls { id: walls }
    Binds { id: binds }
    Battery { id: batteryPanel; onSettingsRequested: prefs.open() }

    Variants {
        model: Quickshell.screens
        Scope {
            id: s
            required property var modelData
            Back { screen: s.modelData }
            Home { screen: s.modelData; visible: Theme.scr(s.modelData.name, "home") }
            Hot { screen: s.modelData; onTriggered: quick.peek() }

            Bar {
                screen: s.modelData
                visible: Theme.scr(s.modelData.name, "bar")
                quickOpen: quick.open
                deckOpen: Sys.deckOpen
                calOpen: cal.open
                onWifiClicked: quick.openWith("wifi")
                onBluetoothClicked: quick.openWith("bt")
                onBatteryClicked: batteryPanel.toggle()
                onMarkClicked: launcher.toggle()
                onTrayClicked: quick.toggle()
                onPowerClicked: prefs.open()
                onClockClicked: cal.toggle()
                onDeckClicked: deck.toggle()
                onClipClicked: clip.toggle()
                onCharmsClicked: charms.toggle()
                onBindsClicked: binds.toggle()
                onWallsClicked: walls.toggle()
            }

            Dock {
                screen: s.modelData
                onLauncherRequested: launcher.toggle()
                onQuickRequested: quick.toggle()
                onSettingsRequested: prefs.open()
            }
        }
    }

    Component.onCompleted: {
        hypr();
        if (Theme.state.paint) Theme.apps();
        Rules.night();
        Rules.idle();
    }

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

    Connections {
        target: Quickshell
        function onScreensChanged() { Rules.monitor(true); }
    }


    Timer { id: paint; interval: 300; onTriggered: { Theme.apply(); Theme.apps(); } }

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

    Connections {
        target: Rules.store
        function onUltraChanged() { Theme.apply(); }
        function onGameChanged() { Rules.motion(); Theme.apply(); }
    }

    // Tap Super: Deck dashboard
    property bool interrupted: false
    Shortcut {
        name: "deckTap"
        description: "Deck dashboard (tap Super)"
        onReleased: {
            if (!shell.interrupted) deck.toggle();
            shell.interrupted = false;
        }
    }
    Shortcut {
        name: "launcher"
        description: "Tap Super (Deck dashboard)"
        onReleased: {
            if (!shell.interrupted) deck.toggle();
            shell.interrupted = false;
        }
    }
    Shortcut { name: "launcherArm"; description: "Super press — reset interrupt flag"; onPressed: shell.interrupted = false }
    Shortcut { name: "launcherInterrupt"; description: "Super+<key> — cancel deck tap trigger"; onPressed: shell.interrupted = true }

    // Super+Space: Spotlight Launcher
    Shortcut { name: "launcherToggle"; description: "Spotlight launcher"; onPressed: launcher.toggle() }
    // Super+A: Control Center
    Shortcut { name: "quick"; description: "Control Center"; onPressed: quick.toggle() }
    Shortcut { name: "ward"; description: "Control Center (secondary)"; onPressed: quick.toggle() }
    // Super+D: Deck dashboard
    Shortcut { name: "altar"; description: "Deck dashboard"; onPressed: deck.toggle() }
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
