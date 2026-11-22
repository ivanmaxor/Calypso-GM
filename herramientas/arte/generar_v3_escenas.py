# -*- coding: utf-8 -*-
"""Arte de escenas de la version 0.3: Don Tuerca de medio cuerpo, el Hangar y las balas.

Uso: python generar_v3_escenas.py <carpeta juego> [filtro] [--montajes=<carpeta>]

filtro: parte del nombre de lo que se quiere generar (retrato_tuerca, hangar_fondo, hangar_obj_naves,
bala_pellet). Sin filtro se genera todo. hangar_fondo tambien escribe los hangar_delante_<id>: lo del fondo
que queda delante de una estacion y que el juego dibuja despues de ellas.
"""
import math
import os
import random
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(AQUI))  # herramientas/arte -> raíz del repo
CAPTURA_MAPA = os.path.join(REPO, "docs", "capturas", "mapa.png")  # el fondo del montaje de Don Tuerca
sys.path.insert(0, AQUI)
from fuente_v1 import glifo
from sdf import (CONTORNO, Rampa, _escena_mat, _normal, a_imagen, capsula, caja, cilindro, cono_truncado, elipsoide, esfera, hex2rgb,
                 poligono, renderizar, resta, rot_x, rot_y, rot_z, toro, union_suave)
import modelos as m

ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
OPC = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
JUEGO = ARGS[0]
FILTRO = ARGS[1] if len(ARGS) > 1 else ""
DEST = os.path.join(JUEGO, "arte", "sprites")
MONTAJES = OPC.get("montajes", "")
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0


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
# DON TUERCA: viejo de medio cuerpo. Tiene que leerse al tiro: cabeza, cuello, hombros,
# dos brazos con manos, torso con overol y tirantes, y su llave inglesa.
# =============================================================================
R_PIEL = Rampa(["#7a4630", "#a8683f", "#d49464", "#f0b888", "#ffdcb8"], mate=True, curva=0.8)
R_BARBA = Rampa(["#7c7c8c", "#a4a4b2", "#c8c8d2", "#e8e8ee", "#ffffff"], mate=True, curva=0.75)
R_CONO = Rampa(["#8a300a", "#c84e0c", "#f0701c", "#ff9a3c", "#ffc880"], curva=0.8)
R_BLANCO = Rampa(["#7a7a90", "#a4a4b8", "#ccccdc", "#ececf5", "#ffffff"], mate=True, curva=0.75)
R_OVEROL = Rampa(["#1c3a70", "#2a5496", "#3a70b8", "#5a94d8", "#a0ccf4"], mate=True, curva=0.85)
R_OVEROL2 = Rampa(["#16305e", "#20467e", "#2c5a9c", "#4078bc", "#6a9cd8"], mate=True, curva=0.85)
R_CAMISA = Rampa(["#8a6a4a", "#b0906a", "#d4b88e", "#ecd8b0", "#fff4d8"], mate=True, curva=0.8)
R_ROJO = Rampa(["#7a1630", "#b81e3a", "#e83a44", "#ff6a58", "#ffc0a0"], curva=0.85)
R_LENTE_A = Rampa(["#157a9e", "#29c5e6", "#5fe0f6", "#a8f4ff"], emisiva=True, curva=1.3)
R_LENTE_B = Rampa(["#a0500c", "#e8801c", "#ffa030", "#ffc860"], emisiva=True, curva=1.3)
R_MESON = Rampa(["#3a2214", "#5a3820", "#7c5230", "#a07040", "#c89a60"], mate=True, curva=0.9)
R_LLAVE = Rampa(["#3a4660", "#66788f", "#9fb3c4", "#d0dce6", "#ffffff"], curva=0.8)
RT = [R_PIEL, R_BARBA, R_CONO, R_BLANCO, m.R_NEGRO, m.R_ACERO, R_OVEROL, R_ROJO, R_LENTE_A, R_LENTE_B, m.R_ORO, R_CAMISA, R_LLAVE, R_OVEROL2, R_MESON]
T_PIEL, T_BARBA, T_CONO, T_BLANCO, T_NEGRO, T_ACERO, T_OVEROL, T_ROJO, T_LA, T_LB, T_ORO, T_CAMISA, T_LLAVE, T_OVEROL2, T_MESON = range(15)
_V = lambda *x: np.array(x, dtype=np.float64)


def mezcla(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def cabeza(p, boca, cejas, guino, mueca=0.0):
    """Cabeza en sus propias unidades: centro en el origen, radio ~0.65 (la de siempre, con bigote)."""
    random.seed(11)
    pelos = []
    for _ in range(44):
        a = random.uniform(math.pi * 1.04, math.pi * 1.96)
        r = random.uniform(0.40, 0.56)
        pelos.append((math.cos(a) * r, -0.13 + math.sin(a) * r, 0.30 + random.uniform(-0.12, 0.20), random.uniform(0.09, 0.14)))
    for _ in range(14):
        s = random.choice((-1, 1))
        pelos.append((s * random.uniform(0.50, 0.68), random.uniform(0.02, 0.36), random.uniform(-0.1, 0.18), random.uniform(0.07, 0.11)))
    ds = []
    ds.append((elipsoide(p, (0, 0.0, 0), (0.64, 0.72, 0.56)), T_PIEL))
    for s in (-1, 1):
        ds.append((elipsoide(p, (s * 0.64, 0.04, 0), (0.11, 0.18, 0.08)), T_PIEL))
    d = None
    for (x, y, z, r) in pelos:
        di = esfera(p, (x, y, z), r)
        d = di if d is None else np.minimum(d, di)
    pb = rot_z(p - _V(0, -0.30 - 0.05 * boca, 0), mueca)
    d = resta(d, elipsoide(pb, (0, 0, 0.56), (0.27, 0.05 + 0.23 * boca, 0.30)))
    ds.append((d, T_BARBA))
    # boca con dientes chuecos
    ds.append((elipsoide(pb, (0, 0, 0.46), (0.25, 0.028 + 0.227 * boca, 0.14)), T_NEGRO))
    if boca > 0.3:
        ds.append((caja(p, (-0.10, -0.20 - 0.02 * boca, 0.56), (0.05, 0.05, 0.03), 0.005), T_BLANCO))
        ds.append((caja(p, (0.10, -0.21 - 0.02 * boca, 0.56), (0.06, 0.05, 0.03), 0.005), T_BLANCO))
        ds.append((elipsoide(p, (0, -0.44 - 0.08 * boca, 0.52), (0.13, 0.06 + 0.02 * boca, 0.06)), T_ROJO))
    # bigote de viejo, debajo de la nariz
    for s in (-1, 1):
        ds.append((elipsoide(rot_z(p - _V(s * 0.17, -0.15, 0.52), s * 0.35), (0, 0, 0), (0.20, 0.075, 0.08)), T_BARBA))
    # nariz de borracho
    ds.append((esfera(p, (0.02, -0.04, 0.60), 0.16), T_ROJO))
    # antiparras disparejas: la marca del personaje. Correa a los lados y puente entre los lentes
    for lado in (-1, 1):
        ds.append((caja(p, (lado * 0.62, 0.21, 0.28), (0.14, 0.055, 0.20), 0.01), T_NEGRO))
    ds.append((capsula(p, (-0.06, 0.24, 0.60), (0.12, 0.25, 0.58), 0.035), T_ACERO))
    ds.append((cilindro(p, (-0.27, 0.21, 0.36), (-0.27, 0.21, 0.56), 0.27), T_ACERO))
    ds.append((cilindro(p, (-0.27, 0.21, 0.50), (-0.27, 0.21, 0.60), 0.215), T_LA))
    ds.append((esfera(p, (-0.27, 0.19, 0.60), 0.085), T_NEGRO))
    ds.append((esfera(p, (-0.36, 0.30, 0.61), 0.038), T_BLANCO))
    ds.append((cilindro(p, (0.28, 0.24, 0.36), (0.28, 0.24, 0.54), 0.20), T_ACERO))
    ds.append((cilindro(p, (0.28, 0.24, 0.48), (0.28, 0.24, 0.58), 0.15), T_LB))
    if guino:
        # guiño: el parpado baja y queda una raya
        ds.append((caja(p, (0.28, 0.23, 0.585), (0.125, 0.026, 0.02), 0.004), T_NEGRO))
    else:
        ds.append((esfera(p, (0.28, 0.23, 0.57), 0.055), T_NEGRO))
        ds.append((esfera(p, (0.22, 0.30, 0.585), 0.03), T_BLANCO))
    # cejas locas: en reposo enojonas, al gritar se disparan hacia arriba
    for s, c0 in ((-1, 0.54), (1, 0.48)):
        k = 0.0 if (guino and s == 1) else cejas
        q = rot_z(p - _V(s * 0.28, c0 + 0.13 * k, 0.52), -s * (0.25 - 0.62 * k))
        ds.append((caja(q, (0, 0, 0), (0.25, 0.055, 0.06), 0.02), T_BARBA))
    # cono de transito en la cabeza
    ds.append((caja(p, (0, 0.76, -0.02), (0.74, 0.07, 0.50), 0.02), T_CONO))
    cono = cono_truncado(p, (0.02, 0.78, -0.02), (0.13, 1.62, -0.02), 0.50, 0.05)
    ds.append((cono, T_CONO))
    banda = resta(cono_truncado(p, (0.05, 1.00, -0.02), (0.075, 1.24, -0.02), 0.42, 0.30), elipsoide(p, (0.06, 1.12, -0.02), (0.20, 0.50, 0.20)))
    ds.append((banda, T_BLANCO))
    return ds


def llave_inglesa(p, base, punta, grosor=1.0):
    """Llave inglesa: mango grueso y cabeza con mandibula abierta. base y punta: extremos del mango en XY."""
    bx, by, bz = base
    tx, ty = punta
    ang = math.atan2(tx - bx, ty - by)
    largo = math.hypot(tx - bx, ty - by)
    q = rot_z(p - _V(bx, by, bz), ang)  # el mango queda sobre +Y
    mango = caja(q, (0, largo / 2, 0), (0.085 * grosor, largo / 2 + 0.03, 0.05), 0.03)
    cabeza_ll = cilindro(q, (0, largo + 0.11, -0.055), (0, largo + 0.11, 0.055), 0.27 * grosor)
    # la boca de la llave: una muesca abierta hacia arriba y a un lado
    q2 = rot_z(q - _V(0, largo + 0.17, 0), -0.30)
    cabeza_ll = resta(cabeza_ll, caja(q2, (0, 0.20, 0), (0.115 * grosor, 0.24, 0.2), 0.0))
    # tornillo de ajuste
    tornillo = caja(q, (0, largo - 0.12, 0.05), (0.06, 0.05, 0.02), 0.008)
    return [(union_suave(mango, cabeza_ll, 0.05), T_LLAVE), (tornillo, T_ORO)]


def mano_puño(p, c, r=0.17, dedos_dir=(1, 0), z_extra=0.0):
    """Puño: una bola y cuatro nudillos que asoman, para que se lea como mano."""
    ds = [(esfera(p, c, r), T_PIEL)]
    for k in range(4):
        f = (k - 1.5) * r * 0.60
        dx, dy = dedos_dir
        cx = c[0] + (-dy) * f + dx * r * 0.45
        cy = c[1] + dx * f + dy * r * 0.45
        ds.append((esfera(p, (cx, cy, c[2] + r * 0.72 + z_extra), r * 0.36), T_PIEL))
    # pulgar cruzado sobre los dedos
    dx, dy = dedos_dir
    ds.append((capsula(p, (c[0] - dx * r * 0.2 - dy * r * 0.7, c[1] - dy * r * 0.2 + dx * r * 0.7, c[2] + r * 0.8),
                       (c[0] + dx * r * 0.45 + dy * r * 0.1, c[1] + dy * r * 0.45 - dx * r * 0.1, c[2] + r * 1.05), r * 0.30), T_PIEL))
    return ds


def don_tuerca(boca=0.0, cejas=0.0, guino=False, pose=0):
    """pose: 0 tranquilo, 1 grita (sube los hombros y aprieta la llave), 2 levanta la llave."""
    sube = {0: 0.0, 1: 0.03, 2: 0.015}[pose]
    # posiciones de los brazos segun la pose: hombro, codo, muñeca
    if pose == 2:
        cod_d, mun_d, punta_ll = (1.52, -0.72, -0.02), (1.36, -0.04, 0.20), (1.46, 1.02)
    elif pose == 1:
        cod_d, mun_d, punta_ll = (1.52, -1.14, -0.02), (1.38, -0.56, 0.20), (1.54, 0.40)
    else:
        cod_d, mun_d, punta_ll = (1.52, -1.20, -0.02), (1.36, -0.64, 0.20), (1.44, 0.30)
    hom_d, hom_i = (0.84, -0.66 + sube, -0.04), (-0.84, -0.66 + sube, -0.04)
    cod_i, mun_i = (-1.50, -1.02, -0.10), (-1.14, -1.34, 0.16)

    def e(p):
        ds = []
        # --- torso: pecho, guata y hombros ---
        pecho = elipsoide(p, (0, -0.98 + sube, -0.05), (0.84, 0.60, 0.46))
        guata = elipsoide(p, (0, -1.56, 0.03), (0.82, 0.62, 0.52))
        torso = union_suave(pecho, guata, 0.2)
        for s in (-1, 1):
            torso = union_suave(torso, esfera(p, (s * 0.80, -0.68 + sube, -0.05), 0.24), 0.2)
            torso = union_suave(torso, capsula(p, (0, -0.52 + sube, -0.06), (s * 0.72, -0.66 + sube, -0.06), 0.15), 0.14)
        ds.append((torso, T_CAMISA))
        # --- cuello flaco de viejo, con manzana de Adan ---
        ds.append((capsula(p, (0, 0.06, -0.06), (0, -0.52 + sube, -0.08), 0.19), T_PIEL))
        ds.append((esfera(p, (0.0, -0.28, 0.12), 0.05), T_PIEL))
        # camisa abierta en V: asoma la piel del pecho, con dos solapas a los lados
        escote = poligono(p, [(-0.17, -0.44 + sube), (0.17, -0.44 + sube), (0.0, -0.78 + sube)], 3.0)
        ds.append((np.maximum(torso - 0.012, np.maximum(escote, -p[..., 2])), T_PIEL))
        for s in (-1, 1):
            q = rot_z(p - _V(s * 0.20, -0.53 + sube, 0.22), s * 1.05)
            ds.append((caja(q, (0, 0, 0), (0.18, 0.075, 0.09), 0.02), T_BLANCO))
        # --- overol: la pechera y el pantalon van pegados al cuerpo ---
        cubierta = torso - 0.035
        pechera = poligono(p, [(-0.44, -0.90 + sube), (0.44, -0.90 + sube), (0.56, -1.30), (-0.56, -1.30)], 3.0)
        pechera = np.maximum(pechera, -p[..., 2])
        cintura = p[..., 1] + 1.30
        ds.append((np.maximum(cubierta, np.minimum(pechera, cintura)), T_OVEROL))
        # bolsillo de la pechera
        bolsillo = caja(p, (0, -1.10 + sube, 0.5), (0.25, 0.12, 0.5), 0.01)
        ds.append((np.maximum(torso - 0.05, bolsillo), T_OVEROL2))
        # tirantes: suben desde la pechera y pasan por encima de los hombros
        for s in (-1, 1):
            tirante = poligono(p, [(s * 0.28, -0.88 + sube), (s * 0.44, -0.88 + sube), (s * 0.68, -0.30 + sube), (s * 0.50, -0.30 + sube)], 3.0)
            ds.append((np.maximum(torso - 0.04, tirante), T_OVEROL))
            hebilla = caja(p, (s * 0.36, -0.88 + sube, 0.5), (0.10, 0.075, 0.5), 0.01)
            ds.append((np.maximum(torso - 0.06, hebilla), T_ORO))
        # tuerca bordada en el bolsillo: es su nombre
        hexa = [(math.cos(k * math.pi / 3 + 0.52) * 0.125, -1.11 + sube + math.sin(k * math.pi / 3 + 0.52) * 0.125) for k in range(6)]
        tuerca = resta(poligono(p, hexa, 3.0), cilindro(p, (0, -1.11 + sube, -3), (0, -1.11 + sube, 3), 0.05))
        ds.append((np.maximum(torso - 0.065, np.maximum(tuerca, -p[..., 2])), T_ORO))
        # destornillador asomado en el bolsillo
        ds.append((capsula(p, (0.17, -0.99 + sube, 0.50), (0.20, -0.86 + sube, 0.47), 0.03), T_ROJO))
        # manchas de grasa
        for (mx, my, mr) in ((-0.42, -1.44, 0.08), (0.38, -1.52, 0.06), (0.52, -1.40, 0.04)):
            ds.append((np.maximum(torso - 0.05, elipsoide(p, (mx, my, 0.5), (mr, mr * 0.7, 2.0))), T_OVEROL2))
        # --- brazo izquierdo de la pantalla: mano en la cintura ---
        media_i = mezcla(hom_i, cod_i, 0.48)
        ds.append((capsula(p, hom_i, media_i, 0.205), T_CAMISA))
        ds.append((capsula(p, mezcla(hom_i, cod_i, 0.42), media_i, 0.228), T_BLANCO))
        ds.append((capsula(p, media_i, cod_i, 0.155), T_PIEL))
        ds.append((capsula(p, cod_i, mun_i, 0.14), T_PIEL))
        ds += mano_puño(p, mezcla(cod_i, mun_i, 1.16), 0.19, (0.75, -0.65))
        # --- brazo derecho de la pantalla: agarra la llave inglesa ---
        media_d = mezcla(hom_d, cod_d, 0.48)
        ds.append((capsula(p, hom_d, media_d, 0.205), T_CAMISA))
        ds.append((capsula(p, mezcla(hom_d, cod_d, 0.42), media_d, 0.228), T_BLANCO))
        ds.append((capsula(p, media_d, cod_d, 0.155), T_PIEL))
        ds.append((capsula(p, cod_d, mun_d, 0.14), T_PIEL))
        mano = mezcla(cod_d, mun_d, 1.14)
        base_ll = (mano[0] - (punta_ll[0] - mano[0]) * 0.14, mano[1] - (punta_ll[1] - mano[1]) * 0.14, mano[2] + 0.02)
        ds += llave_inglesa(p, base_ll, punta_ll)
        ds += mano_puño(p, mano, 0.19, (1.0, 0.1))
        # --- meson de trabajo: el retrato se corta en el, no en el aire ---
        ds.append((caja(p, (0, -1.80, 1.0), (2.3, 0.20, 0.1), 0.0), T_MESON))
        # --- cabeza, encima de todo ---
        s = 0.86
        c = _V(0.0, 0.50 + sube, 0.0)
        q = (p - c) / s
        if pose == 2:
            q = rot_z(q, 0.05)
        elif pose == 1:
            q = rot_z(q, -0.04)
        for d, mat in cabeza(q, boca, cejas, guino, 0.28 if guino else 0.0):
            ds.append((d * s, mat))
        return ds

    return e


def pintar_meson(a):
    """El retrato se corta en el meson de trabajo, no en el aire: tablon con vetas, canto de fierro y tuercas."""
    h, w = a.shape[:2]
    y0 = h - 10  # el meson ocupa las ultimas filas
    r = random.Random(4)
    cols = [hex2rgb(c) for c in ("#6a4428", "#5a3820", "#7c5230")]
    for y in range(y0, h):
        a[y, :, :3] = hex2rgb("#6a4428")
        a[y, :, 3] = 255
    for _ in range(26):
        y = r.randint(y0 + 3, h - 1)
        x = r.randint(-6, w)
        a[y, max(x, 0):max(x + r.randint(6, 26), 0), :3] = r.choice(cols[1:])
    a[y0 - 1, :, :3] = hex2rgb("#0d0a18")
    a[y0 - 1, :, 3] = 255
    a[y0, :, :3] = hex2rgb("#d0dce6")
    a[y0 + 1, :, :3] = hex2rgb("#66788f")
    a[y0 + 2, :, :3] = hex2rgb("#3a2214")
    for x in range(6, w, 29):
        a[y0 + 5, x:x + 2, :3] = hex2rgb("#3a2214")
        a[y0 + 4, x:x + 1, :3] = hex2rgb("#c89a60")
    return a, y0


# Tuerca de adorno sobre el meson: su nombre, en dorado
_TUERCA_PX = ["..kkkk..", ".kyyyyk.", "kyhkkyyk", "kykkkkyk", "kykkkkyk", "kyykkyyk", ".kooook.", "..kkkk.."]
_TUERCA_COL = {"k": "#0d0a18", "y": "#f5c84c", "h": "#fff2a0", "o": "#a06a18"}


def pegar_tuerca(a, x, y):
    for j, f in enumerate(_TUERCA_PX):
        for i, ch in enumerate(f):
            if ch != ".":
                a[y + j, x + i, :3] = hex2rgb(_TUERCA_COL[ch])
                a[y + j, x + i, 3] = 255


def render_tuerca(boca, cejas, guino, pose):
    a = renderizar(don_tuerca(boca, cejas, guino, pose), RT, 128, encuadre=1.90, centro=(0.02, 0.03), inclinacion=0.03, ss=3, luz=(-0.45, 0.65, 0.75))
    a, y0 = pintar_meson(a)
    pegar_tuerca(a, 106, y0 - 8)
    return a


if quiere("retrato_tuerca"):
    tira("retrato_tuerca", [render_tuerca(b, c, g, po) for b, c, g, po in ((0.0, 0.0, False, 0), (0.55, 0.15, False, 0), (1.0, 1.0, False, 1), (0.12, 1.0, True, 2))])


# =============================================================================
# EL HANGAR: el baño de Don Tuerca convertido en taller.
# Todo vive en una sola habitacion 3D (metros) vista por una sola camara, asi que el fondo y los
# objetos calzan solos: cada objeto se renderiza en el lugar exacto donde va en la pantalla.
# X: derecha, Y: arriba, Z: hacia la camara. La pared del fondo esta en Z=0.
# =============================================================================
CAM_D, CAM_F, CAM_OJO, CAM_CX, CAM_CY = 6.0, 420.0, 2.0, 320.0, 90.0
SALA_X, SALA_Y = 3.0, 2.7
LAMPARAS = [(-0.74, 2.26, 1.45), (0.74, 2.26, 1.45)]
# Los objetos se iluminan con la misma luz, pero algo mas adelante: asi sus frentes no quedan a oscuras
LUCES_OBJ = [(-1.1, 2.5, 3.0), (1.1, 2.5, 3.0)]


def proyectar(x, y, z):
    k = CAM_F / (CAM_D - z)
    return CAM_CX + x * k, CAM_CY + (CAM_OJO - y) * k


def escala_en(z):
    """Pixeles por metro a esa profundidad."""
    return CAM_F / (CAM_D - z)


def _sombra_rayo(escena, p, l, largo, pasos=14):
    """Sombra suave hacia la lampara: 1 con luz, 0 tapado."""
    t = np.full(p.shape[0], 0.04)
    s = np.ones(p.shape[0])
    vivo = np.ones(p.shape[0], bool)
    for _ in range(pasos):
        idx = np.where(vivo)[0]
        if not len(idx):
            break
        dd = _escena_mat(escena, p[idx] + l[idx] * t[idx][:, None])[0]
        s[idx] = np.minimum(s[idx], np.clip(7.0 * dd / t[idx], 0, 1))
        t[idx] += np.maximum(dd, 0.02)
        vivo[idx[(t[idx] > largo[idx]) | (dd < 0.002)]] = False
        s[idx[dd < 0.002]] = 0.0
    return s


def _alfa_limpio(codigo, min_pedazo=10, max_hoyo=24):
    """Quita pedacitos sueltos y tapa hoyitos: el contorno que brilla sale del alfa y debe ser limpio."""
    h, w = codigo.shape
    lleno = codigo >= 0

    def manchas(mascara):
        visto = np.zeros(mascara.shape, bool)
        salida = []
        for y0, x0 in zip(*np.where(mascara)):
            if visto[y0, x0]:
                continue
            pila, puntos = [(y0, x0)], []
            visto[y0, x0] = True
            while pila:
                y, x = pila.pop()
                puntos.append((y, x))
                for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                    if 0 <= ny < h and 0 <= nx < w and mascara[ny, nx] and not visto[ny, nx]:
                        visto[ny, nx] = True
                        pila.append((ny, nx))
            salida.append(puntos)
        return salida

    for puntos in manchas(lleno):
        if len(puntos) < min_pedazo:
            for y, x in puntos:
                codigo[y, x] = -1
    vacio = codigo < 0
    tapar = []
    for puntos in manchas(vacio):
        toca = any(y in (0, h - 1) or x in (0, w - 1) for y, x in puntos)
        if not toca and len(puntos) <= max_hoyo:
            tapar += puntos
    return codigo, tapar


def render_objeto(escena, rampas, lim, ss=3, tramado=0.3, salto=0.10, sombra=True, contorno=True, luz_base=0.10):
    """Renderiza con la camara de la sala. lim: caja que encierra el objeto ((x,y,z), (x,y,z)).
    Devuelve (rgba, x0, y0): el dibujo recortado justo a lo pintado y donde va en la pantalla."""
    lo, hi = np.array(lim[0], dtype=np.float64), np.array(lim[1], dtype=np.float64)
    esq = [proyectar(x, y, z) for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])]
    x0 = max(int(math.floor(min(e[0] for e in esq))) - 3, 0)
    x1 = min(int(math.ceil(max(e[0] for e in esq))) + 3, 640)
    y0 = max(int(math.floor(min(e[1] for e in esq))) - 3, 0)
    y1 = min(int(math.ceil(max(e[1] for e in esq))) + 3, 360)
    w, h = x1 - x0, y1 - y0
    W, H = w * ss, h * ss
    XX, YY = np.meshgrid(x0 + (np.arange(W) + 0.5) / ss, y0 + (np.arange(H) + 0.5) / ss)
    d = np.stack([(XX - CAM_CX) / CAM_F, -(YY - CAM_CY) / CAM_F, -np.ones_like(XX)], -1).reshape(-1, 3)
    d /= np.linalg.norm(d, axis=-1, keepdims=True)
    o = np.array([0.0, CAM_OJO, CAM_D])
    with np.errstate(divide="ignore", invalid="ignore"):
        t1, t2 = (lo - o) / d, (hi - o) / d
    tn, tf = np.minimum(t1, t2).max(-1), np.maximum(t1, t2).min(-1)
    vivo = (tn < tf) & (tf > 0)
    t = np.maximum(tn, 0.0)
    golpe = np.zeros(d.shape[0], bool)
    for _ in range(100):
        idx = np.where(vivo)[0]
        if not len(idx):
            break
        dd = _escena_mat(escena, o + d[idx] * t[idx][:, None])[0]
        t[idx] += dd * 0.9
        g = dd < 0.004
        golpe[idx[g]] = True
        vivo[idx[g]] = False
        vivo[idx[t[idx] > tf[idx] + 0.01]] = False
    codigo_fino = np.full(d.shape[0], -1, dtype=np.int32)
    prof = np.full(d.shape[0], 99.0)
    if golpe.any():
        p = o + d[golpe] * t[golpe][:, None]
        n = _normal(escena, p, e=0.006)
        m_ = _escena_mat(escena, p)[1]
        V = -d[golpe]
        ao = np.clip(_escena_mat(escena, p + n * 0.06)[0] / 0.06, 0, 1)
        luces = np.zeros(p.shape[0])
        esp = np.zeros(p.shape[0])
        for L in LUCES_OBJ:
            lv = np.array(L) - p
            dist = np.linalg.norm(lv, axis=-1)
            ln = lv / dist[:, None]
            dif = np.clip((n * ln).sum(-1), 0, 1)
            s = _sombra_rayo(escena, p + n * 0.015, ln, dist) if sombra else 1.0
            luces += dif * s / (1.0 + 0.10 * dist * dist)
            medio = ln + V
            medio /= np.linalg.norm(medio, axis=-1, keepdims=True)
            esp = np.maximum(esp, np.clip((n * medio).sum(-1), 0, 1) ** 28 * s)
        frente = np.clip((n * V).sum(-1), 0, 1)
        val = luz_base + 0.78 * luces * (0.6 + 0.4 * ao) + 0.26 * frente * (0.55 + 0.45 * ao)
        rim = (1.0 - frente) ** 3
        idx_px = np.where(golpe)[0]
        py, px = np.unravel_index(idx_px, (H, W))
        bay = BAYER[(py // ss) % 4, (px // ss) % 4] - 0.5
        tono = np.zeros(p.shape[0], dtype=np.int32)
        for mi, r in enumerate(rampas):
            sel = m_ == mi
            if not sel.any():
                continue
            N = len(r.c)
            if r.emisiva:
                tono[sel] = np.clip((frente[sel] ** r.curva * N).astype(int), 0, N - 1)
            else:
                x = (np.clip(val[sel], 0, 1) ** r.curva) * N + bay[sel] * tramado
                x = np.clip(x.astype(int), 0, N - 1 if r.mate else N - 2)
                if not r.mate:
                    x = np.where(esp[sel] > 0.72, N - 1, x)
                tono[sel] = np.where((rim[sel] > 0.55) & (x <= 1), x + 1, x)
        codigo_fino[golpe] = m_ * 16 + tono
        prof[golpe] = t[golpe]
    codigo_fino = codigo_fino.reshape(H, W)
    prof = prof.reshape(H, W)
    # reduccion por moda: el color mas repetido de cada celda, sin mezclar colores
    codigo = np.full((h, w), -1, dtype=np.int32)
    pr = np.full((h, w), 99.0)
    for y in range(h):
        for x in range(w):
            celda = codigo_fino[y * ss:(y + 1) * ss, x * ss:(x + 1) * ss].ravel()
            llenos = celda[celda >= 0]
            if llenos.size * 2 < celda.size:
                continue
            v, c = np.unique(llenos, return_counts=True)
            codigo[y, x] = v[c.argmax()]
            pr[y, x] = prof[y * ss:(y + 1) * ss, x * ss:(x + 1) * ss].min()
    codigo, tapar = _alfa_limpio(codigo)
    a = np.zeros((h, w, 4), dtype=np.uint8)
    for y, x in zip(*np.where(codigo >= 0)):
        k = codigo[y, x]
        a[y, x, :3] = rampas[k // 16].c[k % 16]
        a[y, x, 3] = 255
    for y, x in tapar:
        a[y, x] = CONTORNO + (255,)
    # raya interior: un tono mas oscuro donde hay salto de profundidad
    copia = a.copy()
    for y, x in zip(*np.where(codigo >= 0)):
        k = codigo[y, x]
        if rampas[k // 16].emisiva:
            continue
        for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and codigo[ny, nx] >= 0 and pr[y, x] - pr[ny, nx] > salto:
                copia[y, x, :3] = rampas[k // 16].c[0]
                break
    a = copia
    if contorno:
        s = a[..., 3] > 0
        vec = np.zeros_like(s)
        vec[1:, :] |= s[:-1, :]
        vec[:-1, :] |= s[1:, :]
        vec[:, 1:] |= s[:, :-1]
        vec[:, :-1] |= s[:, 1:]
        anillo = vec & ~s
        a[anillo, :3] = CONTORNO
        a[anillo, 3] = 255
    ys, xs = np.where(a[..., 3] > 0)
    if not len(xs):
        return a[:1, :1], x0, y0
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1], x0 + int(xs.min()), y0 + int(ys.min())


# --- letras para los carteles -------------------------------------------------
_L3 = {"A": ".#.|#.#|###|#.#|#.#", "B": "##.|#.#|##.|#.#|##.", "C": ".##|#..|#..|#..|.##", "D": "##.|#.#|#.#|#.#|##.", "E": "###|#..|##.|#..|###",
       "F": "###|#..|##.|#..|#..", "G": ".##|#..|#.#|#.#|.##", "H": "#.#|#.#|###|#.#|#.#", "I": "###|.#.|.#.|.#.|###", "J": "..#|..#|..#|#.#|.#.",
       "K": "#.#|#.#|##.|#.#|#.#", "L": "#..|#..|#..|#..|###", "M": "#.#|###|###|#.#|#.#", "N": "##.|#.#|#.#|#.#|#.#", "O": "###|#.#|#.#|#.#|###",
       "P": "##.|#.#|##.|#..|#..", "Q": ".#.|#.#|#.#|##.|.##", "R": "##.|#.#|##.|#.#|#.#", "S": ".##|#..|.#.|..#|##.", "T": "###|.#.|.#.|.#.|.#.",
       "U": "#.#|#.#|#.#|#.#|###", "V": "#.#|#.#|#.#|#.#|.#.", "W": "#.#|#.#|###|###|#.#", "X": "#.#|#.#|.#.|#.#|#.#", "Y": "#.#|#.#|.#.|.#.|.#.",
       "Z": "###|..#|.#.|#..|###", "0": "###|#.#|#.#|#.#|###", "1": ".#.|##.|.#.|.#.|###", "2": "##.|..#|.#.|#..|###", "3": "##.|..#|.#.|..#|##.",
       "4": "#.#|#.#|###|..#|..#", "5": "###|#..|##.|..#|##.", "6": ".##|#..|###|#.#|###", "7": "###|..#|.#.|.#.|.#.", "8": "###|#.#|###|#.#|###",
       "9": "###|#.#|###|..#|##.", ">": "#..|.#.|..#|.#.|#..", ".": "...|...|...|...|.#.", "!": ".#.|.#.|.#.|...|.#.", "¡": ".#.|...|.#.|.#.|.#.", "-": "...|...|###|...|...",
       ":": "...|.#.|...|.#.|...", "?": "##.|..#|.#.|...|.#.", "¿": ".#.|...|.#.|#..|.##", "/": "..#|..#|.#.|#..|#..", " ": "...|...|...|...|..."}
_ACENTOS = {"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ñ": "N"}


def texto_inclinado(a, x0, y0, centro, eje_u, txt, col):
    """Texto de 3x5 sobre una cara girada: conserva cada letra pixel por pixel y solo la inclina por escalones."""
    c = np.array(centro, dtype=np.float64)
    u = np.array(eje_u, dtype=np.float64)
    pa, pb = proyectar(*(c - u * 0.2)), proyectar(*(c + u * 0.2))
    m_ = (pb[1] - pa[1]) / (pb[0] - pa[0])
    sx, sy = proyectar(*c)
    ancho = ancho3(txt)
    t = lamina(ancho, 7)
    texto3(t, 0, 2, txt, col)
    xi, yi = int(round(sx - ancho / 2)) - x0, int(round(sy - 3.5)) - y0
    for i in range(ancho):
        d_ = int(round(m_ * (i - ancho / 2)))
        for j in range(7):
            if t[j, i, 3] > 0 and 0 <= yi + j + d_ < a.shape[0] and 0 <= xi + i < a.shape[1]:
                a[yi + j + d_, xi + i, :3] = t[j, i, :3]


def texto3(a, x, y, txt, col):
    """Texto de 3x5 (con tildes y eñe encima). a: RGBA o RGB. Devuelve el ancho escrito."""
    col = hex2rgb(col) if isinstance(col, str) else col
    c0 = x
    for ch in txt:
        base = _ACENTOS.get(ch, ch)
        for j, fila in enumerate(_L3[base].split("|")):
            for i, q in enumerate(fila):
                if q == "#" and 0 <= y + j < a.shape[0] and 0 <= x + i < a.shape[1]:
                    a[y + j, x + i, :3] = col
                    if a.shape[2] == 4:
                        a[y + j, x + i, 3] = 255
        if ch in _ACENTOS and 0 <= y - 2 < a.shape[0]:
            if ch == "Ñ":
                a[y - 2, x:x + 3, :3] = col
            else:
                a[y - 2, x + 1, :3] = col
        x += 4
    return x - c0 - 1


def ancho3(txt):
    return len(txt) * 4 - 1


def texto5(a, x, y, txt, col, esc=1, sombra=None, temblor=None):
    """Letra grande de 5x7 de la fuente v1. temblor: Random para que parezca pintada a mano."""
    col = hex2rgb(col) if isinstance(col, str) else col
    for ch in txt:
        filas, ancho = glifo(ch)
        dy = temblor.randint(-1, 1) if temblor else 0
        for j, fila in enumerate(filas):
            for i, q in enumerate(fila):
                if q != "#":
                    continue
                X, Y = x + i * esc, y + (j - 2) * esc + dy
                if sombra is not None:
                    a[Y + esc:Y + esc * 2, X + 1:X + esc + 1, :3] = hex2rgb(sombra)
                a[Y:Y + esc, X:X + esc, :3] = col
        x += (ancho + 1) * esc
    return x


# =============================================================================
# MATERIALES DE LA SALA
# =============================================================================
_R = lambda *c, **k: Rampa(list(c), **k)
RS = [
    _R("#1e2433", "#333f55", "#4f6076", "#71879c", "#9fb3c4", "#e3eef5"),  # 0 acero
    _R("#12141c", "#1c2230", "#2a3244", "#3c485e", "#566880", "#8aa0b4"),  # 1 acero oscuro
    _R("#62627a", "#83839a", "#a6a6b8", "#c8c8d4", "#e6e6ec", "#ffffff", mate=True),  # 2 porcelana
    _R("#3a1c14", "#6a3420", "#9a5630", "#c87c44", "#eca868", "#ffe0a8"),  # 3 cobre
    _R("#4a2a1a", "#8a5220", "#c08a2c", "#e8b844", "#f8d870", "#fff6b0"),  # 4 laton
    _R("#3a161c", "#5e2224", "#84302a", "#a4422c", "#c45c32", "#e88a4c", mate=True),  # 5 casillero
    _R("#7a2a08", "#b8460c", "#e8681a", "#ff9238", "#ffbe70", mate=True),  # 6 cono
    _R("#6c6a78", "#94929e", "#bab8c2", "#dedce2", "#f6f4f6", "#ffffff", mate=True),  # 7 papel
    _R("#0d0a18", "#16112a", "#201a38", "#2c2448", "#3a3058", mate=True),  # 8 negro
    _R("#3c2616", "#5c3c22", "#7c5632", "#9a7246", "#b68e5e", "#d0aa7a", mate=True),  # 9 corcho
    _R("#2a1810", "#46291a", "#643e26", "#845632", "#a47040", "#c89258", mate=True),  # 10 madera
    _R("#4a4230", "#6e644c", "#94886c", "#b8ac8c", "#d8ccac", "#f4ead0", mate=True),  # 11 plastico viejo
    _R("#0e3a1c", "#1c6a30", "#3cb050", "#8ef07c", emisiva=True, curva=1.0),  # 12 pantalla
    _R("#7a1ea0", "#c040e0", "#f070f0", "#ffb8ff", "#ffffff", emisiva=True, curva=0.72),  # 13 violeta
    _R("#157a9e", "#29c5e6", "#8ff0ff", "#ffffff", emisiva=True, curva=1.0),  # 14 cian
    _R("#5a1020", "#9a1a30", "#d02a3a", "#f0584a", "#ffa080"),  # 15 rojo
    _R("#5a2a4a", "#863c68", "#b85a8a", "#e08ab0", "#ffc0d8", mate=True),  # 16 frazada
    _R("#5a4008", "#a07c10", "#e0b820", "#f8d840", "#fff08a", mate=True),  # 17 amarillo
    _R("#20203a", "#2c2c4a", "#3c3c5c", "#585874", "#7c7c94", mate=True),  # 18 goma
    _R("#2a4a34", "#3a6a48", "#50906a", "#7ab890", "#b0e0b8", mate=True),  # 19 verde gastado
    _R("#c8a030", "#f0d060", "#fff4a0", "#ffffff", emisiva=True, curva=0.8),  # 20 ampolleta
    _R("#2a3c5c", "#3c5880", "#5a80ac", "#86aad0", "#c0dcf0", mate=True),  # 21 azul cortina
    _R("#a06c20", "#d89c30", "#ffd24a", "#fff0a0", emisiva=True, curva=0.9),  # 22 aviso encendido
    _R("#1a7a3a", "#20904a", "#26a452", "#30b85c", emisiva=True, curva=0.8),  # 23 letrero de salida
]
M_ACERO, M_ACERO2, M_PORC, M_COBRE, M_LATON, M_LOCKER, M_CONO, M_PAPEL, M_NEGRO, M_CORCHO, M_MADERA, M_PLASTICO, M_PANTALLA, M_VIOLETA, M_CIAN, M_ROJO, M_FRAZADA, M_AMARILLO, M_GOMA, M_VERDE, M_AMPOLLETA, M_CORTINA, M_AVISO, M_SALIDA = range(24)


def tubo(p, puntos, r):
    d = capsula(p, puntos[0], puntos[1], r)
    for a, b in zip(puntos[1:-1], puntos[2:]):
        d = np.minimum(d, capsula(p, a, b, r))
    return d


# =============================================================================
# CALCOMANIAS: pegan una imagen chica sobre un rectangulo 3D, con perspectiva correcta
# =============================================================================
def lamina(w, h, fondo=None):
    a = np.zeros((h, w, 4), dtype=np.uint8)
    if fondo:
        a[..., :3] = hex2rgb(fondo)
        a[..., 3] = 255
    return a


def decal(a, x0, y0, O, U, V, tex):
    """a: sprite en la pantalla (x0, y0). O: esquina de arriba a la izquierda. U: lado ancho. V: lado alto, hacia abajo."""
    O, U, V = np.array(O, dtype=np.float64), np.array(U, dtype=np.float64), np.array(V, dtype=np.float64)
    N = np.cross(U, V)
    o = np.array([0.0, CAM_OJO, CAM_D])
    h, w = a.shape[:2]
    XX, YY = np.meshgrid(x0 + np.arange(w) + 0.5, y0 + np.arange(h) + 0.5)
    d = np.stack([(XX - CAM_CX) / CAM_F, -(YY - CAM_CY) / CAM_F, -np.ones_like(XX)], -1)
    with np.errstate(divide="ignore", invalid="ignore"):
        t = ((O - o) * N).sum() / (d * N).sum(-1)
    P = o + d * t[..., None]
    u = ((P - O) * U).sum(-1) / (U * U).sum()
    v = ((P - O) * V).sum(-1) / (V * V).sum()
    th, tw = tex.shape[:2]
    dentro = (u >= 0) & (u < 1) & (v >= 0) & (v < 1) & (a[..., 3] > 0)
    iy, ix = (v[dentro] * th).astype(int), (u[dentro] * tw).astype(int)
    texel = tex[iy, ix]
    op = texel[..., 3] > 0
    ys, xs = np.where(dentro)
    a[ys[op], xs[op], :3] = texel[op][..., :3]


def frontal(a, x0, y0, x, y, z, tex):
    """Pega tex de frente, un texel por pixel, centrado en el punto 3D (x, y, z)."""
    sx, sy = proyectar(x, y, z)
    ox, oy = int(round(sx - tex.shape[1] / 2)) - x0, int(round(sy - tex.shape[0] / 2)) - y0
    for j in range(tex.shape[0]):
        for i in range(tex.shape[1]):
            if tex[j, i, 3] > 0 and 0 <= oy + j < a.shape[0] and 0 <= ox + i < a.shape[1] and a[oy + j, ox + i, 3] > 0:
                a[oy + j, ox + i, :3] = tex[j, i, :3]


_CALAVERA = ["..###..", ".#####.", ".#.#.#.", ".#####.", "..###..", "..#.#.."]


# =============================================================================
# OBJETOS DEL HANGAR. Cada uno: (escena, caja limite, retoque final)
# =============================================================================
PLATO_Z = 1.54
LOCKER_C, LOCKER_ANG = _V(-2.60, 0.0, 1.62), -0.24
LOCKER_W, LOCKER_D = 0.42, 0.26
EXC_X = -1.72
TINA_C, TINA_L = _V(1.43, 0.0, 2.02), 0.58
ARS_T, ARS_M, ARS_L = 2.01, 1.91, 1.89  # donde va cada parte del arsenal, para que en pantalla queden alineadas
PUERTA_Z0, PUERTA_Z1 = 0.62, 1.90


def e_plataforma():
    c = _V(0.0, 0.0, PLATO_Z)

    def e(p):
        q = p - c
        ds = []
        ds.append((cilindro(q, (0, 0.0, 0), (0, 0.08, 0), 0.78), M_ACERO2))
        ds.append((cilindro(q, (0, 0.08, 0), (0, 0.15, 0), 0.72), M_ACERO))
        # anillo con franjas de peligro: se elige el material segun el angulo
        ang = np.arctan2(q[..., 2], q[..., 0])
        franja = np.sin(ang * 14.0) > 0
        anillo = resta(cilindro(q, (0, 0.15, 0), (0, 0.165, 0), 0.70), cilindro(q, (0, 0.10, 0), (0, 0.20, 0), 0.57))
        ds.append((np.where(franja, anillo, anillo + 0.2), M_AMARILLO))
        ds.append((np.where(franja, anillo + 0.2, anillo), M_NEGRO))
        # luz azul y el plato del medio
        ds.append((toro(q, (0, 0.16, 0), (0, 1, 0), 0.53, 0.018), M_CIAN))
        ds.append((cilindro(q, (0, 0.15, 0), (0, 0.165, 0), 0.49), M_ACERO))
        # el desague de la ducha sigue ahi, en el centro
        ds.append((cilindro(q, (0, 0.16, 0), (0, 0.172, 0), 0.20), M_ACERO2))
        ds.append((toro(q, (0, 0.172, 0), (0, 1, 0), 0.20, 0.014), M_ACERO))
        rejilla = np.abs(np.sin(q[..., 0] * 52.0)) < 0.5
        ds.append((np.where(rejilla, cilindro(q, (0, 0.165, 0), (0, 0.178, 0), 0.165), 9.0), M_NEGRO))
        # pernos del borde
        for k in range(12):
            a = k * math.pi / 6 + 0.26
            ds.append((esfera(q, (math.cos(a) * 0.755, 0.085, math.sin(a) * 0.755), 0.022), M_ACERO))
        return ds

    return e, ((-0.82, -0.01, PLATO_Z - 0.82), (0.82, 0.22, PLATO_Z + 0.82)), None


def e_locker():
    W, D_ = LOCKER_W, LOCKER_D

    def e(p):
        q = rot_y(p - LOCKER_C, LOCKER_ANG)
        ds = []
        ds.append((caja(q, (0, 1.03, 0), (W, 1.03, D_), 0.012), M_LOCKER))
        ds.append((caja(q, (0, 0.045, 0.0), (W - 0.04, 0.045, D_ - 0.04), 0.0), M_ACERO2))
        # puerta, un poco saliente
        ds.append((caja(q, (0, 1.06, D_ + 0.005), (W - 0.05, 0.94, 0.012), 0.004), M_LOCKER))
        # rejilla de ventilacion
        for k in range(5):
            ds.append((caja(q, (0, 1.78 - k * 0.075, D_ + 0.02), (W - 0.17, 0.018, 0.012), 0.0), M_NEGRO))
        # manilla y candado
        ds.append((caja(q, (W - 0.15, 1.28, D_ + 0.035), (0.026, 0.14, 0.025), 0.008), M_ACERO))
        ds.append((caja(q, (W - 0.15, 1.10, D_ + 0.04), (0.052, 0.05, 0.02), 0.01), M_LATON))
        ds.append((toro(q, (W - 0.15, 1.17, D_ + 0.04), (0, 0, 1), 0.032, 0.009), M_ACERO))
        # calcetin atrapado en la puerta
        ds.append((caja(q, (W - 0.015, 1.03, D_ + 0.02), (0.05, 0.03, 0.03), 0.01), M_PAPEL))
        ds.append((capsula(q, (W - 0.01, 1.00, D_ + 0.03), (W - 0.01, 0.68, D_ + 0.03), 0.046), M_PAPEL))
        ds.append((capsula(q, (W - 0.01, 0.66, D_ + 0.03), (W - 0.20, 0.60, D_ + 0.03), 0.052), M_PAPEL))
        ds.append((esfera(q, (W - 0.215, 0.597, D_ + 0.03), 0.058), M_ROJO))
        ds.append((esfera(q, (W + 0.0, 0.655, D_ + 0.03), 0.056), M_ROJO))
        for ya in (0.95, 0.87):
            ds.append((capsula(q, (W - 0.01, ya, D_ + 0.03), (W - 0.01, ya - 0.022, D_ + 0.03), 0.049), M_ROJO))
        # lugar de las calcomanias
        ds.append((caja(q, (0, 1.36, D_ + 0.02), (0.19, 0.05, 0.008), 0.0), M_PAPEL))
        ds.append((elipsoide(q, (-0.14, 0.62, D_ + 0.02), (0.11, 0.11, 0.008)), M_AMARILLO))
        ds.append((caja(q, (0.04, 0.34, D_ + 0.02), (0.23, 0.09, 0.008), 0.0), M_CIAN))
        # cono de repuesto arriba: no vaya a faltar
        ds.append((caja(q, (-0.08, 2.075, 0.0), (0.21, 0.015, 0.19), 0.004), M_CONO))
        ds.append((cono_truncado(q, (-0.08, 2.08, 0.0), (-0.08, 2.40, 0.0), 0.145, 0.022), M_CONO))
        ds.append((cono_truncado(q, (-0.08, 2.20, 0.0), (-0.08, 2.27, 0.0), 0.10, 0.074), M_PAPEL))
        return ds

    def retoque(a, x0, y0):
        # los ejes del frente de la puerta, ya girada
        cs, sn = math.cos(LOCKER_ANG), math.sin(LOCKER_ANG)
        ux, uz = cs, sn  # eje X local en el mundo
        def punto(lx, ly, lz):
            return (LOCKER_C[0] + cs * lx - sn * lz, ly, LOCKER_C[2] + sn * lx + cs * lz)
        # etiqueta
        texto_inclinado(a, x0, y0, punto(0, 1.36, D_ + 0.03), (ux, 0, uz), "EQUIPO", "#2a2340")
        # sticker con carita
        t = lamina(22, 22)
        for (cx, cy) in ((7, 8), (14, 8)):
            t[cy - 1:cy + 2, cx:cx + 2] = hex2rgb("#2a1a10") + (255,)
        for x in range(6, 16):
            y = 14 + int(2.2 * math.sin((x - 6) / 9 * math.pi))
            t[y:y + 1, x:x + 1] = hex2rgb("#2a1a10") + (255,)
        decal(a, x0, y0, punto(-0.25, 0.73, D_ + 0.03), (0.22 * ux, 0, 0.22 * uz), (0, -0.22, 0), t)
        # sticker azul: la recomendacion de la casa
        texto_inclinado(a, x0, y0, punto(0.04, 0.375, D_ + 0.03), (ux, 0, uz), "NO ABRIR", "#0e2a4a")
        texto_inclinado(a, x0, y0, punto(0.04, 0.305, D_ + 0.03), (ux, 0, uz), "HUELE MAL", "#0e2a4a")

    return e, ((-3.08, -0.01, 1.2), (-2.05, 2.46, 2.1)), retoque


def e_excusado():
    x0_ = EXC_X

    def e(p):
        q = p - _V(x0_, 0, 0)
        ds = []
        # --- el excusado: pie, taza y asiento ---
        ds.append((cono_truncado(q, (0, 0.0, 1.00), (0, 0.46, 1.04), 0.30, 0.21), M_PORC))
        taza = elipsoide(q, (0, 0.58, 1.10), (0.46, 0.26, 0.58))
        taza = np.maximum(taza, q[..., 1] - 0.72)
        hueco = elipsoide(q, (0, 0.74, 1.10), (0.385, 0.26, 0.50))
        ds.append((resta(taza, hueco), M_PORC))
        # agua que brilla: aqui se hace la magia
        ds.append((np.maximum(hueco, q[..., 1] - 0.64), M_VIOLETA))
        # asiento
        qs = (q - _V(0, 0.74, 1.10)) * _V(1.0, 1.0, 0.82)
        ds.append((toro(qs, (0, 0, 0), (0, 1, 0), 0.385, 0.040) * 0.82, M_MADERA))
        # --- estanque, convertido en maquina ---
        ds.append((caja(q, (0, 0.92, 0.22), (0.58, 0.42, 0.21), 0.04), M_PORC))
        ds.append((caja(q, (0, 1.36, 0.22), (0.62, 0.035, 0.24), 0.01), M_ACERO))
        # sube a tres embudos: tres piezas entran
        for s in (-0.40, 0.0, 0.40):
            ds.append((cilindro(q, (s, 1.38, 0.22), (s, 1.62, 0.22), 0.055), M_COBRE))
            ds.append((cono_truncado(q, (s, 1.60, 0.22), (s, 1.84, 0.22), 0.06, 0.19), M_ACERO))
            ds.append((toro(q, (s, 1.84, 0.22), (0, 1, 0), 0.19, 0.022), M_LATON))
        # manometro
        ds.append((cilindro(q, (-0.20, 1.14, 0.40), (-0.20, 1.14, 0.45), 0.135), M_LATON))
        ds.append((cilindro(q, (-0.20, 1.14, 0.44), (-0.20, 1.14, 0.462), 0.105), M_PAPEL))
        ds.append((capsula(q, (-0.20, 1.14, 0.47), (-0.14, 1.20, 0.47), 0.012), M_ROJO))
        # letrero del estanque
        ds.append((caja(q, (0.24, 0.88, 0.435), (0.32, 0.15, 0.006), 0.0), M_PAPEL))
        # palanca grande
        ds.append((cilindro(q, (0.58, 0.86, 0.22), (0.66, 0.86, 0.22), 0.05), M_ACERO))
        ds.append((capsula(q, (0.68, 0.84, 0.22), (0.70, 1.18, 0.26), 0.028), M_ACERO))
        ds.append((esfera(q, (0.70, 1.22, 0.26), 0.075), M_ROJO))
        # la cadena de siempre: sigue funcionando
        ds.append((capsula(q, (-0.44, 1.30, 0.34), (-0.44, 1.30, 0.47), 0.02), M_ACERO2))
        for k in range(6):
            ds.append((esfera(q, (-0.44, 1.28 - k * 0.07, 0.47), 0.027), M_ACERO2))
        ds.append((capsula(q, (-0.44, 0.88, 0.47), (-0.44, 0.78, 0.47), 0.05), M_ROJO))
        return ds

    def retoque(a, x0, y0):
        t = lamina(47, 23)
        for i, lin in enumerate(("FAVOR TIRAR", "LA CADENA", "AL FUSIONAR")):
            texto3(t, (47 - ancho3(lin)) // 2, 2 + i * 7, lin, "#2a2340")
        frontal(a, x0, y0, x0_ + 0.24, 0.88, 0.443, t)
        # chispas en el agua
        r = random.Random(7)
        cols = [hex2rgb(c) for c in ("#7a1ea0", "#c040e0", "#f070f0", "#ffb8ff", "#ffffff")]
        vio = np.zeros(a.shape[:2], bool)
        for c_ in cols:
            vio |= (a[..., :3] == np.array(c_, dtype=np.uint8)).all(-1)
        # el blanco de la porcelana no cuenta: solo lo que esta rodeado de violeta
        vio &= ~((a[..., :3] == np.array(cols[4], dtype=np.uint8)).all(-1))
        ys, xs = np.where(vio)
        if len(xs):
            for _ in range(len(xs) // 5):
                k = r.randrange(len(xs))
                a[ys[k], xs[k], :3] = r.choice(cols[1:4])
            for _ in range(5):
                k = r.randrange(len(xs))
                a[ys[k], xs[k], :3] = (255, 255, 255)

    return e, ((x0_ - 0.74, -0.01, 0.0), (x0_ + 0.82, 2.06, 1.72)), retoque


def e_tina():
    c, L = TINA_C, TINA_L

    def e(p):
        q = p - c
        ds = []
        cuerpo = caja(q, (0, 0.32, 0), (L, 0.22, 0.33), 0.13)
        hueco = caja(q, (0, 0.52, 0), (L - 0.09, 0.22, 0.24), 0.10)
        ds.append((resta(cuerpo, hueco), M_PORC))
        # borde redondeado
        ds.append((resta(caja(q, (0, 0.53, 0), (L + 0.01, 0.022, 0.34), 0.02), hueco), M_PORC))
        # patas de leon
        for sx in (-L + 0.14, L - 0.14):
            for sz in (-0.19, 0.19):
                ds.append((elipsoide(q, (sx, 0.07, sz), (0.09, 0.08, 0.08)), M_LATON))
                ds.append((esfera(q, (sx + 0.05 * (1 if sx > 0 else -1), 0.035, sz + 0.05), 0.04), M_LATON))
        # colchon, frazada y almohada
        ds.append((caja(q, (0, 0.50, 0), (L - 0.11, 0.06, 0.225), 0.05), M_PAPEL))
        ds.append((caja(q, (0.14, 0.54, 0), (L - 0.27, 0.055, 0.24), 0.05), M_FRAZADA))
        ds.append((caja(q, (0.14 - L + 0.25, 0.562, 0), (0.05, 0.04, 0.245), 0.03), M_PAPEL))
        ds.append((caja(q, (L - 0.20, 0.59, 0), (0.035, 0.012, 0.25), 0.004), M_PAPEL))
        ds.append((elipsoide(q, (-L + 0.17, 0.60, 0), (0.135, 0.07, 0.18)), M_PAPEL))
        # griferia al pie de la tina
        ds.append((tubo(q, [(L - 0.03, 0.54, 0.0), (L - 0.03, 0.74, 0.0), (L - 0.15, 0.79, 0.0), (L - 0.19, 0.73, 0.0)], 0.024), M_ACERO))
        for sz, col in ((-0.13, M_ROJO), (0.13, M_CORTINA)):
            ds.append((cilindro(q, (L - 0.03, 0.54, sz), (L - 0.03, 0.62, sz), 0.02), M_ACERO))
            ds.append((esfera(q, (L - 0.03, 0.64, sz), 0.036), col))
        # pato de goma en el borde
        ds.append((elipsoide(q, (-L + 0.08, 0.61, 0.32), (0.075, 0.055, 0.055)), M_AMARILLO))
        ds.append((esfera(q, (-L + 0.125, 0.68, 0.325), 0.042), M_AMARILLO))
        ds.append((elipsoide(q, (-L + 0.17, 0.675, 0.325), (0.03, 0.012, 0.02)), M_CONO))
        # cartel en el frente de la tina
        ds.append((caja(q, (0.0, 0.31, 0.336), (0.32, 0.075, 0.006), 0.0), M_PAPEL))
        return ds

    def retoque(a, x0, y0):
        t = lamina(38, 16)
        texto3(t, (38 - ancho3("CUIDADO:")) // 2, 2, "CUIDADO:", "#b02a30")
        texto3(t, (38 - ancho3("MUERDE")) // 2, 9, "MUERDE", "#b02a30")
        frontal(a, x0, y0, c[0], 0.31, c[2] + 0.345, t)

    return e, ((c[0] - L - 0.16, -0.01, c[2] - 0.42), (c[0] + L + 0.16, 0.84, c[2] + 0.42)), retoque


def e_arsenal():
    def e(p):
        ds = []
        q = p - _V(ARS_T, 0, 0)
        # --- tablon de encargos, en el marco del que fue el espejo del baño ---
        ds.append((caja(q, (0, 2.02, 0.05), (0.72, 0.40, 0.03), 0.005), M_CORCHO))
        marco = resta(caja(q, (0, 2.02, 0.06), (0.76, 0.44, 0.05), 0.01), caja(q, (0, 2.02, 0.10), (0.71, 0.39, 0.06)))
        ds.append((marco, M_MADERA))
        # --- lavamanos colgado, con el computador viejo encima ---
        q = p - _V(ARS_L, 0, 0)
        ds.append((caja(q, (0, 0.90, 0.40), (0.78, 0.11, 0.38), 0.07), M_PORC))
        # llave de agua, todavia gotea
        ds.append((tubo(q, [(-0.66, 1.00, 0.16), (-0.66, 1.16, 0.16), (-0.66, 1.16, 0.40), (-0.66, 1.08, 0.40)], 0.028), M_ACERO))
        ds.append((esfera(q, (-0.66, 1.18, 0.10), 0.05), M_ACERO))
        # vaso con cepillo de dientes y destornillador
        ds.append((cilindro(q, (0.68, 1.00, 0.48), (0.68, 1.14, 0.48), 0.055), M_CORTINA))
        ds.append((capsula(q, (0.67, 1.10, 0.48), (0.63, 1.30, 0.48), 0.014), M_ROJO))
        ds.append((capsula(q, (0.70, 1.10, 0.48), (0.73, 1.26, 0.48), 0.014), M_AMARILLO))
        # sifon cromado
        ds.append((tubo(q, [(-0.36, 0.80, 0.40), (-0.36, 0.64, 0.40), (-0.36, 0.56, 0.30), (-0.36, 0.62, 0.14), (-0.36, 0.62, 0.0)], 0.036), M_ACERO))
        q = p - _V(ARS_M, 0, 0)
        # monitor gordo y su teclado
        ds.append((caja(q, (0.0, 1.32, 0.34), (0.56, 0.34, 0.30), 0.05), M_PLASTICO))
        ds.append((caja(q, (0.0, 1.03, 0.36), (0.32, 0.05, 0.24), 0.01), M_PLASTICO))
        ds.append((caja(q, (0.0, 1.34, 0.64), (0.47, 0.27, 0.012), 0.03), M_NEGRO))
        ds.append((caja(q, (0.0, 1.34, 0.648), (0.41, 0.22, 0.008), 0.02), M_NEGRO))
        ds.append((cilindro(q, (0.46, 1.03, 0.62), (0.46, 1.03, 0.66), 0.022), M_ROJO))
        return ds

    def retoque(a, x0, y0):
        # pantalla: letras verdes sobre negro
        px0, py0 = proyectar(ARS_M - 0.40, 1.54, 0.656)
        ax, ay = int(round(px0)) - x0, int(round(py0)) - y0
        pw = int(round(0.80 * escala_en(0.656)))
        ph = int(round(0.42 * escala_en(0.656)))
        a[ay:ay + ph, ax:ax + pw, :3] = hex2rgb("#0a2a16")
        for y in range(ay, ay + ph, 2):
            a[y, ax:ax + pw, :3] = hex2rgb("#0c3019")
        texto3(a, ax + 3, ay + 4, "> ENCARGOS", "#8ef07c")
        for i, lin in enumerate(("  ARMAS", "  PIEZAS")):
            texto3(a, ax + 3, ay + 13 + i * 8, lin, "#3cb050")
        a[ay + ph - 7:ay + ph - 2, ax + pw - 8:ax + pw - 4, :3] = hex2rgb("#8ef07c")
        # tablon: titulo, notas clavadas y un hilo rojo que no explica nada
        tz = 0.09
        sx, sy = proyectar(ARS_T - 0.70, 2.40, tz)
        ox, oy = int(round(sx)) - x0, int(round(sy)) - y0
        W_, H_ = int(1.40 * escala_en(tz)), int(0.78 * escala_en(tz))
        papel, amarillo, rosa, verde = "#efece6", "#f8d840", "#f4a8c8", "#9ad8a8"
        tinta = "#3a3050"
        notas = [
            (4, 6, 24, 16, papel, ["SE", "BUSCA"], 0), (32, 3, 23, 17, amarillo, ["PAGO:", "ATÚN"], 0),
            (59, 7, 19, 15, papel, ["JEFE", "X3"], 0), (82, 4, 15, 13, rosa, ["OJO"], 0),
            (6, 27, 24, 12, amarillo, ["BOTÍN"], 0), (35, 26, 17, 16, papel, None, 1), (56, 28, 24, 12, verde, ["ARMAS"], 0), (84, 24, 13, 17, papel, None, 2),
        ]
        for (nx, ny, nw, nh, col, lineas, clase) in notas:
            X, Y = ox + nx, oy + ny
            a[Y + 1:Y + nh + 1, X + 1:X + nw + 1, :3] = hex2rgb("#2a1a10")
            a[Y:Y + nh, X:X + nw, :3] = hex2rgb(col)
            if lineas:
                for i, lin in enumerate(lineas):
                    texto3(a, X + (nw - ancho3(lin)) // 2, Y + 3 + i * 7, lin, tinta)
            elif clase == 1:
                for j, fila in enumerate(_CALAVERA):
                    for i, ch in enumerate(fila):
                        if ch == "#":
                            a[Y + 5 + j, X + 5 + i, :3] = hex2rgb(tinta)
            else:
                for j in range(4):
                    a[Y + 4 + j * 3, X + 2:X + nw - 2 - (j % 2) * 3, :3] = hex2rgb("#8a8498")
            a[Y, X + nw // 2:X + nw // 2 + 2, :3] = hex2rgb("#e0303a")
        # hilo rojo entre notas
        ima = Image.fromarray(a, "RGBA")
        dib = ImageDraw.Draw(ima)
        for (p0, p1) in (((16, 6), (41, 3)), ((41, 3), (66, 28)), ((66, 28), (90, 24))):
            dib.line([(ox + p0[0], oy + p0[1]), (ox + p1[0], oy + p1[1])], fill=hex2rgb("#e0303a") + (255,))
        a[:] = np.array(ima)

    return e, ((ARS_L - 0.96, 0.42, 0.0), (ARS_T + 0.84, 2.50, 0.84)), retoque


def e_puerta():
    z0, z1 = PUERTA_Z0, PUERTA_Z1
    zc = (z0 + z1) / 2
    sx, sy, sz = 2.56, 2.32, 1.60

    def e(p):
        ds = []
        # marco y hoja
        ds.append((resta(caja(p, (2.975, 1.09, zc), (0.05, 1.09, (z1 - z0) / 2 + 0.08), 0.01), caja(p, (2.90, 1.02, zc), (0.05, 1.02, (z1 - z0) / 2 - 0.02))), M_ACERO))
        ds.append((caja(p, (2.97, 1.02, zc), (0.022, 1.02, (z1 - z0) / 2 - 0.02), 0.004), M_MADERA))
        # tablones
        for k in range(1, 4):
            ds.append((caja(p, (2.945, 1.02, z0 + (z1 - z0) * k / 4), (0.004, 1.0, 0.006), 0.0), M_NEGRO))
        # manilla, placa y seguro
        ds.append((capsula(p, (2.90, 1.02, z1 - 0.28), (2.90, 1.02, z1 - 0.10), 0.026), M_LATON))
        ds.append((caja(p, (2.947, 1.02, z1 - 0.20), (0.004, 0.14, 0.13), 0.0), M_ACERO))
        # letrero de salida: sale de la pared para que se lea de frente
        ds.append((caja(p, (sx + 0.34 + 0.08, sy, sz), (0.08 + 0.02, 0.02, 0.02), 0.0), M_ACERO))
        ds.append((capsula(p, (2.97, sy, sz), (2.97, 2.12, sz), 0.018), M_ACERO))
        ds.append((caja(p, (sx, sy, sz), (0.36, 0.12, 0.03), 0.015), M_SALIDA))
        ds.append((resta(caja(p, (sx, sy, sz), (0.38, 0.14, 0.025), 0.01), caja(p, (sx, sy, sz + 0.04), (0.35, 0.11, 0.03))), M_ACERO2))
        return ds

    def retoque(a, x0, y0):
        # letrero
        sw = lamina(46, 15)
        texto5(sw, 2, 3, "SALIDA", "#f0fff4")
        # el texto5 solo pinta color: se le da opacidad donde se escribio
        sw[..., 3] = np.where((sw[..., :3] != 0).any(-1), 255, 0)
        frontal(a, x0, y0, sx, sy, sz + 0.035, sw)
        # placa de la puerta: WC tachado
        t = lamina(32, 22, "#e6e2da")
        t[0, :] = t[-1, :] = t[:, 0] = t[:, -1] = hex2rgb("#2a4a8a") + (255,)
        tx = lamina(32, 22)
        texto5(tx, 5, 6, "WC", "#2a4a8a", esc=2)
        mask = (tx[..., :3] != 0).any(-1)
        t[mask, :3] = hex2rgb("#2a4a8a")
        for k in range(30):
            y = 3 + int(k * 16 / 30)
            t[y:y + 2, k + 1:k + 2, :3] = hex2rgb("#d02a3a")
        decal(a, x0, y0, (2.944, 1.72, z0 + 0.34), (0, 0, 0.60), (0, -0.42, 0), t)
        # seguro: LIBRE
        t = lamina(23, 9, "#2aa048")
        texto3(t, 2, 2, "LIBRE", "#eafff0")
        decal(a, x0, y0, (2.944, 0.87, z1 - 0.42), (0, 0, 0.40), (0, -0.13, 0), t)

    return e, ((2.05, -0.01, z0 - 0.12), (3.04, 2.50, z1 + 0.12)), retoque


# =============================================================================
# FONDO: paredes de azulejo, piso a cuadros, luz calida con tramado (como el cielo del mapa)
# =============================================================================
R_AZULEJO = ["#0f1620", "#13242e", "#18363e", "#1d4a4e", "#246060", "#2f7a76", "#4a9488", "#78ae98", "#b4c8a0"]
R_FRANJA = ["#120e1c", "#1c1426", "#2a1a30", "#3c2038", "#542a40", "#723648", "#94504e", "#b87c5c"]
R_YESO = ["#16111c", "#221924", "#32252a", "#46352f", "#5e4835", "#7a6240", "#98804e", "#b8a060", "#d4c078"]
R_PISO_A = ["#0e0b13", "#16111a", "#201820", "#2a2026", "#35282c", "#433330", "#544038", "#6a5240"]
R_PISO_B = ["#1a1520", "#28202a", "#3a2e30", "#4e3e38", "#665240", "#826a4c", "#a0855c", "#c0a470", "#dcc488"]
R_TECHO = ["#0c0912", "#141018", "#1e1820", "#2a2228", "#382e30", "#4a3e38"]
R_JUNTA = ["#0c0b14", "#12121c", "#181a22", "#1e2428", "#263230", "#304238", "#405448"]
R_ZOCALO = ["#0e0b14", "#16101c", "#201824", "#2c2230", "#3a2e3c", "#4a3e4a"]


def _ruido(rng, w, h, celda, modo=Image.BICUBIC):
    """Ruido suave entre 0 y 1."""
    b = rng.random((h // celda + 3, w // celda + 3))
    im = Image.fromarray((b * 255).astype(np.uint8), "L").resize((w + celda * 2, h + celda * 2), modo)
    return np.array(im).astype(np.float64)[celda:celda + h, celda:celda + w] / 255.0


def _pintar_rampa(rgb, mascara, v, rampa, bay):
    pal = np.array([hex2rgb(c) for c in rampa], dtype=np.uint8)
    n = len(pal)
    i = np.clip((np.clip(v, 0, 1) * (n - 1) + bay * 0.999).astype(int), 0, n - 1)
    rgb[mascara] = pal[i[mascara]]


def sombras_proxy(p):
    """Bloques simples de los objetos: arrojan la sombra sobre el piso y las paredes."""
    ds = [
        (cilindro(p - _V(0, 0, PLATO_Z), (0, 0, 0), (0, 0.15, 0), 0.78), 0),
        (caja(rot_y(p - LOCKER_C, LOCKER_ANG), (0, 1.03, 0), (LOCKER_W, 1.03, LOCKER_D)), 0),
        (caja(p, (EXC_X, 0.40, 1.08), (0.32, 0.38, 0.50)), 0),
        (caja(p, (EXC_X, 0.92, 0.22), (0.58, 0.42, 0.22)), 0),
        (caja(p, (TINA_C[0], 0.30, TINA_C[2]), (TINA_L, 0.30, 0.33), 0.05), 0),
        (caja(p, (ARS_L, 0.90, 0.40), (0.78, 0.11, 0.38)), 0),
        (caja(p, (ARS_M, 1.32, 0.34), (0.56, 0.34, 0.30)), 0),
    ]
    return ds


def sala_cruda():
    """Devuelve el RGB de la habitacion vacia y sus mapas: superficie, posicion y luz."""
    W, H = 640, 360
    rng = np.random.default_rng(21)
    XX, YY = np.meshgrid(np.arange(W) + 0.5, np.arange(H) + 0.5)
    dx, dy = (XX - CAM_CX) / CAM_F, -(YY - CAM_CY) / CAM_F
    bay = BAYER[(np.arange(H)[:, None]) % 4, (np.arange(W)[None, :]) % 4]
    t = np.full(XX.shape, CAM_D)
    sup = np.zeros(XX.shape, dtype=int)  # 0 fondo, 1 izquierda, 2 derecha, 3 piso, 4 techo
    with np.errstate(divide="ignore", invalid="ignore"):
        tl = np.where(dx < 0, -SALA_X / dx, 1e9)
        tr = np.where(dx > 0, SALA_X / dx, 1e9)
        tp = np.where(dy < 0, -CAM_OJO / dy, 1e9)
        tt = np.where(dy > 0, (SALA_Y - CAM_OJO) / dy, 1e9)
    for k, ti in ((1, tl), (2, tr), (3, tp), (4, tt)):
        m_ = ti < t
        t = np.where(m_, ti, t)
        sup = np.where(m_, k, sup)
    px, py, pz = dx * t, CAM_OJO + dy * t, CAM_D - t
    n = np.zeros(XX.shape + (3,))
    n[sup == 0] = (0, 0, 1)
    n[sup == 1] = (1, 0, 0)
    n[sup == 2] = (-1, 0, 0)
    n[sup == 3] = (0, 1, 0)
    n[sup == 4] = (0, -1, 0)
    P = np.stack([px, py, pz], -1)
    # luz de las dos lamparas, mas una sombra suave de los objetos
    plano = P.reshape(-1, 3)
    normal = n.reshape(-1, 3)
    luces = np.zeros(plano.shape[0])
    for L in LAMPARAS:
        lv = np.array(L) - plano
        dist = np.linalg.norm(lv, axis=-1)
        ln = lv / dist[:, None]
        dif = np.clip((normal * ln).sum(-1), 0, 1) ** 0.75
        s = _sombra_rayo(sombras_proxy, plano + normal * 0.012, ln, dist, pasos=18)
        s = np.where(s > 0.0, s, 0.0)
        luces += dif * (0.30 + 0.70 * s) / (1.0 + 0.11 * dist * dist)
    luces = luces.reshape(XX.shape)
    # oscurece las esquinas de la pieza (oclusion barata)
    borde = np.minimum.reduce([np.abs(px + SALA_X) + (sup == 1) * 9, np.abs(px - SALA_X) + (sup == 2) * 9, py + (sup == 3) * 9, np.abs(py - SALA_Y) + (sup == 4) * 9, pz + (sup == 0) * 9])
    ao = 0.62 + 0.38 * np.clip(borde / 0.55, 0, 1)
    # contacto con el piso bajo los objetos (mancha oscura)
    prox = sombras_proxy(plano)
    dmin = np.min(np.stack([d for d, _ in prox], 0), 0).reshape(XX.shape)
    contacto = 0.55 + 0.45 * np.clip(dmin / 0.20, 0, 1)
    luz = (0.06 + 0.90 * luces) * ao * contacto
    # viñeta suave hacia los bordes de la pantalla
    vin = np.clip(1.0 - (((XX - 320) / 420) ** 2 + ((YY - 170) / 320) ** 2) * 0.55, 0.45, 1)
    luz *= vin

    rgb = np.zeros((H, W, 3), dtype=np.uint8)
    es_pared = sup <= 2
    u = np.where(sup == 0, px, pz)
    # --- azulejos (hasta 1.70 m) ---
    TS = 0.30
    ti = np.floor(u / TS).astype(int)
    tj = np.floor(py / TS).astype(int)
    tabla = rng.random((64, 64))
    tabla2 = rng.random((64, 64))
    tiles = tabla[ti % 64, tj % 64]
    tiles2 = tabla2[ti % 64, tj % 64]
    alto_az = 1.68
    az = es_pared & (py < alto_az)
    v_az = luz * (0.74 + 0.24 * tiles)
    # brillo esmaltado: una diagonal de luz en algunos azulejos y canto superior claro
    fu, fv = u / TS - ti, py / TS - tj
    brillo = (np.abs(fu + (1 - fv) - 0.55) < 0.10) & (tiles2 > 0.45)
    v_az = np.where(brillo, v_az + 0.11, v_az)
    v_az = np.where(fv > 0.90, v_az + 0.05, v_az)
    v_az = np.where(fu < 0.08, v_az + 0.03, v_az)
    # manchas de humedad y de grasa
    man = _ruido(rng, W, H, 26)
    v_az = np.where(man > 0.70, v_az - 0.07, v_az)
    _pintar_rampa(rgb, az, v_az, R_AZULEJO, bay)
    # franja decorativa a media altura
    fr = es_pared & (py >= 0.90) & (py < 1.05)
    cuadros = ((np.floor(u / 0.15).astype(int) + np.floor(py / 0.075).astype(int)) % 2 == 0)
    _pintar_rampa(rgb, fr, luz * np.where(cuadros, 1.10, 0.78), R_FRANJA, bay)
    # remate superior
    rem = es_pared & (py >= alto_az) & (py < alto_az + 0.07)
    _pintar_rampa(rgb, rem, luz * 0.72, R_FRANJA, bay)
    # yeso arriba, con chorreras de humedad
    ye = es_pared & (py >= alto_az + 0.07)
    chorro = _ruido(rng, W, H, 7)
    chorro = np.array(Image.fromarray((chorro * 255).astype(np.uint8), "L").resize((W, H * 3), Image.BICUBIC).crop((0, 0, W, H))).astype(float) / 255
    _pintar_rampa(rgb, ye, luz * (1.06 + 0.26 * (man - 0.5)) - np.where(chorro > 0.66, 0.08, 0.0), R_YESO, bay)
    # zocalo
    zo = es_pared & (py < 0.13)
    _pintar_rampa(rgb, zo, luz * 0.9, R_ZOCALO, bay)
    # juntas de un pixel, sin importar la distancia: asi no se ensucian de lejos
    salto_i = ti != np.roll(ti, -1, axis=1)
    salto_j = tj != np.roll(tj, -1, axis=0)
    salto_i[:, -1] = False
    salto_j[-1, :] = False
    jun = az & (salto_i | salto_j)
    _pintar_rampa(rgb, jun, luz * 0.92, R_JUNTA, bay)
    # --- piso a cuadros, gastado ---
    FS = 0.50
    pi_ = np.floor(px / FS).astype(int)
    pj = np.floor(pz / FS).astype(int)
    par = (pi_ + pj) % 2 == 0
    piso = sup == 3
    ruido_p = _ruido(rng, W, H, 12)
    v_p = luz * (0.98 + 0.28 * (ruido_p - 0.5))
    # el piso encerado refleja las lamparas
    for L in LAMPARAS:
        rx, rz = px - L[0], (pz - L[2]) * 0.8
        v_p = v_p + 0.16 * np.exp(-(rx * rx + rz * rz) / 0.22)
    _pintar_rampa(rgb, piso & par, v_p * 0.82, R_PISO_A, bay)
    _pintar_rampa(rgb, piso & ~par, v_p * 0.92, R_PISO_B, bay)
    sj = (pi_ != np.roll(pi_, -1, axis=1)) | (pj != np.roll(pj, -1, axis=0))
    sj[:, -1] = False
    sj[-1, :] = False
    rgb[piso & sj] = (rgb[piso & sj].astype(int) * 0.68).astype(np.uint8)
    # techo
    te = sup == 4
    _pintar_rampa(rgb, te, luz * 1.15, R_TECHO, bay)
    # costura entre superficies: una raya oscura en las esquinas de la pieza
    costura = (sup != np.roll(sup, -1, axis=1)) | (sup != np.roll(sup, -1, axis=0))
    costura[:, -1] = False
    costura[-1, :] = False
    rgb[costura] = (rgb[costura].astype(int) * 0.55).astype(np.uint8)
    return rgb, sup, P, luz


# =============================================================================
# UTILERIA DEL FONDO: lo que no se toca, pero da gusto mirar
# =============================================================================
SOPAPO = (-0.60, 1.26)


def e_utileria():
    """Lo que va pegado a la pieza: lamparas, cañerias, ducha, cortina y demas. Lista de (escena, caja, delante).
    delante: None, o el id del sprite hangar_delante_<id> que lo repite encima de las estaciones (ver DELANTE)."""
    piezas = []

    # --- lamparas colgando ---
    for i, (lx, ly, lz) in enumerate(LAMPARAS):
        def lampara(p, lx=lx, ly=ly, lz=lz):
            q = p - _V(lx, ly, lz)
            return [(capsula(q, (0, 0.16, 0), (0, 0.60, 0), 0.006), M_NEGRO),
                    (resta(cono_truncado(q, (0, 0.18, 0), (0, 0.02, 0), 0.05, 0.20), cono_truncado(q, (0, 0.14, 0), (0, 0.0, 0), 0.03, 0.18)), M_VERDE),
                    (esfera(q, (0, -0.012, 0), 0.062), M_AMPOLLETA)]
        # la de la derecha cuelga delante del tablon de encargos
        piezas.append((lampara, ((lx - 0.24, ly - 0.06, lz - 0.24), (lx + 0.24, 2.70, lz + 0.24)), "lampara" if i == 1 else None))

    # --- cañerias: la de cobre y la de fierro, por el fondo y el costado ---
    def cañerias(p):
        ds = []
        ds.append((tubo(p, [(-3.0, 2.56, 0.10), (3.0, 2.56, 0.10)], 0.04), M_COBRE))
        ds.append((tubo(p, [(EXC_X, 2.56, 0.10), (EXC_X, 1.90, 0.10)], 0.03), M_ACERO))
        ds.append((tubo(p, [(2.88, 2.70, 0.08), (2.88, 0.0, 0.08)], 0.036), M_ACERO))
        ds.append((tubo(p, [(2.88, 0.92, 0.08), (2.60, 0.92, 0.08)], 0.026), M_ACERO))
        # rumbo al costado izquierdo
        ds.append((tubo(p, [(-2.92, 2.56, 0.10), (-2.92, 2.56, 1.30), (-2.92, 2.70, 1.30)], 0.03), M_COBRE))
        for x in (-2.4, -1.5, -0.6, 0.6, 1.5, 2.4):
            ds.append((caja(p, (x, 2.56, 0.05), (0.03, 0.055, 0.06), 0.005), M_ACERO2))
            ds.append((toro(p, (x, 2.56, 0.10), (1, 0, 0), 0.045, 0.012), M_LATON))
        for z in (0.5, 1.0):
            ds.append((caja(p, (-2.96, 2.56, z), (0.04, 0.05, 0.03), 0.005), M_ACERO2))
        # llave de paso roja, en la que nadie se atreve a tocar
        ds.append((cilindro(p, (EXC_X, 2.28, 0.10), (EXC_X, 2.28, 0.19), 0.018), M_ACERO))
        ds.append((toro(p, (EXC_X, 2.28, 0.19), (0, 0, 1), 0.07, 0.016), M_ROJO))
        return ds
    piezas.append((cañerias, ((-3.0, 0.0, 0.0), (3.0, 2.70, 2.6)), None))

    # --- la ducha, sobre la nave ---
    def ducha(p):
        return [(tubo(p, [(0, 1.56, 0.0), (0, 1.62, 0.14), (0, 1.74, 0.30)], 0.028), M_ACERO),
                (cono_truncado(p, (0, 1.76, 0.30), (0, 1.62, 0.36), 0.04, 0.15), M_ACERO),
                (cilindro(p, (0, 1.63, 0.36), (0, 1.60, 0.37), 0.15), M_ACERO2)]
    piezas.append((ducha, ((-0.2, 1.5, 0.0), (0.2, 1.8, 0.5)), None))

    # --- repisa de la ducha: shampoo, jabon y aceite de motor ---
    def repisa(p):
        q = p - _V(0.40, 1.22, 0.0)
        ds = [(caja(q, (0, 0, 0.10), (0.26, 0.012, 0.10), 0.004), M_ACERO),
              (cilindro(q, (-0.15, 0.012, 0.10), (-0.15, 0.20, 0.10), 0.05), M_FRAZADA),
              (cilindro(q, (-0.15, 0.20, 0.10), (-0.15, 0.25, 0.10), 0.02), M_PAPEL),
              (cilindro(q, (0.0, 0.012, 0.10), (0.0, 0.14, 0.10), 0.055), M_ROJO),
              (capsula(q, (0.03, 0.14, 0.10), (0.09, 0.22, 0.10), 0.012), M_ACERO),
              (cilindro(q, (0.15, 0.012, 0.10), (0.15, 0.17, 0.10), 0.045), M_VERDE),
              (cilindro(q, (0.15, 0.17, 0.10), (0.15, 0.21, 0.10), 0.016), M_PAPEL)]
        return ds
    piezas.append((repisa, ((0.1, 1.15, 0.0), (0.7, 1.52, 0.24)), None))

    # --- caja de herramientas roja, tirada en el piso ---
    hx, hz = 2.46, 2.28

    def caja_herr(p):
        q = p - _V(hx, 0, hz)
        return [(caja(q, (0, 0.08, 0), (0.21, 0.08, 0.11), 0.01), M_ROJO),
                (caja(q, (0, 0.17, 0), (0.22, 0.03, 0.12), 0.01), M_ROJO),
                (caja(q, (0, 0.135, 0.112), (0.215, 0.008, 0.004), 0.0), M_NEGRO),
                (caja(q, (0.10, 0.125, 0.118), (0.02, 0.02, 0.004), 0.0), M_LATON),
                (caja(q, (-0.10, 0.125, 0.118), (0.02, 0.02, 0.004), 0.0), M_LATON),
                (capsula(q, (-0.07, 0.235, 0), (0.07, 0.235, 0), 0.012), M_ACERO),
                (capsula(q, (-0.07, 0.20, 0), (-0.07, 0.235, 0), 0.012), M_ACERO),
                (capsula(q, (0.07, 0.20, 0), (0.07, 0.235, 0), 0.012), M_ACERO)]
    piezas.append((caja_herr, ((hx - 0.26, -0.01, hz - 0.15), (hx + 0.26, 0.26, hz + 0.15)), "herramientas"))

    # --- barra y cortina de ducha, corrida a un lado ---
    def cortina(p):
        ds = [(capsula(p, (-0.95, 1.82, 0.50), (0.98, 1.82, 0.50), 0.018), M_ACERO)]
        for x in (-0.95, 0.98):
            ds.append((capsula(p, (x, 1.82, 0.50), (x, 1.82, 0.0), 0.012), M_ACERO))
        pliegue = 0.022 * np.sin(p[..., 0] * 62.0)
        lado = caja(p, (0.82, 0.98, 0.50), (0.15, 0.82, 0.05), 0.02) + pliegue
        ds.append((lado, M_CORTINA))
        return ds
    piezas.append((cortina, ((-1.0, 0.1, 0.0), (1.02, 1.86, 0.62)), None))

    # --- caja de emergencia con el sopapo ---
    cx, cy = SOPAPO

    def sopapo(p):
        q = p - _V(cx, cy, 0.0)
        ds = [(caja(q, (0, 0, 0.04), (0.30, 0.34, 0.04), 0.008), M_ROJO),
              (caja(q, (0, 0, 0.082), (0.26, 0.30, 0.004), 0.0), M_NEGRO),
              (capsula(q, (0.03, 0.25, 0.095), (-0.04, -0.14, 0.095), 0.02), M_MADERA),
              (elipsoide(rot_z(q - _V(-0.05, -0.14, 0.095), -0.18), (0, 0, 0), (0.155, 0.095, 0.02)), M_ROJO)]
        return ds
    piezas.append((sopapo, ((cx - 0.34, cy - 0.38, 0.0), (cx + 0.34, cy + 0.38, 0.14)), None))

    # --- balde bajo el sifon: el lavamanos gotea ---
    bx, bz = ARS_L - 0.36, 0.36

    def balde(p):
        q = p - _V(bx, 0, bz)
        cuerpo = resta(cono_truncado(q, (0, 0.0, 0), (0, 0.32, 0), 0.13, 0.18), cono_truncado(q, (0, 0.05, 0), (0, 0.36, 0), 0.11, 0.165))
        return [(cuerpo, M_CORTINA), (cilindro(q, (0, 0.04, 0), (0, 0.22, 0), 0.15), M_CIAN),
                (toro(q, (0, 0.32, 0), (0, 1, 0), 0.178, 0.012), M_ACERO)]
    piezas.append((balde, ((bx - 0.22, -0.01, bz - 0.22), (bx + 0.22, 0.38, bz + 0.22)), None))

    # --- letrero de piso mojado, porque ser prevenido es gratis ---
    mx, mz = -0.98, 2.00

    def letrero(p):
        q = p - _V(mx, 0, mz)
        a1 = rot_x(q - _V(0, 0, 0.09), 0.16)
        a2 = rot_x(q - _V(0, 0, -0.09), -0.16)
        return [(caja(a1, (0, 0.27, 0), (0.18, 0.27, 0.012), 0.008), M_AMARILLO), (caja(a2, (0, 0.27, 0), (0.18, 0.27, 0.012), 0.008), M_AMARILLO)]
    piezas.append((letrero, ((mx - 0.24, -0.01, mz - 0.22), (mx + 0.24, 0.58, mz + 0.22)), "piso_mojado"))

    # --- torre de rollos de confort, junto al locker ---
    rx, rz = -1.86, 2.02

    def rollos(p):
        q = p - _V(rx, 0, rz)
        ds = []
        for k, (dx, dz) in enumerate(((0, 0), (0.02, -0.01), (-0.015, 0.01))):
            y = 0.075 + k * 0.15
            ds.append((resta(cilindro(q, (dx, y - 0.07, dz), (dx, y + 0.07, dz), 0.105), cilindro(q, (dx, y - 0.2, dz), (dx, y + 0.2, dz), 0.03)), M_PAPEL))
        return ds
    piezas.append((rollos, ((rx - 0.16, -0.01, rz - 0.16), (rx + 0.16, 0.48, rz + 0.16)), "rollos"))
    return piezas


def _mini_tuerca():
    """Don Tuerca chiquitito, para el cuadro del empleado del mes."""
    return renderizar(don_tuerca(0.2, 0.0, False, 0), RT, 28, encuadre=1.36, centro=(0.02, 0.80), ss=4, luz=(-0.45, 0.65, 0.75))[:26]


def pintar_utileria(a):
    """Carteles y detalles a mano sobre el fondo ya compuesto (RGB)."""
    r = random.Random(5)
    h, w = a.shape[:2]
    def mezclar(x, y, col, t):
        if 0 <= x < w and 0 <= y < h:
            a[y, x] = (a[y, x] * (1 - t) + np.array(col) * t).astype(np.uint8)

    # --- la placa de BAÑO colgando de la cañeria, tachada, y el HANGAR pintado a mano ---
    ancho_p, alto_p = 56, 19
    px, py = 320 - ancho_p // 2, 56
    for wx in (px + 8, px + ancho_p - 9):
        a[50:py, wx:wx + 1] = hex2rgb("#14101a")
    a[py + 1:py + alto_p + 1, px + 1:px + ancho_p + 1] = hex2rgb("#2a1a14")
    a[py:py + alto_p, px:px + ancho_p] = hex2rgb("#3a5a9a")
    a[py + 1:py + alto_p - 1, px + 1:px + ancho_p - 1] = hex2rgb("#e0dccc")
    texto5(a, px + 6, py + 5, "BAÑO", "#1a2a6a", esc=2)
    # tachadura de pintura roja, una sola raya para que igual se lea
    for k in range(ancho_p + 8):
        t = k / (ancho_p + 8)
        y = int(py + alto_p - 2 - t * (alto_p - 4) + math.sin(k * 0.7) * 0.7)
        x = px - 4 + k
        a[y:y + 2, x:x + 1] = hex2rgb("#e0303a")
    for dx, largo in ((6, 6), (20, 5), (44, 3)):
        a[py + alto_p - 4 - dx // 5:py + alto_p - 4 - dx // 5 + largo, px + dx:px + dx + 1] = hex2rgb("#e0303a")
    temblor = random.Random(3)
    tx0 = 320 - (6 * 18 - 3) // 2
    a2 = a.copy()
    texto5(a2, tx0, 78, "HANGAR", "#ffb040", esc=3, sombra="#3a2010", temblor=temblor)
    a[:] = a2
    # chorreo de la pintura de las letras
    for dx, largo in ((5, 7), (30, 4), (52, 8), (77, 5), (99, 6)):
        a[98:98 + largo, tx0 + dx:tx0 + dx + 1] = hex2rgb("#c8842c")

    # --- empleado del mes: el unico empleado ---
    fx, fy = 122, 57
    a[fy + 1:fy + 43, fx + 1:fx + 47] = hex2rgb("#1a1014")
    a[fy:fy + 42, fx:fx + 46] = hex2rgb("#8a5a2a")
    a[fy + 1:fy + 1, fx:fx] = hex2rgb("#c89a60")
    a[fy:fy + 1, fx:fx + 46] = hex2rgb("#c89a60")
    a[fy:fy + 42, fx:fx + 1] = hex2rgb("#c89a60")
    a[fy + 2:fy + 40, fx + 2:fx + 44] = hex2rgb("#2a2238")
    retr = _mini_tuerca()
    for j in range(retr.shape[0]):
        for i in range(retr.shape[1]):
            if retr[j, i, 3] > 0:
                a[fy + 2 + j, fx + 9 + i] = retr[j, i, :3]
    a[fy + 27:fy + 40, fx + 2:fx + 44] = hex2rgb("#e6dcc0")
    texto3(a, fx + (46 - ancho3("EMPLEADO")) // 2, fy + 28, "EMPLEADO", "#3a2010")
    texto3(a, fx + (46 - ancho3("DEL MES")) // 2, fy + 34, "DEL MES", "#3a2010")

    # --- textos de la caja del sopapo ---
    cx, cy = proyectar(SOPAPO[0], SOPAPO[1], 0.085)
    cx, cy = int(cx), int(cy)
    texto3(a, cx - ancho3("EMERGENCIA") // 2, cy - 22, "EMERGENCIA", "#fff4e0")
    # vidrio: dos brillos en diagonal
    for k in range(10):
        mezclar(cx - 14 + k, cy + 2 - k, (220, 240, 255), 0.35)
        mezclar(cx - 11 + k, cy + 6 - k, (220, 240, 255), 0.25)
    texto3(a, cx - ancho3("ROMPER") // 2, cy + 15, "ROMPER", "#fff4e0")

    # --- cartel de piso mojado ---
    mx, my = proyectar(-0.98, 0.34, 2.09)
    mx, my = int(mx), int(my)
    tri = [(0, -11), (-7, 0), (7, 0)]
    img = Image.fromarray(a, "RGB")
    dib = ImageDraw.Draw(img)
    dib.polygon([(mx + q[0], my + q[1]) for q in tri], fill=hex2rgb("#2a2010"))
    dib.polygon([(mx + q[0] * 0.55, my + q[1] * 0.6 - 2) for q in tri], fill=hex2rgb("#f8d840"))
    a[:] = np.array(img)
    a[my - 8:my - 4, mx:mx + 1] = hex2rgb("#2a2010")
    a[my - 3:my - 2, mx:mx + 1] = hex2rgb("#2a2010")
    texto3(a, mx - ancho3("PISO") // 2, my + 3, "PISO", "#2a2010")
    texto3(a, mx - ancho3("MOJADO") // 2, my + 10, "MOJADO", "#2a2010")

    # --- charcos y aceite ---
    img = Image.fromarray(a, "RGB")
    dib = ImageDraw.Draw(img)
    def charco(x, y, rx, ry, c1, c2, c3):
        dib.ellipse([x - rx, y - ry, x + rx, y + ry], fill=hex2rgb(c1))
        dib.ellipse([x - rx + 3, y - ry + 1, x + rx - 5, y + ry - 2], fill=hex2rgb(c2))
        dib.arc([x - rx + 2, y - ry + 1, x + rx - 2, y + ry - 1], 190, 300, fill=hex2rgb(c3))
    charco(240, 312, 24, 5, "#2a4a60", "#3a6a84", "#b0e0f0")
    charco(170, 293, 16, 4, "#14121f", "#1c1a2c", "#5a4a90")
    charco(120, 236, 14, 3, "#14121f", "#1c1a2c", "#5a4a90")
    a[:] = np.array(img)

    # --- gotas que caen de la ducha, del lavamanos y del techo ---
    for x, y in ((316, 128), (322, 136), (319, 148), (324, 160), (315, 170)):
        a[y:y + 3, x:x + 1] = hex2rgb("#8ff0ff")
        a[y + 2:y + 3, x:x + 1] = hex2rgb("#ffffff")
    gx = int(proyectar(ARS_L - 0.36, 0.5, 0.2)[0])
    a[208:211, gx:gx + 1] = hex2rgb("#8ff0ff")

    # --- tuercas tiradas: es su taller, despues de todo ---
    for (x, y) in ((186, 306), (404, 304)):
        for j, f in enumerate(_TUERCA_PX):
            for i, ch in enumerate(f):
                if ch != ".":
                    a[y + j, x + i] = hex2rgb(_TUERCA_COL[ch])


def resplandor(a, x, y, radio, tinte, fuerza, chato=1.0):
    """Luz de color con tramado: sube el brillo por escalones, sin mezclar en suave."""
    h, w = a.shape[:2]
    XX, YY = np.meshgrid(np.arange(w) + 0.5, np.arange(h) + 0.5)
    d = np.sqrt(((XX - x) / radio) ** 2 + ((YY - y) / (radio * chato)) ** 2)
    s = np.clip(1.0 - d, 0, 1) ** 1.6 * fuerza
    bay = BAYER[(np.arange(h)[:, None]) % 4, (np.arange(w)[None, :]) % 4]
    nivel = np.floor(s * 4 + bay) / 4
    nivel = np.clip(nivel, 0, 1)[..., None]
    a[:] = np.clip(a.astype(np.float64) + np.array(hex2rgb(tinte)) * nivel, 0, 255).astype(np.uint8)


def componer_fondo():
    """Devuelve el fondo (RGB) y lo que va delante de las estaciones: {id: (rgba, x, y)}.
    Lo de delante se recorta del fondo ya terminado, asi trae las mismas luces y letras y calza pixel a pixel."""
    rgb, sup, P, luz = sala_cruda()
    lienzo = Image.fromarray(rgb, "RGB").convert("RGBA")
    mascaras = {}
    for esc, lim, delante in e_utileria():
        arr, x0, y0 = render_objeto(esc, RS, lim, ss=2, sombra=False, luz_base=0.12)
        lienzo.alpha_composite(Image.fromarray(arr, "RGBA"), (x0, y0))
        if delante:
            m_ = np.zeros((360, 640), bool)
            m_[y0:y0 + arr.shape[0], x0:x0 + arr.shape[1]] = arr[..., 3] > 0
            mascaras[delante] = m_
    a = np.array(lienzo.convert("RGB"))
    # luces de color: dan la pista de dónde están las cosas importantes
    bx, by = proyectar(EXC_X, 0.55, 1.1)
    resplandor(a, bx, by + 4, 70, "#50186a", 0.8, 0.75)
    cx, cy = proyectar(ARS_M, 1.34, 0.7)
    resplandor(a, cx, cy, 80, "#0c4a24", 0.55, 0.9)
    sx, sy = proyectar(2.56, 2.32, 1.6)
    resplandor(a, sx, sy, 56, "#0c5a2c", 0.8, 0.7)
    for L in LAMPARAS:
        lx, ly = proyectar(L[0], L[1] + 0.03, L[2])
        resplandor(a, lx, ly, 46, "#6a4a18", 0.75)
    # conos de luz bajo las lamparas
    h, w = a.shape[:2]
    XX, YY = np.meshgrid(np.arange(w) + 0.5, np.arange(h) + 0.5)
    bay = BAYER[(np.arange(h)[:, None]) % 4, (np.arange(w)[None, :]) % 4]
    for L in LAMPARAS:
        lx, ly = proyectar(L[0], L[1], L[2])
        fy = (YY - ly) / (proyectar(L[0], 0, L[2])[1] - ly)
        ancho = 8 + np.clip(fy, 0, 1) * 92
        dentro = (fy > 0) & (fy < 1) & (np.abs(XX - lx) < ancho)
        s = np.where(dentro, np.clip(1 - fy, 0, 1) ** 1.2 * np.clip(1 - np.abs(XX - lx) / ancho, 0, 1) ** 0.5, 0.0) * 0.5
        nivel = np.floor(s * 4 + bay) / 4
        a[:] = np.clip(a + (np.array(hex2rgb("#3a2810")) * nivel[..., None]), 0, 255).astype(np.uint8)
    # luz azul del plato sobre el piso
    px_, py_ = proyectar(0, 0.02, PLATO_Z)
    resplandor(a, px_, py_ + 6, 118, "#0c3a4a", 0.8, 0.46)
    pintar_utileria(a)
    delante = {}
    for k, m_ in mascaras.items():
        m_[:26] = False  # la franja de la barra de estaciones no se tapa
        ys, xs = np.where(m_)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        recorte = np.zeros((y1 - y0, x1 - x0, 4), dtype=np.uint8)
        dentro = m_[y0:y1, x0:x1]
        recorte[dentro, :3] = a[y0:y1, x0:x1][dentro]
        recorte[dentro, 3] = 255
        delante[k] = (recorte, int(x0), int(y0))
    return a, delante


# =============================================================================
# GENERACION DEL HANGAR Y PUBLICACION DE POSICIONES
# =============================================================================
OBJETOS_SALA = {"naves": e_plataforma, "equipo": e_locker, "fusionar": e_excusado, "mascota": e_tina, "arsenal": e_arsenal, "salida": e_puerta}
SS = int(OPC.get("ss", "3"))
SALA_GD = os.path.join(JUEGO, "nucleo", "sala_hangar.gd")
# la nave real flota sobre el desague del plato; su sprite mide 48x48 y se dibuja al doble
POS_NAVE = (320, int(round(proyectar(0, 0.17, PLATO_Z)[1])) - 38)
# la mascota se dibuja al doble, centrada aqui, con las patas sobre la frazada
POS_MASCOTA = (int(round(proyectar(TINA_C[0] + 0.04, 0.60, TINA_C[2])[0])), int(round(proyectar(TINA_C[0], 0.60, TINA_C[2])[1])) - 13)


def leer_posiciones():
    """Donde quedo cada objeto: sale de sala_hangar.gd, asi regenerar uno no pierde los demas."""
    texto = open(SALA_GD, encoding="utf-8").read()
    return {k: (int(float(x)), int(float(y))) for k, x, y in re.findall(r'"(\w+)": \{"r": Rect2\(([\d.]+), ([\d.]+),', texto)}


def leer_delante():
    """Donde va cada sprite hangar_delante_<id>, segun la lista DELANTE de sala_hangar.gd."""
    texto = open(SALA_GD, encoding="utf-8").read()
    bloque = re.search(r"const DELANTE := \{[^}]*\}", texto).group(0)
    return {k: (int(float(x)), int(float(y))) for k, x, y in re.findall(r'"(\w+)": Rect2\(([\d.]+), ([\d.]+),', bloque)}


def publicar_posiciones(rects):
    """Escribe en sala_hangar.gd los rectangulos reales y la posicion de la nave y la mascota. Lo demas no se toca."""
    texto = open(SALA_GD, encoding="utf-8", newline="").read()
    for k, (x, y, w, h) in rects.items():
        texto, n = re.subn(r'("%s": \{"r": Rect2\()[^)]*\)' % k, lambda m_: f"{m_.group(1)}{x}, {y}, {w}, {h})", texto)
        assert n == 1, k
    texto = re.sub(r"const POS_NAVE := Vector2\([^)]*\)", f"const POS_NAVE := Vector2({POS_NAVE[0]}, {POS_NAVE[1]})", texto)
    texto = re.sub(r"const POS_MASCOTA := Vector2\([^)]*\)", f"const POS_MASCOTA := Vector2({POS_MASCOTA[0]}, {POS_MASCOTA[1]})", texto)
    open(SALA_GD, "w", encoding="utf-8", newline="").write(texto)


POS_OBJ = leer_posiciones()
rects_nuevos = {}
for nombre, f in OBJETOS_SALA.items():
    if quiere("hangar_obj_" + nombre):
        esc, lim, retoque = f()
        arr, x0, y0 = render_objeto(esc, RS, lim, ss=SS)
        arr = arr.copy()
        if retoque:
            retoque(arr, x0, y0)
        guardar("hangar_obj_" + nombre, arr)
        POS_OBJ[nombre] = (x0, y0)
        rects_nuevos[nombre] = (x0, y0, arr.shape[1], arr.shape[0])
        print(f"hangar_obj_{nombre}: {arr.shape[1]}x{arr.shape[0]} en ({x0},{y0}) hasta ({x0 + arr.shape[1]},{y0 + arr.shape[0]})")
if rects_nuevos or quiere("hangar"):
    publicar_posiciones(rects_nuevos)

def publicar_delante(delante):
    """Reescribe en sala_hangar.gd la lista DELANTE: id y rectangulo de cada sprite hangar_delante_<id>."""
    texto = open(SALA_GD, encoding="utf-8", newline="").read()
    filas = "".join(f'\t"{k}": Rect2({x}, {y}, {arr.shape[1]}, {arr.shape[0]}),\n' for k, (arr, x, y) in delante.items())
    texto, n = re.subn(r"const DELANTE := \{[^}]*\}", lambda m_: "const DELANTE := {\n" + filas + "}", texto)
    assert n == 1, "falta const DELANTE en sala_hangar.gd"
    open(SALA_GD, "w", encoding="utf-8", newline="").write(texto)


# el fondo y lo que va delante de las estaciones salen juntos: lo de delante es un recorte del fondo
if quiere("hangar_fondo") or quiere("hangar_delante"):
    fondo, delante = componer_fondo()
    Image.fromarray(fondo, "RGB").save(os.path.join(DEST, "hangar_fondo.png"))
    print("hangar_fondo listo")
    for k, (arr, x, y) in delante.items():
        guardar("hangar_delante_" + k, arr)
        print(f"hangar_delante_{k}: {arr.shape[1]}x{arr.shape[0]} en ({x},{y})")
    publicar_delante(delante)


# =============================================================================
# BALAS: el pellet ahora es rojo como el orbe. Las balas son rojas y redondas; los Bits, dorados y en rombo.
# =============================================================================
def matriz_px(filas, paleta):
    a = np.zeros((len(filas), len(filas[0]), 4), dtype=np.uint8)
    for j, f in enumerate(filas):
        for i, ch in enumerate(f):
            if ch != ".":
                a[j, i] = hex2rgb(paleta[ch]) + (255,)
    return a


if quiere("bala_pellet"):
    forma = ["..kkk..", ".krrrk.", "krrprrk", "krpwprk", "krrprrk", ".krrrk.", "..kkk.."]
    tira("bala_pellet", [matriz_px(forma, {"k": "#10061a", "r": "#ff2a68", "p": "#ff9ac0", "w": "#ffffff"}),
                         matriz_px(forma, {"k": "#10061a", "r": "#ff5a8c", "p": "#ffd0e0", "w": "#ffffff"})])


# =============================================================================
# MONTAJES DE REVISION (solo con --montajes=<carpeta>): reproducen lo que hacen los scripts del juego
# =============================================================================
OSCURO = 0.42
FRASES = {"naves": "Elige con qué nave sales y píntala.", "equipo": "Ponle piezas a tu nave y mejóralas con chatarra.",
          "fusionar": "Tres piezas iguales entran, una mejor sale. No preguntes.", "mascota": "Conoce a tus mascotas y elige con cuál sales.",
          "arsenal": "Encargos de Don Tuerca, y qué armas pueden salir.", "salida": "De vuelta al mapa."}
NOMBRES = {"naves": "NAVES", "equipo": "EQUIPO", "fusionar": "FUSIONAR", "mascota": "MASCOTA", "arsenal": "ARSENAL", "salida": "SALIR"}


def _sprite(nombre):
    return Image.open(os.path.join(DEST, nombre + ".png")).convert("RGBA")


def _multiplica(im, v):
    a = np.array(im).astype(np.float64)
    a[..., :3] *= v
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")


def _nave_pintada():
    """La nave con los colores que le pone el shader del juego (pintura roja, alas y llama comunes)."""
    a = np.array(_sprite("nave2_tryhard"))[:, 4 * 48:5 * 48].copy()
    casco = [hex2rgb(c) for c in ("#3a0c1e", "#7a1630", "#c42b3e", "#f0584a", "#ffc0a0")]
    franja = [hex2rgb(c) for c in ("#4a4a4a", "#7c7c7c", "#a8a8a8", "#d0d0d0", "#f0f0f0")]
    llama = [hex2rgb(c) for c in ("#b02a00", "#ff7a1a", "#ffd24a", "#fff8d0")]
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    for k in range(5):
        a[(g < 2) & (b < 2) & (r >= 30) & (np.clip(np.round(r / 40) - 1, 0, 4) == k), :3] = casco[k]
        a[(r < 2) & (b < 2) & (g >= 30) & (np.clip(np.round(g / 40) - 1, 0, 4) == k), :3] = franja[k]
    for k in range(4):
        a[(r < 2) & (g < 2) & (b >= 30) & (np.clip(np.round(b / 40) - 1, 0, 3) == k), :3] = llama[k]
    return Image.fromarray(a, "RGBA").resize((96, 96), Image.NEAREST)


def _contorno(im, col="#ffd24a"):
    """Igual que hangar_sala.gd: primer anillo con 4 vecinos y uno tenue por fuera."""
    s = np.pad(np.array(im)[..., 3] >= 128, 2)

    def vec(m_):
        v = np.zeros_like(m_)
        v[1:, :] |= m_[:-1, :]
        v[:-1, :] |= m_[1:, :]
        v[:, 1:] |= m_[:, :-1]
        v[:, :-1] |= m_[:, 1:]
        return v

    a1 = vec(s) & ~s
    a2 = vec(a1) & ~s & ~a1
    salida = np.zeros(s.shape + (4,), dtype=np.uint8)
    salida[..., :3] = hex2rgb(col)
    salida[a1, 3] = 255
    salida[a2, 3] = 90
    return Image.fromarray(salida, "RGBA")


def _fuente(tam, bold=False):
    from PIL import ImageFont
    return ImageFont.truetype(os.path.join(JUEGO, "arte", "fuente", "BarlowSemiCondensed-" + ("Bold" if bold else "SemiBold") + ".ttf"), tam)


def montaje_sala(foco, ruta):
    b = OSCURO if foco else 1.0
    lienzo = _multiplica(_sprite("hangar_fondo"), b)
    tam = {k: _sprite("hangar_obj_" + k).size for k in POS_OBJ}
    for k in sorted(POS_OBJ, key=lambda k: POS_OBJ[k][1] + tam[k][1]):
        v = 1.0 if (foco == k or not foco) else OSCURO
        lienzo.alpha_composite(_multiplica(_sprite("hangar_obj_" + k), v), POS_OBJ[k])
    # lo del fondo que va delante de las estaciones, con la luz del fondo
    for k, (x, y) in leer_delante().items():
        lienzo.alpha_composite(_multiplica(_sprite("hangar_delante_" + k), b), (x, y))
    v = 1.0 if (foco == "naves" or not foco) else OSCURO
    lienzo.alpha_composite(_multiplica(_nave_pintada(), v), (POS_NAVE[0] - 48, POS_NAVE[1] - 48))
    pet = _sprite("mascota_0")
    t_ = pet.height
    pet = pet.crop((0, 0, t_, t_)).resize((t_ * 2, t_ * 2), Image.NEAREST)
    v = 1.0 if (foco == "mascota" or not foco) else OSCURO
    lienzo.alpha_composite(_multiplica(pet, v), (POS_MASCOTA[0] - t_, POS_MASCOTA[1] - t_))
    if foco:
        x, y = POS_OBJ[foco]
        lienzo.alpha_composite(_contorno(_sprite("hangar_obj_" + foco)), (x - 2, y - 2))
    a = np.array(lienzo)
    a[:26, :, :3] = (a[:26, :, :3] * 0.1 + np.array([0.05, 0.04, 0.09]) * 255 * 0.9).astype(np.uint8)
    out = Image.fromarray(a, "RGBA").resize((1280, 720), Image.NEAREST)
    d = ImageDraw.Draw(out)
    orden = sorted(POS_OBJ, key=lambda k: (k == "salida", POS_OBJ[k][0] + tam[k][0] / 2))
    ancho = (640 - 8 - 15) / 6
    for i, k in enumerate(orden):
        x0_, x1_ = (4 + i * (ancho + 3)) * 2, (4 + i * (ancho + 3) + ancho) * 2
        d.rectangle([x0_, 4, x1_, 48], fill=(51, 42, 96) if k == foco else (38, 32, 68), outline=(245, 200, 76) if k == foco else (74, 63, 122), width=2)
        tw = d.textlength(NOMBRES[k], font=_fuente(28))
        d.text(((x0_ + x1_ - tw) / 2, 8), NOMBRES[k], fill=(245, 200, 76) if k == foco else (244, 240, 255), font=_fuente(28))
    if foco:
        d.rectangle([16, 642, 1264, 712], fill=(15, 13, 28), outline=(245, 200, 76), width=2)
        d.text((32, 646), NOMBRES[foco], fill=(245, 200, 76), font=_fuente(56, True))
        d.text((284, 648), FRASES[foco], fill=(244, 240, 255), font=_fuente(28))
        d.text((284, 678), "Una línea con el estado de esta estación.", fill=(168, 162, 200), font=_fuente(28))
    out.convert("RGB").save(ruta)


def montaje_tuerca(ruta):
    """Don Tuerca como lo dibuja dialogo.gd: abajo a la izquierda, sobre la pantalla oscurecida."""
    if not os.path.exists(CAPTURA_MAPA):
        print("  sin", CAPTURA_MAPA, "-> me salto el montaje de Don Tuerca")
        return
    base = Image.open(CAPTURA_MAPA).convert("RGBA").resize((640, 360), Image.NEAREST)
    hoja = _sprite("retrato_tuerca")
    cuadros = [hoja.crop((i * 128, 0, (i + 1) * 128, 128)) for i in range(4)]
    velo = Image.new("RGBA", (640, 360), (5, 3, 13, 140))
    lienzos = []
    textos = [("Cabro, ¿cachai? Esto antes era el baño, pero casi no se nota.", 0, 0), ("Cabro, ¿cachai? Esto antes era el baño, pero casi no se nota.", 1, 0),
              ("¡Cabro, cabro, cabro! ¡Mira lo que salió de una lata de atún!", 2, 2), ("¡Cabro, cabro, cabro! ¡Mira lo que salió de una lata de atún!", 3, 0)]
    for txt, f, salto in textos:
        l_ = base.copy()
        l_.alpha_composite(velo)
        l_.alpha_composite(cuadros[f], (4, 222 - salto))
        out = l_.resize((1280, 720), Image.NEAREST)
        d = ImageDraw.Draw(out)
        d.rectangle([272, 524, 1264, 704], fill=(29, 23, 54), outline=(245, 200, 76), width=2)
        ancho_n = d.textlength("DON TUERCA", font=_fuente(28)) + 28
        d.rectangle([272, 492, 272 + ancho_n, 524], fill=(98, 80, 30), outline=(245, 200, 76), width=2)
        d.text((286, 490), "DON TUERCA", fill=(255, 255, 255), font=_fuente(28))
        d.text((292, 534), txt, fill=(244, 240, 255), font=_fuente(28))
        d.text((292, 668), "Esc: saltar", fill=(106, 100, 136), font=_fuente(28))
        lienzos.append(out)
    # la primera vista grande, y debajo los cuatro cuadros
    lienzos[0].convert("RGB").save(ruta)
    fila = Image.new("RGBA", (1280, 720), (18, 14, 34, 255))
    for i, im in enumerate(lienzos):
        fila.alpha_composite(im.resize((640, 360), Image.NEAREST), ((i % 2) * 640, (i // 2) * 360))
    fila.convert("RGB").save(ruta.replace(".png", "_cuadros.png"))


def montaje_balas(ruta):
    """Balas y Bits juntos: ampliados sobre oscuro y en tamaño real sobre el fondo del combate."""
    lien = Image.new("RGBA", (640, 360), (18, 14, 34, 255))
    d = ImageDraw.Draw(lien)
    nombres = [("bala_pellet", 7, "pellet"), ("bala_orbe", 11, "orbe"), ("bala_grande", 17, "grande"), ("bit2", 9, "bit"), ("bit_grande2", 13, "bit grande")]
    x = 8
    for n, t_, et in nombres:
        s_ = _sprite(n).crop((0, 0, t_, t_))
        z_ = 6 if t_ <= 11 else 4
        lien.alpha_composite(s_.resize((t_ * z_, t_ * z_), Image.NEAREST), (x, 12))
        d.text((x, 92), et, fill=(200, 200, 220), font=_fuente(12))
        x += max(t_ * z_, 48) + 14
    # en tamaño real sobre el fondo de verdad, mezclados como en el 1-1
    fondo_c = Image.open(os.path.join(DEST, "fondo_chatarra_lejos.png")).convert("RGBA")
    zona = fondo_c.crop((0, 0, min(fondo_c.width, 640), min(fondo_c.height, 250)))
    lien.alpha_composite(zona, (0, 110))
    r = random.Random(2)
    pel = _sprite("bala_pellet").crop((0, 0, 7, 7))
    orb = _sprite("bala_orbe").crop((0, 0, 11, 11))
    bit = _sprite("bit2")
    bitg = _sprite("bit_grande2")
    for _ in range(46):
        lien.alpha_composite(pel, (r.randint(10, 620), r.randint(116, 340)))
    for _ in range(10):
        lien.alpha_composite(orb, (r.randint(10, 620), r.randint(116, 340)))
    for _ in range(26):
        lien.alpha_composite(bit, (r.randint(10, 620), r.randint(116, 340)))
    for _ in range(7):
        lien.alpha_composite(bitg, (r.randint(10, 620), r.randint(116, 340)))
    lien.resize((1280, 720), Image.NEAREST).convert("RGB").save(ruta)


def revisar_sala():
    """Revisa que todo cumpla: alfa binario, sin tapar la barra, dentro de pantalla y sin objetos encimados."""
    malos = 0
    mascaras = {}
    tam = {}
    for k, (x, y) in POS_OBJ.items():
        a = np.array(_sprite("hangar_obj_" + k))
        tam[k] = a.shape[1], a.shape[0]
        al = a[..., 3]
        if not np.isin(al, (0, 255)).all():
            print("  alfa no binario:", k)
            malos += 1
        if y < 26 or x < 0 or x + a.shape[1] > 640 or y + a.shape[0] > 360:
            print("  fuera de lugar:", k)
            malos += 1
        m_ = np.zeros((360, 640), bool)
        m_[y:y + a.shape[0], x:x + a.shape[1]] = al > 0
        mascaras[k] = m_
    claves = list(mascaras)
    for i, a_ in enumerate(claves):
        for b_ in claves[i + 1:]:
            cruce = int((mascaras[a_] & mascaras[b_]).sum())
            dil = mascaras[a_].copy()
            for _ in range(4):
                v = dil.copy()
                v[1:, :] |= dil[:-1, :]
                v[:-1, :] |= dil[1:, :]
                v[:, 1:] |= dil[:, :-1]
                v[:, :-1] |= dil[:, 1:]
                dil = v
            cerca = int((dil & mascaras[b_]).sum())
            if cruce or cerca:
                print(f"  {a_} y {b_}: {cruce} pixeles encimados, {cerca} a menos de 4 px")
    # lo de delante: tiene que ser igual al fondo donde esta, y tapar algo de una estacion (si no, sobra)
    fondo = np.array(_sprite("hangar_fondo"))
    for k, (x, y) in leer_delante().items():
        a = np.array(_sprite("hangar_delante_" + k))
        al = a[..., 3]
        if not np.isin(al, (0, 255)).all() or y < 26 or x < 0 or x + a.shape[1] > 640 or y + a.shape[0] > 360:
            print("  delante mal hecho o fuera de lugar:", k)
            malos += 1
            continue
        lleno = al > 0
        if (a[..., :3][lleno] != fondo[y:y + a.shape[0], x:x + a.shape[1], :3][lleno]).any():
            print("  delante no calza con el fondo:", k)
            malos += 1
        m_ = np.zeros((360, 640), bool)
        m_[y:y + a.shape[0], x:x + a.shape[1]] = lleno
        tapa = {e: int((m_ & mascaras[e]).sum()) for e in mascaras if (m_ & mascaras[e]).any()}
        if not tapa:
            print("  delante no tapa ninguna estacion:", k)
            malos += 1
        print(f"  delante {k}: va encima de", ", ".join(f"{e} ({n} px)" for e, n in tapa.items()))
    print("revision de la sala:", "ok" if not malos else f"{malos} problemas")


if MONTAJES:
    os.makedirs(MONTAJES, exist_ok=True)
    POS_OBJ = leer_posiciones()
    revisar_sala()
    montaje_sala(None, os.path.join(MONTAJES, "hangar_completo.png"))
    for k in OPC.get("focos", "naves,equipo,fusionar,mascota,arsenal,salida").split(","):
        montaje_sala(k, os.path.join(MONTAJES, "hangar_foco_" + k + ".png"))
    montaje_tuerca(os.path.join(MONTAJES, "don_tuerca_dialogo.png"))
    montaje_balas(os.path.join(MONTAJES, "balas_comparacion.png"))
    print("montajes en", MONTAJES)
print("listo")
