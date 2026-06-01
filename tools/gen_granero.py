#!/usr/bin/env python3
"""Generador parametrico de la granja rustica (granero caminable) + cerca de corral.

Construye un modelo voxel al estilo CubeWorld / granero de madera y exporta:
  - assets/vox_models/granero.vox , cerca.vox  (abribles en MagicaVoxel)
  Luego se convierten a .obj con tools/vox_to_obj.py (pipeline del proyecto).

Convenciones (iguales a tools/vox_to_obj.py):
  - Espacio MagicaVoxel: Z = arriba. Se exporta a Godot (Y arriba) como (x, z, -y).
  - Centrado en X/Y, base apoyada en Z=0. 1 voxel = 1 unidad (escalar al instanciar).
  - El PISO interior esta en z=0 (a ras del suelo) para que el jugador
    (CharacterBody3D sin step-up) entre por la puerta sin tropezar un escalon.

Uso: python tools/gen_granero.py   (escribe .vox; el .obj se hace con vox_to_obj.py)
"""
import os
import struct

VOX_DIR = os.path.join("assets", "vox_models")
OBJ_DIR = os.path.join("assets", "models")

# --- Paleta (indice -> RGB). Maderas calidas, piedra gris, acentos. ---
PALETTE = {
    1:  (120, 118, 115),  # piedra base
    2:  (96, 94, 91),     # piedra sombra
    3:  (150, 148, 145),  # piedra luz
    4:  (92, 64, 40),     # pared madera oscura base
    5:  (74, 50, 30),     # pared madera oscura sombra (hiladas)
    6:  (112, 82, 52),    # madera luz
    7:  (150, 110, 70),   # piso madera base
    8:  (170, 128, 84),   # piso madera luz
    9:  (110, 74, 46),    # techo base
    10: (88, 58, 36),     # techo sombra
    11: (250, 225, 140),  # ventana (vidrio calido)
    12: (58, 40, 26),     # marco oscuro
    13: (70, 120, 55),    # enredadera verde base
    14: (98, 150, 72),    # enredadera verde luz
    15: (178, 174, 168),  # tope de piedra (cocina)
    16: (205, 122, 55),   # gabinete naranja
    17: (255, 226, 130),  # luz de lampara
    18: (36, 31, 28),     # metal negro
    19: (124, 86, 52),    # banca madera
    20: (82, 56, 34),     # pilar madera
    21: (60, 110, 48),    # cesped (cerca)
}


class Grid:
    def __init__(self):
        self.v = {}

    def fill(self, x0, x1, y0, y1, z0, z1, c):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                for z in range(z0, z1 + 1):
                    if c is None:
                        self.v.pop((x, y, z), None)
                    else:
                        self.v[(x, y, z)] = c

    def set(self, x, y, z, c):
        if c is None:
            self.v.pop((x, y, z), None)
        else:
            self.v[(x, y, z)] = c

    def bounds(self):
        xs = [p[0] for p in self.v]
        ys = [p[1] for p in self.v]
        zs = [p[2] for p in self.v]
        return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))


def banded_wall(g, x0, x1, y0, y1, z0, z1, base, shadow):
    """Pared con hiladas: cada ~3 niveles Z alterna base/sombra (tablones)."""
    for z in range(z0, z1 + 1):
        c = shadow if ((z) // 3) % 2 == 1 else base
        g.fill(x0, x1, y0, y1, z, z, c)


# ============================================================
#  GRANERO  (piso a ras: z=0)
# ============================================================
def build_granero():
    g = Grid()
    X0, X1 = 8, 55
    Y0, Y1 = 8, 43
    STONE_TOP = 3      # hiladas de piedra: z1..3
    WALL_TOP = 24      # tope de muros (interior ~3.6 m a escala 0.15)
    RIDGE_Z = 38       # caballete
    DOOR_TOP = 16      # alto de la puerta (~2.4 m)
    cx = (X0 + X1) // 2

    def courses(x0, x1, y0, y1, z0, z1):
        """Muro: piedra en z<=STONE_TOP, madera en tablones arriba."""
        for z in range(z0, z1 + 1):
            if z <= STONE_TOP:
                c = 2 if (z % 2 == 0) else 1
            else:
                c = 5 if ((z) // 3) % 2 == 1 else 4
            g.fill(x0, x1, y0, y1, z, z, c)

    # --- Piso de madera a ras del suelo (z=0) ---
    for x in range(X0, X1 + 1):
        for y in range(Y0, Y1 + 1):
            g.set(x, y, 0, 7 if (x + y) % 5 else 8)

    # --- Muros (2 de grosor): piedra abajo, madera arriba ---
    courses(X0, X0 + 1, Y0, Y1, 1, WALL_TOP)        # izquierda
    courses(X1 - 1, X1, Y0, Y1, 1, WALL_TOP)        # derecha
    courses(X0, X1, Y0, Y0 + 1, 1, WALL_TOP)        # frente (Y bajo)
    courses(X0, X1, Y1 - 1, Y1, 1, WALL_TOP)        # fondo

    # --- Puerta frontal a ras, con arco de piedra ---
    g.fill(cx - 4, cx + 4, Y0, Y0 + 1, 0, DOOR_TOP, None)       # hueco hasta el piso
    g.fill(cx - 5, cx - 4, Y0, Y0 + 1, 1, DOOR_TOP, 1)         # jamba piedra izq
    g.fill(cx + 4, cx + 5, Y0, Y0 + 1, 1, DOOR_TOP, 1)         # jamba piedra der
    g.fill(cx - 5, cx + 5, Y0, Y0 + 1, DOOR_TOP, DOOR_TOP + 1, 1)  # dintel/arco

    # --- Ventanas frontales a los lados de la puerta ---
    for sx in (X0 + 5, X1 - 9):
        g.fill(sx, sx + 3, Y0, Y0 + 1, 9, 15, None)
        g.fill(sx, sx + 3, Y0 + 1, Y0 + 1, 9, 15, 11)
        g.fill(sx - 1, sx + 4, Y0, Y0 + 1, 8, 8, 12)
        g.fill(sx - 1, sx + 4, Y0, Y0 + 1, 16, 16, 12)

    # --- Hastiales + techo curvo de granero (gambrel) ---
    profile = []
    for z in range(WALL_TOP, RIDGE_Z + 1):
        t = (z - WALL_TOP) / float(RIDGE_Z - WALL_TOP)
        if t < 0.45:
            hw = 24 - t * (4 / 0.45)             # casi vertical
        else:
            hw = 20 - (t - 0.45) * (18 / 0.55)   # inclinado al caballete
        profile.append((z, max(2, int(round(hw)))))

    for (z, hw) in profile:                       # hastiales de madera
        banded_wall(g, cx - hw, cx + hw, Y0, Y0 + 1, z, z, 4, 5)
        banded_wall(g, cx - hw, cx + hw, Y1 - 1, Y1, z, z, 4, 5)
    g.fill(cx - 3, cx + 3, Y0, Y0 + 1, 27, 32, 12)   # ventana del pajar (marco)
    g.fill(cx - 2, cx + 2, Y0 + 1, Y0 + 1, 28, 31, 11)

    for (z, hw) in profile:                       # faldones con alero
        for dy in range(Y0 - 2, Y1 + 3):
            col = 10 if (z % 2) else 9
            for t in range(0, 3):
                g.set(cx - hw - t, dy, z, col)
                g.set(cx + hw + t, dy, z, col)
    g.fill(cx - 2, cx + 2, Y0 - 2, Y1 + 2, RIDGE_Z, RIDGE_Z, 10)  # caballete

    # --- Porche techado al frente con pilares ---
    PORCH_Y = Y0 - 7
    for px in (X0 + 4, X1 - 4):
        g.fill(px, px + 1, PORCH_Y + 1, PORCH_Y + 2, 0, 18, 20)
    for i, yy in enumerate(range(PORCH_Y, Y0 + 1)):
        zlvl = 19 - i // 2
        g.fill(X0 - 1, X1 + 1, yy, yy, zlvl, zlvl + 1, 9)
    g.fill(X0, X1, PORCH_Y + 1, Y0, 0, 0, 19)     # piso de tablas del porche

    # ============================================================
    #  INTERIOR "COZY"  (todo apoyado en el piso z=0)
    # ============================================================
    # --- Cocina: gabinetes naranja + tope de piedra contra el fondo ---
    g.fill(X0 + 4, X0 + 26, Y1 - 4, Y1 - 2, 1, 6, 16)         # gabinetes
    g.fill(X0 + 4, X0 + 26, Y1 - 4, Y1 - 2, 7, 7, 15)         # tope de piedra
    for gx in range(X0 + 4, X0 + 27, 6):
        g.fill(gx, gx, Y1 - 4, Y1 - 4, 1, 6, 12)             # separadores
    g.fill(X0 + 8, X0 + 20, Y1 - 1, Y1, 9, 17, None)         # ventana amplia
    g.fill(X0 + 8, X0 + 20, Y1 - 1, Y1 - 1, 9, 17, 11)
    g.fill(X0 + 7, X0 + 21, Y1, Y1, 8, 8, 12)
    g.fill(X0 + 7, X0 + 21, Y1, Y1, 18, 18, 12)

    # --- Rincon de descanso: banca en L + mesa + planta ---
    bx, by = X0 + 3, Y0 + 3
    g.fill(bx, bx + 10, by, by + 2, 1, 2, 19)                # asiento (X)
    g.fill(bx, bx + 2, by, by + 8, 1, 2, 19)                # asiento (Y)
    g.fill(bx, bx + 10, by, by, 3, 5, 19)                   # respaldo
    g.fill(bx, bx, by, by + 8, 3, 5, 19)                   # respaldo lateral
    g.fill(bx + 5, bx + 8, by + 5, by + 8, 1, 4, 19)        # mesa
    g.set(bx + 6, by + 6, 5, 13)                            # planta
    g.set(bx + 7, by + 6, 5, 14)

    # --- Lampara colgante sobre la mesa (foco expuesto hacia abajo) ---
    lx, ly = bx + 6, by + 6
    g.fill(lx, lx, ly, ly, 13, WALL_TOP - 1, 18)            # cadena
    g.fill(lx - 1, lx + 1, ly - 1, ly + 1, 10, 12, 18)     # carcasa
    g.set(lx, ly, 9, 17)                                    # foco (debajo, visible)

    # --- Enredaderas en paredes ---
    for vx in range(X0 + 3, X1 - 1, 5):
        h = 5 + (vx % 4)
        for z in range(STONE_TOP + 1, STONE_TOP + 1 + h):
            g.set(vx, Y0, z, 13 if z % 2 else 14)          # exterior frente
    for vy in range(Y0 + 3, Y1 - 3, 6):
        for z in range(WALL_TOP - 6, WALL_TOP):
            g.set(X0 + 1, vy, z, 14 if z % 2 else 13)      # interior

    return g


# ============================================================
#  CERCA (panel de corral reutilizable)
# ============================================================
def build_cerca():
    g = Grid()
    L = 15
    g.fill(0, 1, 0, 1, 0, 11, 20)         # poste izq
    g.fill(L - 1, L, 0, 1, 0, 11, 20)     # poste der
    g.fill(0, L, 0, 0, 3, 4, 19)          # travesano bajo
    g.fill(0, L, 0, 0, 8, 9, 19)          # travesano alto
    return g


# ============================================================
#  ESCRITURA .vox  (RGBA[c] = color c, para tools/vox_to_obj.py)
# ============================================================
def write_vox(path, g):
    minx, maxx, miny, maxy, minz, maxz = g.bounds()
    sx, sy, sz = maxx - minx + 1, maxy - miny + 1, maxz - minz + 1
    vox = [(x - minx, y - miny, z - minz, c) for (x, y, z), c in g.v.items()]

    def chunk(cid, content):
        return cid + struct.pack("<ii", len(content), 0) + content

    size_c = chunk(b"SIZE", struct.pack("<iii", sx, sy, sz))
    xyzi = struct.pack("<i", len(vox))
    for (x, y, z, c) in vox:
        xyzi += struct.pack("<BBBB", x, y, z, c)
    xyzi_c = chunk(b"XYZI", xyzi)
    rgba = b""
    for i in range(256):
        r, gr, b = PALETTE.get(i, (0, 0, 0))
        a = 255 if i in PALETTE else 0
        rgba += struct.pack("<BBBB", r, gr, b, a)
    rgba_c = chunk(b"RGBA", rgba)
    body = size_c + xyzi_c + rgba_c
    main_c = b"MAIN" + struct.pack("<ii", 0, len(body)) + body
    data = b"VOX " + struct.pack("<i", 150) + main_c
    with open(path, "wb") as f:
        f.write(data)
    return sx, sy, sz, len(vox)


def main():
    os.makedirs(VOX_DIR, exist_ok=True)
    for nombre, builder in (("granero", build_granero), ("cerca", build_cerca)):
        g = builder()
        sx, sy, sz, nv = write_vox(os.path.join(VOX_DIR, nombre + ".vox"), g)
        print("%-8s vox=%dx%dx%d voxeles=%d" % (nombre, sx, sy, sz, nv))
    print("Listo. Ahora: python tools/vox_to_obj.py assets/vox_models assets/models")


if __name__ == "__main__":
    main()
