#!/usr/bin/env python3
"""Genera variantes VOX puras y luego se convierten a OBJ/MTL.

Salida VOX: assets/vox_models/variantes/
Salida OBJ/MTL: assets/models/variantes/ (via tools/vox_to_obj.py)
"""

from __future__ import annotations

from pathlib import Path
import struct
import subprocess


ROOT = Path(__file__).resolve().parents[1]
VOX_BASE = ROOT / "assets" / "vox_models"
VOX_OUT = VOX_BASE / "variantes"
OBJ_OUT = ROOT / "assets" / "models" / "variantes"


def leer_chunks(data: bytes) -> list[tuple[bytes, bytes]]:
    chunks: list[tuple[bytes, bytes]] = []
    off = 8
    fin = len(data)
    while off + 12 <= fin:
        cid = data[off : off + 4]
        n_content = struct.unpack_from("<i", data, off + 4)[0]
        content_off = off + 12
        chunks.append((cid, data[content_off : content_off + n_content]))
        off = content_off + n_content
    return chunks


def parsear_vox(path: Path) -> tuple[tuple[int, int, int], list[tuple[int, int, int, int]], list[tuple[int, int, int, int]]]:
    data = path.read_bytes()
    if data[:4] != b"VOX ":
        raise ValueError(f"No es VOX: {path}")

    size = (16, 16, 16)
    voxels: list[tuple[int, int, int, int]] = []
    palette = [(136, 136, 136, 255)] * 256

    for cid, content in leer_chunks(data):
        if cid == b"SIZE":
            size = struct.unpack_from("<iii", content, 0)
        elif cid == b"XYZI":
            n = struct.unpack_from("<i", content, 0)[0]
            for i in range(n):
                x, y, z, c = content[4 + i * 4 : 8 + i * 4]
                voxels.append((x, y, z, c))
        elif cid == b"RGBA":
            pal = []
            for i in range(256):
                r, g, b, a = content[i * 4 : i * 4 + 4]
                pal.append((r, g, b, a))
            palette = pal
    return size, voxels, palette


def chunk(cid: bytes, content: bytes) -> bytes:
    return cid + struct.pack("<ii", len(content), 0) + content


def escribir_vox(path: Path, size: tuple[int, int, int], voxels: list[tuple[int, int, int, int]], palette: list[tuple[int, int, int, int]]) -> None:
    sx, sy, sz = size
    size_c = struct.pack("<iii", sx, sy, sz)
    xyzi = bytearray(struct.pack("<i", len(voxels)))
    for x, y, z, c in voxels:
        xyzi.extend(bytes((x, y, z, c)))
    rgba = bytearray()
    pal = palette[:256]
    if len(pal) < 256:
        pal = pal + [(0, 0, 0, 255)] * (256 - len(pal))
    for r, g, b, a in pal:
        rgba.extend(bytes((r, g, b, a)))

    children = chunk(b"SIZE", size_c) + chunk(b"XYZI", bytes(xyzi)) + chunk(b"RGBA", bytes(rgba))
    main = b"MAIN" + struct.pack("<ii", 0, len(children))
    data = b"VOX " + struct.pack("<i", 150) + main + children
    path.write_bytes(data)


def aplicar_remapeo(voxels: list[tuple[int, int, int, int]], m: dict[int, int]) -> list[tuple[int, int, int, int]]:
    out = []
    for x, y, z, c in voxels:
        out.append((x, y, z, m.get(c, c)))
    return out


def bounds(voxels: list[tuple[int, int, int, int]]) -> tuple[int, int, int, int, int, int]:
    xs = [v[0] for v in voxels]
    ys = [v[1] for v in voxels]
    zs = [v[2] for v in voxels]
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)


def add_or_set(voxels: list[tuple[int, int, int, int]], extra: list[tuple[int, int, int, int]]) -> list[tuple[int, int, int, int]]:
    d = {(x, y, z): c for x, y, z, c in voxels}
    for x, y, z, c in extra:
        d[(x, y, z)] = c
    return [(x, y, z, c) for (x, y, z), c in sorted(d.items())]


def variantes_desde_base(nombre: str, size: tuple[int, int, int], voxels: list[tuple[int, int, int, int]]) -> list[list[tuple[int, int, int, int]]]:
    if nombre == "vaca":
        v1 = aplicar_remapeo(voxels, {})
        v2 = aplicar_remapeo(voxels, {20: 19, 19: 20})
        v3 = aplicar_remapeo(voxels, {20: 24, 19: 21, 26: 19})
        v4 = aplicar_remapeo(voxels, {20: 22, 19: 27, 26: 23})
        return [v1, v2, v3, v4]

    if nombre == "toro":
        v1 = aplicar_remapeo(voxels, {})
        v2 = aplicar_remapeo(voxels, {21: 24, 19: 21, 26: 19})
        v3 = aplicar_remapeo(voxels, {21: 26, 19: 26})
        v4 = aplicar_remapeo(voxels, {21: 20, 19: 27, 26: 23})
        return [v1, v2, v3, v4]

    if nombre == "caballo":
        v1 = aplicar_remapeo(voxels, {})
        v2 = aplicar_remapeo(voxels, {27: 20, 28: 19, 19: 27})
        v3 = aplicar_remapeo(voxels, {27: 21, 28: 24, 19: 26})
        v4 = aplicar_remapeo(voxels, {27: 33, 28: 27, 19: 22})
        return [v1, v2, v3, v4]

    if nombre == "cerdo":
        b = bounds(voxels)
        minx, maxx, miny, maxy, minz, maxz = b
        v1 = aplicar_remapeo(voxels, {})
        v2 = aplicar_remapeo(voxels, {29: 30, 30: 29})
        mud = []
        side_x = minx
        for y in range(miny + 1, miny + 4):
            for z in range(minz + 1, minz + 4):
                mud.append((side_x, y, z, 6 if (y + z) % 2 == 0 else 4))
        v2 = add_or_set(v2, mud)
        v3 = aplicar_remapeo(voxels, {29: 24, 30: 19})
        v4 = aplicar_remapeo(voxels, {29: 22, 30: 29})
        return [v1, v2, v3, v4]

    if nombre == "gallina":
        v1 = aplicar_remapeo(voxels, {31: 26, 19: 26})
        v2 = aplicar_remapeo(voxels, {31: 31, 19: 19})
        v3 = aplicar_remapeo(voxels, {31: 20, 19: 27})
        v4 = aplicar_remapeo(voxels, {31: 24, 19: 21})
        return [v1, v2, v3, v4]

    if nombre == "gallo":
        v1 = aplicar_remapeo(voxels, {})
        v2 = aplicar_remapeo(voxels, {32: 33, 34: 33, 35: 34})
        v3 = aplicar_remapeo(voxels, {32: 26, 34: 35, 35: 34})
        v4 = aplicar_remapeo(voxels, {32: 24, 33: 23, 34: 21, 35: 24})
        return [v1, v2, v3, v4]

    return [voxels]


def generar_pollito_vox(v: int) -> tuple[tuple[int, int, int], list[tuple[int, int, int, int]]]:
    size = (16, 16, 16)
    vox: list[tuple[int, int, int, int]] = []

    # Variantes con silueta tipo "baby chicken" y cambios de paleta.
    # idx relevantes: 26 blanco, 25 ojo, 22 pico rosado, 37 amarillo, 23/24 patas.
    body_base, body_light, body_shadow, beak = {
        1: (26, 26, 21, 22),
        2: (38, 33, 17, 37),
        3: (31, 26, 19, 22),
        4: (21, 26, 24, 22),
    }[v]

    def agregar_caja(x0: int, x1: int, y0: int, y1: int, z0: int, z1: int, color: int) -> None:
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                for z in range(z0, z1 + 1):
                    vox.append((x, y, z, color))

    # Cabeza grande (cubo principal).
    agregar_caja(4, 11, 4, 11, 6, 13, body_base)

    # Cuerpo compacto debajo de la cabeza.
    agregar_caja(5, 10, 5, 10, 3, 6, body_base)

    # Alas laterales sencillas.
    agregar_caja(3, 3, 6, 9, 6, 9, body_shadow)
    agregar_caja(12, 12, 6, 9, 6, 9, body_shadow)

    # Pico frontal 2x2x2.
    agregar_caja(7, 8, 2, 3, 8, 9, beak)

    # Patas y pies.
    agregar_caja(6, 6, 7, 7, 0, 2, 23)
    agregar_caja(9, 9, 7, 7, 0, 2, 23)
    agregar_caja(5, 6, 7, 8, 0, 0, 24)
    agregar_caja(9, 10, 7, 8, 0, 0, 24)

    # Ojos.
    vox.append((5, 4, 10, 25))
    vox.append((10, 4, 10, 25))

    # Luces/sombras suaves para evitar bloque plano.
    detalle: list[tuple[int, int, int, int]] = []
    for x, y, z, c in vox:
        if c != body_base:
            continue
        if z >= 11 and (x + y) % 3 == 0:
            detalle.append((x, y, z, body_light))
        elif (x in (4, 11) or y in (4, 11) or z <= 4) and (x + y + z) % 2 == 0:
            detalle.append((x, y, z, body_shadow))

    return size, add_or_set(vox, detalle)


def main() -> None:
    VOX_OUT.mkdir(parents=True, exist_ok=True)
    OBJ_OUT.mkdir(parents=True, exist_ok=True)

    bases = ["vaca", "toro", "caballo", "cerdo", "gallina", "gallo"]
    for nombre in bases:
        size, voxels, palette = parsear_vox(VOX_BASE / f"{nombre}.vox")
        vars_vox = variantes_desde_base(nombre, size, voxels)
        for i, vv in enumerate(vars_vox, start=1):
            escribir_vox(VOX_OUT / f"{nombre}_v{i}.vox", size, vv, palette)

    # Pollitos nuevos, modelados aparte (no reutiliza gallina).
    _, _, palette_pollito = parsear_vox(VOX_BASE / "pollito.vox")
    for i in range(1, 5):
        size, vox = generar_pollito_vox(i)
        escribir_vox(VOX_OUT / f"pollito_v{i}.vox", size, vox, palette_pollito)

    subprocess.check_call([
        "python",
        str(ROOT / "tools" / "vox_to_obj.py"),
        str(VOX_OUT),
        str(OBJ_OUT),
        "0.1",
    ])

    print(f"Variantes VOX generadas en: {VOX_OUT}")
    print(f"Variantes OBJ/MTL generadas en: {OBJ_OUT}")


if __name__ == "__main__":
    main()
