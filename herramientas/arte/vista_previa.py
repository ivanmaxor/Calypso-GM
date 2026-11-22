# -*- coding: utf-8 -*-
"""Hoja de revision rapida: renderiza una muestra de cada modelo, ampliada."""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image

from sdf import a_imagen, escalar, hex2rgb
import modelos as m

salida = sys.argv[1]
t0 = time.time()
filas = [
    [(m.render_nave(a), 4) for a in ("pistola", "escopeta", "railgun", "macro", "ping_pong", "cohetes")],
    [(m.render_bot(), 4), (m.render_rabioso(), 4), (m.render_sniper(), 4), (m.render_spammer(), 3), (m.render_compacto(), 3), (m.render_reparador(), 4)],
    [(m.render_grua(), 3), (m.render_compactador(0.0), 3), (m.render_compactador(1.0, enojo=1.0), 3)],
    [(m.render_mascota(0, ancho=22), 6), (m.render_mascota(0, boca=1.0, ancho=22), 6), (m.render_mascota(1, ancho=30), 5), (m.render_mascota(1, boca=1.0, ancho=30), 5), (m.render_mascota(2, ancho=40), 4), (m.render_mascota(2, boca=1.0, ancho=40), 4)],
]
print("render", round(time.time() - t0, 1), "s")
ancho = 0
alto = 8
imgs = []
for f in filas:
    fila = [escalar(a_imagen(a), k) for a, k in f]
    ancho = max(ancho, sum(i.width + 8 for i in fila) + 8)
    alto += max(i.height for i in fila) + 8
    imgs.append(fila)
lienzo = Image.new("RGBA", (ancho, alto), hex2rgb("#2a2238") + (255,))
y = 8
for fila in imgs:
    x = 8
    for i in fila:
        lienzo.alpha_composite(i, (x, y))
        x += i.width + 8
    y += max(i.height for i in fila) + 8
lienzo.save(salida)
print("ok", lienzo.size)
