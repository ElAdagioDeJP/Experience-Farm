# AGENTS.md

Collaboration protocol for AI/code agents working on **Experience-Farm**.

This file complements `CLAUDE.md`:

- `CLAUDE.md` defines project constraints and technical ground truth.
- `AGENTS.md` defines *how* an agent should operate in this repository.

## Mission

Agents should help evolve the project while preserving:

1. Core artistic identity (voxel, cozy, colorful, low-poly).
2. Stable Godot setup (`4.6`, `GL Compatibility`, `Jolt`).
3. Spanish gameplay naming conventions.

## Working Principles

### 1) Read before editing

- Review `README.md`, `CLAUDE.md`, and relevant scene/script files before proposing structural changes.
- Prefer minimal, targeted edits over broad rewrites unless requested.

### 2) Protect project invariants

Do not silently change:

- renderer/backend strategy,
- physics backend,
- input action names,
- main scene path,
- established art direction.

If a task requires changing an invariant, call it out explicitly in the change notes.

### 3) Use Spanish in gameplay-facing code

Use Spanish for:

- node names,
- script/class filenames,
- exported gameplay properties,
- input action identifiers.

English is acceptable for tooling, external integrations, and documentation intended for broad audiences.

### 4) Validate with runtime behavior

There is no formal test suite. Validation is practical:

- run the project,
- open `escenas/Main.tscn`,
- verify movement/camera,
- verify imported assets orientation and scale.

## Recommended Agent Roles

### A) Gameplay Agent

Scope:

- player movement and camera behavior,
- interaction prototypes,
- lightweight world logic.

Rules:

- keep controllers readable,
- expose tuning values via `@export`,
- avoid introducing complex systems not requested (quests, combat loops, inventories) unless explicitly asked.

### B) World/Scene Agent

Scope:

- terrain and flora distribution,
- scene composition,
- atmosphere tuning.

Rules:

- maintain clear path readability,
- preserve warm visual mood,
- protect performance-friendly choices (`GridMap`, `MultiMeshInstance3D`).

### C) Asset Pipeline Agent

Scope:

- `.vox` authoring flow,
- converter updates,
- import consistency.

Rules:

- first-party assets begin as `.vox` in `assets/vox_models/`,
- keep `.vox -> .obj/.mtl` converter behavior stable unless change is intentional and documented,
- avoid breaking axis expectations (`Z-up` source to `Y-up` runtime).

### D) Documentation Agent

Scope:

- README clarity,
- architecture docs,
- contributor onboarding.

Rules:

- use concise Markdown,
- keep sections skimmable (headings, lists, short paragraphs),
- synchronize docs when behavior/config changes.

## Definition of Done (Agent Version)

A task is considered complete when:

1. Requested files are updated with consistent style and naming.
2. No forbidden configuration drift is introduced.
3. Changes are understandable from the diff alone.
4. Runtime validation steps are executed or explicitly listed if execution is unavailable.
5. Documentation is updated when pipeline, controls, or architecture change.

## Safe Change Patterns

Good patterns:

- Add a focused feature in one script plus scene wiring.
- Add a new voxel asset with documented source and conversion.
- Improve docs with concrete commands and guardrails.

Risky patterns (avoid unless requested):

- Global renames across Spanish identifiers.
- Renderer/physics migrations.
- Introducing high-poly asset packs that break visual language.
- Large refactors that mix gameplay, art, and docs in one commit.

## Handoff Format

When an agent finishes, report with this compact structure:

1. **What changed** (files + intent).
2. **Why** (problem solved / quality improved).
3. **Validation** (what was run/checked).
4. **Follow-ups** (optional, short numbered list).

## Quick References

- Main scene: `escenas/Main.tscn`
- Player: `escenas/jugador/Jugador.tscn`
- Terrain/flora scripts: `escenas/mundo/ConstructorTerreno.gd`, `escenas/mundo/EsparcidorFlora.gd`
- Voxel sources: `assets/vox_models/`
- Runtime meshes: `assets/models/`
- Converter: `tools/vox_to_obj.py`
- Ops context: `CLAUDE.md`
