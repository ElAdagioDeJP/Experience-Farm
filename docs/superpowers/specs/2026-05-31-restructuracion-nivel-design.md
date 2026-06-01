# Reestructuración del nivel — escala, topografía, flora, camino, nubes

**Fecha:** 2026-05-31
**Proyecto:** Experience-Farm (`Granja_Carabobeña`) — Godot 4.6, GL Compatibility, Jolt.

## Problema

El prototipo actual tiene cinco defectos de fondo:

1. **Escala rota.** Los `.obj` se importan a **1 vóxel = 1 unidad = 1 m**. Una gallina de 8 vóxels mide 8 m. Por eso se aplicaban hacks `1.5×` en escena y nada guarda proporción con el jugador (cápsula de 1.8 m).
2. **Montañas piramidales/puntiagudas** (12 instancias de `montana.obj` en anillo) — no parecen el relieve ondulado del valle de Carabobo.
3. **Flora pobre** — "pilares negros" de grama, arbustos planos.
4. **Camino recto** horneado en `suelo.gdshader` (tira en x≈0). No zigzaguea y no es fuente de verdad para nada.
5. **Árboles que se fusionan** — `EsparcidorFlora.gd` solo excluye un radio alrededor del origen; no respeta distancia entre árboles ni el camino. Sin nubes.

## Estándar de escala (decisión raíz)

**1 vóxel = 0.1 m.** El jugador (cápsula) se mantiene en 1.8 m (≈18 vóxels de referencia). Todas las instancias de `Main.tscn` se reescalan a este estándar; se eliminan los `1.5×`.

| Asset | Altura objetivo | Cómo |
|---|---|---|
| gallina / gallo | ~0.35 m | modelo vox pequeño, ×0.1 |
| pollito | ~0.15 m | diminuto |
| vaca / toro / caballo / cerdo | 1.3–1.6 m | ×0.1 |
| arbol_saman | 7–10 m (paragua ancho) | vox grande + escala extra |
| arbol_araguaney | 6–8 m (copa amarilla, sin verde) | vox grande + escala extra |
| arbustos | 0.6–1.1 m | ×0.1 |
| grama alta / baja | 0.2–0.6 m | ×0.1 |

## Fase 1 — Vóxel (magicavoxel MCP → `tools/vox_to_obj.py`)

1. **Colinas onduladas** — reemplazan `montana.vox`. Nuevo `colina.vox`: domo suave (esfera/cono recortado + ruido + `erode`) de cima redondeada, paleta verdes 1–3. En escena: anillo de instancias con rotación/escala variadas que dan relieve continuo, no picos.
2. **Grama** — rediseñar `mata_grama.vox` (baja) + nuevo `grama_alta.vox` (briznas altas). Mezcla verde vivo (1–3) + seco amarillo (17). Elimina los "pilares negros".
3. **Arbustos** — `arbusto.vox` rehecho: redondeado, frondoso, follaje 9–11, se ve bien agrupado.
4. **Árboles** — verificar silueta paragua (samán) / copa toda amarilla (araguaney); rehacer si la proporción falla a la nueva escala.

Pipeline sin cambios: `.vox` → `python tools/vox_to_obj.py assets/vox_models assets/models` → `.obj`. Eje MagicaVoxel Z-up → Godot Y-up vía `(x, z, -y)`.

## Fase 2 — Godot (escena + scripts)

1. **`Sendero` (Path3D + Curve3D)** — zigzag trazado a mano desde spawn (z≈+120) hasta la cabaña (z≈−120). **Fuente única de verdad** del camino y de la exclusión de flora.
2. **`GeneradorCamino.gd`** (nuevo, sobre un `MeshInstance3D`) — construye por script una malla-cinta de tierra plana siguiendo el `Curve3D` baked, apoyada ~0.02 m sobre el suelo. Material tierra plano (estilo CubeWorld). Se elimina la rama del camino recto de `suelo.gdshader`.
3. **`EsparcidorFlora.gd` reescrito** — Poisson-disk sampling (rejilla de distancia mínima) para que los árboles **no se fusionen**; rechaza toda muestra dentro de `radio_camino` del `Curve3D` (`Curve3D.get_closest_point`). `@export var sendero: NodePath`, `@export var radio_camino: float`, `@export var dist_minima: float`. Tronco + copa comparten la **misma lista de puntos** (semilla determinista) para quedar alineados. Mantiene una sola draw call (MultiMesh).
4. **Nubes** — `ShaderMaterial` de cielo (sky shader, válido en GL Compatibility) que reemplaza el `ProceduralSkyMaterial`. Capas de value-noise que se desplazan con `TIME` sobre un cielo cálido de sabana. (Nota: `ProceduralSkyMaterial` no tiene parámetro de nubes; "animarlo" exige un sky shader propio.)
5. **Reescalado** de todas las instancias de Corral/árboles/flora al estándar 0.1; se quitan los hacks `1.5×`.

## Arquitectura / fuentes de verdad

```
Sendero (Path3D/Curve3D)
   ├─► GeneradorCamino.gd  → malla cinta de tierra (visual)
   └─► EsparcidorFlora.gd  → exclusión (lógica)   ← misma curva, sin desincronización
```

Cada unidad es independiente y testeable: el camino se dibuja sin saber de flora; la flora consulta la curva por interfaz (`get_closest_point`).

## Verificación

No hay test suite ni lint. Verificación = correr el juego (godot MCP `run_project`) y observar: jugador a escala humana, gallinas pequeñas, árboles altos sin fusionarse, camino zigzag despejado de obstáculos, colinas onduladas en el horizonte, nubes desplazándose.

## Fuera de alcance (YAGNI)

IA/movimiento de animales, revivir GridMap, LOD, rework de colisiones más allá de lo que fuerce la escala.
