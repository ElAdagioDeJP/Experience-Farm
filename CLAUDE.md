# CLAUDE.md

Operational guide for Claude Code (and compatible coding agents) in this repository.

If you only read one section, read **Quick Guardrails** first.

## Quick Guardrails

1. Keep Godot config stable: `4.6`, `GL Compatibility`, `Jolt`, `d3d12` on Windows.
2. Preserve art direction: voxel, cozy, colorful, low-poly, Cube World vibe.
3. Keep gameplay naming in Spanish (`escenas`, `jugador`, `mover_adelante`).
4. Every first-party model starts as `.vox` in `assets/vox_models/`.
5. Validate by running the game; there is no formal test suite.

---

## 1) Project Identity

**Experience-Farm** (`Granja_Carabobena`) is a first-person walking simulator in a Venezuelan Carabobo farm setting.

- Focus: ambience and exploration, not combat or score loops.
- Visual target: stylized voxel world inspired by *Cube World* / *3D Dot Game Heroes*.
- Mood: warm, approachable, handcrafted.

### Non-negotiable artistic direction

- Avoid realistic/high-poly assets unless explicitly requested.
- Keep silhouettes readable and charming.
- Prioritize coherence across terrain, flora, fauna, and props.

---

## 2) Engine Constraints (Do Not Change Silently)

From `project.godot`:

| Setting | Required Value | Notes |
|---|---|---|
| Engine | `Godot 4.6` | Current baseline |
| Renderer | `GL Compatibility` | Desktop + mobile target |
| Physics 3D | `Jolt` | Keep for consistency |
| Windows device driver | `d3d12` | Existing platform expectation |
| Main scene | `res://escenas/Main.tscn` | Entry point |

### Input map (physical keycodes)

- `mover_adelante` -> `W`
- `mover_atras` -> `S`
- `mover_izquierda` -> `A`
- `mover_derecha` -> `D`
- `ui_cancel` -> `Esc` (free mouse cursor)

> Do not migrate to Forward+/Vulkan features (SDFGI or incompatible advanced shader paths) without an explicit renderer strategy.

---

## 3) Language and Naming Rules

- Gameplay-facing identifiers stay in **Spanish**.
- Directory naming stays in **Spanish**.
- Keep consistency with existing script style and node naming.
- If adding comments in scripts, prefer Spanish for local coherence.

Examples:

- Good: `ConstructorTerreno.gd`, `EsparcidorFlora.gd`, `malla_desde_escena`.
- Avoid: `TerrainBuilder.gd`, `player_move_forward`, mixed-language node trees.

---

## 4) Repository Map

```text
Experience-Farm/
|- escenas/
|  |- Main.tscn
|  |- jugador/
|  `- mundo/
|- assets/
|  |- vox_models/     # source-of-truth voxel assets
|  `- models/         # runtime meshes (.obj/.mtl/.glb/.tres)
|- tools/
|  `- vox_to_obj.py
|- export/
|- project.godot
|- .mcp.json
|- mcp-config.json
|- README.md
|- AGENTS.md
`- LICENSE
```

Notes:

- `.godot/` and `*.import` are ignored cache artifacts.
- `.vox`, `.png`, `.glb` are binary in `.gitattributes`; keep this updated for new binary types.

---

## 5) Asset Pipeline (Core Workflow)

```text
MagicaVoxel (.vox) -> tools/vox_to_obj.py -> .obj/.mtl -> ext_resource in Godot scene
```

Typical command:

```bash
python tools/vox_to_obj.py assets/vox_models assets/models
```

Converter guarantees:

- Internal-face culling to reduce mesh size.
- Flat materials per used palette index (`Kd` color style).
- Axis conversion from MagicaVoxel `Z-up` to Godot `Y-up`.
- Model resting base at `Y=0`.
- `1 voxel = 1 unit` before import-scale tuning.

### `.glb` policy

- `.glb` can be imported natively by Godot.
- Use mostly for approved third-party assets.
- Add attribution in `README.md` and this file when license requires it.

---

## 6) Main Scene Architecture (`escenas/Main.tscn`)

### Terrain layer

- Built with `GridMap` + `escenas/mundo/ConstructorTerreno.gd`.
- MeshLibrary expected index mapping:
  - `0`: grama
  - `1`: tierra
  - `2`: camino
- World intent: broad field, central path spawn -> cabin, compacted clearing near cabin.

### Flora layer

- `MultiMeshInstance3D` + `escenas/mundo/EsparcidorFlora.gd`.
- Seeded scatter for reproducible placement.
- Keep clear radius around path/spawn for readability.
- For trees split in trunk/canopy nodes, keep matching seed/area/count and offset by `altura_offset`.

### Player layer

- `escenas/jugador/Jugador.tscn` + `Jugador.gd`.
- `CharacterBody3D` with WASD, mouse look, gravity, cursor capture flow.
- Expected node hierarchy:

```text
Jugador
|- CollisionShape3D
`- PivoteCamara
   `- Camara
```

### Atmosphere layer

- `WorldEnvironment` with warm procedural sky/fog.
- `DirectionalLight3D` for key sunlight.

---

## 7) Voxel Art Conventions

Keep a consistent global style across all `.vox` assets.

- Axis in MagicaVoxel: `Z = up`; body length usually on `X`, width on `Y`.
- 3-tone rule per material: `BASE + SHADOW + LIGHT`.
- No gradients, no hand-painted anti-aliasing.
- Rounded corners and expressive eyes are preferred stylistic cues.

### Signature silhouettes

- **Saman**: broad umbrella canopy.
- **Araguaney**: yellow canopy, no green crown.
- **Brahman bovines**: hump + drooping ears + dewlap.

### Shared palette index map

| Idx | Use | Idx | Use |
|---|---|---|---|
| 1-3 | grass light/base/shadow | 20 | cow Carora reddish |
| 4-6 | dirt base/shadow/vein | 21 | Brahman gray |
| 7-8 | trunk base/shadow | 22 | muzzle pink |
| 9-11 | foliage base/light/shadow | 23 | horn bone |
| 12 | saman flower | 24 | hoof dark |
| 13-15 | araguaney yellow/light/shadow | 25 | eye black |
| 16 | bush | 26 | white |
| 17 | dry grass | 27-28 | horse alazan/mane |
| 18 | berry red | 29-30 | pig pink/shadow |
| 19 | generic body-shadow | 31 | hen brown |
| 32 | rooster body | 36 | comb red |
| 33 | gold | 37 | beak yellow |
| 34 | tail green | 38 | chick yellow |
| 35 | tail blue |  |  |

Current wave in `assets/vox_models/`:

- `tile_tierra`, `tile_camino`
- `arbol_saman`, `arbol_araguaney`, `arbusto`, `mata_grama`
- `vaca`, `toro`, `caballo`, `cerdo`, `gallina`, `gallo`, `pollito`

---

## 8) MCP Workflow Expectations

Two MCP configs exist and must stay synchronized:

- `.mcp.json`
- `mcp-config.json`

Expected servers:

- `godot` (`@coding-solo/godot-mcp`): scene/node automation, run/stop project, debug output.
- `magicavoxel`: programmatic voxel generation/editing in `assets/vox_models/`.

Operational notes:

- `GODOT_PATH` is machine-local and usually needs manual adjustment after clone.
- MCP cannot replace visual judgment; always run and inspect in-editor/in-game.

---

## 9) Validation Checklist for Changes

Before considering a task done:

1. Project opens without import errors in Godot 4.6.
2. `escenas/Main.tscn` runs.
3. Player movement and mouse look work.
4. New/updated assets appear with correct orientation and scale.
5. Art direction still feels coherent with existing world.
6. No accidental renaming that breaks Spanish naming conventions.

---

## 10) Git and Contribution Policy

- Default branch: `main`.
- Keep license as `AGPL-3.0`.
- Do not add `Co-Authored-By` trailers unless maintainers explicitly request them.
- Keep commits scoped: gameplay logic, pipeline, art assets, and docs should be separable when possible.

---

## 11) Related Docs

- Project overview and onboarding: `README.md`
- Agent-role guide and collaboration protocol: `AGENTS.md`
