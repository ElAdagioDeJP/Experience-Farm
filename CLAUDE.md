# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Experience-Farm** (`Granja_Carabobeña`) — a Godot 4.6 walking-simulator / virtual experience of a Carabobo (Venezuela) farm with a *llanero* landscape twist. Art direction is deliberately Cube World / 3D Dot Game Heroes: blocky voxel models, cozy, colorful, low-poly, game-optimized.

The repo is in an early stage: the Godot project and a first wave of voxel assets exist, but there are no scenes (`escenas/` is empty) or GDScript yet. Directory and node names are in **Spanish** (`escenas`, `Granja_Carabobeña`) — keep new gameplay-facing names consistent with that.

## Engine configuration (do not silently change)

From `project.godot`:
- Godot **4.6**, renderer **GL Compatibility** (`gl_compatibility`) — desktop *and* mobile. Avoid Forward+/Vulkan-only features (advanced shaders, SDFGI, etc.); they won't render.
- Physics engine: **Jolt Physics** (3D).
- Windows rendering device driver: **d3d12**.

## MCP-driven workflow

Two MCP servers are configured in `.mcp.json` (and a duplicate `mcp-config.json`):

- **godot** (`@coding-solo/godot-mcp`) — drives the Godot editor: create scenes/nodes, load sprites, run/stop the project, read debug output. `GODOT_PATH` points at the local Godot 4.6.2 binary; the editor is launched through the MCP, not a build/test CLI. There is no test suite or lint step.
- **magicavoxel** — builds/edits `.vox` models programmatically. `VOX_DIR=./assets/vox_models`, so every model created via this MCP lands directly in the tracked asset folder.

To run the game, use the godot MCP's `run_project` against this directory (or open the local Godot binary). To verify a model, open the `.vox` in MagicaVoxel — the MCP cannot render previews.

## Asset pipeline & layout

- `assets/vox_models/` — source `.vox` files (MagicaVoxel output, version-controlled).
- `assets/models/` — intended for engine-ready meshes (e.g. exported `.glb`/`MeshLibrary`); empty so far.
- `escenas/` — Godot scenes (`.tscn`); empty so far.
- `export/` — build output.
- `.vox`, `.png`, `.glb` are marked `binary` in `.gitattributes` (the global rule normalizes EOL to LF for text). New binary asset types should be added there too.

## Voxel modeling conventions

All wave-1 models follow these rules; keep future models consistent so a single master palette emerges:

- **Axis:** Z = up (MagicaVoxel standard). Body length runs along X, width along Y.
- **3-tone rule:** every material uses a flat BASE + SHADOW (~15% darker) + LIGHT (~12% lighter). No gradients/anti-aliasing.
- **Shared palette index map** (reuse these indices across every `.vox`):
  1–3 grass light/base/shadow · 4–6 dirt base/shadow/vein · 7–8 trunk base/shadow · 9–11 foliage base/light/shadow · 12 samán flower · 13–15 araguaney yellow/light/shadow · 16 bush · 17 dry grass · 18 berry red · 19 generic body-shadow (reused per file) · 20 cow Carora reddish · 21 Brahman gray · 22 muzzle pink · 23 horn bone · 24 hoof dark · 25 eye black · 26 white · 27–28 horse alazán/mane · 29–30 pig pink/shadow · 31 hen brown · 32 rooster body · 33 gold · 34 tail green · 35 tail blue · 36 comb red · 37 beak yellow · 38 chick yellow.
- **Style cues:** rounded-off corners for cozy feel; big eyes with a white highlight voxel; signature silhouettes matter (samán = wide flat umbrella canopy, araguaney = all-yellow canopy with no green, Brahman bull/cow = hump + drooping ears + dewlap).

Wave 1 models in `assets/vox_models/`: `tile_tierra`, `arbol_saman`, `arbol_araguaney`, `arbusto`, `mata_grama`, `vaca`, `toro`, `caballo`, `cerdo`, `gallina`, `gallo`, `pollito`.

## Git

Default branch is `main`. The `.godot/` cache and import sidecars are gitignored. `GODOT_PATH` in the MCP configs is an absolute local path — it differs per machine and will not work on a clone as-is.
