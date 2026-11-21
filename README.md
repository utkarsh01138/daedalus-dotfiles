# Project Daedalus Dotfiles

> **Production-grade, bare-metal Arch Linux + Hyprland + Quickshell workstation environment engineered for Hal (ASUS Vivobook 16X).**

[![Arch Linux](https://img.shields.io/badge/OS-Arch_Linux-1793D1?logo=arch-linux&logoColor=white)](https://archlinux.org)
[![Hyprland](https://img.shields.io/badge/Compositor-Hyprland-00FFFF?logo=wayland&logoColor=white)](https://hyprland.org)
[![QuickShell](https://img.shields.io/badge/Shell-QuickShell-EA80FC)](https://quickshell.outfoxxed.me)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)

---

> [!NOTE]
> **Lineage & Foundation:** Daedalus Dotfiles is built upon the desktop shell foundation of [Nebelung-cloud/glyph-rice](https://github.com/Nebelung-cloud/glyph-rice). It has been heavily re-engineered and extended under **Project Daedalus** with real-time GLSL fragment shaders, omni-search calculations, persistent emoji history, workstation ergonomics, and multi-rice switching capabilities.

---

## 🖥️ Machine Hardware Specification (Hal)

These dotfiles are tailored and tuned for the following hardware architecture:

| Component | Specification | Details |
| :--- | :--- | :--- |
| **Device Model** | **ASUS Vivobook 16X** | `M1603QA_M1603QA` |
| **Processor (CPU)** | **AMD Ryzen 7 5800HS** | 8 Cores / 16 Threads @ up to 4.4 GHz |
| **Memory (RAM)** | **16 GB DDR4** | Dual-channel @ 3200 MT/s |
| **Display Panel** | **16.0" 16:10 WUXGA** | `1920x1200 @ 60Hz` (1.0 Integer Scale, Chimei Innolux `0x1618`) |
| **Graphics (iGPU)** | **AMD Cezanne Radeon Vega** | Native kernel KMS acceleration |
| **Audio Subsystem** | **PipeWire 1.6+** | WirePlumber low-latency virtual routing |
| **Wireless / Bluetooth** | **MediaTek MT7921** | Wi-Fi 6 (802.11ax) + Bluetooth 5.2 |

---

## ✨ What Daedalus Adds to Glyph

While retaining the clean NothingOS dot-matrix visual aesthetic, **Project Daedalus** introduces significant architectural expansions:

### 🌌 1. Daedalus Optics (14 Real-Time GLSL Fragment Shaders)
Direct single-pass GLSL ES 3.0 fragment shader injection into Hyprland's composited rendering pipeline at 60 FPS with zero CPU overhead.
* **CLI Controller:** `/home/utki/.local/bin/daedalus-shader` (symlinked as `shader`).
* **Daily Rotation Cycle:** Cycles through 6 primary shaders + normal mode:
  $$\text{astronomy-red} \longrightarrow \text{crt-scanlines} \longrightarrow \text{blueprint} \longrightarrow \text{grayscale} \longrightarrow \text{theme-quantize} \longrightarrow \text{true-black} \longrightarrow \text{off}$$
* **Quick Actions Sub-Menu:** Right-clicking the Shader tile in Quick Settings opens an integrated catalog displaying both the `daily (6)` rotation and `all (14)` catalog.
* **Curated Shader Library (`config/hypr/shaders/`):**
  * `astronomy-red.glsl`: Pure red channel pass stripping 100% of green and blue light to preserve scotopic dark adaptation for telescope stargazing.
  * `crt-scanlines.glsl`: Subtle horizontal line darkening matched to 1200p with phosphor warmth and vignetting.
  * `blueprint.glsl`: Prussian-blue architectural cyanotype drafting mode with 32px grid lines.
  * `paper-mode.glsl`: Reflective E-Ink display emulation with 88% desaturation and deterministic static fiber grain.
  * `p31-green.glsl`: Tektronix oscilloscope P31 zinc-sulfide phosphor (520 nm peak with mint-white highlights).
  * `bayer-dither.glsl`: 1-bit monochrome ordered Bayer matrix dithering ($4\times4$) with gamma compensation.
  * `inferno.glsl` & `viridis.glsl`: Matplotlib scientific colormaps evaluated via 6th-degree polynomial fits.
  * `theme-quantize.glsl`: Catppuccin Mocha universal palette quantizer via redmean perceptual distance.
  * `gameboy.glsl`, `virtual-boy.glsl`, `true-black.glsl`, `smart-invert.glsl`, `grayscale.glsl`.

### 🧮 2. Omni-Search & Mathematical Launcher (`Super + Space`)
* **Live Calculation & Conversion:** Type any mathematical expression (`2+2`, `sqrt(144)`, `sin(pi/4)`) or currency conversion (`200 usd to inr`, `50 eur to gbp`) directly into the search bar. Real-time evaluations are performed via `/usr/bin/qalc`; pressing `Enter` copies the result.
* **CLI Execution:** Type any terminal command (e.g. `shader red`, `mnemosyne`, `>top`). Pressing `Enter` executes it silently in the background; pressing `Shift + Enter` launches it inside an interactive Kitty terminal.

### 🎭 3. Persistent Recent History Charms Picker (`Super + .`)
* **30-Item Recent History:** Automatically tracks the last 30 emojis, symbols, math characters, or kaomoji in strict Most Recently Used (MRU) order, saved persistently to state (`charms-recent.json`).
* **Category Hierarchy:** `recent` $\rightarrow$ `emoji` $\rightarrow$ `math` $\rightarrow$ `symbols` $\rightarrow$ `kaomoji`.
* **Instant Action:** Single-click or `Enter` inserts the charm directly into the active text field via `~/.local/bin/copy-and-paste`; Right-click or `Shift + Enter` copies to clipboard.
* **Omni-Search:** Typing a query (e.g. `pi`, `integral`, `shruggie`) matches across all datasets simultaneously.

### 📋 4. Direct-Insert Clipboard Manager (`Super + V`)
* **Direct Paste:** Pressing `Enter` or clicking any clipboard card directly pastes it into the active window.
* **Action Menu:** Windows 11 style `···` menu on every card with quick actions: Copy only, Pin/Unpin, and Delete. `Shift + Enter` copies only.

### 🔔 5. Restructured Quick Actions Panel (`Super + A`)
* Re-ordered vertical hierarchy: Notifications stack cleanly at the top, followed by Clock/Date, Wi-Fi/Bluetooth pills, action tiles, volume/brightness sliders, and media player.
* Auto-adapting layout: When no notifications are active, the panel cleanly collapses to start with the Clock.

### 🔄 6. Multi-Rice Architecture (`rice switch`)
* Built-in multi-rice management engine (`~/.config/quickshell/rice/rice`).
* Instant 0.5-second hot-swapping between desktop identities:
  * **NothingOS (`glyph`):** Clean, consumer dot-matrix minimalism for everyday use.
  * **NERV Tactical (`nge`):** High-urgency, chamfered command bunker HUD for deep focus coding sessions.

---

## ⌨️ Keybindings Reference

| Hotkey | Action | Component |
| :--- | :--- | :--- |
| `Super + Space` | Open Omni-Search Launcher (Apps, `qalc` Math, CLI) | Launcher |
| `Super` | Open Bottom Deck Dashboard (Click outside to dismiss) | Deck |
| `Super + A` | Open Quick Actions & Notification Center | Quick |
| `Super + V` | Open Clipboard History (Direct paste on `Enter`) | Clip |
| `Super + .` | Open Charms & Emoji Picker (30 Recent History) | Charms |
| `Super + Alt + O` | Toggle Astronomy Red Night Vision Mode | Daedalus Optics |
| `Super + Shift + O` | Toggle Retro CRT Scanlines | Daedalus Optics |
| `Ctrl + Super + O` | Instantly clear all active screen shaders | Daedalus Optics |
| `Super + Shift + W` | Open Wallpaper Selector | Walls |
| `Super + Shift + T` | In-memory Screen OCR text extraction to clipboard | Daedalus Vision |
| `Print` | Interactive Screenshot, Annotation, & Recording | Shot |
| `Super + Esc` | Power, Lock, & Session Menu | Power |

---

## 📦 Installation

### Prerequisites (Arch Linux)
Hal runs pure Arch Linux. You can install all system packages and dependencies via:
```bash
sudo pacman -Syu --needed base-devel git curl jq python \
    hyprland hypridle hyprsunset xdg-desktop-portal-hyprland \
    sddm quickshell pipewire wireplumber networkmanager bluez \
    brightnessctl playerctl wl-clipboard cliphist grim slurp \
    libqalculate kitty fish starship fastfetch btop cava
```

### Deploying the Dotfiles
```bash
# Clone the Daedalus Dotfiles repository
git clone https://github.com/utkarsh01138/daedalus-dotfiles ~/.local/share/glyph

# Apply symlinks to ~/.config/ and ~/.local/bin/
~/.local/share/glyph/install.sh --links

# (Optional) Full automated install including SDDM greeter:
# ~/.local/share/glyph/install.sh
```

---

## 🙏 Acknowledgements & Credits

* [**Nebelung-cloud/glyph-rice**](https://github.com/Nebelung-cloud/glyph-rice): The desktop shell foundation from which this rice was derived and extended.
* [**Nothing Technology Ltd.**](https://nothing.tech): Visual inspiration, Nothing OS typography, and Glyph interface design language.
* [**Doto**](https://github.com/oliverlalan/Doto): The dot-matrix typeface.
* [**Qalculate!**](https://qalculate.github.io): Calculation and unit conversion CLI engine.
* [**Hyprland**](https://hyprland.org): The dynamic tiling Wayland compositor powering Hal.

---

## 📄 License

This project is licensed under the [GNU General Public License v3.0](LICENSE).  
Fonts are licensed under the [SIL Open Font License](config/fonts/OFL.txt).
