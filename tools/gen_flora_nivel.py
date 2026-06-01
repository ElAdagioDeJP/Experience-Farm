#!/usr/bin/env python3
"""Genera modelos voxel para la reestructuracion del nivel:
  - colina.vox        : modulo de colina suave y ondulante (reemplaza montana piramidal)
  - grama_alta.vox    : grama alta verde viva (reemplaza mata_grama con pilares negros)
  - grama_seca.vox    : grama baja seca/amarilla para mezclar
  - arbusto_v2.vox    : arbusto frondoso y organico (reemplaza arbusto actual)
  - nube.vox          : nube voxel para sistema de nubes dinamicas

Paleta de colores: verde Carabobo, tierra roja, cielo claro.
1 voxel = 1 unidad; escalar al instanciar en Godot.
"""
import os, struct, math

VOX_DIR = os.path.join("assets", "vox_models")

# Paleta comun (consistente con CLAUDE.md: indices 1-3 grama, 4-6 tierra, etc.)
PALETTE = {
    # Grama / vegetacion baja
    1:  (120, 160, 72),   # grama base verde
    2:  (96,  132, 56),   # grama sombra
    3:  (148, 190, 88),   # grama luz
    # Tierra / camino
    4:  (148, 112, 72),   # tierra base
    5:  (120, 88,  56),   # tierra sombra
    6:  (172, 140, 96),   # tierra luz (vena seca)
    # Tronco (compartido con arboles existentes)
    7:  (100, 72,  44),   # tronco base
    8:  (80,  56,  32),   # tronco sombra
    # Follaje verde (arboles / arbustos)
    9:  (60,  110, 50),   # follaje base
    10: (80,  140, 64),   # follaje luz
    11: (44,  84,  36),   # follaje sombra
    # Montania / colinas
    40: (120, 118, 115),  # piedra gris base
    41: (96,  94,  90),   # piedra sombra
    42: (148, 146, 142),  # piedra luz
    43: (88,  110, 72),   # verde de ladera (hierba alta en colina)
    44: (68,  88,  54),   # verde oscuro ladera
    # Grama seca
    50: (188, 168, 100),  # seco base
    51: (164, 144, 80),   # seco sombra
    52: (210, 194, 130),  # seco luz
    # Nube
    60: (240, 242, 248),  # blanco nube
    61: (200, 210, 230),  # gris nube sombra
    62: (255, 255, 255),  # nube pura luz
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


# ============================================================
#  COLINA ONDULANTE  (modulo de 80x60, altura max ~30)
#  Se instancia 12x alrededor de la escena via script
# ============================================================
def build_colina():
    g = Grid()
    W, D = 80, 60   # ancho X, fondo Y
    # Altura de la colina en cada punto: Gaussiana doble (dos protuberancias)
    def altura(x, y):
        cx1, cy1, h1, rx1, ry1 = 25, 22, 28, 14.0, 12.0
        cx2, cy2, h2, rx2, ry2 = 55, 38, 22, 12.0, 10.0
        # evitar div/0 si rx o ry son 0
        g1 = math.exp(-((x-cx1)**2/(2*rx1**2) + (y-cy1)**2/(2*ry1**2)))
        g2 = math.exp(-((x-cx2)**2/(2*rx2**2) + (y-cy2)**2/(2*ry2**2)))
        return max(0, int((g1*h1 + g2*h2)))

    for x in range(W + 1):
        for y in range(D + 1):
            h = altura(x, y)
            if h == 0:
                continue
            for z in range(h):
                # Color: piedra en el cuerpo, verde en la capa superior
                col = 43 if z >= h - 2 else (42 if z >= h - 5 else (40 if z >= h - 12 else 41))
                g.set(x, y, z, col)

    return g


# ============================================================
#  GRAMA ALTA  (mata de hierba viva, ~12x12x14 vox)
#  Varios tallos que se abren desde la base
# ============================================================
def build_grama_alta():
    g = Grid()
    # Base de tierra
    g.fill(2, 9, 2, 9, 0, 1, 4)
    # Tallos en disposicion de abanico
    tallos = [
        (4, 4), (5, 3), (6, 4), (7, 5), (4, 6), (6, 6), (5, 5), (3, 5), (7, 3),
    ]
    for i, (tx, ty) in enumerate(tallos):
        h = 8 + (i % 4)  # variacion de altura
        for z in range(2, h + 2):
            # Inclinar ligeramente (offset cada 3 alturas)
            ox = (i % 3) - 1 if z > 5 else 0
            oy = ((i // 3) % 3) - 1 if z > 6 else 0
            col = 3 if z >= h else (1 if z >= 2 else 2)
            g.set(tx + ox, ty + oy, z, col)
        # Punta del tallo
        g.set(tx + (i % 3) - 1, ty + ((i // 3) % 2), h + 2, 3)
    return g


# ============================================================
#  GRAMA SECA  (mata baja y seca, ~10x10x8 vox)
# ============================================================
def build_grama_seca():
    g = Grid()
    g.fill(2, 7, 2, 7, 0, 0, 5)   # tierra seca
    tallos = [(3, 3), (5, 3), (4, 5), (6, 4), (3, 5), (5, 5)]
    for i, (tx, ty) in enumerate(tallos):
        h = 4 + (i % 3)
        for z in range(1, h + 1):
            col = 52 if z == h else (50 if z % 2 == 0 else 51)
            ox = (i % 2) if z > 3 else 0
            g.set(tx + ox, ty, z, col)
    return g


# ============================================================
#  ARBUSTO V2  (domo esférico denso, sin tronco visible)
#  Referencia: arbusto frondoso tipo bola desde el suelo.
#  Radio 8 vox, centro en z=8 → base rasante en z=0.
# ============================================================
def build_arbusto_v2():
    g = Grid()
    R = 8
    cx, cy, cz = 9, 9, 8   # centro: base en z=0 (8-R=0)
    for x in range(cx - R, cx + R + 1):
        for y in range(cy - R, cy + R + 1):
            for z in range(0, cz + R + 1):
                dx, dy, dz = x - cx, y - cy, z - cz
                dist2 = dx*dx + dy*dy + dz*dz
                if dist2 <= R * R:
                    # Color por altura: sombra abajo, verde medio, luz arriba
                    if dz >= R // 2:
                        col = 10   # verde claro (copa iluminada)
                    elif dz >= 0:
                        col = 9    # verde medio
                    elif dz >= -(R // 2):
                        col = 9    # verde medio (hemisferio inferior)
                    else:
                        col = 11   # verde oscuro (interior/sombra)
                    g.set(x, y, z, col)
    return g


# ============================================================
#  NUBE  (~40x24x12 vox)
#  Forma de cumulus: base plana, cima redondeada
# ============================================================
def build_nube():
    g = Grid()
    W, D, H = 40, 24, 12
    cx, cy = W // 2, D // 2

    # Perfil de la nube: elipse con protuberancias
    def en_nube(x, y, z):
        # protuberancia principal centrada
        r1 = math.sqrt(((x - cx) / 14.0)**2 + ((y - cy) / 8.0)**2 + ((z - 4) / 4.5)**2)
        # protuberancia izquierda
        r2 = math.sqrt(((x - cx + 10) / 9.0)**2 + ((y - cy) / 6.0)**2 + ((z - 3) / 3.5)**2)
        # protuberancia derecha
        r3 = math.sqrt(((x - cx - 10) / 9.0)**2 + ((y - cy) / 6.0)**2 + ((z - 3) / 3.5)**2)
        return min(r1, r2, r3) < 1.0

    for x in range(W + 1):
        for y in range(D + 1):
            for z in range(H + 1):
                if en_nube(x, y, z):
                    # base gris, cima blanca
                    col = 62 if z >= 7 else (60 if z >= 3 else 61)
                    g.set(x, y, z, col)
    return g


# ============================================================
#  ESCRITURA .vox  (RGBA[c] = color c, para tools/vox_to_obj.py)
# ============================================================
def write_vox(path, g):
    if not g.v:
        print(f"  WARN: {path} vacio, ignorado")
        return 0, 0, 0, 0
    minx, maxx, miny, maxy, minz, maxz = g.bounds()
    sx = maxx - minx + 1
    sy = maxy - miny + 1
    sz = maxz - minz + 1
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
    models = [
        ("colina",      build_colina),
        ("grama_alta",  build_grama_alta),
        ("grama_seca",  build_grama_seca),
        ("arbusto_v2",  build_arbusto_v2),
        ("nube",        build_nube),
    ]
    for nombre, builder in models:
        g = builder()
        sx, sy, sz, nv = write_vox(os.path.join(VOX_DIR, nombre + ".vox"), g)
        print(f"{nombre:<14} vox={sx}x{sy}x{sz}  voxeles={nv}")
    print("\nListo. Convertir: python tools/vox_to_obj.py assets/vox_models assets/models")


if __name__ == "__main__":
    main()
