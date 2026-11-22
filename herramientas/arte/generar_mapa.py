# -*- coding: utf-8 -*-
"""Mapa del Mundo 1 estilo Plantas vs Zombies 2: un paisaje con un camino de niveles.

Uso: python generar_mapa.py <carpeta juego>
"""
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw

JUEGO = sys.argv[1]
SP = os.path.join(JUEGO, "arte", "sprites")
W, H = 1040, 360
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0
# deben coincidir con Datos.NODOS en el juego
NODOS = [(70, 282), (178, 226), (288, 280), (398, 204), (516, 266), (628, 210), (740, 274), (872, 208), (984, 268)]
rng = random.Random(8)


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def degradado(y0, y1, colores):
    pal = [hexc(c) for c in colores]
    a = np.zeros((y1 - y0, W, 3), dtype=np.uint8)
    n = len(pal) - 1
    for y in range(y1 - y0):
        v = y / (y1 - y0 - 1) * n
        for x in range(W):
            i = int(v + BAYER[(y + y0) % 4, x % 4] * 0.999)
            a[y, x] = pal[min(i, n)]
    return Image.fromarray(a, "RGB")


im = Image.new("RGBA", (W, H), (0, 0, 0, 255))
cielo = degradado(0, 176, ["#150d2a", "#1f1236", "#2e1740", "#46204c", "#6a2a52", "#96384e", "#c8553f", "#e88a42"])
im.paste(cielo, (0, 0))
d = ImageDraw.Draw(im)

# estrellas
for _ in range(190):
    x, y = rng.randint(0, W - 1), int(rng.random() ** 1.6 * 110)
    d.point((x, y), fill=rng.choice([(255, 255, 255, 255), (200, 190, 255, 255), (150, 140, 200, 255)]))
for _ in range(10):
    x, y = rng.randint(0, W - 1), rng.randint(0, 70)
    d.line([(x - 1, y), (x + 1, y)], fill=(255, 255, 255, 255))
    d.line([(x, y - 1), (x, y + 1)], fill=(255, 255, 255, 255))


def planeta(cx, cy, r, c1, c2, c3, anillo=None):
    a = np.array(im)
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if not (0 <= x < W and 0 <= y < H):
                continue
            dx, dy = (x - cx) / r, (y - cy) / r
            if dx * dx + dy * dy > 1:
                continue
            z = math.sqrt(max(0.0, 1 - dx * dx - dy * dy))
            luz = max(0.0, -0.55 * dx - 0.55 * dy + 0.62 * z)
            v = luz + BAYER[y % 4, x % 4] * 0.22
            a[y, x, :3] = c1 if v < 0.34 else (c2 if v < 0.72 else c3)
    im.paste(Image.fromarray(a, "RGBA"), (0, 0))
    if anillo:
        dd = ImageDraw.Draw(im)
        dd.arc([cx - int(r * 1.8), cy - int(r * 0.42), cx + int(r * 1.8), cy + int(r * 0.42)], 200, 500, fill=anillo, width=2)


planeta(360, 62, 34, hexc("#3a1a50"), hexc("#6a3070"), hexc("#a85a88"), hexc("#d890a8") + (255,))
planeta(742, 40, 15, hexc("#2a2050"), hexc("#50408a"), hexc("#8a80c8"))
planeta(980, 78, 22, hexc("#4a1a30"), hexc("#8a3040"), hexc("#d86048"))
d = ImageDraw.Draw(im)


def cordillera(seed, base, amp, col, detalle=None, paso=(14, 38)):
    r = random.Random(seed)
    x = -20
    pts = [(-20, 200)]
    tops = []
    while x < W + 30:
        y = base - r.random() * amp
        pts.append((x, y))
        tops.append((x, y))
        x += r.randint(*paso)
    pts += [(W + 30, 200)]
    d.polygon(pts, fill=col)
    if detalle:
        for (x, y) in tops:
            q = r.random()
            if q < 0.16:
                d.rectangle([x - 5, y - 16, x + 5, y + 8], fill=col)
                d.point((x, y - 12), fill=detalle)
                d.point((x + 3, y - 6), fill=detalle)
            elif q < 0.28:
                d.line([(x, y), (x, y - 26)], fill=col, width=1)
                d.line([(x - 8, y - 24), (x + 8, y - 24)], fill=col, width=1)
                d.point((x + 8, y - 26), fill=detalle)
            elif q < 0.38:
                d.ellipse([x - 9, y - 9, x + 9, y + 9], fill=col)


cordillera(1, 150, 58, hexc("#4e2146") + (255,), hexc("#f0b060") + (255,))
cordillera(2, 164, 50, hexc("#3c1a38") + (255,), hexc("#ffcf70") + (255,), (10, 28))
cordillera(3, 176, 34, hexc("#2b1528") + (255,), None, (8, 22))

# suelo
suelo = degradado(172, H, ["#241722", "#2a1b22", "#2f1f21", "#352320", "#3a2820", "#3d2a20"])
im.paste(suelo, (0, 172))
d = ImageDraw.Draw(im)


def tono(*cs):
    return hexc(rng.choice(cs)) + (255,)


# placas y manchas del suelo
for _ in range(95):
    x, y = rng.randint(-20, W), rng.randint(180, H)
    an, al = rng.randint(16, 64), rng.randint(5, 16)
    c = tono("#2c1e20", "#332320", "#3a2922", "#2a2228")
    d.rectangle([x, y, x + an, y + al], fill=c)
    d.line([(x, y), (x + an, y)], fill=tono("#46322a", "#3f3028"))
for _ in range(14):
    x, y = rng.randint(0, W), rng.randint(190, H - 10)
    rx, ry = rng.randint(14, 36), rng.randint(4, 9)
    d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=hexc("#14121f") + (255,))
    d.arc([x - rx + 3, y - ry + 1, x + rx - 3, y + ry - 1], 190, 300, fill=hexc("#5a4a90") + (255,))

# el camino: tierra clara que une los niveles
def catmull(pts, pasos=26):
    r = []
    for i in range(len(pts) - 1):
        p0 = pts[max(i - 1, 0)]
        p1 = pts[i]
        p2 = pts[i + 1]
        p3 = pts[min(i + 2, len(pts) - 1)]
        for k in range(pasos):
            t = k / pasos
            t2, t3 = t * t, t * t * t
            x = 0.5 * (2 * p1[0] + (p2[0] - p0[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (3 * p1[0] - p0[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * (2 * p1[1] + (p2[1] - p0[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (3 * p1[1] - p0[1] - 3 * p2[1] + p3[1]) * t3)
            r.append((x, y))
    r.append(pts[-1])
    return r


curva = catmull(NODOS)
for (x, y) in curva:
    d.ellipse([x - 16, y - 10, x + 16, y + 10], fill=hexc("#4c3628") + (255,))
for (x, y) in curva:
    d.ellipse([x - 12, y - 7, x + 12, y + 7], fill=hexc("#5c4230") + (255,))

# utilerias
def llanta(x, y, r=11):
    ry = int(r * 0.62)
    d.ellipse([x - r, y - ry, x + r, y + ry], fill=hexc("#17121c") + (255,), outline=hexc("#0b0810") + (255,))
    d.ellipse([x - r + 4, y - ry + 3, x + r - 4, y + ry - 3], fill=hexc("#2a2228") + (255,))
    d.arc([x - r + 1, y - ry + 1, x + r - 1, y + ry - 1], 190, 320, fill=hexc("#3f3438") + (255,))


def pila_llantas(x, y, n=3):
    for k in range(n):
        llanta(x, y - k * 7, 12)


def caja(x, y, t=14):
    c = tono("#6a4426", "#5a3c26", "#54463a")
    k = hexc("#14101a") + (255,)
    d.rectangle([x, y - t, x + t, y], fill=c, outline=k)
    d.polygon([(x, y - t), (x + 5, y - t - 5), (x + t + 5, y - t - 5), (x + t, y - t)], fill=hexc("#8a6038") + (255,), outline=k)
    d.polygon([(x + t, y), (x + t + 5, y - 5), (x + t + 5, y - t - 5), (x + t, y - t)], fill=hexc("#3f2a1e") + (255,), outline=k)
    d.line([(x + 2, y - 2), (x + t - 2, y - t + 2)], fill=hexc("#3f2a1e") + (255,))


def auto_roto(x, y):
    k = hexc("#14101a") + (255,)
    c = tono("#7a3a2a", "#3f5a6a", "#6a6a3a")
    d.polygon([(x, y), (x + 4, y - 11), (x + 14, y - 12), (x + 22, y - 21), (x + 42, y - 21), (x + 50, y - 12), (x + 62, y - 10), (x + 64, y)], fill=c, outline=k)
    d.polygon([(x + 25, y - 19), (x + 40, y - 19), (x + 45, y - 12), (x + 20, y - 12)], fill=hexc("#1a1a2c") + (255,), outline=k)
    d.ellipse([x + 7, y - 7, x + 19, y + 3], fill=hexc("#15121a") + (255,))
    d.ellipse([x + 44, y - 7, x + 56, y + 3], fill=hexc("#15121a") + (255,))


def tubo(x, y, largo):
    k = hexc("#14101a") + (255,)
    d.rectangle([x, y - 7, x + largo, y], fill=hexc("#4a5660") + (255,), outline=k)
    d.line([(x + 1, y - 5), (x + largo - 1, y - 5)], fill=hexc("#7a8a94") + (255,))
    d.ellipse([x + largo - 4, y - 8, x + largo + 4, y + 1], fill=hexc("#14101a") + (255,), outline=hexc("#7a8a94") + (255,))


def sprite(nombre, marco, ancho, x, y, esc=1, tinte=(0.72, 0.68, 0.74)):
    s = Image.open(os.path.join(SP, nombre + ".png")).convert("RGBA")
    alto = s.height
    r = s.crop((marco * ancho, 0, (marco + 1) * ancho, alto))
    a = np.array(r).astype(np.float32)
    a[..., 0] *= tinte[0]
    a[..., 1] *= tinte[1]
    a[..., 2] *= tinte[2]
    r = Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA").resize((ancho * esc, alto * esc), Image.NEAREST)
    im.alpha_composite(r, (int(x - r.width / 2), int(y - r.height)))


def sombra(x, y, rx, ry=None):
    ry = ry or max(3, rx // 4)
    d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=hexc("#15101a") + (255,))


# taller de Don Tuerca, junto al primer nivel
k = hexc("#14101a") + (255,)
sombra(58, 222, 58, 8)
d.rectangle([10, 174, 106, 222], fill=hexc("#6a4426") + (255,), outline=k)
for x in range(16, 104, 14):
    d.line([(x, 175), (x, 221)], fill=hexc("#54361e") + (255,))
d.polygon([(2, 176), (58, 146), (114, 176)], fill=hexc("#7a8a94") + (255,), outline=k)
d.line([(12, 172), (104, 172)], fill=hexc("#4a5660") + (255,))
d.rectangle([44, 192, 72, 222], fill=hexc("#1d1420") + (255,), outline=k)
d.rectangle([16, 184, 36, 200], fill=hexc("#e8b040") + (255,), outline=k)
d.line([(26, 184), (26, 200)], fill=k)
d.rectangle([80, 184, 100, 200], fill=hexc("#e8b040") + (255,), outline=k)
d.line([(90, 184), (90, 200)], fill=k)
# cono gigante en el techo: su firma
d.polygon([(50, 150), (58, 118), (66, 150)], fill=hexc("#f0701c") + (255,), outline=k)
d.polygon([(54, 136), (62, 136), (60, 128), (56, 128)], fill=hexc("#ffffff") + (255,))
d.rectangle([44, 150, 72, 154], fill=hexc("#c04a0c") + (255,), outline=k)

# escena principal, de atras hacia adelante
pila_llantas(138, 176)
caja(226, 196)
auto_roto(226, 244)
sombra(330, 207, 26)
sprite("bot", 0, 32, 330, 212, 1)
pila_llantas(318, 188)
tubo(340, 186, 46)
sombra(446, 180, 40, 6)
sprite("grua", 0, 96, 446, 196, 1)
auto_roto(462, 236)
caja(420, 300, 16)
caja(560, 218)
pila_llantas(590, 188)
tubo(566, 300, 58)
sombra(640, 300, 18)
sprite("rabioso", 0, 32, 640, 302, 1)
auto_roto(676, 196)
caja(700, 318, 15)
pila_llantas(790, 186)
sombra(798, 318, 18)
sprite("sniper", 0, 40, 798, 322, 1)
# el Compactador, gigante, vigila el ultimo tramo
sombra(872, 182, 58, 8)
sprite("compactador", 0, 128, 872, 192, 1, (0.86, 0.8, 0.82))
for x, y in ((152, 306), (250, 330), (372, 332), (606, 338), (812, 340), (930, 316)):
    if rng.random() < 0.7:
        caja(x, y, 12)
    else:
        llanta(x, y, 11)
auto_roto(120, 340)
auto_roto(486, 348)
auto_roto(900, 350)

# portal apagado al mundo siguiente
px, py = 984, 268
sombra(px, py + 2, 34, 6)
d.ellipse([px - 26, py - 62, px + 26, py + 4], fill=hexc("#150a2a") + (255,), outline=k)
d.ellipse([px - 22, py - 58, px + 22, py + 1], fill=hexc("#241048") + (255,))
for r_, c_ in ((16, "#3a1c70"), (10, "#2a1458")):
    d.ellipse([px - r_, py - 29 - int(r_ * 1.3), px + r_, py - 29 + int(r_ * 1.3)], outline=hexc(c_) + (255,))
d.arc([px - 30, py - 66, px + 30, py + 8], 180, 360, fill=hexc("#7a8a94") + (255,), width=4)
d.rectangle([px - 33, py - 34, px - 27, py + 4], fill=hexc("#4a5660") + (255,), outline=k)
d.rectangle([px + 27, py - 34, px + 33, py + 4], fill=hexc("#4a5660") + (255,), outline=k)

salida = os.path.join(SP, "mapa_chatarra.png")
im.convert("RGB").save(salida)
print("mapa ok", im.size)
