# -*- coding: utf-8 -*-
"""Genera todos los sprites del juego en juego/arte/sprites.

Uso: python generar_sprites.py [carpeta_juego] [filtro]
Con filtro solo regenera lo que contiene ese texto (por ejemplo "nave" o "icono").
"""
import math
import os
import random
import sys
import time

import numpy as np
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
from sdf import (Rampa, a_imagen, capsula, caja, cilindro, cono_truncado, elipsoide, esfera, hex2rgb,
                 poligono, renderizar, resta, rot_z, toro)
import modelos as m

JUEGO = sys.argv[1] if len(sys.argv) > 1 else os.path.join(AQUI, "..", "..", "juego")
FILTRO = sys.argv[2] if len(sys.argv) > 2 else ""
DEST = os.path.join(JUEGO, "arte", "sprites")
os.makedirs(DEST, exist_ok=True)
ARMAS = ("pistola", "escopeta", "railgun", "macro", "ping_pong", "cohetes")


def quiere(nombre):
    return FILTRO in nombre


def tira(nombre, cuadros):
    """Une cuadros (arrays RGBA del mismo tamaño) en una tira horizontal."""
    if not quiere(nombre):
        return
    t0 = time.time()
    cuadros = list(cuadros)
    h, w = cuadros[0].shape[:2]
    lienzo = np.zeros((h, w * len(cuadros), 4), dtype=np.uint8)
    for i, c in enumerate(cuadros):
        lienzo[:, i * w:(i + 1) * w] = c
    a_imagen(lienzo).save(os.path.join(DEST, nombre + ".png"))
    print(f"{nombre}: {len(cuadros)} cuadros de {w}x{h}  ({time.time() - t0:.1f}s)")


def de_matriz(filas, paleta):
    h, w = len(filas), len(filas[0])
    a = np.zeros((h, w, 4), dtype=np.uint8)
    for j, f in enumerate(filas):
        for i, c in enumerate(f):
            if c != ".":
                a[j, i] = hex2rgb(paleta[c]) + (255,)
    return a


def guardar(nombre, arr):
    if quiere(nombre):
        a_imagen(arr).save(os.path.join(DEST, nombre + ".png"))


# --- personajes ---------------------------------------------------------------
class Perezoso:
    """Evita renderizar si el filtro no pide ese nombre."""


def gen(nombre, funcion):
    if quiere(nombre):
        tira(nombre, funcion())


for arma in ARMAS:
    gen(f"nave_{arma}", lambda arma=arma: [m.render_nave(arma, b, t) for b in (-1.0, -0.5, 0.0, 0.5, 1.0) for t in (0.0, 0.25)])

gen("bot", lambda: [m.render_bot(k / 4) for k in range(4)])
gen("rabioso", lambda: [m.render_rabioso(k / 4) for k in range(4)])
gen("sniper", lambda: [m.render_sniper(k / 4) for k in range(4)] + [m.render_sniper(0, 0.5), m.render_sniper(0, 1.0)])
gen("spammer", lambda: [m.render_spammer(k / 4) for k in range(4)] + [m.render_spammer(0.3, 0.5), m.render_spammer(0.3, 1.0)])
gen("compacto", lambda: [m.render_compacto(k / 4) for k in range(4)])
gen("reparador", lambda: [m.render_reparador(k / 4) for k in range(4)])
gen("grua", lambda: [m.render_grua(k / 4) for k in range(4)])
gen("compactador", lambda: [m.render_compactador(a, 0.0, e) for e in (0.0, 1.0) for a in (0.0, 0.33, 0.66, 1.0)])
# Las mascotas ahora las genera generar_v3_iconos.py (22, 24 y 28 px).


# --- balas ------------------------------------------------------------------------
P = {"k": "#0d0a18", "r": "#ff3d78", "w": "#fff4f8", "p": "#ff9ac0", "o": "#ff8a2a", "y": "#ffd24a", "c": "#29c5e6", "e": "#ffffff", "n": "#0e3a55", "g": "#f5c84c", "h": "#fff8c8", "d": "#3a2410", "t": "#8a5220", "a": "#66788f", "s": "#9fb3c4", "m": "#d84a4a", "q": "#f5d58a", "b": "#a0522d", "v": "#5ccb6c", "z": "#0f4020"}
guardar("orbe", de_matriz(["..kkkk..", ".krrrrk.", "krppwwrk", "krpwwwrk", "krwwwprk", "krwwpprk", ".krrrrk.", "..kkkk.."], P))
guardar("orbe_grande", de_matriz([
    "....kkkkkk....", "..kkrrrrrrkk..", ".krrrrpprrrrk.", ".krrppwwwprrk.", "krrppwwwwwprrk", "krppwwwwwwpprk", "krpwwwwwwwwprk",
    "krpwwwwwwwwprk", "krppwwwwwwpprk", "krrppwwwwwprrk", ".krrppwwwprrk.", ".krrrrpprrrrk.", "..kkrrrrrrkk..", "....kkkkkk...."], P))
guardar("pellet", de_matriz([".kk.", "koyk", "kyok", ".kk."], P))
guardar("punta", de_matriz(["..k..", ".kyk.", ".kyk.", ".kyk.", "kyeyk", "kyeyk", "kyeyk", "kyeyk", ".kok.", ".kok.", "..k.."], P))
guardar("tiro", de_matriz(["n.n", "cec", "cec", "cec", "cec", "cec", "cec", "ncn", ".n."], P))
guardar("tiro_riel", de_matriz(["cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "cec", "ncn"], P))
guardar("tiro_cohete", de_matriz([".n.", "ncn", "cec", "cec", "cec", "aaa", "aoa", ".o.", ".y."], P))
guardar("tiro_rebote", de_matriz([".nnn.", "ncccn", "nceen", "nceen", ".nnn."], P))
guardar("bit", de_matriz(["..d..", ".dgd.", "dghgd", ".dgd.", "..d.."], P))
guardar("bit_grande", de_matriz(["...d...", "..dgd..", ".dggd..", "dghhgd.", ".dggd..", "..dgd..", "...d..."], P)[:, :7])
guardar("chatarra", de_matriz([".kkkkk.", "kassaak", "kaskssk", "kssaask", "kaassak", ".kkkkk."], P))
guardar("pizza", de_matriz([
    "kkkkkkkkkk", "kbbbbbbbbk", ".kqqmqqqk.", ".kqqqqmqk.", "..kqmqqk..", "..kqqqqk..", "...kqmk...", "...kqqk...", "....kk...."], P))
guardar("cofre", de_matriz([
    ".kkkkkkkkkkk.", "kbbbbbbbbbbbk", "kbqqqqqqqqqbk", "kbbbbbgbbbbbk", "kkkkkkgkkkkkk", "kbbbbbgbbbbbk", "kbqqqqqqqqqbk", "kbbbbbbbbbbbk", "kkkkkkkkkkkkk"], P))

TINY = {
    "L": ["#..", "#..", "#..", "#..", "###"], "O": ["###", "#.#", "#.#", "#.#", "###"],
    "G": ["###", "#..", "#.#", "#.#", "###"], "E": ["###", "#..", "##.", "#..", "###"],
    "Z": ["###", "..#", ".#.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
    "!": ["#", "#", "#", ".", "#"], "?": ["##.", "..#", ".#.", "...", ".#."],
}


def burbuja(txt):
    ancho = sum(len(TINY[c][0]) + 1 for c in txt) - 1 + 6
    a = np.zeros((14, ancho, 4), dtype=np.uint8)
    k = hex2rgb("#0d0a18") + (255,)
    borde = hex2rgb("#e64fa0") + (255,)
    relleno = hex2rgb("#fff2fa") + (255,)
    tinta = hex2rgb("#2a1a44") + (255,)
    for j in range(0, 11):
        for i in range(ancho):
            if (j in (0, 10)) and (i in (0, ancho - 1)):
                continue
            a[j, i] = k
    for j in range(1, 10):
        for i in range(1, ancho - 1):
            a[j, i] = k if (j in (1, 9)) and (i in (1, ancho - 2)) else borde
    for j in range(2, 9):
        for i in range(2, ancho - 2):
            a[j, i] = relleno
    for f, (x0, n) in enumerate(((3, 3), (3, 2), (3, 1))):
        for i in range(n):
            a[10 + f, x0 + i] = borde if 0 < i < n - 1 or n == 1 else k
        a[10 + f, x0 + n] = k
        a[10 + f, x0 - 1] = k
    x = 3
    for c in txt:
        g = TINY[c]
        for j, fila in enumerate(g):
            for i, v in enumerate(fila):
                if v == "#":
                    a[3 + j, x + i] = tinta
        x += len(g[0]) + 1
    return a


for nombre, txt in (("lol", "LOL"), ("gg", "GG"), ("ez", "EZ"), ("f", "F"), ("excl", "!!!")):
    guardar(f"burbuja_{nombre}", burbuja(txt))


# --- explosiones ------------------------------------------------------------------
def explosion(r, seed, fase, n):
    rng = random.Random(seed)
    a = np.zeros((n, n, 4), dtype=np.uint8)
    c = n // 2
    if r < 2:
        return a
    bandas = ["#ffffff", "#fff4b0", "#ffd24a", "#ff8a2a", "#e0382a", "#7a1a30", "#2a1438"]
    desf = [rng.uniform(0, 6.28) for _ in range(5)]
    for y in range(n):
        for x in range(n):
            dx, dy = x - c, y - c
            d = math.hypot(dx, dy)
            ang = math.atan2(dy, dx)
            ruido = sum(math.sin(ang * (k + 3) + desf[k]) for k in range(5)) * 0.055
            v = d / r + ruido
            if v > 1:
                continue
            hueco = fase - 0.45
            if v < hueco:
                continue
            base = max(hueco, 0)
            # al final queda solo humo oscuro
            i = int(((v - base) / (1 - base)) * (len(bandas) - 1) + 0.3 * rng.random() + fase * 2.5)
            a[y, x] = hex2rgb(bandas[min(i, len(bandas) - 1)]) + (255,)
    return a


for nombre, tam in (("expl_chica", 24), ("expl_media", 40), ("expl_grande", 72)):
    if quiere(nombre):
        fases = [0.05, 0.2, 0.42, 0.62, 0.82, 1.0]
        radios = [0.5, 0.82, 1.0, 1.0, 0.96, 0.9]
        tira(nombre, [explosion(int((tam // 2 - 1) * rr), 7, f, tam) for f, rr in zip(fases, radios)])


# --- iconos de equipamiento, 24x24 --------------------------------------------------
def icono(nombre, escena, rampas, encuadre=1.0, centro=(0, 0), inclinacion=0.0):
    if quiere("icono_" + nombre):
        a_imagen(renderizar(escena, rampas, 24, encuadre=encuadre, centro=centro, inclinacion=inclinacion, luz=(-0.5, 0.7, 0.7))).save(os.path.join(DEST, f"icono_{nombre}.png"))


RI = [m.R_ACERO, m.R_ORO, m.R_NUCLEO, m.R_NEGRO, m.R_CIAN, m.R_VERDE, m.R_MOTOR, m.R_OXIDO]


def canon(tipo):
    def e(p):
        ds = []
        q = rot_z(p, -0.65)
        if tipo == "pistola":
            ds += [(caja(q, (0, -0.25, 0), (0.24, 0.36, 0.14), 0.05), 0), (cilindro(q, (0, 0.1, 0), (0, 0.84, 0), 0.10), 0), (toro(q, (0, 0.82, 0), (0, 1, 0), 0.10, 0.03), 1)]
        elif tipo == "escopeta":
            ds += [(caja(q, (0, -0.35, 0), (0.28, 0.32, 0.14), 0.05), 7)]
            for s in (-0.13, 0.13):
                ds.append((cilindro(q, (s, 0, 0), (s, 0.76, 0), 0.115), 0))
            ds.append((caja(q, (0, 0.32, 0.03), (0.28, 0.06, 0.13), 0.02), 1))
        elif tipo == "railgun":
            for s in (-0.14, 0.14):
                ds.append((caja(q, (s, 0.1, 0), (0.05, 0.86, 0.09), 0.01), 0))
            ds.append((capsula(q, (0, -0.7, 0), (0, 0.9, 0), 0.05), 4))
            ds.append((caja(q, (0, -0.6, 0), (0.24, 0.16, 0.13), 0.03), 1))
        elif tipo == "macro":
            for s in (-0.17, 0.0, 0.17):
                ds.append((cilindro(q, (s, -0.05, 0), (s, 0.86, 0), 0.07), 0))
            ds.append((cilindro(q, (0, -0.55, 0), (0, -0.05, 0), 0.32), 3))
            ds.append((toro(q, (0, 0.42, 0), (0, 1, 0), 0.23, 0.04), 1))
        elif tipo == "ping_pong":
            ds += [(esfera(p, (0, 0, 0), 0.52), 0), (esfera(p, (-0.1, 0.1, 0.32), 0.24), 4), (toro(p, (0, 0, 0), (0.3, 0.3, 1), 0.70, 0.06), 1)]
        elif tipo == "cohetes":
            ds += [(capsula(q, (0, -0.55, 0), (0, 0.55, 0), 0.24), 0), (esfera(q, (0, 0.6, 0), 0.22), 2)]
            for k in range(3):
                a = k * 2.09 + 0.3
                ds.append((caja(q, (np.cos(a) * 0.26, -0.62, np.sin(a) * 0.26), (0.05, 0.2, 0.05), 0.01), 1))
        return ds
    return e


for t in ARMAS:
    icono(t, canon(t), RI)


def casco(blindado):
    def e(p):
        ds = [(resta(esfera(p, (0, -0.12, 0), 0.74), caja(p, (0, -0.92, 0), (1.1, 0.6, 1.1))), 7 if blindado else 0)]
        ds.append((caja(p, (0, -0.14, 0.52), (0.48, 0.14, 0.2), 0.04), 3))
        ds.append((caja(p, (0, -0.14, 0.68), (0.36, 0.05, 0.05), 0.01), 4))
        if blindado:
            ds.append((caja(p, (0, 0.5, 0.22), (0.1, 0.2, 0.42), 0.02), 1))
        return ds
    return e


icono("casco_lata", casco(False), RI)
icono("casco_blindado", casco(True), RI)


def alas(iman):
    def e(p):
        q = p.copy()
        q[..., 0] = np.abs(q[..., 0])
        ds = [(poligono(q, [(0.05, 0.42), (0.92, -0.1), (0.92, -0.52), (0.5, -0.32), (0.05, -0.32)], 0.05, 0.03), 7 if iman else 0)]
        ds.append((capsula(p, (0, -0.42), (0, 0.5) if False else (0, -0.42, 0), 0.0) if False else (esfera(p, (0, 0.0, 0.05), 0.13)), 4 if not iman else 2))
        if iman:
            ds.append((toro(p, (0, 0.0, 0.05), (0, 0, 1), 0.3, 0.05), 1))
        else:
            ds.append((caja(q, (0.56, -0.2, 0.06), (0.26, 0.04, 0.03), 0.005), 1))
        return ds
    return e


icono("alas_ligeras", alas(False), RI)
icono("alas_iman", alas(True), RI)


def motor(fantasma):
    def e(p):
        q = rot_z(p, -0.6)
        ds = [(cono_truncado(q, (0, 0.62, 0), (0, -0.12, 0), 0.32, 0.46), 0), (toro(q, (0, -0.16, 0), (0, 1, 0), 0.47, 0.06), 1)]
        ds.append((elipsoide(q, (0, -0.56, 0), (0.28, 0.42, 0.28)), 4 if fantasma else 6))
        ds.append((cilindro(q, (0, 0.62, 0), (0, 0.84, 0), 0.20), 3))
        return ds
    return e


icono("motor_turbo", motor(False), RI)
icono("motor_fantasma", motor(True), RI)


def reactor(cascada):
    def e(p):
        ds = [(resta(cilindro(p, (0, -0.74, 0), (0, 0.74, 0), 0.52), cilindro(p, (0, -0.42, 0), (0, 0.42, 0), 0.62)), 0)]
        for y in (-0.70, 0.70):
            ds.append((toro(p, (0, y, 0), (0, 1, 0), 0.52, 0.06), 1))
        ds.append((cilindro(p, (0, -0.44, 0), (0, 0.44, 0), 0.34), 2 if cascada else 4))
        for a in (0.0, 2.09, 4.19):
            ds.append((capsula(p, (np.cos(a) * 0.5, -0.5, np.sin(a) * 0.5), (np.cos(a) * 0.5, 0.5, np.sin(a) * 0.5), 0.035), 1))
        return ds
    return e


icono("reactor_lag", reactor(False), RI, inclinacion=0.25)
icono("reactor_cascada", reactor(True), RI, inclinacion=0.25)


def chip(critico):
    def e(p):
        ds = [(caja(p, (0, 0, 0), (0.56, 0.56, 0.09), 0.02), 5), (caja(p, (0, 0, 0.1), (0.26, 0.26, 0.06), 0.01), 3)]
        ds.append((esfera(p, (0, 0, 0.14), 0.15), 2 if critico else 1))
        for k in (-0.34, 0.0, 0.34):
            for s in (-1, 1):
                ds.append((caja(p, (s * 0.72, k, 0), (0.16, 0.05, 0.04), 0.005), 1))
                ds.append((caja(p, (k, s * 0.72, 0), (0.05, 0.16, 0.04), 0.005), 1))
        return ds
    return e


icono("chip_suerte", chip(False), RI)
icono("chip_critico", chip(True), RI)


# --- fondos del mundo Chatarra ---------------------------------------------------------
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0


def fondo_lejos():
    w, h = 400, 720
    rng = random.Random(4)
    pal = [hex2rgb(c) for c in ("#120d14", "#171118", "#1c151a", "#221a1c")]
    a = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            v = 1.4 + 0.9 * math.sin((x * 0.018) + math.sin(y * 2 * math.pi / h) * 1.5) + 0.7 * math.sin(y * 4 * math.pi / h)
            v += BAYER[y % 4, x % 4] - 0.5
            a[y, x] = pal[max(0, min(3, int(round(v))))]
    im = Image.fromarray(a, "RGB").convert("RGBA")
    d = ImageDraw.Draw(im)
    tonos = [hex2rgb(c) + (255,) for c in ("#1e171a", "#21191a", "#1b1b1e", "#241b18", "#181e22")]
    claro = [hex2rgb(c) + (255,) for c in ("#2a211e", "#2c231c", "#25292b")]
    osc = hex2rgb("#0f0b10") + (255,)

    def envolver(funcion, x, y, *args):
        for dy in (-h, 0, h):
            funcion(x, y + dy, *args)

    def placa(x, y, an, al):
        c = rng.choice(tonos)
        c2 = rng.choice(claro)
        cols = (c, c2)

        def dib(x, y, an, al):
            d.rectangle([x, y, x + an, y + al], fill=cols[0], outline=osc)
            d.line([x + 1, y + 1, x + an - 1, y + 1], fill=cols[1])
            for rx in (x + 3, x + an - 3):
                for ry in (y + 3, y + al - 3):
                    d.point([rx, ry], fill=cols[1])
        envolver(dib, x, y, an, al)

    def caja2(x, y, t):
        c = rng.choice(tonos)
        c2 = rng.choice(claro)

        def dib(x, y, t):
            d.rectangle([x, y, x + t, y + t], fill=c, outline=osc)
            d.line([x + 2, y + 2, x + t - 2, y + t - 2], fill=c2)
            d.line([x + t - 2, y + 2, x + 2, y + t - 2], fill=c2)
        envolver(dib, x, y, t)

    def llanta(x, y, r):
        def dib(x, y, r):
            d.ellipse([x - r, y - r, x + r, y + r], fill=osc)
            d.ellipse([x - r + 3, y - r + 3, x + r - 3, y + r - 3], outline=tonos[2], width=2)
            d.ellipse([x - r + 7, y - r + 7, x + r - 7, y + r - 7], fill=tonos[0])
        envolver(dib, x, y, r)

    def tubo(x, y, largo, horiz):
        c = rng.choice(claro)

        def dib(x, y, largo, horiz):
            if horiz:
                d.rectangle([x, y, x + largo, y + 7], fill=tonos[4], outline=osc)
                d.line([x + 1, y + 2, x + largo - 1, y + 2], fill=c)
            else:
                d.rectangle([x, y, x + 7, y + largo], fill=tonos[4], outline=osc)
                d.line([x + 2, y + 1, x + 2, y + largo - 1], fill=c)
        envolver(dib, x, y, largo, horiz)

    for _ in range(46):
        placa(rng.randint(-20, 400), rng.randint(0, h), rng.randint(30, 90), rng.randint(20, 70))
    for _ in range(26):
        tubo(rng.randint(-20, 380), rng.randint(0, h), rng.randint(40, 170), rng.random() < 0.5)
    for _ in range(36):
        caja2(rng.randint(-5, 395), rng.randint(0, h), rng.randint(11, 26))
    for _ in range(16):
        llanta(rng.randint(0, 400), rng.randint(0, h), rng.randint(9, 17))
    return im


def fondo_cerca():
    w, h = 400, 720
    rng = random.Random(9)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    sombra = hex2rgb("#141014") + (255,)
    filo = hex2rgb("#1f1919") + (255,)
    for _ in range(9):
        cx, cy = rng.randint(0, w), rng.randint(0, h)
        r = rng.randint(6, 18)
        n = rng.randint(5, 8)
        puntos = []
        desf = rng.uniform(0, 6.28)
        for i in range(n):
            ang = desf + i / n * 6.283
            rr = r * rng.uniform(0.55, 1.1)
            puntos.append((rr * math.cos(ang), rr * math.sin(ang)))
        for dy in (-h, 0, h):
            pts = [(cx + a, cy + b + dy) for a, b in puntos]
            d.polygon(pts, fill=sombra, outline=filo)
    return im


if quiere("fondo_lejos"):
    fondo_lejos().save(os.path.join(DEST, "fondo_chatarra_lejos.png"))
if quiere("fondo_cerca"):
    fondo_cerca().save(os.path.join(DEST, "fondo_chatarra_cerca.png"))

print("listo")
