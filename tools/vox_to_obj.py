#!/usr/bin/env python3
"""Convierte modelos MagicaVoxel .vox a .obj + .mtl para importar en Godot 4.

- Lee chunks SIZE / XYZI / RGBA del formato .vox.
- Mallifica con culling de caras internas (solo emite caras hacia vacio).
- Un material plano por color de paleta usado (Kd = color), look CubeWorld.
- Convierte de espacio MagicaVoxel (Z arriba) a Godot (Y arriba): (x, z, -y).
- Centra en X/Z y apoya la base en Y=0. Unidades: 1 voxel = 1 unidad
  (aplicar escala en la importacion de Godot, p.ej. 0.125 para 16 vox = 2 m).

Uso: python tools/vox_to_obj.py <dir_entrada> <dir_salida>
"""
import os
import sys
import struct

# Paleta por defecto de MagicaVoxel (usada si el .vox no trae chunk RGBA).
DEFAULT_PALETTE = [0x00000000] + [
    0xffffffff, 0xffccffff, 0xff99ffff, 0xff66ffff, 0xff33ffff, 0xff00ffff,
] + [0xff888888] * 249  # relleno; los modelos de este proyecto si traen RGBA.


def leer_chunks(data):
    # Lectura lineal: tras 'VOX '(4)+version(4) viene MAIN (content=0) y luego
    # sus sub-chunks secuenciales. Avanzamos 12 (cabecera) + n_content por chunk,
    # ignorando n_children (solo MAIN lo usa y su content es 0). Asi saltamos
    # limpiamente chunks de escena (nTRN/nGRP/nSHP/LAYR/MATL...) sin desalinear.
    chunks = []
    off = 8
    fin = len(data)
    while off + 12 <= fin:
        cid = data[off:off + 4]
        (n_content,) = struct.unpack_from("<i", data, off + 4)
        content_off = off + 12
        chunks.append((cid, data[content_off:content_off + n_content]))
        off = content_off + n_content
    return chunks


def parsear_vox(path):
    with open(path, "rb") as f:
        data = f.read()
    assert data[:4] == b"VOX ", "no es un .vox"
    chunks = leer_chunks(data)

    size = None
    voxels = []
    palette = None
    for cid, content in chunks:
        if cid == b"SIZE":
            size = struct.unpack_from("<iii", content, 0)
        elif cid == b"XYZI":
            (n,) = struct.unpack_from("<i", content, 0)
            for i in range(n):
                x, y, z, c = content[4 + i * 4: 8 + i * 4]
                voxels.append((x, y, z, c))
        elif cid == b"RGBA":
            # Este MCP escribe .vox donde el voxel de valor v usa RGBA[v]
            # (no el estandar RGBA[v-1]). Indexamos directo: palette[v] = RGBA[v].
            palette = []
            for i in range(256):
                r, g, b, a = content[i * 4: i * 4 + 4]
                palette.append((r, g, b, a))
    if palette is None:
        palette = [(136, 136, 136, 255)] * 256
    return size, voxels, palette


# Caras de un cubo unitario en (x,y,z): (dir_vecino, [4 vertices CCW vistos afuera])
CARAS = [
    ((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]),
    ((-1, 0, 0), [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
    ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]),
    ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
    ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]),
    ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]),
]


def vox_a_godot(p):
    # MagicaVoxel (X der, Y adelante, Z arriba) -> Godot (X der, Y arriba, Z atras).
    x, y, z = p
    return (x, z, -y)


def convertir(path_vox, path_obj, path_mtl, escala=1.0):
    size, voxels, palette = parsear_vox(path_vox)
    ocupados = {(x, y, z): c for (x, y, z, c) in voxels}

    nombre_mtl = os.path.basename(path_mtl)
    vertices = []          # lista de (gx,gy,gz)
    idx_vert = {}          # (gx,gy,gz) -> indice 1-based en obj
    caras_por_color = {}   # color_idx -> lista de (i0,i1,i2,i3)
    colores_usados = set()

    def vid(gv):
        i = idx_vert.get(gv)
        if i is None:
            vertices.append(gv)
            i = len(vertices)
            idx_vert[gv] = i
        return i

    for (x, y, z, c) in voxels:
        for (dvec, quad) in CARAS:
            vecino = (x + dvec[0], y + dvec[1], z + dvec[2])
            if vecino in ocupados:
                continue  # cara interna, se omite
            ids = []
            for (ox, oy, oz) in quad:
                gv = vox_a_godot((x + ox, y + oy, z + oz))
                ids.append(vid(gv))
            caras_por_color.setdefault(c, []).append(tuple(ids))
            colores_usados.add(c)

    if not vertices:
        print("  (vacio, omitido)")
        return False

    # Centrar en X/Z, apoyar base en Y=0.
    xs = [v[0] for v in vertices]
    ys = [v[1] for v in vertices]
    zs = [v[2] for v in vertices]
    cx = (min(xs) + max(xs)) / 2.0
    cz = (min(zs) + max(zs)) / 2.0
    miny = min(ys)

    # Escribir .mtl
    with open(path_mtl, "w") as m:
        for c in sorted(colores_usados):
            r, g, b, a = palette[c]
            m.write("newmtl c%d\n" % c)
            m.write("Kd %.4f %.4f %.4f\n" % (r / 255.0, g / 255.0, b / 255.0))
            m.write("Ka 0 0 0\nKs 0 0 0\nillum 1\nd 1\n\n")

    # Escribir .obj
    with open(path_obj, "w") as o:
        o.write("# generado por tools/vox_to_obj.py desde %s\n" % os.path.basename(path_vox))
        o.write("mtllib %s\n" % nombre_mtl)
        for (gx, gy, gz) in vertices:
            o.write("v %.4f %.4f %.4f\n" % (
                (gx - cx) * escala, (gy - miny) * escala, (gz - cz) * escala))
        for c in sorted(caras_por_color):
            o.write("usemtl c%d\n" % c)
            for (a, b, cc, d) in caras_por_color[c]:
                o.write("f %d %d %d %d\n" % (a, b, cc, d))

    print("  v=%d caras=%d colores=%d" % (
        len(vertices), sum(len(f) for f in caras_por_color.values()), len(colores_usados)))
    return True


def main():
    if len(sys.argv) < 3:
        print("uso: python tools/vox_to_obj.py <dir_entrada> <dir_salida> [escala]")
        sys.exit(1)
    din, dout = sys.argv[1], sys.argv[2]
    escala = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
    os.makedirs(dout, exist_ok=True)
    for fn in sorted(os.listdir(din)):
        if not fn.lower().endswith(".vox"):
            continue
        nombre = os.path.splitext(fn)[0]
        print(nombre)
        convertir(
            os.path.join(din, fn),
            os.path.join(dout, nombre + ".obj"),
            os.path.join(dout, nombre + ".mtl"),
            escala,
        )


if __name__ == "__main__":
    main()
