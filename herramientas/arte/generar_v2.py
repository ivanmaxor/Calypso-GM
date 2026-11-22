# -*- coding: utf-8 -*-
"""Arte de la version 0.2: naves, iconos de armas y habilidades, objetos, retratos y planetas.

Uso: python generar_v2.py <carpeta juego> [filtro]
"""
import math
import os
import random
import sys

import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
from sdf import (Rampa, a_imagen, capsula, caja, cilindro, cono_truncado, elipsoide, esfera, hex2rgb,
                 poligono, renderizar, resta, rot_x, rot_y, rot_z, toro, union_suave)
import modelos as m

JUEGO = sys.argv[1]
FILTRO = sys.argv[2] if len(sys.argv) > 2 else ""
DEST = os.path.join(JUEGO, "arte", "sprites")
os.makedirs(DEST, exist_ok=True)


def quiere(n):
    return FILTRO in n


def guardar(nombre, arr):
    a_imagen(arr).save(os.path.join(DEST, nombre + ".png"))


def tira(nombre, cuadros):
    cuadros = list(cuadros)
    h, w = cuadros[0].shape[:2]
    lienzo = np.zeros((h, w * len(cuadros), 4), dtype=np.uint8)
    for i, c in enumerate(cuadros):
        lienzo[:, i * w:(i + 1) * w] = c
    guardar(nombre, lienzo)
    print(f"{nombre}: {len(cuadros)} x {w}x{h}")


# =============================================================================
# NAVES: seis cascos distintos. Colores clave: el shader pone pintura, franja y llama.
# =============================================================================
RN = m.RAMPAS_NAVE  # 0 casco, 1 acero, 2 vidrio, 3 llama, 4 franja, 5 oro


def nave(tipo, banco=0.0, t=0.0):
    ll = 0.24 + 0.06 * np.sin(2 * np.pi * t * 2)

    def escena(p):
        p = rot_y(p, banco * 0.6)
        q = p.copy()
        q[..., 0] = np.abs(q[..., 0])
        q2 = rot_y(q, -0.30)
        ds = []
        if tipo == "tryhard":
            fus = cono_truncado(p, (0, -0.42, 0), (0, 0.48, 0.0), 0.235, 0.10)
            fus = union_suave(fus, cono_truncado(p, (0, 0.46, 0), (0, 0.90, 0.0), 0.10, 0.018), 0.05)
            ds.append((fus, 0))
            ds.append((poligono(q2, [(0.10, 0.22), (0.86, -0.42), (0.86, -0.62), (0.52, -0.50), (0.10, -0.48)], 0.015, 0.03), 0))
            ds.append((poligono(q2 - np.array([0, 0, 0.035]), [(0.36, -0.15), (0.78, -0.47), (0.74, -0.53), (0.33, -0.25)], 0.012, 0.0), 4))
            ds.append((capsula(q, (0.86, -0.62, -0.02), (0.86, -0.02, -0.02), 0.038), 1))
            ds.append((elipsoide(q, (0.20, -0.46, -0.03), (0.105, 0.24, 0.10)), 1))
            ds.append((elipsoide(q, (0.20, -0.74 - ll * 0.3, -0.03), (0.062, ll * 0.75, 0.05)), 3))
            ds.append((elipsoide(p, (0, 0.20, 0.13), (0.10, 0.25, 0.10)), 2))
            ds.append((elipsoide(p, (0, -0.72 - ll * 0.3, 0), (0.08, ll, 0.06)), 3))
            ds.append((capsula(p, (0, 0.76, 0.0), (0, 1.02, 0.0), 0.022), 1))
        elif tipo == "camper":
            # larga y fina, con un riel enorme
            ds.append((cono_truncado(p, (0, -0.62, 0), (0, 0.42, 0), 0.20, 0.09), 0))
            ds.append((poligono(q2, [(0.07, 0.02), (0.60, -0.42), (0.62, -0.66), (0.07, -0.44)], 0.015, 0.025), 0))
            ds.append((poligono(q2 - np.array([0, 0, 0.03]), [(0.22, -0.20), (0.56, -0.46), (0.54, -0.54), (0.20, -0.30)], 0.01, 0.0), 4))
            for s in (-0.07, 0.07):
                ds.append((caja(p, (s, 0.80, 0.03), (0.024, 0.58, 0.022), 0.006), 5))
            ds.append((capsula(p, (0, 0.34, 0.03), (0, 1.34, 0.03), 0.014), 2))
            ds.append((elipsoide(p, (0, -0.12, 0.13), (0.085, 0.22, 0.09)), 2))
            ds.append((elipsoide(q, (0.12, -0.66, -0.02), (0.09, 0.18, 0.09)), 1))
            ds.append((elipsoide(q, (0.12, -0.88 - ll * 0.2, -0.02), (0.05, ll * 0.6, 0.04)), 3))
        elif tipo == "support":
            # platillo redondo con dos cápsulas
            ds.append((elipsoide(p, (0, -0.08, 0), (0.66, 0.56, 0.16)), 0))
            ds.append((toro(p, (0, -0.08, 0.03), (0, 0, 1), 0.46, 0.035), 4))
            ds.append((esfera(p, (0, 0.02, 0.13), 0.22), 2))
            ds.append((elipsoide(q, (0.82, -0.14, 0), (0.15, 0.30, 0.13)), 1))
            ds.append((esfera(q, (0.82, 0.14, 0.03), 0.09), 2))
            ds.append((caja(p, (0, 0.50, 0), (0.06, 0.14, 0.04), 0.02), 1))
            ds.append((elipsoide(q, (0.24, -0.66, -0.02), (0.10, 0.12, 0.08)), 1))
            ds.append((elipsoide(q, (0.24, -0.84 - ll * 0.25, -0.02), (0.06, ll * 0.6, 0.05)), 3))
        elif tipo == "ballena":
            # enorme y pesada, tres motores
            ds.append((elipsoide(p, (0, -0.02, 0), (0.46, 0.86, 0.24)), 0))
            ds.append((poligono(q2, [(0.25, 0.30), (1.16, -0.08), (1.20, -0.52), (0.25, -0.62)], 0.03, 0.04), 0))
            ds.append((poligono(q2 - np.array([0, 0, 0.06]), [(0.42, -0.04), (1.06, -0.22), (1.08, -0.36), (0.42, -0.26)], 0.012, 0.0), 4))
            ds.append((caja(p, (0, 0.66, 0.10), (0.26, 0.16, 0.10), 0.05), 1))
            for s in (-0.13, 0.13):
                ds.append((cilindro(p, (s, 0.70, 0.12), (s, 1.02, 0.12), 0.07), 1))
            ds.append((elipsoide(p, (0, 0.26, 0.20), (0.13, 0.18, 0.09)), 2))
            for x, r in ((0.0, 0.14), (0.42, 0.12), (-0.42, 0.12)):
                ds.append((elipsoide(p, (x, -0.74, -0.03), (r, 0.20, 0.11)), 1))
                ds.append((elipsoide(p, (x, -0.98 - ll * 0.3, -0.03), (r * 0.62, ll * 0.85, 0.06)), 3))
        elif tipo == "speedrunner":
            # dardo con alas hacia adelante
            ds.append((cono_truncado(p, (0, -0.56, 0), (0, 1.02, 0), 0.15, 0.008), 0))
            ds.append((poligono(q2, [(0.05, -0.34), (0.74, 0.28), (0.78, 0.10), (0.10, -0.66)], 0.012, 0.022), 0))
            ds.append((poligono(q2 - np.array([0, 0, 0.03]), [(0.28, -0.22), (0.68, 0.14), (0.66, 0.05), (0.30, -0.32)], 0.01, 0.0), 4))
            ds.append((elipsoide(p, (0, 0.10, 0.08), (0.06, 0.22, 0.07)), 2))
            ds.append((elipsoide(p, (0, -0.56, 0), (0.15, 0.14, 0.12)), 1))
            ds.append((elipsoide(p, (0, -0.84 - ll * 0.5, 0), (0.09, ll * 1.25, 0.07)), 3))
            for s in (-0.18, 0.18):
                ds.append((capsula(p, (s, -0.20, 0.0), (s, 0.40, 0.0), 0.022), 1))
        elif tipo == "smurf":
            # chiquitita y adorable, con cabina gigante
            ds.append((elipsoide(p, (0, -0.06, 0), (0.30, 0.42, 0.20)), 0))
            ds.append((poligono(q2, [(0.14, 0.02), (0.52, -0.16), (0.54, -0.40), (0.14, -0.34)], 0.012, 0.022), 0))
            ds.append((poligono(q2 - np.array([0, 0, 0.03]), [(0.26, -0.10), (0.48, -0.20), (0.48, -0.30), (0.26, -0.24)], 0.008, 0.0), 4))
            ds.append((esfera(p, (0, 0.08, 0.12), 0.20), 2))
            ds.append((esfera(q, (0.56, -0.26, 0.02), 0.10), 5))
            ds.append((elipsoide(p, (0, -0.52 - ll * 0.3, -0.02), (0.08, ll * 0.8, 0.05)), 3))
        return ds

    return escena


def render_nave(tipo, banco=0.0, t=0.0):
    return renderizar(nave(tipo, banco, t), RN, 48, encuadre=1.57, centro=(0, -0.02), luz=(-0.55, 0.45, 0.75), oscuro_interior=False)


NAVES = ("tryhard", "camper", "support", "ballena", "speedrunner", "smurf")
for n in NAVES:
    if quiere("nave2_" + n):
        tira("nave2_" + n, [render_nave(n, b, t) for b in (-1.0, -0.5, 0.0, 0.5, 1.0) for t in (0.0, 0.25)])

# =============================================================================
# ICONOS 32x32
# =============================================================================
R_ROJO = Rampa(["#3a0c1e", "#7a1630", "#c42b3e", "#f0584a", "#ffc0a0"], curva=0.9)
R_BLANCO = Rampa(["#6a6a80", "#9a9ab0", "#c8c8d8", "#ececf5", "#ffffff"], mate=True, curva=0.8)
R_NARANJA = Rampa(["#5a2008", "#a0400c", "#e06a14", "#ff9a30", "#ffd080"], curva=0.85)
R_TOXICO = Rampa(["#1f6a1c", "#3cb030", "#7ee850", "#d8ff90"], emisiva=True, curva=1.0)
R_ROSA_L = Rampa(["#a01860", "#e83a90", "#ff8ac0", "#ffffff"], emisiva=True, curva=1.0)
R_RAYO = Rampa(["#a07010", "#f0c020", "#fff070", "#ffffff"], emisiva=True, curva=0.6)
R_PIEL = Rampa(["#6a3a28", "#a0603c", "#d09060", "#f0b888", "#ffdcb8"], mate=True, curva=0.85)
R_MASA = Rampa(["#5a3010", "#8a5a20", "#c08a3c", "#e8b860", "#ffe0a0"], mate=True, curva=0.9)
R_QUESO = Rampa(["#7a4a10", "#c08820", "#f0c040", "#ffe070", "#fff4b0"], mate=True, curva=0.9)
RI = [m.R_ACERO, m.R_ORO, m.R_NUCLEO, m.R_NEGRO, m.R_CIAN, m.R_VERDE, m.R_MOTOR, m.R_OXIDO, R_ROJO, R_BLANCO, R_NARANJA, R_TOXICO, R_ROSA_L, R_RAYO, R_PIEL, R_MASA, R_QUESO]
AC, OR, NU, NE, CI, VE, MO, OX, RJ, BL, NA, TX, RL, RY, PI, MA, QU = range(17)


def icono(nombre, escena, encuadre=1.0, centro=(0, 0), inclinacion=0.0, tam=32):
    if quiere("icono_" + nombre):
        guardar("icono_" + nombre, renderizar(escena, RI, tam, encuadre=encuadre, centro=centro, inclinacion=inclinacion, luz=(-0.5, 0.7, 0.7), ss=4))


def diag(p):
    return rot_z(p, -0.70)


# --- armas ---------------------------------------------------------------------------------
def i_pistola(p):
    q = diag(p)
    return [(caja(q, (0, -0.25, 0), (0.24, 0.36, 0.14), 0.05), AC), (cilindro(q, (0, 0.1, 0), (0, 0.84, 0), 0.10), AC),
            (toro(q, (0, 0.82, 0), (0, 1, 0), 0.10, 0.03), OR), (caja(q, (0, -0.48, 0.13), (0.14, 0.08, 0.04), 0.01), CI)]


def i_escopeta(p):
    q = diag(p)
    ds = [(caja(q, (0, -0.40, 0), (0.28, 0.34, 0.14), 0.05), OX)]
    for s in (-0.14, 0.14):
        ds.append((cilindro(q, (s, 0, 0), (s, 0.86, 0), 0.125), AC))
    ds.append((caja(q, (0, 0.34, 0.03), (0.30, 0.07, 0.14), 0.02), OR))
    return ds


def i_railgun(p):
    q = diag(p)
    ds = []
    for s in (-0.16, 0.16):
        ds.append((caja(q, (s, 0.1, 0), (0.055, 0.88, 0.09), 0.01), AC))
    ds.append((capsula(q, (0, -0.74, 0), (0, 0.94, 0), 0.06), CI))
    ds.append((caja(q, (0, -0.64, 0), (0.26, 0.17, 0.13), 0.03), OR))
    return ds


def i_macro(p):
    q = diag(p)
    ds = [(cilindro(q, (0, -0.62, 0), (0, -0.08, 0), 0.34), NE)]
    for a in (0.0, 2.09, 4.19):
        ds.append((cilindro(q, (np.cos(a) * 0.19, -0.1, np.sin(a) * 0.19), (np.cos(a) * 0.19, 0.9, np.sin(a) * 0.19), 0.075), AC))
    ds.append((toro(q, (0, 0.46, 0), (0, 1, 0), 0.26, 0.05), OR))
    return ds


def i_ping_pong(p):
    return [(esfera(p, (0, 0, 0), 0.50), BL), (esfera(p, (-0.14, 0.14, 0.34), 0.20), CI),
            (toro(p, (0, 0, 0), (0.3, 0.3, 1), 0.72, 0.06), CI), (esfera(p, (0.62, -0.46, 0.2), 0.10), OR)]


def i_cohetes(p):
    q = diag(p)
    ds = [(capsula(q, (0, -0.60, 0), (0, 0.46, 0), 0.25), AC), (cono_truncado(q, (0, 0.42, 0), (0, 0.92, 0), 0.25, 0.03), RJ),
          (toro(q, (0, 0.40, 0), (0, 1, 0), 0.25, 0.03), OR)]
    for s in (-1, 1):
        ds.append((poligono(rot_y(q, 0.0), [(s * 0.22, -0.34), (s * 0.48, -0.80), (s * 0.22, -0.74)], 0.03, 0.01), OX))
    return ds


def i_misiles(p):
    q = diag(p)
    ds = [(capsula(q, (0, -0.38, 0), (0, 0.42, 0), 0.17), BL), (cono_truncado(q, (0, 0.40, 0), (0, 0.86, 0), 0.17, 0.02), RJ),
          (caja(q, (0, 0.12, 0.13), (0.15, 0.04, 0.05), 0.005), RJ), (elipsoide(q, (0, -0.74, 0), (0.12, 0.28, 0.10)), MO)]
    for s in (-1, 1):
        ds.append((poligono(q, [(s * 0.14, -0.14), (s * 0.40, -0.54), (s * 0.14, -0.46)], 0.03, 0.01), RJ))
    return ds


def i_drones(p):
    ds = [(elipsoide(p, (0, -0.06, 0), (0.42, 0.28, 0.28)), AC), (esfera(p, (0, -0.06, 0.24), 0.14), CI)]
    for s in (-1, 1):
        ds.append((capsula(p, (s * 0.30, 0.10, 0), (s * 0.62, 0.40, 0), 0.05), AC))
        ds.append((toro(p, (s * 0.62, 0.44, 0.02), (0, 0.3, 1), 0.30, 0.04), CI))
    ds.append((capsula(p, (0, -0.30, 0), (0, -0.56, 0.0), 0.06), OR))
    return ds


def i_aura(p):
    return [(esfera(p, (0, 0, 0), 0.26), TX), (toro(p, (0, 0, 0), (0, 0, 1), 0.56, 0.05), TX), (toro(p, (0, 0, 0), (0, 0, 1), 0.86, 0.04), VE)]


def i_rayo(p):
    return [(poligono(p, [(0.26, 0.92), (-0.34, 0.06), (-0.02, 0.06), (-0.26, -0.92), (0.36, -0.08), (0.04, -0.08)], 0.09, 0.01), RY)]


def _dientes(n, r1, r2):
    pts = []
    for k in range(n * 2):
        a = math.pi * k / n
        r = r2 if k % 2 == 0 else r1
        pts.append((math.cos(a) * r, math.sin(a) * r))
    return pts


def i_sierras(p):
    ds = [(poligono(p, _dientes(10, 0.62, 0.92), 0.05, 0.01), AC), (esfera(p, (0, 0, 0.02), 0.22), OR), (toro(p, (0, 0, 0.06), (0, 0, 1), 0.42, 0.03), NE)]
    return ds


def i_laser(p):
    q = diag(p)
    return [(cilindro(q, (0, -0.72, 0), (0, -0.14, 0), 0.26), AC), (toro(q, (0, -0.14, 0), (0, 1, 0), 0.26, 0.05), OR),
            (capsula(q, (0, -0.06, 0), (0, 0.96, 0), 0.10), RL)]


for nombre, f in (("pistola", i_pistola), ("escopeta", i_escopeta), ("railgun", i_railgun), ("macro", i_macro), ("ping_pong", i_ping_pong),
                  ("cohetes", i_cohetes), ("misiles", i_misiles), ("drones", i_drones), ("aura", i_aura), ("rayo", i_rayo), ("sierras", i_sierras), ("laser", i_laser)):
    icono(nombre, f)


# --- habilidades ------------------------------------------------------------------------------
def h_spray(p):
    q = p - np.array([0.20, -0.08, 0])
    ds = [(cilindro(q, (0, -0.66, 0), (0, 0.32, 0), 0.32), AC), (cilindro(q, (0, -0.30, 0), (0, 0.04, 0), 0.335), RJ), (cono_truncado(q, (0, 0.32, 0), (0, 0.50, 0), 0.32, 0.12), AC), (caja(q, (0, 0.58, 0), (0.10, 0.09, 0.09), 0.02), NE)]
    for x, y, r in ((-0.72, 0.70, 0.07), (-0.56, 0.42, 0.09), (-0.82, 0.30, 0.06), (-0.62, 0.84, 0.05)):
        ds.append((esfera(p, (x, y, 0), r), CI))
    return ds


def h_p2w(p):
    ds = []
    for k, (x, y) in enumerate(((-0.18, -0.46), (0.14, -0.20), (-0.08, 0.06), (0.10, 0.32))):
        ds.append((cilindro(p, (x, y - 0.11, 0), (x, y + 0.11, 0), 0.54), OR))
    return ds


def h_headshot(p):
    return [(toro(p, (0, 0, 0), (0, 0, 1), 0.62, 0.075), RJ), (caja(p, (0, 0.72, 0), (0.05, 0.24, 0.05)), RJ), (caja(p, (0, -0.72, 0), (0.05, 0.24, 0.05)), RJ),
            (caja(p, (0.72, 0, 0), (0.24, 0.05, 0.05)), RJ), (caja(p, (-0.72, 0, 0), (0.24, 0.05, 0.05)), RJ), (esfera(p, (0, 0, 0), 0.15), NU)]


def h_ping0(p):
    return [(caja(p, (-0.60, -0.56, 0), (0.13, 0.22, 0.08), 0.02), VE), (caja(p, (-0.20, -0.36, 0), (0.13, 0.42, 0.08), 0.02), VE),
            (caja(p, (0.20, -0.10, 0), (0.13, 0.68, 0.08), 0.02), VE), (caja(p, (0.60, 0.16, 0), (0.13, 0.94 - 0.2, 0.08), 0.02), VE)]


def h_goblin(p):
    q = p - np.array([0, 0.10, 0])
    aro = resta(toro(q, (0, 0.0, 0), (0, 0, 1), 0.46, 0.20), caja(q, (0, -0.8, 0), (1.0, 0.8, 0.5)))
    ds = [(aro, RJ)]
    for s in (-1, 1):
        ds.append((caja(q, (s * 0.46, -0.24, 0), (0.20, 0.24, 0.18), 0.02), RJ))
        ds.append((caja(q, (s * 0.46, -0.58, 0), (0.20, 0.13, 0.18), 0.02), BL))
    ds.append((poligono(p, [(0, -0.28), (0.16, -0.52), (0, -0.76), (-0.16, -0.52)], 0.05, 0.01), OR))
    return ds


def h_buffer(p):
    ds = [(resta(caja(p, (0, -0.04, 0), (0.42, 0.74, 0.22), 0.05), caja(p, (0, -0.04, 0.2), (0.32, 0.64, 0.12))), AC), (caja(p, (0, 0.78, 0), (0.18, 0.08, 0.14), 0.02), OR)]
    for y in (-0.52, -0.20, 0.12):
        ds.append((caja(p, (0, y, 0.10), (0.26, 0.11, 0.06)), CI))
    return ds


def h_combo(p):
    ds = []
    for k, y in enumerate((0.54, 0.0, -0.54)):
        col = [OR, NA, RJ][k]
        ds.append((poligono(p, [(-0.72, y + 0.26), (0, y - 0.20), (0.72, y + 0.26), (0.72, y + 0.0), (0, y - 0.46), (-0.72, y + 0.0)], 0.07, 0.01), col))
    return ds


def h_copium(p):
    q = rot_z(p, -0.45)
    return [(capsula(q, (0, -0.56, 0), (0, 0.34, 0), 0.34), VE), (cilindro(q, (0, 0.62, 0), (0, 0.78, 0), 0.12), AC), (caja(q, (0.0, 0.84, 0), (0.24, 0.06, 0.06), 0.01), AC), (caja(q, (0, -0.1, 0.30), (0.20, 0.17, 0.05), 0.01), BL)]


def h_pizza(p):
    ds = [(poligono(p, [(0, -0.92), (0.70, 0.56), (-0.70, 0.56)], 0.06, 0.03), QU), (capsula(p, (-0.72, 0.62, 0.03), (0.72, 0.62, 0.03), 0.13), MA)]
    for x, y in ((-0.20, 0.26), (0.22, 0.20), (0.0, -0.28)):
        ds.append((cilindro(p, (x, y, 0.06), (x, y, 0.12), 0.14), RJ))
    return ds


def h_stonks(p):
    ds = [(caja(p, (-0.62, -0.62, -0.1), (0.13, 0.22, 0.06)), AC), (caja(p, (-0.16, -0.48, -0.1), (0.13, 0.36, 0.06)), AC), (caja(p, (0.30, -0.32, -0.1), (0.13, 0.52, 0.06)), AC)]
    ds.append((poligono(p, [(-0.86, -0.28), (-0.20, 0.20), (0.12, -0.04), (0.50, 0.40), (0.26, 0.56), (0.92, 0.88), (0.84, 0.16), (0.64, 0.30), (0.14, -0.26), (-0.20, -0.02), (-0.78, -0.46)], 0.06, 0.012), VE))
    return ds


def h_tank(p):
    return [(poligono(p, [(0, 0.90), (0.72, 0.62), (0.68, -0.12), (0, -0.90), (-0.68, -0.12), (-0.72, 0.62)], 0.08, 0.04), AC),
            (poligono(p - np.array([0, 0, 0.09]), [(0, 0.66), (0.50, 0.46), (0.47, -0.08), (0, -0.62), (-0.47, -0.08), (-0.50, 0.46)], 0.03, 0.01), CI)]


def h_wallbang(p):
    pared = caja(p, (-0.34, 0, 0), (0.22, 0.88, 0.26), 0.01)
    pared = resta(pared, esfera(p, (-0.34, 0, 0), 0.26))
    ds = [(pared, OX)]
    for y in (-0.5, 0.5):
        ds.append((caja(p, (-0.34, y, 0.26), (0.22, 0.02, 0.02)), NE))
    ds += [(capsula(p, (-0.9, 0, 0), (0.46, 0, 0), 0.12), OR), (cono_truncado(p, (0.46, 0, 0), (0.86, 0, 0), 0.12, 0.02), OR)]
    return ds


def h_doble(p):
    ds = [(elipsoide(p, (0, -0.12, 0), (0.52, 0.76, 0.26)), BL), (caja(p, (0, 0.28, 0.20), (0.02, 0.36, 0.06)), NE), (capsula(p, (0, 0.22, 0.22), (0, 0.42, 0.22), 0.06), RJ), (caja(p, (0, -0.02, 0.21), (0.48, 0.02, 0.05)), NE)]
    for x, y, a in ((-0.84, 0.64, 0.7), (0.84, 0.64, -0.7)):
        q = rot_z(p - np.array([x, y, 0]), a)
        ds.append((caja(q, (0, 0, 0), (0.04, 0.16, 0.04)), OR))
    return ds


def h_aimbot(p):
    q = p - np.array([0, -0.08, 0])
    ds = [(toro(q, (0, 0, 0), (0, 0, 1), 0.52, 0.06), CI), (esfera(q, (0, 0, 0), 0.12), NU)]
    # flecha curva que entra al blanco
    for k in range(5):
        a = 0.2 + k * 0.42
        ds.append((esfera(p, (np.cos(a) * 0.84, np.sin(a) * 0.84 - 0.08, 0.04), 0.055 + k * 0.012), OR))
    ds.append((poligono(p, [(-0.50, 0.84), (-0.08, 0.86), (-0.32, 0.50)], 0.04, 0.01), OR))
    return ds


def h_lagcomp(p):
    return [(caja(p, (0.74, 0, 0), (0.08, 0.92, 0.12), 0.01), AC), (capsula(p, (-0.72, 0.78, 0), (0.50, 0.0, 0), 0.08), CI), (capsula(p, (0.50, 0.0, 0), (-0.42, -0.60, 0), 0.08), CI),
            (poligono(p, [(-0.76, -0.82), (-0.22, -0.72), (-0.54, -0.36)], 0.06, 0.01), CI)]


def h_fatfinger(p):
    q = rot_z(p, 0.35)
    return [(capsula(q, (0, -0.86, 0.05), (0, 0.20, 0.05), 0.33), PI), (elipsoide(q, (0, 0.34, 0.26), (0.20, 0.17, 0.05)), BL), (toro(p, (0.12, 0.40, -0.1), (0, 0, 1), 0.60, 0.04), CI), (toro(p, (0.12, 0.40, -0.1), (0, 0, 1), 0.88, 0.03), CI)]


for nombre, f in (("spray", h_spray), ("p2w", h_p2w), ("headshot", h_headshot), ("ping0", h_ping0), ("goblin", h_goblin), ("buffer", h_buffer), ("combo", h_combo), ("copium", h_copium),
                  ("pizza", h_pizza), ("stonks", h_stonks), ("tank", h_tank), ("wallbang", h_wallbang), ("doble", h_doble), ("aimbot", h_aimbot), ("lagcomp", h_lagcomp), ("fatfinger", h_fatfinger)):
    icono(nombre, f)


# --- equipo --------------------------------------------------------------------------------------
def e_mira(p):
    return [(toro(p, (0, 0, 0), (0, 0, 1), 0.56, 0.11), AC), (cilindro(p, (0, 0, -0.3), (0, 0, 0.0), 0.5), NE), (caja(p, (0, 0, 0.06), (0.62, 0.02, 0.02)), RJ), (caja(p, (0, 0, 0.06), (0.02, 0.62, 0.02)), RJ), (esfera(p, (0, 0, 0.04), 0.09), NU), (caja(p, (0, 0.78, 0), (0.09, 0.12, 0.09), 0.02), OR)]


def e_cargador(p):
    q = rot_z(p, -0.30)
    ds = [(caja(q, (0, -0.14, 0), (0.34, 0.70, 0.16), 0.03), AC), (caja(q, (0, 0.66, 0), (0.24, 0.12, 0.13), 0.02), OR)]
    for y in (-0.56, -0.28, 0.0, 0.28):
        ds.append((caja(q, (0, y, 0.15), (0.24, 0.05, 0.03)), NE))
    return ds


def e_perforante(p):
    q = diag(p)
    return [(capsula(q, (0, -0.56, 0), (0, 0.24, 0), 0.25), OR), (cono_truncado(q, (0, 0.22, 0), (0, 0.92, 0), 0.25, 0.015), AC), (cilindro(q, (0, -0.86, 0), (0, -0.62, 0), 0.25), OX)]


def e_explosiva(p):
    return [(esfera(p, (0, -0.14, 0), 0.60), NE), (toro(p, (0, 0.44, 0), (0, 1, 0), 0.16, 0.05), AC), (capsula(p, (0, 0.5, 0), (0.30, 0.74, 0), 0.03), OX), (esfera(p, (0.34, 0.78, 0), 0.10), MO), (esfera(p, (-0.18, 0.06, 0.48), 0.11), BL)]


icono("mira_laser", e_mira)
icono("cargador", e_cargador)
icono("mun_perforante", e_perforante)
icono("mun_explosiva", e_explosiva)


def casco(blindado):
    def e(p):
        ds = [(resta(esfera(p, (0, -0.12, 0), 0.74), caja(p, (0, -0.92, 0), (1.1, 0.6, 1.1))), OX if blindado else AC)]
        ds.append((caja(p, (0, -0.14, 0.52), (0.48, 0.14, 0.2), 0.04), NE))
        ds.append((caja(p, (0, -0.14, 0.68), (0.36, 0.05, 0.05), 0.01), CI))
        if blindado:
            ds.append((caja(p, (0, 0.5, 0.22), (0.1, 0.2, 0.42), 0.02), AC))
        return ds
    return e


def alas(iman):
    def e(p):
        q = p.copy()
        q[..., 0] = np.abs(q[..., 0])
        ds = [(poligono(q, [(0.05, 0.42), (0.92, -0.1), (0.92, -0.52), (0.5, -0.32), (0.05, -0.32)], 0.05, 0.03), OX if iman else AC)]
        ds.append((esfera(p, (0, 0.0, 0.05), 0.15), NU if iman else CI))
        if iman:
            ds.append((toro(p, (0, 0.0, 0.05), (0, 0, 1), 0.3, 0.05), AC))
        else:
            ds.append((caja(q, (0.56, -0.2, 0.06), (0.26, 0.04, 0.03), 0.005), OR))
        return ds
    return e


def motor(fantasma):
    def e(p):
        q = rot_z(p, -0.6)
        return [(cono_truncado(q, (0, 0.62, 0), (0, -0.12, 0), 0.32, 0.46), AC), (toro(q, (0, -0.16, 0), (0, 1, 0), 0.47, 0.06), OR),
                (elipsoide(q, (0, -0.56, 0), (0.28, 0.42, 0.28)), CI if fantasma else MO), (cilindro(q, (0, 0.62, 0), (0, 0.84, 0), 0.20), NE)]
    return e


def reactor(cascada):
    def e(p):
        ds = [(resta(cilindro(p, (0, -0.74, 0), (0, 0.74, 0), 0.52), cilindro(p, (0, -0.42, 0), (0, 0.42, 0), 0.62)), AC)]
        for y in (-0.70, 0.70):
            ds.append((toro(p, (0, y, 0), (0, 1, 0), 0.52, 0.06), OR))
        ds.append((cilindro(p, (0, -0.44, 0), (0, 0.44, 0), 0.34), NU if cascada else CI))
        for a in (0.0, 2.09, 4.19):
            ds.append((capsula(p, (np.cos(a) * 0.5, -0.5, np.sin(a) * 0.5), (np.cos(a) * 0.5, 0.5, np.sin(a) * 0.5), 0.035), AC))
        return ds
    return e


def chip(critico):
    def e(p):
        ds = [(caja(p, (0, 0, 0), (0.56, 0.56, 0.09), 0.02), VE), (caja(p, (0, 0, 0.1), (0.26, 0.26, 0.06), 0.01), NE)]
        ds.append((esfera(p, (0, 0, 0.14), 0.15), NU if critico else OR))
        for k in (-0.34, 0.0, 0.34):
            for s in (-1, 1):
                ds.append((caja(p, (s * 0.72, k, 0), (0.16, 0.05, 0.04), 0.005), AC))
                ds.append((caja(p, (k, s * 0.72, 0), (0.05, 0.16, 0.04), 0.005), AC))
        return ds
    return e


icono("casco_lata", casco(False))
icono("casco_blindado", casco(True))
icono("alas_ligeras", alas(False))
icono("alas_iman", alas(True))
icono("motor_turbo", motor(False))
icono("motor_fantasma", motor(True))
icono("reactor_lag", reactor(False), inclinacion=0.25)
icono("reactor_cascada", reactor(True), inclinacion=0.25)
icono("chip_suerte", chip(False))
icono("chip_critico", chip(True))

# Ranuras vacias y Desync
icono("desync", lambda p: [(toro(p, (0, 0, 0), (0, 0, 1), 0.68, 0.09), CI), (poligono(p, [(0.14, 0.56), (-0.26, 0.04), (-0.02, 0.04), (-0.14, -0.56), (0.28, -0.06), (0.04, -0.06)], 0.06, 0.01), BL)])
icono("hangar", lambda p: [(caja(p, (0, -0.2, 0), (0.82, 0.58, 0.3), 0.03), OX), (caja(p, (0, -0.32, 0.26), (0.56, 0.46, 0.05)), NE), (poligono(p, [(-0.94, 0.38), (0, 0.9), (0.94, 0.38)], 0.3, 0.01), AC)])
icono("fusion", lambda p: [(toro(p, (-0.42, -0.42, 0), (0, 0, 1), 0.28, 0.05), OR), (toro(p, (0.42, -0.42, 0), (0, 0, 1), 0.28, 0.05), OR), (toro(p, (0, 0.34, 0), (0, 0, 1), 0.44, 0.08), NU), (esfera(p, (0, 0.34, 0), 0.20), RY)])

# --- objetos que se recogen, grandes y claros -----------------------------------------------------
if quiere("obj_"):
    def obj(nombre, escena, tam=18, **k):
        guardar(nombre, renderizar(escena, RI, tam, encuadre=k.get("encuadre", 1.0), centro=k.get("centro", (0, 0)), luz=(-0.5, 0.7, 0.7), ss=4))

    obj("obj_pizza", h_pizza)
    obj("obj_iman", h_goblin)
    obj("obj_bomba", e_explosiva)
    obj("obj_cofre", lambda p: [(caja(p, (0, -0.22, 0), (0.86, 0.46, 0.4), 0.04), OX), (elipsoide(p, (0, 0.24, 0), (0.86, 0.36, 0.4)), OX), (caja(p, (0, 0.04, 0.38), (0.18, 0.18, 0.06), 0.02), OR), (caja(p, (0, 0.05, 0.3), (0.88, 0.05, 0.12)), OR)])
    hexa = [(math.cos(k * math.pi / 3) * 0.92, math.sin(k * math.pi / 3) * 0.92) for k in range(6)]
    obj("obj_tuerca", lambda p: [(resta(poligono(p, hexa, 0.2, 0.02), cilindro(p, (0, 0, -1), (0, 0, 1), 0.42)), AC)], tam=11)
    obj("obj_tuerca_grande", lambda p: [(resta(poligono(p, hexa, 0.2, 0.02), cilindro(p, (0, 0, -1), (0, 0, 1), 0.42)), AC)], tam=16)
    # misil y cohete vistos desde arriba, apuntando hacia arriba
    def spr_misil(t):
        def e(p):
            return [(capsula(p, (0, -0.30, 0), (0, 0.34, 0), 0.20), BL), (cono_truncado(p, (0, 0.32, 0), (0, 0.86, 0), 0.20, 0.02), RJ), (caja(p, (0, 0.06, 0.16), (0.17, 0.05, 0.05), 0.005), RJ),
                    (poligono(p, [(0.16, -0.08), (0.46, -0.56), (0.16, -0.46)], 0.03, 0.01), RJ), (poligono(p, [(-0.16, -0.08), (-0.46, -0.56), (-0.16, -0.46)], 0.03, 0.01), RJ),
                    (elipsoide(p, (0, -0.72, 0), (0.13, 0.22 + 0.08 * t, 0.10)), MO)]
        return e
    tira("obj_misil", [renderizar(spr_misil(t), RI, 16, encuadre=1.0, luz=(-0.5, 0.7, 0.7), ss=4) for t in (0, 1)])
    def spr_cohete(t):
        def e(p):
            return [(capsula(p, (0, -0.40, 0), (0, 0.36, 0), 0.30), AC), (cono_truncado(p, (0, 0.34, 0), (0, 0.92, 0), 0.30, 0.03), NA), (toro(p, (0, 0.30, 0), (0, 1, 0), 0.30, 0.04), OR),
                    (poligono(p, [(0.26, -0.18), (0.54, -0.70), (0.26, -0.60)], 0.03, 0.01), OX), (poligono(p, [(-0.26, -0.18), (-0.54, -0.70), (-0.26, -0.60)], 0.03, 0.01), OX),
                    (elipsoide(p, (0, -0.76, 0), (0.17, 0.18 + 0.08 * t, 0.10)), MO)]
        return e
    tira("obj_cohete", [renderizar(spr_cohete(t), RI, 14, encuadre=1.0, luz=(-0.5, 0.7, 0.7), ss=4) for t in (0, 1)])
    def spr_sierra(a):
        def e(p):
            q = rot_z(p, a)
            return [(poligono(q, _dientes(8, 0.58, 0.96), 0.05, 0.01), AC), (esfera(p, (0, 0, 0.0), 0.26), OR), (toro(p, (0, 0, 0.05), (0, 0, 1), 0.42, 0.04), NE)]
        return e
    tira("obj_sierra", [renderizar(spr_sierra(k * math.pi / 16), RI, 18, encuadre=1.04, luz=(-0.5, 0.7, 0.7), ss=4) for k in range(4)])
    tira("obj_sierra_evo", [renderizar(spr_sierra(k * math.pi / 16), [m.R_ORO] + RI[1:], 18, encuadre=1.04, luz=(-0.5, 0.7, 0.7), ss=4) for k in range(4)])
    guardar("obj_dron", renderizar(lambda p: [(elipsoide(p, (0, -0.1, 0), (0.56, 0.42, 0.34)), AC), (esfera(p, (0, -0.1, 0.28), 0.22), CI), (capsula(p, (-0.46, 0.24, 0), (-0.80, 0.60, 0), 0.08), AC), (capsula(p, (0.46, 0.24, 0), (0.80, 0.60, 0), 0.08), AC), (capsula(p, (-0.96, 0.62, 0.02), (-0.62, 0.62, 0.02), 0.06), CI), (capsula(p, (0.96, 0.62, 0.02), (0.62, 0.62, 0.02), 0.06), CI)], RI, 14, encuadre=1.08, luz=(-0.5, 0.7, 0.7), ss=4))
    def spr_torre(p):
        return [(esfera(p, (0, 0, 0), 0.5), AC)]


# --- balas: mas grandes y con dos cuadros para que llamen la atencion ------------------------------
def bala_redonda(diam, borde, medio, centro, punto):
    a = np.zeros((diam, diam, 4), dtype=np.uint8)
    c = (diam - 1) / 2.0
    R = diam / 2.0
    for y in range(diam):
        for x in range(diam):
            d = math.hypot(x - c, y - c)
            if d > R:
                continue
            if d > R - 1.15:
                col = hex2rgb(borde)
            elif d > R * 0.62:
                col = hex2rgb(medio)
            elif d > R * 0.3:
                col = hex2rgb(centro)
            else:
                col = hex2rgb(punto)
            a[y, x] = col + (255,)
    return a


if quiere("bala_"):
    tira("bala_orbe", [bala_redonda(11, "#10061a", "#ff2a68", "#ff9ac0", "#ffffff"), bala_redonda(11, "#10061a", "#ff5a8c", "#ffd0e0", "#ffffff")])
    tira("bala_grande", [bala_redonda(17, "#10061a", "#ff2a68", "#ff8ab8", "#ffffff"), bala_redonda(17, "#10061a", "#ff5a8c", "#ffd0e0", "#ffffff")])
    tira("bala_pellet", [bala_redonda(7, "#180a06", "#ff8a2a", "#ffd24a", "#ffffff"), bala_redonda(7, "#180a06", "#ffb04a", "#ffe89a", "#ffffff")])
    P = {"k": "#10061a", "y": "#ffd24a", "e": "#ffffff", "o": "#ff8a2a", "c": "#29c5e6", "n": "#0e3a55", "w": "#d8fbff", "g": "#f5c84c", "h": "#fff8c8", "d": "#3a2410"}

    def mat(filas):
        a = np.zeros((len(filas), len(filas[0]), 4), dtype=np.uint8)
        for j, f in enumerate(filas):
            for i, ch in enumerate(f):
                if ch != ".":
                    a[j, i] = hex2rgb(P[ch]) + (255,)
        return a

    guardar("bala_punta", mat(["...k...", "..kyk..", "..kyk..", ".kyeyk.", ".kyeyk.", ".kyeyk.", ".kyeyk.", ".kyeyk.", ".kyeyk.", "..kok..", "..kok..", "...k..."]))
    guardar("tiro2", mat(["n...n"[:5], "ncccn", "ncwcn", "ncwcn", "ncwcn", "ncwcn", "ncwcn", "ncwcn", "ncwcn", "ncccn", ".nnn."]))
    guardar("tiro_riel2", mat(["ncwcn"] * 26))
    guardar("bit2", mat(["....d....", "...dgd...", "..dghgd..", ".dghhhgd.", "dghhhhhgd", ".dghhhgd.", "..dghgd..", "...dgd...", "....d...."]))
    guardar("bit_grande2", mat(["......d......", ".....dgd.....", "....dghgd....", "...dghhhgd...", "..dghhhhhgd..", ".dghhhwhhhgd.", "dghhhwwwhhhgd", ".dghhhwhhhgd.", "..dghhhhhgd..", "...dghhhgd...", "....dghgd....", ".....dgd.....", "......d......"]))
    guardar("tiro_rebote2", mat([".nnnnn.", "ncccccn", "ncwwwcn", "ncwwwcn", "ncwwwcn", "ncccccn", ".nnnnn."]))


# --- iconos de interfaz --------------------------------------------------------------------------
def de_matriz(filas, paleta):
    a = np.zeros((len(filas), len(filas[0]), 4), dtype=np.uint8)
    for j, f in enumerate(filas):
        for i, ch in enumerate(f):
            if ch != ".":
                a[j, i] = hex2rgb(paleta[ch]) + (255,)
    return a


if quiere("ui_"):
    P2 = {"k": "#10061a", "g": "#9fb3c4", "d": "#4a5266", "y": "#f5c84c", "o": "#a06a18", "h": "#fff4a8", "r": "#ff4a5a", "m": "#a01830", "w": "#ffffff", "e": "#2a2340"}
    guardar("ui_candado", de_matriz([
        "...kkkkkk...", "..kggggggk..", "..kgk..kgk..", "..kgk..kgk..", ".kkkkkkkkkk.", ".kddddddddk.", ".kdddkkdddk.", ".kdddkkdddk.", ".kddddddddk.", ".kkkkkkkkkk."], P2))
    guardar("ui_estrella", de_matriz([
        "......kk......", "......kk......", ".....kyyk.....", ".....kyyk.....", "kkkkkkyhykkkkk", ".kyyyyyhhyyyk.", "..kyyyyhyyyk..", "...kyyyyyyk...", "...kyyyyyyk...", "..kyyyoyyyyk..", "..kyyokkoyyk..", ".kyokk..kkoyk.", ".kkk......kkk."], P2))
    guardar("ui_estrella_vacia", de_matriz([
        "......kk......", "......kk......", ".....keek.....", ".....keek.....", "kkkkkkeeekkkkk", ".keeeeeeeeeek.", "..keeeeeeeek..", "...keeeeeek...", "...keeeeeek...", "..keeekkeeek..", "..keek..keek..", ".keek....keek.", ".kkk......kkk."], P2))
    guardar("ui_corazon", de_matriz([
        ".kkk...kkk.", "krrrk.krrrk", "krwrrkrrrrk", "krrrrrrrrrk", "kmrrrrrrrmk", ".kmrrrrrmk.", "..kmrrrmk..", "...kmrmk...", "....kmk....", ".....k....."], P2))
    guardar("ui_calavera", de_matriz([
        "...kkkkkkkk...", "..kwwwwwwwwk..", ".kwwwwwwwwwwk.", ".kwkkwwwwkkwk.", ".kwkkwwwwkkwk.", ".kwwwwkkwwwwk.", ".kkwwwkkwwwkk.", "..kwwwwwwwwk..", "..kwkwkwkwkk..", "...kkkkkkkk..."], P2))
    guardar("ui_regalo", de_matriz([
        "...kk...kk...", "..kyyk.kyyk..", "...kyykyyk...", "kkkkkkkkkkkkk", "krrrryyyrrrrk", "kkkkkkkkkkkkk", ".krrryyyrrrk.", ".krrryyyrrrk.", ".krrryyyrrrk.", ".kkkkkkkkkkk."], P2))
    guardar("ui_flecha", de_matriz(["...kk...", "..kyyk..", ".kyyyyk.", "kyyyyyyk", "kkkyykkk", "..kyyk..", "..kkkk.."], P2))


# =============================================================================
# RETRATOS
# =============================================================================
R_BARBA = Rampa(["#6a6a78", "#9a9aa8", "#c4c4cc", "#e6e6ec", "#ffffff"], mate=True, curva=0.8)
R_CONO = Rampa(["#7a2a08", "#c04a0c", "#f0701c", "#ff9a3c", "#ffc880"], curva=0.85)
R_OVEROL = Rampa(["#10203a", "#1c3a66", "#2c5a96", "#4a82c0", "#88b8e8"], mate=True, curva=0.9)
R_LENTE_A = Rampa(["#157a9e", "#29c5e6", "#8ff0ff", "#ffffff"], emisiva=True, curva=0.5)
R_LENTE_B = Rampa(["#a0500c", "#f09020", "#ffd060", "#fff8d0"], emisiva=True, curva=0.5)
RT = [R_PIEL, R_BARBA, R_CONO, R_BLANCO, m.R_NEGRO, m.R_ACERO, R_OVEROL, R_ROJO, R_LENTE_A, R_LENTE_B, m.R_ORO]
T_PIEL, T_BARBA, T_CONO, T_BLANCO, T_NEGRO, T_ACERO, T_OVEROL, T_ROJO, T_LA, T_LB, T_ORO = range(11)


def don_tuerca(boca=0.0, cejas=0.0, mira=0.0):
    random.seed(11)
    pelos = []
    for _ in range(46):
        a = random.uniform(math.pi * 1.02, math.pi * 1.98)
        r = random.uniform(0.40, 0.70)
        pelos.append((math.cos(a) * r, -0.20 + math.sin(a) * r * 1.0, 0.30 + random.uniform(-0.1, 0.22), random.uniform(0.09, 0.15)))
    for _ in range(12):
        s = random.choice((-1, 1))
        pelos.append((s * random.uniform(0.52, 0.72), random.uniform(0.05, 0.38), random.uniform(-0.1, 0.18), random.uniform(0.07, 0.12)))

    def e(p):
        ds = []
        # hombros y overol
        ds.append((elipsoide(p, (0, -1.28, -0.1), (1.02, 0.56, 0.5)), T_OVEROL))
        for s in (-0.42, 0.42):
            ds.append((caja(p, (s, -1.02, 0.34), (0.09, 0.28, 0.06), 0.01), T_OVEROL))
            ds.append((esfera(p, (s, -0.86, 0.42), 0.04), T_ORO))
        # cara
        ds.append((elipsoide(p, (0, 0.0, 0), (0.64, 0.72, 0.56)), T_PIEL))
        for s in (-1, 1):
            ds.append((elipsoide(p, (s * 0.64, 0.02, 0), (0.11, 0.18, 0.08)), T_PIEL))
        # barba desordenada
        d = None
        for (x, y, z, r) in pelos:
            di = esfera(p, (x, y, z), r)
            d = di if d is None else np.minimum(d, di)
        d = resta(d, elipsoide(p, (0, -0.30, 0.56), (0.26, 0.08 + 0.15 * boca, 0.30)))
        ds.append((d, T_BARBA))
        # boca con dientes chuecos
        ds.append((elipsoide(p, (0, -0.30, 0.46), (0.25, 0.07 + 0.15 * boca, 0.14)), T_NEGRO))
        if boca > 0.3:
            ds.append((caja(p, (-0.10, -0.20, 0.56), (0.05, 0.05, 0.03), 0.005), T_BLANCO))
            ds.append((caja(p, (0.10, -0.21, 0.56), (0.06, 0.05, 0.03), 0.005), T_BLANCO))
            ds.append((elipsoide(p, (0, -0.42, 0.52), (0.12, 0.06, 0.06)), T_ROJO))
        # nariz de borracho
        ds.append((esfera(p, (0.02, -0.04, 0.60), 0.16), T_ROJO))
        # lentes de soldar disparejos: la marca del personaje
        ds.append((caja(p, (0, 0.24, 0.40), (0.72, 0.05, 0.22), 0.01), T_NEGRO))
        ds.append((cilindro(p, (-0.27, 0.24, 0.40), (-0.27, 0.24, 0.66), 0.26), T_ACERO))
        ds.append((esfera(p, (-0.27, 0.24, 0.50), 0.205), T_LA))
        ds.append((esfera(p, (-0.27 + 0.05 * mira, 0.22, 0.68), 0.075), T_NEGRO))
        ds.append((cilindro(p, (0.28, 0.27, 0.40), (0.28, 0.27, 0.62), 0.19), T_ACERO))
        ds.append((esfera(p, (0.28, 0.27, 0.48), 0.14), T_LB))
        ds.append((esfera(p, (0.28 + 0.04 * mira, 0.26, 0.62), 0.05), T_NEGRO))
        # cejas locas
        for s, c0 in ((-1, 0.60), (1, 0.52)):
            q = rot_z(p - np.array([s * 0.28, c0 + 0.08 * cejas, 0.52]), s * (-0.25 - 0.35 * cejas))
            ds.append((caja(q, (0, 0, 0), (0.25, 0.05, 0.06), 0.02), T_BARBA))
        # cono de transito en la cabeza
        ds.append((caja(p, (0, 0.68, -0.02), (0.74, 0.05, 0.50), 0.02), T_CONO))
        cono = cono_truncado(p, (0.02, 0.70, -0.02), (0.14, 1.72, -0.02), 0.50, 0.05)
        ds.append((cono, T_CONO))
        banda = resta(cono_truncado(p, (0.05, 0.98, -0.02), (0.08, 1.24, -0.02), 0.42, 0.30), elipsoide(p, (0.06, 1.1, -0.02), (0.20, 0.50, 0.20)))
        ds.append((banda, T_BLANCO))
        return ds

    return e


if quiere("retrato_tuerca"):
    cuadros = []
    for boca, cejas in ((0.0, 0.0), (0.7, 0.2), (1.0, 1.0), (0.2, 1.0)):
        cuadros.append(renderizar(don_tuerca(boca, cejas), RT, 128, encuadre=1.82, centro=(0.02, 0.06), inclinacion=0.04, ss=2, luz=(-0.45, 0.65, 0.75)))
    tira("retrato_tuerca", cuadros)

RC = [m.R_ACERO, R_LENTE_A, m.R_NEGRO, m.R_NUCLEO]


def calypso(pulso=0.0, abre=0.0):
    def e(p):
        ds = [(esfera(p, (0, 0, 0), 0.70), 0), (caja(p, (0, 0.02, 0.56), (0.50, 0.10 + 0.08 * abre, 0.16), 0.03), 2), (elipsoide(p, (0, 0.02, 0.68), (0.34, 0.05 + 0.07 * abre, 0.04)), 1)]
        ds.append((toro(rot_x(p, 0.9), (0, 0, 0), (0, 0, 1), 0.96 + 0.05 * pulso, 0.05), 1))
        ds.append((capsula(p, (0, 0.68, 0), (0, 1.0, 0), 0.03), 0))
        ds.append((esfera(p, (0, 1.06, 0), 0.07), 1))
        return ds
    return e


if quiere("retrato_calypso"):
    tira("retrato_calypso", [renderizar(calypso(p, a), RC, 96, encuadre=1.28, centro=(0, 0.06), ss=2, luz=(-0.45, 0.65, 0.75)) for p, a in ((0.0, 0.0), (1.0, 1.0))])

# =============================================================================
# PLANETAS: el selector de mundos
# =============================================================================
if quiere("mundo_"):
    defs = [
        ("mundo_0", ["#2a1410", "#54281a", "#8a4522", "#c47330", "#f0b060"], "#9fb3c4"),
        ("mundo_1", ["#0f3018", "#1c5a2c", "#2f8f40", "#5ccb5c", "#b8f5a0"], None),
        ("mundo_2", ["#3a2a08", "#7a5a10", "#c49a20", "#f5d040", "#fff6a8"], "#ff6fb5"),
        ("mundo_3", ["#06142a", "#0c2a50", "#14508a", "#2a80c0", "#7ac8f0"], None),
        ("mundo_4", ["#2a0c3a", "#54187a", "#8c2bc4", "#c45cf0", "#f0c0ff"], None),
        ("mundo_5", ["#2a0806", "#6a1608", "#c43a10", "#ff7a20", "#ffd060"], None),
        ("mundo_6", ["#1a1a26", "#34344a", "#5c5c78", "#8e8ea8", "#d0d0e0"], "#f5c84c"),
    ]
    for i, (nombre, rampa, anillo) in enumerate(defs):
        R = Rampa(rampa, curva=0.9, mate=True)
        R2 = Rampa([rampa[0], rampa[0], rampa[1], rampa[1], rampa[2]], mate=True)
        anillos = Rampa(["#3a3a4a", anillo or "#ffffff", anillo or "#ffffff", "#ffffff", "#ffffff"], mate=True)

        def escena(p, i=i):
            ds = []
            if i == 4:
                ds.append((caja(rot_y(rot_x(p, 0.5), 0.6), (0, 0, 0), (0.52, 0.52, 0.52), 0.04), 0))
            else:
                ds.append((esfera(p, (0, 0, 0), 0.74), 0))
                random.seed(i * 7 + 3)
                dd = None
                for _ in range(9):
                    a, b = random.uniform(0, 6.28), random.uniform(-1.2, 1.2)
                    c = (math.cos(a) * math.cos(b) * 0.72, math.sin(b) * 0.72, math.sin(a) * math.cos(b) * 0.72)
                    di = esfera(p, c, random.uniform(0.08, 0.2))
                    dd = di if dd is None else np.minimum(dd, di)
                ds.append((np.maximum(dd, esfera(p, (0, 0, 0), 0.752)), 1))
            if anillo:
                q = rot_z(rot_x(p, 1.2), 0.32)
                ds.append((toro(q, (0, 0, 0), (0, 0, 1), 1.0, 0.04), 2))
            return ds

        guardar(nombre, renderizar(escena, [R, R2, anillos], 48, encuadre=1.1, luz=(-0.6, 0.6, 0.6), ss=3))
    print("planetas ok")

print("listo")
