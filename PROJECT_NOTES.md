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
5. [Git Versioning & Branch Registry](#5-git-versioning--branch-registry)

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

## 5. Git Versioning & Branch Registry
* **`v1.0-nerv-baseline`**: Git tag marking the stable baseline of the NERV tactical rice at commit `84b77ae`.
* **`nerv-tactical-v1`**: Dedicated stable branch tracking the baseline at commit `84b77ae` (pushed to origin).
* **`main`**: Active development branch containing the maximalist `nerv` rice (commit `f500cfd`) and the newly initialized `eva95` rice (commit `d47d83a`).
