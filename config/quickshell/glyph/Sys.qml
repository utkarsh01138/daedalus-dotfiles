pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.services
import qs.settings

// System services: shared state for the bar, quick settings, Glyph effects, and lockscreen.
// Covers audio, backlight, keyboard layout, recording, night light, airplane mode, caffeine, and VPN.
Singleton {
    id: root

    // Detailed stats polling when deck dashboard is open (same as empty Home workspace)
    property bool deckOpen: false
    // When wallpaper picker is open, wallpaper updates instantly without the wave animation
    property bool wallOpen: false

    // ---- Audio controls via Pipewire ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var mic: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.mic] }
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property bool micOn: !(mic?.audio?.muted ?? true)
    function setVol(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    // Microphone in use indicator (illuminates center dot in bar)
    PwNodeLinkTracker { id: micUse; node: root.mic }
    readonly property bool live: rec || micUse.linkGroups.length > 0

    // ---- Brightness controls via Backlight (brightnessctl) ----
    readonly property real bri: Backlight.value
    readonly property bool hasBri: !!Backlight.dev // false if no backlight device found (desktop monitors)
    function setBri(v) { Backlight.set(v); }
    Binding { target: Backlight; property: "steps"; value: Theme.state.briSteps }

    // ---- Keyboard layout tracking: initializes from hyprctl, updates on activelayout event ----
    property string kbd: ""
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector { onStreamFinished: root.kbd = JSON.parse(this.text).keyboards.find(k => k.main)?.active_keymap ?? "" }
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "activelayout") root.kbd = e.data.slice(e.data.lastIndexOf(",") + 1); }
    }
    readonly property string layout: kbd.slice(0, 2).toLowerCase() // "English (US)" → en

    // ---- Recording and Airplane mode polling (also toggled via Hyprland shortcuts) ----
    property bool rec: false
    readonly property bool night: Rules.store.night
    property bool air: false
    Process {
        id: poll
        command: ["sh", "-c", "pgrep -f '^gpu-screen-recorder' >/dev/null && echo rec; "
                            + "rfkill -rno SOFT | grep -qv '^blocked' || echo air"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.rec = text.includes("rec");
                root.air = text.includes("air");
            }
        }
    }
    Timer { running: true; repeat: true; interval: 3000; triggeredOnStart: true; onTriggered: { poll.running = true; root.queryShader(); } }

    function sh(c) { Quickshell.execDetached(["sh", "-c", c]); }
    // Recording settings from Theme.state (quick/Rec) -> gpu-screen-recorder arguments
    readonly property var recFps: [30, 60, 120]
    function recArgs() {
        const st = Theme.state;
        const a = ["", "default_output", "default_input", "default_output|default_input"][st.recAudio];
        return `-f ${st.recFps} -q ${["medium", "high", "very_high", "ultra"][st.recQuality]} -cursor ${st.recCursor ? "yes" : "no"}` + (a ? ` -a "${a}"` : "");
    }
    // Toggle recording: press again to stop. Slurp handles region selection; canceling selection aborts cleanly
    function toggleRec() {
        const w = Theme.state.recArea ? `-w region -region "$(slurp -f %wx%h+%x+%y)"` : `-w ${Hyprland.focusedMonitor?.name ?? "screen"}`;
        sh(`pkill -INT -f '^gpu-screen-recorder' || exec gpu-screen-recorder ${w} ${recArgs()} -o "$(xdg-user-dir VIDEOS)/rec-$(date +%F_%H-%M-%S).mp4"`);
        rec = !rec;
    }
    function toggleNight() { Rules.store.night = !night; Rules.night(); }
    function toggleAir() { Quickshell.execDetached(["rfkill", air ? "unblock" : "block", "all"]); air = !air; }
    function toggleMic() { if (mic?.audio) mic.audio.muted = !mic.audio.muted; }

    // ---- Nothing / CMF earbuds: ANC modes and battery monitoring via ./ear (RFCOMM protocol) ----
    readonly property var buds: Bluetooth.devices.values.find(d => d.connected && /^(nothing|cmf|ear)\b/i.test(d.name)) ?? null
    property var ear: null // {mode, l, r, case?}
    onBudsChanged: ear = null
    // Query earbud status periodically until connected channel initializes
    Timer { interval: 2000; repeat: true; running: !!root.buds && !root.ear; onTriggered: root.earRun([]) }
    readonly property var ancModes: [[5, "off"], [7, "transp"], [3, "low"], [2, "mid"], [1, "high"], [4, "auto"]]
    property var earNext: null
    function earRun(a) {
        if (!buds) return;
        const c = [Quickshell.shellPath("ear"), buds.address, ...a];
        if (earP.running) earNext = c;
        else { earP.command = c; earP.running = true; }
    }
    function setAnc(m) { ear = Object.assign({}, ear, { mode: m }); earRun(["mode", m]); }
    Process {
        id: earP
        stdout: StdioCollector { onStreamFinished: { try { root.ear = JSON.parse(text); } catch (e) { root.ear = null; } } }
        onExited: if (root.earNext) { command = root.earNext; root.earNext = null; running = true; }
    }

    // ---- Bluetooth auto-reconnect: BlueZ disconnects devices before powering down the adapter.
    // We snapshot connected devices with a brief debounce so re-enabling Bluetooth reconnects previous devices. ----
    readonly property var btOn: Bluetooth.devices.values.filter(d => d.connected).map(d => d.address)
    property var btResume: []
    onBtOnChanged: btKeep.restart()
    Timer { id: btKeep; interval: 500; running: true; onTriggered: if (Bluetooth.defaultAdapter?.enabled && !btResumeT.running) root.btResume = root.btOn }
    Connections {
        target: Bluetooth.defaultAdapter
        function onEnabledChanged() { if (Bluetooth.defaultAdapter.enabled) btResumeT.restart(); else { btKeep.stop(); btResumeT.stop(); } }
    }
    // Allow adapter time to initialize after re-enabling
    Timer { id: btResumeT; interval: 1500; onTriggered: { for (const d of Bluetooth.devices.values) if (root.btResume.includes(d.address) && !d.connected) d.connect(); } }

    // ---- Caffeine (idle inhibitor): maintains an invisible 0x0 surface to keep system awake ----
    property bool caffeine: false
    IdleInhibitor {
        enabled: root.caffeine
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "glyph-caffeine"
            mask: Region {}
        }
    }

    // ---- VPN management: controls Clash Verge via its system tray menu entries ----
    readonly property var verge: SystemTray.items.values.find(i => i.title === "clash-verge" || i.id.includes("clash-verge")) ?? null
    QsMenuOpener { id: vmenu; menu: root.verge?.menu ?? null }
    readonly property var vpnItems: ["System Proxy", "TUN Mode"]
    function vpnItem(l) { return vmenu.children.values.find(e => e.text.startsWith(l)) ?? null; }
    readonly property bool vpn: vpnItems.some(l => vpnItem(l)?.checkState === Qt.Checked)
    property var queue: []
    function toggleVpn() {
        if (!verge) return Quickshell.execDetached(["clash-verge"]); // Launch Clash Verge if not running
        queue = vpn ? vpnItems.filter(l => vpnItem(l)?.checkState === Qt.Checked) : vpnItems;
        presser.start();
    }
    // Clash Verge rebuilds tray menu items after each action; execute sequentially
    Timer {
        id: presser
        interval: 350
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const [l, ...rest] = root.queue;
            root.queue = rest;
            if (l) root.vpnItem(l)?.triggered();
            if (!rest.length) stop();
        }
    }

    // ---- Daedalus Optics: Screen Shaders ----
    property string shader: ""
    function shaderLabel(name) {
        if (!name) return "shader";
        const map = {
            "astronomy-red": "red",
            "crt-scanlines": "crt",
            "grayscale": "mono",
            "bayer-dither": "dither",
            "p31-green": "p31",
            "smart-invert": "invert",
            "paper-mode": "paper",
            "gameboy": "gameboy",
            "true-black": "black",
            "inferno": "inferno",
            "viridis": "viridis",
            "blueprint": "blueprint",
            "theme-quantize": "theme",
            "virtual-boy": "v-boy"
        };
        return map[name] || (name.length > 9 ? name.slice(0, 8) + ".." : name);
    }
    Process {
        id: shaderProc
        stdout: StdioCollector {
            onStreamFinished: root.shader = text.trim()
        }
    }
    readonly property var shaderList: [
        { id: "astronomy-red", label: "Astro Red", desc: "Scotopic night vision", fav: true },
        { id: "crt-scanlines", label: "Retro CRT", desc: "1200p scanlines & vignette", fav: true },
        { id: "blueprint", label: "Blueprint", desc: "Prussian blue cyanotype", fav: true },
        { id: "grayscale", label: "Monochrome", desc: "Pure Rec.709 black & white", fav: true },
        { id: "theme-quantize", label: "Theme Quantize", desc: "Catppuccin Mocha palette", fav: true },
        { id: "true-black", label: "True Black", desc: "Soft-knee zero black floor", fav: true },
        { id: "bayer-dither", label: "1-Bit Dither", desc: "Ordered Bayer matrix", fav: false },
        { id: "p31-green", label: "P31 Phosphor", desc: "Tektronix green oscilloscope", fav: false },
        { id: "smart-invert", label: "Smart Invert", desc: "Hue-preserving dark mode", fav: false },
        { id: "paper-mode", label: "E-Ink Paper", desc: "88% desat matte texture", fav: false },
        { id: "gameboy", label: "Game Boy", desc: "1989 DMG-01 olive LCD", fav: false },
        { id: "inferno", label: "Inferno", desc: "Astro false-color heat map", fav: false },
        { id: "viridis", label: "Viridis", desc: "Perceptually uniform colormap", fav: false },
        { id: "virtual-boy", label: "Virtual Boy", desc: "1995 4-level crimson LED", fav: false }
    ]

    function setShader(name) {
        if (!name || name === "off" || name === "none") {
            clearShader();
            return;
        }
        if (!shaderProc.running) {
            shaderProc.command = [Quickshell.env("HOME") + "/.local/bin/shader", name, "--short"];
            shaderProc.running = true;
        }
    }
    function cycleShader() {
        if (!shaderProc.running) {
            shaderProc.command = [Quickshell.env("HOME") + "/.local/bin/shader", "cycle", "--short"];
            shaderProc.running = true;
        }
    }
    function clearShader() {
        if (!shaderProc.running) {
            shaderProc.command = [Quickshell.env("HOME") + "/.local/bin/shader", "off", "--short"];
            shaderProc.running = true;
        }
    }
    function queryShader() {
        if (!shaderProc.running) {
            shaderProc.command = [Quickshell.env("HOME") + "/.local/bin/shader", "current"];
            shaderProc.running = true;
        }
    }
    Component.onCompleted: root.queryShader()
}
