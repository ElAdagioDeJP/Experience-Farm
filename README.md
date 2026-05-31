<div align="center">

# 🌾 Granja Carabobeña — *Experience-Farm*

**Un paseo virtual por una granja del llano carabobeño.**
Camina entre samanes y araguaneys, recorre el sendero de tierra hasta la cabaña
y siente cómo se vive una granja de Carabobo — todo en un mundo voxel acogedor,
al estilo *Cube World* / *3D Dot Game Heroes*.

[![Godot](https://img.shields.io/badge/Godot-4.6-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![Renderer](https://img.shields.io/badge/render-GL%20Compatibility-5b8?logo=opengl&logoColor=white)](#-requisitos)
[![Physics](https://img.shields.io/badge/physics-Jolt-orange)](https://github.com/godotengine/godot-jolt)
[![Voxel](https://img.shields.io/badge/arte-MagicaVoxel-9cf)](https://ephtracy.github.io/)
[![License](https://img.shields.io/badge/license-AGPL--3.0-brightgreen)](LICENSE)

</div>

---

## ✨ Qué es

Un **walking-simulator** en primera persona: no hay enemigos ni puntajes, solo
un espacio para pasear y observar. La meta es transmitir la atmósfera de una
granja carabobeña — la sabana, los árboles típicos del llano, los animales —
con una estética voxel cálida, colorida y de bajo polígono.

> 🐮 Vacas Carora y toros Brahman, caballos alazanes, cerdos, gallinas, gallos y
> pollitos. 🌳 Samanes de copa ancha y araguaneys amarillos. Un sendero de tierra
> que te guía desde el spawn hasta la cabaña del fondo.

---

## 🎮 Controles

| Acción | Tecla |
|---|---|
| Avanzar / Retroceder | `W` / `S` |
| Izquierda / Derecha | `A` / `D` |
| Mirar | Mouse |
| Liberar / capturar cursor | `Esc` / clic |

---

## 🚀 Empezar

### Requisitos

- **Godot 4.6** (probado con 4.6.2). Renderizador **GL Compatibility** (corre en
  escritorio *y* móvil; **no** uses funciones Forward+/Vulkan: no renderizan).
- Física **Jolt** (incluida en Godot 4.6).
- En Windows el driver de dispositivo es **d3d12**.

### Correr el juego

```bash
git clone https://github.com/ElAdagioDeJP/Experience-Farm.git
cd Experience-Farm
```

Abre la carpeta en Godot 4.6 y pulsa **▶**, o desde línea de comandos:

```bash
godot --path . res://escenas/Main.tscn
```

La escena principal es `escenas/Main.tscn`.

---

## 🧱 Estética voxel

Todo asset propio nace como un `.vox` de **MagicaVoxel** y sigue reglas estrictas
para que toda la granja comparta una sola paleta maestra:

- **Eje Z = arriba**; largo del cuerpo en X, ancho en Y.
- **Regla de 3 tonos** por material: BASE plano + SOMBRA (~15% más oscuro) +
  LUZ (~12% más clara). Sin degradados ni anti-aliasing.
- Esquinas redondeadas (acogedor), ojos grandes con un vóxel de brillo blanco, y
  siluetas reconocibles: el samán = copa ancha de paraguas, el araguaney = copa
  toda amarilla, el Brahman = joroba + orejas caídas + papada.

> Convenciones completas (mapa de índices de paleta, lista de modelos): ver
> [`CLAUDE.md`](CLAUDE.md).

---

## 🔧 Pipeline de assets

```
   MagicaVoxel .vox            tools/vox_to_obj.py            Escena Godot
 (assets/vox_models/)   ──►   .obj + .mtl              ──►   ArrayMesh en
                              (assets/models/)               Main.tscn
```

El convertidor `tools/vox_to_obj.py` mallifica el `.vox` (con *culling* de caras
internas), genera un material plano por color de paleta (look CubeWorld), pasa de
**Z-arriba (MagicaVoxel) → Y-arriba (Godot)** y deja la base en `Y=0`.
**1 vóxel = 1 unidad** (escala al importar en Godot).

```bash
python tools/vox_to_obj.py assets/vox_models assets/models
```

---

## 📂 Estructura

```
escenas/        Escenas y scripts (.tscn / .gd) — nombres en español
  Main.tscn       el nivel (terreno GridMap, flora MultiMesh, jugador, atmósfera)
  jugador/        controlador en primera persona (CharacterBody3D)
  mundo/          ConstructorTerreno.gd (pinta el terreno), EsparcidorFlora.gd (esparce flora)
assets/
  vox_models/     fuentes .vox (MagicaVoxel)
  models/         mallas listas para el motor (.obj/.mtl, .glb, MeshLibrary .tres)
tools/            vox_to_obj.py (convertidor del pipeline)
export/           salida de build
```

---

## 🤖 Flujo con MCP

El proyecto se desarrolla asistido por dos servidores **MCP** (config en
`.mcp.json`): **godot** (`@coding-solo/godot-mcp`, controla el editor: crea
escenas/nodos, corre el proyecto, lee la salida de depuración) y **magicavoxel**
(crea/edita `.vox` directo en `assets/vox_models/`). No hay suite de tests ni
linter: *correr el juego es la verificación*. `GODOT_PATH` en la config es una
ruta local absoluta — cámbiala por la tuya tras clonar.

---

## 📜 Licencia y créditos

Distribuido bajo **AGPL-3.0** — ver [`LICENSE`](LICENSE). Los servicios derivados
en red deben compartir su código fuente.

Assets de terceros (cuando se usen) se acreditan aquí. Ej.: modelos `.glb` bajo
**CC-BY** requieren atribución a su autor.

<div align="center">

*Hecho con cariño llanero. 🐎🌅*

</div>
