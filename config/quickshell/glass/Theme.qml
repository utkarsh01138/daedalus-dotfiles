pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.settings
import "schemes.js" as Schemes

// Profile 4: glass — Liquid Frosted Acrylic (The Creative Studio).
// macOS and visionOS translucent material depth with continuous squircle rounding and specular reflections.
Singleton {
    id: root

    readonly property alias state: st
    readonly property var pal: make({})
    readonly property bool light: pal.light

    // Exact tokens from Section 5.5: Profile 4: glass
    readonly property color bg: Qt.rgba(13 / 255, 16 / 255, 23 / 255, 0.92) // Smoky deep obsidian acrylic base
    readonly property color card: Qt.rgba(1, 1, 1, 0.08)                     // Elevated floating frosted card surface
    readonly property color specular: Qt.rgba(1, 1, 1, 0.22)                 // Top-edge specular white light refraction hairline
    readonly property color cyan: "#70C0D0"                                  // Icy glacial glow (active focus highlight)
    readonly property color lavender: "#B48EAD"                              // Luminous soft neon purple (media & secondary tags)
    readonly property color fg: "#FFFFFF"                                    // Optical white with soft drop-shadow
    readonly property color sub: "#C0CCE0"                                   // High-legibility frosted secondary text

    // QuickShell component mapping roles: deep obsidian acrylic guarantees high contrast & legibility
    readonly property color s1: Qt.rgba(18 / 255, 22 / 255, 32 / 255, 0.94) // Major panels (Prefs, Clip, Cal, Charms)
    readonly property color s2: Qt.rgba(30 / 255, 38 / 255, 54 / 255, 0.90) // Secondary surfaces & tiles
    readonly property color s3: Qt.rgba(255, 255, 255, 0.16)                 // Specular borders, dividers
    readonly property color mute: "#6B7B9E"                                  // Subdued metadata & inactive icons
    readonly property color grey: "#A3B1CC"                                  // Frosted secondary labels
    readonly property color ink: "#0D1017"                                   // Dark text on bright active pills
    readonly property color accent: cyan                                     // Primary interactive accent
    readonly property color red: "#FF5C5C"                                   // macOS window close red / critical alerts
    readonly property color yellow: "#FFBD2E"                                // macOS window minimize yellow
    readonly property color green: "#27C93F"                                 // macOS window maximize green
    readonly property color glow: Qt.rgba(112 / 255, 192 / 255, 208 / 255, 0.40)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.45)

    // Typography hierarchy
    readonly property string title: "Inter Display"
    readonly property string ui: "Inter"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string nf: "JetBrainsMono Nerd Font"
    readonly property string dot: "Inter Display"

    readonly property real s: {
        const sc = Quickshell.screens[0];
        return sc ? Math.min(sc.width / 1920, sc.height / 1080) : 1;
    }

    function sid(name) {
        const m = Quickshell.screens.find(s => s.name === name)?.model.trim();
        return m && Quickshell.screens.filter(s => s.model.trim() === m).length === 1 ? m : name;
    }
    function own(name) { return st.screens[sid(name)] ?? st.screens[name]; }
    function scr(name, key) { return own(name)?.[key] ?? { wall: st.wall, widgets: st.widgets }[key] ?? true; }
    function setScr(name, key, v) {
        const o = Object.assign({}, own(name)), all = Object.assign({}, st.screens);
        if (v === undefined) delete o[key];
        else o[key] = v;
        all[sid(name)] = o;
        st.screens = all;
    }

    // Smooth spring curve (bezier = macosSpring, 0.16, 1, 0.3, 1)
    readonly property var glide: [0.16, 1, 0.3, 1]
    readonly property int t: 300

    readonly property string wallCache: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/glyph/walls"
    function wallSrc(p) { return p ? `${wallCache}/${p.slice(p.lastIndexOf("/") + 1)}.jpg` : ""; }
    function url(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : ""; }

    readonly property string wall: scr(Quickshell.screens[0]?.name, "wall")
    readonly property var tones: wall ? st.tones : []
    function hueName(c) {
        const h = Qt.color(c).hslHue * 360;
        return ["red", "orange", "yellow", "green", "teal", "blue", "violet", "pink", "red"][[15, 40, 65, 160, 195, 250, 290, 335, 361].findIndex(x => h < x)];
    }

    readonly property var glassDark: ["#0D1017", "#161B26", "#212838", "#2E384D", "#4B5B7D", "#A3B1CC", "#FFFFFF"]
    readonly property var glassAnsi: ["#0D1017", "#FF5C5C", "#A3BE8C", "#EBCB8B", "#70C0D0", "#B48EAD", "#88C0D0", "#E5E9F0",
                                      "#3E4961", "#FF6E6E", "#B1D199", "#F0D399", "#81D0DF", "#C69FBF", "#97D4E3", "#FFFFFF"]

    function make(o) {
        const k = Object.assign({ paint: st.paint, scheme: st.scheme, at: st.paintAt, variant: st.variant, light: st.light }, o);
        if (k.paint === "scheme") return Schemes.ALL.find(p => p.id === k.scheme) ?? Schemes.ALL[0];
        const base = { light: false, c: glassDark, accent: cyan, red: "#FF5C5C", ansi: glassAnsi };
        const src = tones[Math.min(k.at, tones.length - 1)];
        return k.paint === "wall" && src ? Schemes.dynamic(src, k.variant, base) : base;
    }

    function pair(l) { return null; }
    function setLight(l) { st.light = false; }

    readonly property var styles: []

    function lum(c) { c = Qt.lighter(c, 1); const f = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b); }
    function on(c) { return lum(c) > 0.18 ? "#000000" : "#FFFFFF"; }
    function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    function corner(px) { return Math.round(px * st.corners / 100); }
    function hh(d) { const h = d.getHours(); return st.clock24 ? String(h).padStart(2, "0") : String(h % 12 || 12); }
    function hex(c) { return c.toString().slice(1, 7).toUpperCase(); }

    readonly property string riceState: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/rice"
    Component.onCompleted: stateFile.waitForJob()

    FileView {
        id: stateFile
        path: root.riceState + "/glass.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: Qt.callLater(stateFile.writeAdapter)
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: st
            property bool light: false
            property string paint: ""
            property string scheme: "mocha"
            property int paintAt: 0
            property var tones: []
            property string variant: "tonalspot"
            property bool dnd: false
            property int unread: 0
            property var widgets: ["weather", "calendar", "cpu", "player", "buds", "system"]
            property bool clock24: false
            property bool blink: false
            property string name: ""
            property bool grid: false
            property bool orb: false
            property string wall: ""
            property string wallDir: ""
            property int wallLook: 2
            property int wallPitch: 10
            property int wallBright: 90
            property string gif: ""
            property string gifDir: ""
            property int rounding: 18       // Section 5.5: rounding = 18px
            property int corners: 100
            property bool edges: false
            property int briSteps: 20
            property bool quickHover: false
            property bool deckHover: false  // Deck triggered via Super key; bottom hover dedicated to autohiding Dock
            property var deck: ["clock", "weather", "perf", "net", "media"]
            property var bar: ["layout", "wifi", "bluetooth", "sound", "notes", "battery", "mode", "power"]
            property bool barTitle: true
            property string barAt: "top"
            property var screens: ({})
            property int recArea: 0
            property int recAudio: 0
            property int recFps: 60
            property int recQuality: 2
            property bool recCursor: true
            property bool vpnPortal: false
            property bool anemoi: false
            property string anemoiMode: "auto"
            property int anemoiSeasonIndex: 0
            property bool anemoiManualTime: false
            property real anemoiTimeHour: 12.0
            property int anemoiDensity: 100
            property int anemoiSpeed: 100
            property bool anemoiInteractive: false
            property var hotCorners: ({ topLeft: "none", topRight: "quick", bottomLeft: "missioncontrol", bottomRight: "quicknote" })
        }
    }

    readonly property var kinds: ({ weather: 1, calendar: 1, cpu: 1, ram: 1, gpu: 1, disk: 1, battery: 1, buds: 1, player: 2, system: 3, cat: 1, cava: 1 })
    readonly property var decks: ["clock", "weather", "perf", "net", "media"]
    readonly property var bars: ["layout", "wifi", "bluetooth", "sound", "notes", "battery", "mode", "power", "cat"]

    function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", lua]); }

    FileView { id: kitty; path: Quickshell.env("HOME") + "/.config/demonshot/kitty.conf"; printErrors: false }

    function apply() {
        const r = Rules.store, g = r.game;
        const activeBorder = '"rgba(ffffff55)"';
        const inactiveBorder = '"rgba(ffffff14)"';

        // Section 5.5 Specifications & Fluid Animations
        hypr(`hl.curve("macosSpring", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } }); `
           + `hl.curve("fluid", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } }); `
           + `hl.curve("appleEase", { type = "bezier", points = { { 0.25, 1.0 }, { 0.5, 1.0 } } }); `
           + `hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "appleEase" }); `
           + `hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.5, bezier = "fluid", style = "popin 88%" }); `
           + `hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.5, bezier = "appleEase", style = "popin 90%" }); `
           + `hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.5, bezier = "fluid" }); `
           + `hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "appleEase", style = "slidefade 20%" }); `
           + `hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.5, bezier = "fluid", style = "slidefadevert 15%" }); `
           + `hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "appleEase", style = "popin 90%" }); `
           + `hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "appleEase", style = "popin 90%" }); `
           + `hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "appleEase" }); `
           + `hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "appleEase" }); `
           + `hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "appleEase" }); `
           + `hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "appleEase" }); `
           + `hl.window_rule({ match = { class = "kitty" }, opacity = "0.82 0.72 override" }); `
           + `hl.window_rule({ match = { class = "agy-term" }, opacity = "0.85 0.75 override" }); `
           + `hl.layer_rule({ match = { namespace = "glass-(launcher|quick|deck|notifs|bar|dock|osd|battery|island|note|mission|corners)" }, no_anim = true }); `
           + `hl.config({ general = { gaps_in = ${g ? 0 : 8}, gaps_out = ${g ? 0 : 10}, border_size = 1, allow_tearing = ${g}, `
           + `col = { active_border = ${activeBorder}, inactive_border = ${inactiveBorder} } }, `
           + `decoration = { rounding = ${g ? 0 : 18}, active_opacity = 0.85, inactive_opacity = 0.75, `
           + `blur = { enabled = true, passes = 4, size = 7, noise = 0.02, contrast = 0.95, brightness = 1.05 }, `
           + `shadow = { enabled = true, range = 32, render_power = 3, color = "rgba(00000055)" } }, `
           + `group = { col = { border_active = ${activeBorder}, border_inactive = ${inactiveBorder}, border_locked_active = ${activeBorder}, border_locked_inactive = ${inactiveBorder} }, `
           + `groupbar = { font_family = "${ui}", text_color = "rgb(FFFFFF)", col = { active = "rgba(255,255,255,0.18)", inactive = "rgba(255,255,255,0.06)", locked_active = "rgba(255,255,255,0.18)", locked_inactive = "rgba(255,255,255,0.06)" } } }, `
           + `misc = { background_color = "rgb(0D1017)" } })`);

        // Valid kitty configuration using standard hex tokens and fluid cursor trail motion
        kitty.setText("# glass: generated by Theme.apply() — do not edit manually\n"
           + "font_family JetBrains Mono\n"
           + "font_size 12.0\n"
           + "window_padding_width 22 26\n"
           + "background_opacity 0.80\n"
           + "dynamic_background_opacity yes\n"
           + "cursor_trail 4\n"
           + "cursor_trail_decay 0.1 0.4\n"
           + "cursor_trail_start_threshold 2\n"
           + "foreground #FFFFFF\n"
           + "background #0D1017\n"
           + "cursor #70C0D0\n"
           + "cursor_text_color #0D1017\n"
           + "selection_foreground #FFFFFF\n"
           + "selection_background #38495E\n"
           + "url_color #70C0D0\n"
           + "active_border_color #70C0D0\n"
           + "inactive_border_color #1A1E29\n"
           + "active_tab_foreground #0D1017\n"
           + "active_tab_background #70C0D0\n"
           + "inactive_tab_foreground #A3B1CC\n"
           + "inactive_tab_background #161B26\n"
           + "tab_bar_background #0D1017\n"
           + glassAnsi.map((c, i) => `color${i} ${c}`).join("\n") + "\n");
        Quickshell.execDetached(["pkill", "-USR1", "-x", "kitty"]);
    }

    function apps() {
        Quickshell.execDetached(["bash", "-c", `t=$1 o=$2; shift 2
for f in gtk-3.0/gtk.css gtk-4.0/gtk.css qtengine.colors; do
    l=$HOME/.config/$f
    [ -L "$l" ] || [ ! -e "$l" ] || continue
    if [ -f "$t/$f" ]; then mkdir -p "$(dirname "$o/$f")" && cp "$t/$f" "$o/$f" && ln -sfn "$o/$f" "$l"; fi
done`,
            "bash", Quickshell.shellPath("term"), riceState + "/glass"]);
    }
}
