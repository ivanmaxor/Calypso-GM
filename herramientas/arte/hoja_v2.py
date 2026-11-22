# -*- coding: utf-8 -*-
"""Hoja de revision del arte: une sprites generados en una sola imagen ampliada."""
import glob
import os
import sys

from PIL import Image, ImageDraw

carpeta = sys.argv[1]
salida = sys.argv[2]
patrones = sys.argv[3].split(",")
esc = int(sys.argv[4]) if len(sys.argv) > 4 else 3
ancho_max = int(sys.argv[5]) if len(sys.argv) > 5 else 1500
cuadro_ini = len(sys.argv) > 6
archivos = []
for p in patrones:
    archivos += sorted(glob.glob(os.path.join(carpeta, p + ".png")))
items = []
for a in archivos:
    im = Image.open(a).convert("RGBA")
    items.append((os.path.basename(a)[:-4], im.resize((im.width * esc, im.height * esc), Image.NEAREST)))
x = y = 6
fila = 0
pos = []
for n, im in items:
    if x + im.width + 6 > ancho_max:
        x = 6
        y += fila + 14
        fila = 0
    pos.append((n, im, x, y))
    x += max(im.width, 40) + 8
    fila = max(fila, im.height)
lienzo = Image.new("RGBA", (ancho_max, y + fila + 16), (42, 34, 56, 255))
d = ImageDraw.Draw(lienzo)
for n, im, x, y in pos:
    lienzo.alpha_composite(im, (x, y))
    d.text((x, y + im.height), n.replace("icono_", "")[:12], fill=(200, 200, 220))
lienzo.save(salida)
print("ok", len(items), lienzo.size)
