import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components

// =============================================================================
// EVA-95 CENTRAL DOGMA CRT BACKGROUND CANVAS (1995 NGE TV SERIES STYLE)
// =============================================================================
// Layer: Background, isolated layershell namespace eva95-back.
// Renders wallpaper with authentic CRT amber aperture grille raster scanlines,
// tactical coordinate grid, and Sony Trinitron tube vignette on top.
PanelWindow {
    id: root

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "eva95-back"

    readonly property bool home: (Hyprland.monitorFor(screen)?.activeWorkspace?.toplevels.values.length ?? 0) === 0

    Stage {
        id: stage

        // Wallpaper renderer
        Wall {
            id: wall
            anchors.fill: parent
            path: Theme.wallSrc(Theme.scr(root.screen?.name, "wall"))
            animate: !Sys.wallOpen
        }

        // Authentic CRT Scanline, Phosphor Grid & Tube Vignette (Rendered ON TOP of wallpaper)
        Item {
            anchors.fill: parent

            // Horizontal CRT scanlines (subtle 1080p raster)
            Image {
                anchors.fill: parent
                fillMode: Image.Tile
                opacity: 0.12
                source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="1" height="4"><rect width="1" height="1.5" fill="#${Theme.hex(Theme.accent)}"/></svg>`)
            }

            // Tactical coordinate grid lines (64x64 geofront grid)
            Image {
                anchors.fill: parent
                fillMode: Image.Tile
                opacity: 0.08
                source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><line x1="0" y1="0" x2="64" y2="0" stroke="#${Theme.hex(Theme.accent)}" stroke-width="0.5"/><line x1="0" y1="0" x2="0" y2="64" stroke="#${Theme.hex(Theme.accent)}" stroke-width="0.5"/></svg>`)
            }

            // CRT Glass Tube Corner Vignette (Simulates curved Trinitron glass phosphors)
            Image {
                anchors.fill: parent
                opacity: 0.45
                source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600"><defs><radialGradient id="v" cx="50%" cy="50%" r="70%"><stop offset="60%" stop-color="#000" stop-opacity="0"/><stop offset="100%" stop-color="#000" stop-opacity="1"/></radialGradient></defs><rect width="800" height="600" fill="url(#v)"/></svg>`)
            }
        }
    }
}
