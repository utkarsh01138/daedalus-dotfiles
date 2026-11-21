pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.settings
import "schemes.js" as Schemes

// Glyph theme engine: pure black, white dot matrices, single red accent.
// Manages palettes, typography, motion curves, persistent state (theme, DND, etc.), and Hyprland/kitty styling
Singleton {
    id: root

    // Persistent state survives restart and is read by lockscreen daemon (separate process)
    readonly property alias state: st
    // Color source architecture (Launcher -> style, Settings -> STYLE), conceptually similar to Caelestia scheme picker:
    //   - 'nothing': monochrome dark/light with Nothing Red accent
    //   - 'wall': dynamic palette generated from wallpaper dominant tones using selected variant (tonal spot, fruit salad, etc. — schemes.js)
    //   - 'scheme': predefined palette preset with its own dark/light definition
    // Palette structure: { light, c: greys by role, accent, red, ansi: 16 terminal colors }
    readonly property var pal: make({})
    readonly property bool light: pal.light

    // NERV Tactical Command Palettes
    // GeoFront Tactical Bunker (Dark Mode): #060608 base, #121216 panel, #E51D24 Evangelion Blood Red, #FF3B43 bright red
    readonly property var nervDark: ["#060608", "#121216", "#202028", "#32323E", "#787884", "#D8D8DC", "#E51D24"]
    // NERV Scientific Laboratory Dossier (Light Mode): #F0EFEA base, #E4E3DD card, #0B4F8A cobalt, #CC1824 seal
    readonly property var nervLight: ["#F0EFEA", "#E4E3DD", "#D8D7CE", "#C8C7C0", "#767570", "#111214", "#CC1824"]
    readonly property var greys: pal.c
    readonly property color bg: greys[0]   // Root background, tactical bunker black
    readonly property color s1: greys[1]   // Bar, panels, major diagnostic cards
    readonly property color s2: greys[2]   // Secondary surfaces, telemetry tiles
    readonly property color s3: greys[3]   // Dividers, coordinate lines
    readonly property color mute: greys[4] // Inactive / dimmed telemetry
    readonly property color grey: greys[5] // Secondary metadata text, technical labels
    readonly property color fg: greys[6]   // Primary tactical telemetry (Evangelion Blood Crimson #E51D24)
    readonly property color ink: light ? s1 : bg // Text on high-contrast active tiles
    readonly property color accent: pal.accent // Evangelion Blood Crimson (#E51D24)
    readonly property color red: pal.red       // Critical Alert Crimson (#E51D24)
    readonly property color line: s3       // Border & coordinate hairline
    readonly property color amber: "#E51D24" // Overridden to Crimson
    readonly property color bloodRed: "#E51D24"
    readonly property color crimson: "#E51D24"
    readonly property color hazard: "#FF3B43"
    readonly property color cyan: "#00E5FF"
    readonly property color chalk: "#EAEAEB"
    readonly property color glow: light ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(0.9, 0.11, 0.14, 0.5)
    readonly property color scrim: fade(bg, light ? 0.8 : 0.82)

    readonly property string dot: "FOT-Matisse Pro"        // Evangelion Matisse Pro title & number font
    readonly property string eva: "FOT-Matisse Pro"        // Evangelion Matisse font alias
    readonly property string ui: "Space Grotesk"
    readonly property string mono: "Space Mono"            // Uppercase technical labels and code
    readonly property string nf: "JetBrainsMono Nerd Font" // System and UI icons

    // Canvas layout coordinate scale from 1920x1080 design baseline to current screen.
    // Scaled to primary monitor; secondary monitors preserve identical widget scale via Hyprland, with home bento right-aligned
    readonly property real s: {
        const sc = Quickshell.screens[0];
        return sc ? Math.min(sc.width / 1920, sc.height / 1080) : 1;
    }
    // Per-monitor persistent state in state.screens keyed by monitor hardware model:
    // targets physical display regardless of connection port or docking station.
    // Duplicate models or monitors without EDID model string fall back to port connector name (matching hyprctl Rules.key)
    function sid(name) {
        const m = Quickshell.screens.find(s => s.name === name)?.model.trim();
        return m && Quickshell.screens.filter(s => s.model.trim() === m).length === 1 ? m : name;
    }
    // Fall back to connector name for legacy configs (pre-EDID) or single-display duplicate models
    function own(name) { return st.screens[sid(name)] ?? st.screens[name]; }
    // Query monitor-specific configuration by connector name; defaults to global settings (bar and home enabled by default)
    function scr(name, key) { return own(name)?.[key] ?? { wall: st.wall, widgets: st.widgets }[key] ?? true; }
    // 'undefined' clears override, reverting display to global default.
    // Port-based overrides are cloned under model key to maintain consistency across re-plugs
    function setScr(name, key, v) {
        const o = Object.assign({}, own(name)), all = Object.assign({}, st.screens);
        if (v === undefined) delete o[key];
        else o[key] = v;
        all[sid(name)] = o;
        st.screens = all;
    }

    // Ease-out-quart glide curve without overshoot — mirrors Hyprland bezier glide curve
    readonly property var glide: [0.25, 1, 0.5, 1, 1, 1]
    readonly property int t: 350

    // Wallpapers are rendered from cached screen-resolution JPEG copies generated by picker (via ImageMagick);
    // original high-res PNG files (often 40MB+) would introduce multi-second frame stutter.
    // If cache is missing (e.g. wiped cache or manually entered path), displays grid and orb until picker is opened
    readonly property string wallCache: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/glyph/walls"
    function wallSrc(p) { return p ? `${wallCache}/${p.slice(p.lastIndexOf("/") + 1)}.jpg` : ""; }
    function url(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : ""; }

    // ---- Wallpaper palette tones: up to 4 swatches extracted by quantizer (similar to Android Material You).
    // Cached in glyph.json so lockscreen daemon starts with active colors without flashing red default ----
    // Dominant wallpaper source: primary monitor's wallpaper (screen-specific or global)
    readonly property string wall: scr(Quickshell.screens[0]?.name, "wall")
    readonly property var tones: wall ? st.tones : []
    function hueName(c) {
        const h = Qt.color(c).hslHue * 360;
        return ["red", "orange", "yellow", "green", "teal", "blue", "violet", "pink", "red"][[15, 40, 65, 160, 195, 250, 290, 335, 361].findIndex(x => h < x)];
    }
    // Generates a preview palette for state overrides 'o' ({ paint, scheme, at, variant, light }):
    // active shell evaluates with empty overrides; STYLE section uses overrides to preview unselected swatches.
    // If no tones are extracted (grayscale wallpaper or absent image), falls back to Nothing preset
    function make(o) {
        const k = Object.assign({ paint: st.paint, scheme: st.scheme, at: st.paintAt, variant: st.variant, light: st.light }, o);
        if (k.paint === "scheme") return Schemes.ALL.find(p => p.id === k.scheme) ?? Schemes.ALL[0];
        // 16 ANSI colors for NERV: Blood Crimson, Dark Red, Muted Violet, White
        const nervAnsi = ["#121216", "#E51D24", "#FF3B43", "#FF8C00", "#00E5FF", "#B00010", "#9B111E", "#EAEAEB",
                          "#26262E", "#FF5259", "#FF6B6B", "#FFA52E", "#38E1FF", "#D90429", "#BA181B", "#FFFFFF"];
        const base = { light: k.light, c: k.light ? nervLight : nervDark, accent: k.light ? "#CC1824" : "#E51D24", red: "#E51D24",
                       ansi: k.light ? [15, 1, 2, 3, 4, 5, 6, 8, 7, 9, 10, 11, 12, 13, 14, 0].map(i => nervAnsi[i]) : nervAnsi };
        const src = tones[Math.min(k.at, tones.length - 1)];
        return k.paint === "wall" && src ? Schemes.dynamic(src, k.variant, base) : base;
    }
    // Dark/light theme pairing: preset switches between dark and light counterparts within the same theme family
    // (e.g., Catppuccin Mocha <-> Latte, Rosé Pine Dawn <-> Main). Presets without pairs (Nord, Dracula) remain unchanged
    // to prevent st.light desynchronization
    function pair(l) { return st.paint !== "scheme" ? null : pal.light === l ? pal : Schemes.ALL.find(x => x.group === pal.group && x.light === l) ?? null; }
    function setLight(l) {
        const p = pair(l);
        if (st.paint === "scheme" && !p) return;
        if (p) st.scheme = p.id;
        st.light = l;
    }
    // Preset model definitions for launcher (style) and settings (STYLE):
    // blocks: { head, items: [{ name, pal, fill, dot, now, run }] }
    // Structure: color source selector, source-specific sub-options (tones/variants or palette groups), and dark/light toggle
    readonly property var styles: {
        const set = (k, v) => () => st[k] = v, at = Math.min(st.paintAt, tones.length - 1);
        const it = (name, p, now, run, fill) => ({ name, pal: p, fill: fill ?? p.c[1], dot: p.accent, now, run });
        const own = st.paint === "wall" ? [
            { head: "tones", items: tones.map((t, i) => it(hueName(t), make({ at: i }), at === i, set("paintAt", i), t)) },
            // Fill uses variant's mute grey (demonstrates tint cast on neutral surfaces); inner dot represents accent; amount is color intensity
            { head: "variant", items: tones.length ? Schemes.VARIANTS.map((v, i) => {
                const p = make({ variant: v.id });
                return Object.assign(it(v.name, p, st.variant === v.id, set("variant", v.id), p.c[4]), { amount: i / (Schemes.VARIANTS.length - 1) });
            }) : [] }
        ] : st.paint === "scheme" ? Schemes.GROUPS.map(g => ({ head: g, items: Schemes.ALL.filter(p => p.group === g).map(p =>
            Object.assign(it(p.name, p, st.scheme === p.id, () => { st.scheme = p.id; st.light = p.light; }), { extra: g })) })) : [];
        return [{ head: "source", items: [
            it("nerv", make({ paint: "" }), !st.paint || st.paint === "wall" && !tones.length, set("paint", ""), amber),
            it("wallpaper", make({ paint: "wall" }), st.paint === "wall" && !!tones.length, set("paint", "wall"), tones[0]),
            it("palette", make({ paint: "scheme" }), st.paint === "scheme", set("paint", "scheme"))
        ] }].concat(own.filter(b => b.items.length), [
            { head: "theme", items: [["dark", false], ["light", true]].map(([n, l]) => it(n, make({ light: l, scheme: pair(l)?.id ?? st.scheme }),
                light === l, () => setLight(l))) }
        ]);
    }
    // Dominant color extraction inspired by Material You: quantizer samples image into 16 equal-area sectors
    // and computes average color for each. Filters for vibrant candidates (chroma max - min > 0.12 to ignore muted/faded backgrounds);
    // ranks candidates by cluster frequency (+-15 deg hue) and saturation. Selects up to 4 distinct hues separated by at least 30 deg.
    // Falls back to Nothing Red if no vibrant tones are found. Invoked by quantizer in shell.qml
    function pick(cols) {
        const ch = c => c.hsvSaturation * c.hsvValue, d = (a, b) => Math.abs((a.hsvHue - b.hsvHue + 1.5) % 1 - 0.5);
        const all = Array.from(cols), live = all.filter(c => ch(c) > 0.12);
        const score = c => 0.7 * live.filter(o => d(o, c) < 1 / 24).length / all.length + 0.3 * ch(c);
        const out = [];
        for (const c of live.sort((a, b) => score(b) - score(a)))
            if (out.length < 4 && out.every(o => d(o, c) >= 1 / 12)) out.push(c);
        return out.map(c => c.toString());
    }
    // Relative luminance calculation adhering to WCAG standards
    function lum(c) { c = Qt.lighter(c, 1); const f = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b); }
    // Contrast foreground color selection over background 'c': black or white depending on WCAG 0.18 luminance threshold
    function on(c) { return lum(c) > 0.18 ? "#000000" : "#FFFFFF"; }

    function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    // Corner radius calculation for panels, cards, and pills scaled by 'corners' preference (0 = sharp square, 100 = full round)
    function corner(px) { return px * st.corners / 100; }
    // Format hour according to 12/24h preference: padded "09" vs "9"
    function hh(d) { const h = d.getHours(); return st.clock24 ? String(h).padStart(2, "0") : String(h % 12 || 12); }
    function hex(c) { return c.toString().slice(1, 7).toUpperCase(); }

    readonly property string riceState: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/rice"
    // Synchronize glyph.json before applying settings on startup to ensure Theme.apply reads saved state rather than defaults
    Component.onCompleted: stateFile.waitForJob()

    FileView {
        id: stateFile
        path: root.riceState + "/nerv.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        // Debounce state writes to end of event loop to prevent concurrent property updates from conflicting
        onAdapterUpdated: Qt.callLater(stateFile.writeAdapter)
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: st
            property bool light: false
            property string paint: ""     // Color source: empty = Nothing preset, "wall" = wallpaper tones, "scheme" = palette preset
            property string scheme: "mocha" // Palette preset identifier from schemes.js
            property int paintAt: 0       // Selected wallpaper tone index
            property var tones: []        // Extracted wallpaper tone hex colors written by quantizer; empty for grayscale/missing wallpaper
            property string variant: "tonalspot" // Material color scheme variant from schemes.js (VARIANTS)
            property bool dnd: false  // Do Not Disturb mode: suppresses non-critical notification popups
            property int unread: 0    // Unread notification count for lockscreen
            // ---- User Preferences (configured via Prefs.qml) ----
            property var widgets: ["weather", "calendar", "cpu", "player", "buds", "system"] // Home bento widget layout order (see kinds)
            property bool clock24: true
            property bool blink: true      // Blinking colon indicator on clock displays
            property string name: ""       // Custom display name in home greeting; defaults to $USER if blank
            property bool grid: false      // Dotted canvas background grid on desktop (off for NERV wallpaper)
            property bool orb: false       // Half-tone decorative sphere (off for NERV wallpaper)
            // Wallpaper configuration: path to image; empty shows dot grid and orb. Custom wallpaper directory configurable below
            property string wall: "evan_red.png"
            property string wallDir: ""    // Custom wallpaper directory; defaults to ~/Pictures/Wallpapers
            property int wallLook: 2       // Wallpaper render style: 0 = dotted matrix, 1 = grayscale photo, 2 = full color
            property int wallPitch: 10     // Dot matrix grid spacing in pixels
            property int wallBright: 100   // Brightness percentage relative to dark background
            property string gif: ""        // Cat widget animated GIF path (services/Gifs); empty picks first in directory
            property string gifDir: ""     // Custom GIF directory; defaults to ~/Pictures/Gifs
            property int rounding: 0       // Hyprland window corner radius: strictly 0px for NERV
            property int corners: 0        // Shell panel corner radius percentage: 0% = sharp square/chamfered edges
            property bool edges: true      // Edge-aligned telemetry status meters
            property int briSteps: 20      // Hardware brightness key step divisions: 40/20/10 corresponds to 2.5%/5%/10% increments
            property bool quickHover: true // Reveal Quick Settings panel when hovering right screen edge
            property bool deckHover: true  // Reveal bottom Deck dashboard when hovering bottom screen edge
            property var deck: ["clock", "weather", "perf", "net", "media"] // Ordered Deck sections (see decks)
            property var bar: ["layout", "wifi", "bluetooth", "sound", "notes", "battery", "mode", "power"] // Status bar tray icons (see bars)
            property bool barTitle: true   // Window title display on status bar
            property string barAt: "top"   // Bar orientation: "top" for NERV Tactical Command Bar
            // Per-monitor overrides keyed by hardware model (Theme.sid): { "TS2700-S6-1": { bar: false, home: false, ... } }; missing keys use global defaults
            property var screens: ({})
            // Screen recording configuration (quick/Rec, Sys.recArgs)
            property int recArea: 0        // 0 = entire display, 1 = region selection (slurp)
            property int recAudio: 0       // 0 = no audio, 1 = system audio, 2 = microphone, 3 = merged audio
            property int recFps: 60
            property int recQuality: 2     // medium, high, very_high, ultra
            property bool recCursor: true
            property bool vpnPortal: false // VPN disabled due to captive portal, auto-restore once connectivity is Full (vpn/Vpn)
        }
    }

    // Bento widget size mappings: widget ID -> cell span (3-column x 3-row grid of 220px cells). Overflow items excluded
    readonly property var kinds: ({ weather: 1, calendar: 1, cpu: 1, ram: 1, gpu: 1, disk: 1, battery: 1, buds: 1, player: 2, system: 3, cat: 1, cava: 1 })
    // Available Deck section IDs
    readonly property var decks: ["clock", "weather", "perf", "net", "media"]
    // Available Bar tray item IDs
    readonly property var bars: ["layout", "wifi", "bluetooth", "sound", "notes", "battery", "mode", "power", "cat"]

    // ---- External environment configuration (Hyprland, kitty terminal). Invoked by shell.qml on launch and palette changes ----
    // Hyprland inherits Demonshot foundation: display layout, input settings, idle daemon, night light, and window motions
    // are driven by Rules (shell.qml); animations are loaded from hyprland.conf.
    // Glyph applies gaps, borders, blur, and shadows from rules.json, while setting custom border colors, subtle window glow,
    // group bar colors, desktop background, and 20px window rounding (suppressing Demonshot's red window borders and neon glow).
    // Switching back via `rice switch` executes `hyprctl reload`, restoring Demonshot's styling via its applyAll routine
    function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", lua]); }

    // Kitty terminal includes this configuration file after its base configuration; Demonshot writes its own palette to the same location
    FileView { id: kitty; path: Quickshell.env("HOME") + "/.config/demonshot/kitty.conf"; printErrors: false }
    // 16 ANSI pastel terminal colors defined in design concept. Remapped in light mode via make()
    readonly property var ansi: ["#0E0E0E", "#D71921", "#9BB59A", "#D9C38A", "#8EA3C2", "#B79BC2", "#8FB8B8", "#C9C9C9",
                                 "#4A4A4A", "#F0434B", "#B5CCB4", "#E8D6A8", "#AABBD4", "#CDB6D6", "#ABCDCD", "#F2F2F2"]

    function apply() {
        // Game mode override (Rules.store.game): overrides window styling like Ultra mode — 1px border, 0 gaps, 0 rounding,
        // and enables tearing for fullscreen applications and games with immediate presentation (hyprland/rules.lua).
        // Exiting restores custom gaps and rounding and disables tearing
        const r = Rules.store, g = r.game;
        const c = x => `"rgb(${hex(x)})"`;
        // Window shadow: subtle white rim glow in dark mode; soft dark drop shadow in light mode
        const shadow = light ? "rgba(0000002E)" : `rgba(${hex(fg)}1A)`;
        // NERV window active border: Blood Crimson (#E51D24) and Electric Neon Crimson (#FF3B43) 45deg gradient with continuous angle animation
        const activeBorder = `"rgba(e51d24ee) rgba(ff3b43cc) rgba(660708ee) 45deg"`;
        hypr(`hl.config({ general = { gaps_in = ${g ? 0 : r.gapsIn}, gaps_out = ${g ? 0 : r.gapsOut}, border_size = ${g ? 1 : 2}, allow_tearing = ${g}, `
           + `col = { active_border = ${activeBorder}, inactive_border = ${c(s3)} } }, `
           + `decoration = { rounding = 0, blur = { enabled = true, passes = 2, size = 6 }, shadow = { enabled = true, color = "rgba(e51d2433)", range = 24, render_power = 2 } }, `
           + `animations = { enabled = true, animation = { border = { enabled = true, speed = 8, bezier = "standard" }, borderangle = { enabled = true, speed = 30, bezier = "linear", loop = true } } }, `
           + `group = { col = { border_active = ${c(accent)}, border_inactive = ${c(s3)}, border_locked_active = ${c(red)}, border_locked_inactive = ${c(mute)} }, `
           + `groupbar = { font_family = "${mono}", text_color = ${c(fg)}, col = { active = ${c(accent)}, inactive = ${c(s1)}, locked_active = ${c(red)}, locked_inactive = ${c(s1)} } } }, `
           + `misc = { background_color = ${c(bg)} } })`);

        kitty.setText("# nerv: generated by Theme.apply() — do not edit manually\n" + [
            ["font_family", "Space Mono"], ["window_padding_width", "20 24"], ["cursor_trail", "0"],
            ["foreground", fg], ["background", bg], ["cursor", accent], ["cursor_text_color", bg],
            ["selection_foreground", bg], ["selection_background", accent], ["url_color", cyan],
            ["active_border_color", accent], ["inactive_border_color", s3],
            ["active_tab_foreground", bg], ["active_tab_background", accent],
            ["inactive_tab_foreground", grey], ["inactive_tab_background", s1], ["tab_bar_background", bg]
        ].concat(pal.ansi.map((c, i) => ["color" + i, c])).map(([k, v]) => `${k} ${typeof v === "string" ? v : v.toString().slice(0, 7).toUpperCase()}`).join("\n") + "\n");
        Quickshell.execDetached(["pkill", "-USR1", "-x", "kitty"]);
    }

    function apps() {
        const from = nervDark.concat(nervAnsi.slice(1, 7));
        const p = pal.light ? pair(false) ?? make({ light: false }) : pal;
        const to = p.c.concat([p.red], p.ansi.slice(2, 7));
        const pairs = from.map((c, i) => [c, "#" + hex(Qt.lighter(to[i], 1))]).filter(([a, b]) => a !== b);
        const sed = pairs.map(([a], i) => ["-e", `s/${a}/@${i}@/gI`]).concat(pairs.map(([, b], i) => ["-e", `s/@${i}@/${b}/g`])).reduce((x, y) => x.concat(y), []);
        Quickshell.execDetached(["bash", "-c", `t=$1 o=$2; shift 2
for f in gtk-3.0/gtk.css gtk-4.0/gtk.css qtengine.colors; do
    l=$HOME/.config/$f
    [ -L "$l" ] || [ ! -e "$l" ] || continue
    if [ $# -gt 0 ]; then mkdir -p "$(dirname "$o/$f")" && sed "$@" "$t/$f" > "$o/$f" && ln -sfn "$o/$f" "$l"; else ln -sfn "$t/$f" "$l"; fi
done`,
            "bash", Quickshell.shellPath("term"), riceState + "/nerv"].concat(sed));
    }
}
