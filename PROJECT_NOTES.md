# Project Daedalus — Engineering & Project Notes

> **Comprehensive architectural notes, telemetry specifications, multi-rice decoupling, and development roadmap for Hal (ASUS Vivobook 16X).**

---

## 📑 Table of Contents
1. [System & Hardware Baseline](#1-system--hardware-baseline)
2. [Multi-Rice Architecture & Switching](#2-multi-rice-architecture--switching)
3. [NERV Tactical Command Rice (`nerv`)](#3-nerv-tactical-command-rice-nerv)
   * [Color System & Visual Rules](#color-system--visual-rules)
   * [Hardware-Linked MAGI Supercomputer](#hardware-linked-magi-supercomputer)
   * [Pulsing Vector AT-Field (LARP Mode)](#pulsing-vector-at-field-larp-mode)
   * [Adaptive Wallpaper Contrast Engine](#adaptive-wallpaper-contrast-engine)
   * [Terminal & Application Theming](#terminal--application-theming)
4. [EVA-95 Central Dogma Rice (`eva95`)](#4-eva-95-central-dogma-rice-eva95)
   * [Decoupling & Isolation Architecture](#decoupling--isolation-architecture)
   * [1995 Anime Implementation Roadmap](#1995-anime-implementation-roadmap)
5. [Liquid Frosted Acrylic Rice (`glass`)](#5-liquid-frosted-acrylic-rice-glass)
   * [Material System & Exact Tokens](#material-system--exact-tokens)
   * [Compositor Geometry & Materials](#compositor-geometry--materials)
   * [QuickShell Architecture & Signature Specular Glow](#quickshell-architecture--signature-specular-glow)
   * [Terminal & Shell Sync Matrix](#terminal--shell-sync-matrix)
6. [Git Versioning & Branch Registry](#6-git-versioning--branch-registry)

---

## 1. System & Hardware Baseline
* **Machine:** ASUS Vivobook 16X (`M1603QA_M1603QA`) — codename **Hal**
* **Processor (CPU):** AMD Ryzen 7 5800HS (8 cores / 16 threads, base 3.2 GHz, boost up to 4.4 GHz)
* **Memory (RAM):** 16 GB DDR4-3200 (Dual-channel)
* **Display Panel:** 16.0" 16:10 WUXGA (1920x1200 @ 60Hz, integer scale 1.0, Chimei Innolux `0x1618`)
* **OS / Compositor / Shell:** Arch Linux (Kernel 7.3.5-arch1-1), Hyprland 0.57.2 (Wayland), QuickShell (Qt 6.12)
* **Audio / Battery:** PipeWire 1.6+ / WirePlumber, UPower battery monitoring

---

## 2. Multi-Rice Architecture & Switching
Project Daedalus features an atomic multi-shell switching engine located at `/home/utki/.local/bin/rice`.
* **Switching command:** `rice switch <name>`
* **Listing command:** `rice list`
* **Mechanism:**
  1. Identifies shell directory across `~/.config/quickshell/<name>` and `~/daedalus/config/quickshell/<name>`.
  2. Updates persistent active shell pointer at `~/.local/state/rice/shell`.
  3. Symlinks terminal application themes (`starship.toml`, `fastfetch`, `cava`, `btop`, `gtk-3.0`, `gtk-4.0`, `qtengine.colors`).
  4. Signals live processes: `pkill -USR1 -x cava`, `pkill -USR2 -x btop`, reloads Hyprland styling.
  5. Terminates running QuickShell instances cleanly and launches the new shell configuration.

---

## 3. NERV Tactical Command Rice (`nerv`)

### Color System & Visual Rules
* **Palette:**
  * Root Background: `#060608` (Deep Tactical Bunker Black)
  * Surface S1: `#121216` (Major command panels, top rail)
  * Surface S2: `#202028` (Secondary telemetry cards, voting blocks)
  * Hairline Borders: `#32323E` (Grid lines, tactical reticles)
  * Primary Accent: `#E51D24` (Evangelion Blood Crimson)
  * Critical Alert / Hazard: `#FF3B43` (Neon Red)
  * Data Links / Communications: `#00E5FF` (Sub-commander Cyan)
* **Geometry:** Strict `radius: 0` (zero curves) across all windows, panels, HUD overlays, and widgets.
* **Typography:**
  * Title & Numeric: `FOT-Matisse Pro` (Authentic Evangelion font)
  * Technical Labels: `Space Mono` (Uppercase monospace telemetry)
  * UI Elements: `Space Grotesk`
  * System Glyphs: `JetBrainsMono Nerd Font`

### Hardware-Linked MAGI Supercomputer
Implemented in `config/quickshell/nerv/deck/Deck.qml`, the tripartite MAGI cluster evaluates real-time kernel telemetry:
1. **MELCHIOR-1 // SCIENTIST**:
   * Evaluates CPU thread load and package thermals (`SysStats.cpu < 0.85 && SysStats.cpuTemp < 82`).
   * Displays live CPU % and temperature.
   * Votes `[ NOMINAL ]` (Agree) or `[ OVERLOAD ]` (Deny).
2. **BALTHASAR-2 // MOTHER**:
   * Evaluates memory pressure and power buffer preservation (`SysStats.mem < 0.90 && (battery > 15% || AC umbilical connected)`).
   * Displays live RAM in GB and battery state.
   * Votes `[ PROTECT ]` (Agree) or `[ CRITICAL ]` (Deny).
3. **CASPAR-3 // WOMAN**:
   * Evaluates transport link status and bus throughput (`SysStats.rx + SysStats.tx > 50 || network link full`).
   * Displays network interface (`wlp1s0`) and live throughput (`↓KB/s ↑KB/s`).
   * Votes `[ LINK OK ]` (Agree) or `[ SEVERED ]` (Deny).
4. **Consensus & Eva-01 Synchronicity**:
   * Dynamic Consensus Header: `magi · consensus X/3` (color-coded by consensus ratio).
   * Eva-01 Synchronicity Ratio: Mathematically modulated by live CPU frequency and thread load:
     $$\text{synchVal} = \text{clamp}\left(0.680,\, 0.999,\, 0.85 + \frac{\text{cpuFreq}}{4.4} \times 0.10 - \text{cpu} \times 0.08\right)$$
   * Dynamic Harmonic Distortion: Live jitter calculation `±0.0X% [STABLE / DRIFT]`.

### Pulsing Vector AT-Field (LARP Mode)
Configured via `Theme.state.larp` (persisted in `~/.local/state/rice/nerv.json`) and rendered on the desktop layer in `config/quickshell/nerv/bar/HudOverlay.qml`:
* Vector Assets: Mathematically exact regular octagons generated in SVG ([atfield.svg](file:///home/utki/daedalus/config/quickshell/nerv/bar/atfield.svg) and [atfield_pulse.svg](file:///home/utki/daedalus/config/quickshell/nerv/bar/atfield_pulse.svg)).
* Staggered outward-radiating shockwaves (`scale 0.6 → 1.5`, `opacity 0.9 → 0.0`) with 1100ms offset.
* Concentric breathing octagons with radial vertex phase lines.
* Status badge: `[ AT-FIELD // PHASE: 432.8 THz [ACTIVE] ]`.

### Adaptive Wallpaper Contrast Engine
Located in `config/quickshell/nerv/Theme.qml`:
* `isLightWall`: Detects light wallpapers (e.g. `evengalblood.jpg`) and ensures dark wallpapers (`evan.png`, `evan_red.png`) maintain high contrast.
* Dark Wallpapers: Text is rendered in crisp bright white (`#FFFFFF`) and silver (`#EAEAEB`) with neon red accents.
* Light Wallpapers: Text is rendered in deep charcoal (`#0A0A0E`) and graphite (`#1F1F28`) with deep blood-red accents.

### Terminal & Application Theming
* **Fastfetch:** Uses `~/.config/fastfetch/nerv_logo.png` with color-coded system modules.
* **Starship:** Militaristic telemetry bracketed style `[NERV//EVANGELION:3.33] [path] [BRANCH:main] >>`.
* **Btop / Cava:** Pure crimson and neon-red color palettes.

---

## 4. EVA-95 Central Dogma Rice (`eva95`)

### Decoupling & Isolation Architecture
Branched from `nerv` to provide a clean development baseline while guaranteeing that modifications to `eva95` will not alter `nerv`:
* **Config Directory:** `config/quickshell/eva95/` (symlinked at `~/.config/quickshell/eva95`).
* **State File:** `~/.local/state/rice/eva95.json` (independently read and written by `Theme.qml`).
* **Layershell Namespaces:** `eva95-bar`, `eva95-hud` (isolated from `nerv-bar`, `nerv-hud`).
* **Terminal Theme Files:**
  * Starship: `[EVA-95//MAGI-01]` in `config/quickshell/eva95/term/starship.toml`.
  * Fastfetch: `[ NERV CENTRAL DOGMA // MAGI SUPERCOMPUTER // EVA-95 ]` in `config/quickshell/eva95/term/fastfetch/config.jsonc`.
  * Btop: `eva95.theme` and `color_theme = "eva95"` in `config/quickshell/eva95/term/btop/btop.conf`.

### 1995 Anime Implementation Roadmap
The goal of `eva95` is to recreate the authentic 1995 *Neon Genesis Evangelion* CRT supercomputer interface:
1. **CRT Phosphor Palette:** Transition from modern red/black to retro Amber/Orange CRT phosphor (`#FF8800` / `#FFAA00`), stark emergency cyan (`#00FFFF`), and bold yellow-and-black angled hazard chevrons.
2. **Tripartite Hexagonal MAGI Displays:** Replace standard cards with the iconic three interlocking hexagons (Melchior, Balthasar, Caspar) dominating the screen, complete with deliberation status, Japanese kanji/katakana typography, and consensus voting blocks.
3. **Evangelion Umbilical Cable Timer:** Implement the famous `05:00.00` internal battery countdown meter with segmented emergency power drain graphics.
4. **CRT Visual Shaders:** Seamless integration with Daedalus Optics CRT scanline and phosphor bloom shaders (`crt-scanlines.glsl`, `p31-green.glsl`, or dedicated amber CRT shader).
5. **Emergency Kanji Banners:** Large-scale `警報` (EMERGENCY) and `CODE BLUE` banners inspired directly by Anno & Yamashita's 1995 layout design.

---

## 5. Liquid Frosted Acrylic Rice (`glass`)

### Material System & Exact Tokens
Profile 4: `glass` introduces macOS and visionOS translucent material depth to bare-metal Wayland without desktop bloat:
* `Glass.bg`: `rgba(13, 16, 23, 0.65)` (Smoky translucent obsidian acrylic base)
* `Glass.card`: `rgba(255, 255, 255, 0.08)` (Elevated floating frosted card surface)
* `Glass.specular`: `rgba(255, 255, 255, 0.22)` (Top-edge specular white light refraction hairline)
* `Glass.cyan`: `#70C0D0` (Icy glacial glow — active focus highlight)
* `Glass.lavender`: `#B48EAD` (Luminous soft neon purple — media & secondary tags)
* `Glass.fg`: `#FFFFFF` (Optical white with soft drop-shadow)
* `Glass.sub`: `rgba(255, 255, 255, 0.65)` (Semi-translucent frosted label text)

### Compositor Geometry & Materials
Configured in `Theme.apply()`:
* **Window Rounding:** `rounding = 18px` (Continuous liquid squircle curvature).
* **Border Styling:** `border_size = 1px`, `col.active_border = rgba(255,255,255,0.28) rgba(255,255,255,0.06) 90deg` (Simulates physical glass plate top-edge light catch).
* **Window Opacity:** Active `0.85`, Inactive `0.75` (Content floating on frosted plate glass; Kitty terminal window rule `opacity 0.82 0.72 override` for Dual-Kawase wallpaper blur).
* **Blur Profile:** Heavy **Dual-Kawase Blur** (`passes = 4`, `size = 7`, `noise = 0.02`, `contrast = 0.95`, `brightness = 1.05`).
* **Fluid Spring Animation Engine:**
  * Custom Bezier curves: `macosSpring = 0.16, 1, 0.3, 1`, `fluid = 0.05, 0.9, 0.1, 1.05`, `appleEase = 0.25, 1, 0.5, 1`.
  * Fluid window movement (`windowsMove` with `fluid`), elastic popin (`windowsIn` with `fluid`), smooth slidefade workspace transitions (`workspaces` with `appleEase` and `slidefade 20%`), and border focus cross-fades.
* **Layer Rules & Compositor Safeguards:**
  * `hl.layer_rule({ match = { namespace = "glass-(launcher|quick|deck|notifs|bar|dock|osd|battery)" }, no_anim = true })` prevents Hyprland whole-screen slide animations on panel mapping.
  * Never apply `blur = true` to wildcard layer namespaces (`glass-.*`): Hyprland blurs the entire bounding rectangle of full-width or fullscreen transparent layer surfaces, creating intrusive blurred bands. Blur must only be handled inside QML or on tightly-bound opaque panels.
  * Floating HUDs (like `Osd.qml`) must bind `visible: root.shown` so that idle surfaces are completely unmapped from Wayland.

### QuickShell Architecture & Signature Specular Glow
* **Floating Top Menu Bar (`bar/Bar.qml`):** Detached by 8px from tiled windows, frosted glass blur with Apple logo dropdown menu, interactive menu buttons (*File*, *Edit*, *View*, *Window*, *Help*), shifted active window title, prominent glowing charging bolt beside battery capsule bar, and right status tray (Battery, Wi-Fi, Bluetooth, Spotlight, Control Center, Clock).
* **Dedicated Battery Panel (`battery/Battery.qml`):** macOS-style battery menu with live percentage, charging status and time-to-full/empty, continuous level gauge, power draw (wattage), battery health condition, top CPU energy consumers, and Battery Preferences link.
* **The Dynamic Dock (`dock/Dock.qml`):** Centered floating translucent frosted glass shelf. Dynamically replicates running windows in the exact order of their workspaces, with parabolic hover magnification, active workspace indicator dots, window title / workspace tooltip pills, and triple-layer failsafe auto-hide.
* **Spotlight Search (`launcher/Launcher.qml`):** Floating search pane on `Super + Space` featuring 4 mode switcher tabs (*Apps*, *Commands*, *Windows*, *Calculator*), direct shell command execution (`> cmd`), live math evaluation (`qalc`), window switcher, and fluid animated trailing cursor caret.
* **Control Center (`quick/Quick.qml`):** Modular acrylic tiles with prominent Wi-Fi & Bluetooth primary capsules, expand pickers (`Picker.qml`), Focus (DND), Caffeine, Night Light, continuous volume/brightness sliders, and Now Playing media card.
* **Dashboard Deck (`deck/Deck.qml`):** 100% continuous liquid frosted acrylic dashboard with continuous circular arc gauges (`Canvas`) for CPU/RAM/GPU, sleek horizontal process bars, vertical core bars, crisp weather forecast cards, and real-time network throughput sparkline.
* **Signature Interactive Feature:** Dynamic Specular Cursor Glow (`components/SpecularGlow.qml`) projects a soft radial specular highlight beneath the pointer across cards, tiles, and dock shelves.

### Terminal & Shell Sync Matrix
* **Starship:** Smooth connected rounded bubble prompt (`╭─(  )─( ~/daedalus )─(  main )`).
* **Fastfetch:** Apple/Linux fusion vector logo with glacial cyan accents.
* **Kitty:** `background_opacity 0.80`, `dynamic_background_opacity yes`, `cursor_trail 4`, Dual-Kawase blur, Tokyo Night / Catppuccin pastel syntax palette.
* **Btop / Papirus:** `glass.theme` color palette and `folder-cyan` icon overlays.

---

## 6. Git Versioning & Branch Registry
* **`v1.0-nerv-baseline`**: Git tag marking the stable baseline of the NERV tactical rice at commit `84b77ae`.
* **`nerv-tactical-v1`**: Dedicated stable branch tracking the baseline at commit `84b77ae` (pushed to origin).
* **`main`**: Active development branch containing the maximalist `nerv` rice (commit `f500cfd`) and the newly initialized `eva95` rice (commit `d47d83a`).
