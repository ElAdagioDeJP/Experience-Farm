<div align="center">

# Granja Carabobeña - Experience-Farm

**Un walking simulator voxel en primera persona, inspirado en el llano carabobeño (Venezuela).**

[![Godot](https://img.shields.io/badge/Godot-4.6-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![Renderer](https://img.shields.io/badge/render-GL%20Compatibility-5b8?logo=opengl&logoColor=white)](#requisitos)
[![Physics](https://img.shields.io/badge/physics-Jolt-orange)](https://github.com/godotengine/godot-jolt)
[![Arte](https://img.shields.io/badge/arte-MagicaVoxel-9cf)](https://ephtracy.github.io/)
[![License](https://img.shields.io/badge/license-AGPL--3.0-brightgreen)](LICENSE)

</div>

## Visión

Experience-Farm busca recrear la sensación de caminar por una granja del estado Carabobo en un entorno acogedor y estilizado.

- Sin combate, sin HUD complejo y sin objetivos de puntuación.
- Enfoque en atmósfera: sabana, senderos de tierra, cabaña, árboles icónicos y fauna local.
- Dirección artística fija: voxel blocky, colorida y low-poly, con referencia a *Cube World* / *3D Dot Game Heroes*.

## Características actuales

- Exploración libre en primera persona.
- Terreno procedural con `GridMap` y biblioteca de mallas.
- Flora distribuida con `MultiMeshInstance3D` para mejor rendimiento.
- Reparto inicial de fauna voxel: vaca, toro, caballo, cerdo, gallina, gallo y pollito.
- Árboles representativos del llano: samán y araguaney.

## Requisitos

- `Godot 4.6` (probado con `4.6.2`).
- Renderizador: `GL Compatibility`.
- Física 3D: `Jolt`.
- En Windows: driver de dispositivo `d3d12`.

> Importante: no usar funciones exclusivas de Forward+ o Vulkan (por ejemplo SDFGI y ciertos shaders avanzados), porque no renderizan en la configuración de este proyecto.

## Inicio rápido

```bash
git clone https://github.com/ElAdagioDeJP/Experience-Farm.git
cd Experience-Farm
```

Abre el proyecto en Godot y ejecuta la escena principal `escenas/Main.tscn`.

Opcional por CLI:

```bash
godot --path . res://escenas/Main.tscn
```

## Controles

| Acción | Tecla |
|---|---|
| Mover adelante / atras | `W` / `S` |
| Mover izquierda / derecha | `A` / `D` |
| Mirar | Mouse |
| Liberar cursor | `Esc` |
| Recapturar cursor | Clic izquierdo |

## Estructura del repositorio

```text
escenas/
  Main.tscn             # Escena principal
  jugador/              # Jugador.tscn + Jugador.gd
  mundo/                # ConstructorTerreno.gd + EsparcidorFlora.gd
assets/
  vox_models/           # Fuente artística .vox (MagicaVoxel)
  models/               # Mallas listas para Godot (.obj/.mtl/.glb/.tres)
tools/
  vox_to_obj.py         # Conversor .vox -> .obj/.mtl
export/                 # Salida de builds
project.godot           # Configuración del motor
CLAUDE.md               # Contexto técnico y reglas de implementación
AGENTS.md               # Guía operativa para agentes/IA colaborando en el repo
```

## Pipeline de assets voxel

```text
MagicaVoxel (.vox) -> tools/vox_to_obj.py -> OBJ/MTL -> referencia en escena Godot
```

Flujo recomendado:

1. Crear o editar modelos en `assets/vox_models/`.
2. Convertir a formato de runtime:

   ```bash
   python tools/vox_to_obj.py assets/vox_models assets/models
   ```

3. Referenciar el asset generado en `escenas/Main.tscn` u otra escena.

El conversor:

- aplica *culling* de caras internas para reducir geometría,
- genera materiales planos por índice de color,
- transforma eje `Z-up` (MagicaVoxel) a `Y-up` (Godot),
- deja la base del modelo en `Y=0`.

## Convenciones de estilo artístico

- Todo asset propio comienza en `.vox`.
- Regla de 3 tonos por material: base, sombra y luz.
- Sin gradientes ni antialiasing pintado a mano.
- Siluetas claras y legibles primero; detalle después.

Para la guía completa de paleta, índices y modelos de referencia, ver `CLAUDE.md`.

## Flujo MCP

El proyecto mantiene configuración MCP en dos archivos que deben permanecer sincronizados:

- `.mcp.json`
- `mcp-config.json`

Servidores esperados:

- `godot` (`@coding-solo/godot-mcp`): automatiza acciones en editor Godot.
- `magicavoxel`: crea/edita `.vox` dentro de `assets/vox_models/`.

No existe test suite automatizada: la validación principal es ejecutar el juego y comprobar escena, colisiones, cámara y rendimiento básico.

## Contribución

Si vas a colaborar, prioriza consistencia con la dirección del proyecto:

- Nombres de carpetas y gameplay en español (`escenas`, `jugador`, `mover_adelante`, etc.).
- Scripts con variables tipadas y parámetros configurables vía `@export`.
- Cambios visuales alineados al look voxel establecido.
- No introducir assets realistas/high-poly sin justificación explícita.

## Licencia y créditos

- Licencia: `AGPL-3.0` (ver `LICENSE`).
- Si se agregan assets de terceros (por ejemplo `.glb` bajo CC-BY), documentar atribución en este README y en `CLAUDE.md`.

<div align="center">

Hecho con cariño llanero.

</div>
