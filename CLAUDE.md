# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository. Read this first; it encodes decisions that are easy to break and hard to notice.

---

## 1. What this project is

**Experience-Farm** (`Granja_Carabobeña`) — a Godot 4.6 walking-simulator / virtual experience of a Carabobo (Venezuela) farm with a *llanero* (plains) twist. You spawn on a grassy savanna and walk a dirt path toward a cabin at the far end.

**Art direction is non-negotiable:** Cube World / *3D Dot Game Heroes*. Blocky voxel models, cozy, colorful, low-poly, game-optimized. Every authored asset starts as a MagicaVoxel `.vox`. Realistic / high-poly assets clash with the look — avoid them unless explicitly requested.

**Language:** directory and gameplay-facing names are **Spanish** (`escenas`, `jugador`, `mundo`, `Granja_Carabobeña`, `mover_adelante`). Keep new names consistent — Spanish for game-facing identifiers, code comments in Spanish to match existing scripts.

---

## 2. Engine configuration (do not silently change)

From `project.godot`:

| Setting | Value | Why it matters |
|---|---|---|
| Engine | Godot **4.6** | |
| Renderer | **GL Compatibility** (`gl_compatibility`, desktop + mobile) | No Forward+/Vulkan features — SDFGI, advanced/compute shaders, etc. **won't render**. |
| Physics (3D) | **Jolt Physics** | |
| Windows device driver | **d3d12** | |
| Main scene | `res://escenas/Main.tscn` | |

**Input map** (physical keycodes, so layout-independent): `mover_adelante` (W), `mover_atras` (S), `mover_izquierda` (A), `mover_derecha` (D). `ui_cancel` (Esc) frees the mouse cursor.

---

## 3. Repository layout

```
Experience-Farm/
├─ escenas/                  # Godot scenes + scripts (Spanish)
│  ├─ Main.tscn              # the level — entry point
│  ├─ jugador/               # player: Jugador.tscn + Jugador.gd
│  └─ mundo/                 # world scripts: ConstructorTerreno.gd, EsparcidorFlora.gd
├─ assets/
│  ├─ vox_models/            # SOURCE .vox (MagicaVoxel, version-controlled)
│  └─ models/                # engine-ready meshes: .obj/.mtl (from converter), .glb, .tres MeshLibrary
├─ tools/
│  └─ vox_to_obj.py          # .vox → .obj+.mtl converter (the asset pipeline)
├─ export/                   # build output
├─ project.godot             # engine config (section 2)
├─ .mcp.json / mcp-config.json  # MCP server config (duplicate — keep in sync)
└─ LICENSE                   # AGPL-3.0
```

`.godot/` cache and `*.import` sidecars are gitignored. `.vox`, `.png`, `.glb` are marked `binary` in `.gitattributes` (text files normalize to LF) — add new binary asset extensions there too.

---

## 4. The asset pipeline (the core workflow)

```
MagicaVoxel .vox          tools/vox_to_obj.py            Godot scene
(assets/vox_models/)  ──►  .obj + .mtl              ──►  ext_resource ArrayMesh
                           (assets/models/)              in Main.tscn
```

1. **Model** in MagicaVoxel — via the `magicavoxel` MCP (writes straight into `assets/vox_models/`) or the app itself.
2. **Convert** with `python tools/vox_to_obj.py <in_dir> <out_dir>` (typically `assets/vox_models assets/models`). The converter:
   - parses SIZE / XYZI / RGBA chunks;
   - meshes with internal-face culling (only faces touching empty voxels are emitted);
   - one flat material per used palette color (`Kd = color`) — the CubeWorld flat look;
   - converts **MagicaVoxel Z-up → Godot Y-up** via `(x, z, -y)`;
   - centers in X/Z, rests the base at `Y=0`;
   - **1 voxel = 1 unit** — apply scale at Godot import (e.g. `0.125` so 16 vox = 2 m).
3. **Reference** the `.obj` (or `.glb`) as an `ext_resource` in `Main.tscn`.

`.glb` assets (e.g. `grass.glb`, `farm_set_part_2.glb`) bypass the converter — Godot imports them natively. Use these for third-party CC assets; **credit the author** (e.g. CC-BY) in this file and the README when you add one.

---

## 5. Scene architecture (`Main.tscn`)

- **Terrain** — a `GridMap` driven by `escenas/mundo/ConstructorTerreno.gd`, painting cells from the `biblioteca_terreno.tres` MeshLibrary. Item indices: **0 = grama (grass), 1 = tierra (dirt), 2 = camino (path)**. The script lays a grass field, a central dirt path from spawn (z+) to the cabin (z-), and a packed-dirt clearing at the cabin.
- **Flora scatter** — `MultiMeshInstance3D` + `escenas/mundo/EsparcidorFlora.gd`: seeded procedural scatter in a single draw call, with a clear radius around the path/spawn. For a tree, use **two nodes with the same seed/area/count/clear-radius** and different `altura_offset` so trunk and canopy align. Can pull a mesh from a `.glb` via `malla_desde_escena`.
- **Player** — `escenas/jugador/Jugador.tscn` + `Jugador.gd`: `CharacterBody3D` first-person controller. WASD via `Input.get_vector`, mouse-look (body yaw + pitch pivot with clamp), gravity, captured cursor. Expected node tree: `Jugador → CollisionShape3D (capsule) + PivoteCamara (Node3D) → Camara (Camera3D)`.
- Lighting/atmosphere: `WorldEnvironment` (procedural warm sky + fog) and a `DirectionalLight3D`.

When editing scripts, match the existing style: `@export` for inspector-tunable params, Spanish `##` doc comments, typed variables.

---

## 6. MCP-driven workflow

Two MCP servers (configured in **both** `.mcp.json` and `mcp-config.json` — keep them in sync):

- **godot** (`@coding-solo/godot-mcp`) — drives the editor: create scenes/nodes, load sprites, run/stop the project, read debug output. `GODOT_PATH` is an **absolute local path to Godot 4.6.2** — it differs per machine and won't work on a fresh clone. There is **no test suite or lint step**; "running" the game *is* the verification.
- **magicavoxel** — builds/edits `.vox` programmatically. `VOX_DIR=./assets/vox_models`, so models land in the tracked source folder.

To run: godot MCP `run_project` against this dir (or open the local Godot binary). To preview a model: open the `.vox` in MagicaVoxel — the MCP can't render previews.

---

## 7. Voxel modeling conventions

Keep every model consistent so one master palette emerges across all `.vox`.

- **Axis:** Z = up (MagicaVoxel standard). Body length along X, width along Y.
- **3-tone rule:** every material = flat BASE + SHADOW (~15% darker) + LIGHT (~12% lighter). No gradients, no anti-aliasing.
- **Shared palette index map** (reuse these indices in every `.vox`):

  | Idx | Use | Idx | Use |
  |---|---|---|---|
  | 1–3 | grass light/base/shadow | 20 | cow Carora reddish |
  | 4–6 | dirt base/shadow/vein | 21 | Brahman gray |
  | 7–8 | trunk base/shadow | 22 | muzzle pink |
  | 9–11 | foliage base/light/shadow | 23 | horn bone |
  | 12 | samán flower | 24 | hoof dark |
  | 13–15 | araguaney yellow/light/shadow | 25 | eye black |
  | 16 | bush | 26 | white |
  | 17 | dry grass | 27–28 | horse alazán/mane |
  | 18 | berry red | 29–30 | pig pink/shadow |
  | 19 | generic body-shadow (reused per file) | 31 | hen brown |
  | 32 | rooster body | 36 | comb red |
  | 33 | gold | 37 | beak yellow |
  | 34 | tail green | 38 | chick yellow |
  | 35 | tail blue | | |

- **Style cues:** rounded-off corners (cozy); big eyes with a white highlight voxel; signature silhouettes matter — **samán** = wide flat umbrella canopy; **araguaney** = all-yellow canopy, *no green*; **Brahman bull/cow** = hump + drooping ears + dewlap.

**Wave 1** (`assets/vox_models/`): `tile_tierra`, `arbol_saman`, `arbol_araguaney`, `arbusto`, `mata_grama`, `vaca`, `toro`, `caballo`, `cerdo`, `gallina`, `gallo`, `pollito` (+ `tile_camino`).

---

## 8. Git

- Default branch: **`main`**.
- **Never** add a `Co-Authored-By` trailer to commits.
- License is **AGPL-3.0** — keep it; derivative network services must share source.
