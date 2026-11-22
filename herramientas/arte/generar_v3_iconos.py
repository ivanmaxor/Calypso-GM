# -*- coding: utf-8 -*-
"""Arte de la versión 0.3: iconos nuevos, objetos de combate, la mosca y todas las mascotas.

Usa el mismo motor de generar_v2.py (sdf.py), la misma luz y las mismas rampas, para que lo
nuevo se vea igual a lo que ya estaba. Los sprites de proyectiles miran hacia arriba.

Uso: python generar_v3_iconos.py [carpeta juego] [filtro]
     python generar_v3_iconos.py --revisar [carpeta juego]    revisa nombres, tamaños y transparencia
Con filtro solo regenera lo que contiene ese texto (por ejemplo "mascota" o "rueda_").
"""
import math
import os
import sys

import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
from sdf import (Rampa, a_imagen, capsula, caja, cilindro, cono_truncado, elipsoide, esfera, hex2rgb,
                 poligono, renderizar, resta, rot_y, rot_z, toro, union_suave)
import modelos as m

SOLO_REVISAR = "--revisar" in sys.argv
ARGS = [a for a in sys.argv[1:] if a != "--revisar"]
JUEGO = ARGS[0] if len(ARGS) > 0 else os.path.join(AQUI, "..", "..", "juego")
FILTRO = ARGS[1] if len(ARGS) > 1 else ""
DEST = os.path.join(JUEGO, "arte", "sprites")
LUZ = (-0.5, 0.7, 0.7)


def quiere(n):
    return FILTRO in n


def guardar(nombre, arr):
    a_imagen(arr).save(os.path.join(DEST, nombre + ".png"))
    print(nombre, arr.shape[1], "x", arr.shape[0])


def tira(nombre, cuadros):
    cuadros = list(cuadros)
    h, w = cuadros[0].shape[:2]
    lienzo = np.zeros((h, w * len(cuadros), 4), dtype=np.uint8)
    for i, c in enumerate(cuadros):
        lienzo[:, i * w:(i + 1) * w] = c
    guardar(nombre, lienzo)


def pegar(arr, filas, x, y, paleta):
    """Dibuja encima un pedacito a mano, píxel por píxel."""
    for j, f in enumerate(filas):
        for i, ch in enumerate(f):
            if ch != "." and 0 <= y + j < arr.shape[0] and 0 <= x + i < arr.shape[1]:
                arr[y + j, x + i] = hex2rgb(paleta[ch]) + (255,)
    return arr


def toca_borde(arr):
    """True si algo que no es contorno llega al borde del cuadro: quedó cortado."""
    borde = np.concatenate([arr[0], arr[-1], arr[:, 0], arr[:, -1]])
    color = borde[borde[..., 3] > 0][:, :3]
    return bool(len(color) and (color != (13, 10, 24)).any())


def contornear(arr):
    """El mismo contorno oscuro del motor, para lo que se pinta sin él."""
    a = arr[..., 3] > 0
    vec = np.zeros_like(a)
    vec[1:, :] |= a[:-1, :]
    vec[:-1, :] |= a[1:, :]
    vec[:, 1:] |= a[:, :-1]
    vec[:, :-1] |= a[:, 1:]
    anillo = vec & ~a
    arr[anillo, :3] = (13, 10, 24)
    arr[anillo, 3] = 255
    return arr


# =============================================================================
# LO QUE PIDE EL CONTRATO (docs/10_contrato_v0.3.md): nombre -> ancho, alto y cuadros
# =============================================================================
ESPERADO = {}
for _n in ("firewall rollback minas molotov rush_b quickscope tornado taladro gacha ragequit frame_drop sumidero afk_farmer speedhack "
           "thorns lagswitch macrokeys bunnyhop clutch leech reaccion rng hardcore battlepass hitboxchica overclock buffstack framerate "
           "reactor_estable chip_xp mira_termica casco_espinas alas_cuchilla motor_nitro reactor_fuga chip_botin "
           "arsenal ruleta infinito ranura_arma ranura_hab").split():
    ESPERADO["icono_" + _n] = (32, 32, 1)
for _n in "dif_facil dif_normal dif_dificil dif_extremo rueda_jefe rueda_compacto rueda_horda rueda_moneda rueda_bolsa rueda_diamante rueda_pizza rueda_cofre".split():
    ESPERADO[_n] = (32, 32, 1)
ESPERADO.update({"tiro_taladro": (14, 20, 2), "tiro_dado": (11, 11, 2), "tiro_boomerang": (16, 16, 4), "obj_mina": (14, 14, 2), "obj_molotov": (10, 14, 1),
                 "obj_llama": (14, 14, 4), "fx_tajo": (64, 40, 3), "obj_tornado": (28, 28, 4), "tiro_hielo": (12, 12, 2), "obj_agujero": (40, 40, 4),
                 "obj_torreta": (22, 22, 2), "obj_escudo": (16, 16, 1), "mosca": (24, 24, 4)})
for _f, _t in enumerate((22, 24, 28)):
    for _s in ("mascota", "mascota_chispita", "mascota_imancito", "mascota_caparazon"):
        ESPERADO["%s_%d" % (_s, _f)] = (_t, _t, 6)


def revisar():
    """Revisa que esté todo, con el tamaño exacto, con transparencia y que nada quede cortado en el borde."""
    malos = 0
    for n, (w, h, c) in ESPERADO.items():
        ruta = os.path.join(DEST, n + ".png")
        if not os.path.exists(ruta):
            print("FALTA", n)
            malos += 1
            continue
        im = Image.open(ruta)
        a = np.array(im.convert("RGBA"))
        if im.size != (w * c, h):
            print("MEDIDA MALA", n, im.size, "debe ser", (w * c, h))
            malos += 1
        if im.mode != "RGBA" or not (a[..., 3] == 0).any():
            print("SIN TRANSPARENCIA", n, im.mode)
            malos += 1
        if not set(np.unique(a[..., 3])) <= {0, 255}:
            print("ALFA A MEDIAS", n)
            malos += 1
        for k in range(c):
            cu = a[:, k * w:(k + 1) * w]
            if not (cu[..., 3] > 0).any():
                print("CUADRO VACÍO", n, k)
                malos += 1
            if toca_borde(cu):
                print("CORTADO EN EL BORDE", n, "cuadro", k)
                malos += 1
    print("revisados", len(ESPERADO), "archivos; problemas:", malos)
    return malos


if SOLO_REVISAR:
    sys.exit(1 if revisar() else 0)


# =============================================================================
# PALETA: las rampas de siempre y unas pocas nuevas para lo que no tenía color
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
# nuevas
R_MORADO = Rampa(["#2a0c3a", "#54187a", "#8c2bc4", "#c45cf0", "#f0c0ff"])
R_AZUL = Rampa(["#0c1f3a", "#16407a", "#2b6fc4", "#4aa8f0", "#b8e4ff"])
R_PLOMO = Rampa(["#14141c", "#2c2c38", "#4a4a5a", "#7c7c90", "#c0c0d0"])
R_ROSADO = Rampa(["#7a1a50", "#b02a7e", "#e64fa0", "#ff8ac0", "#ffd0e8"], mate=True, curva=0.85)
R_NITRO = Rampa(["#3a1ab0", "#6a4aff", "#a0c0ff", "#ffffff"], emisiva=True, curva=1.8)
R_CARA_V = Rampa(["#1c5a34", "#2f8f4c", "#5ccb6c", "#8ee88a", "#d0ffc0"], mate=True, curva=0.65)
R_CARA_A = Rampa(["#7a5a10", "#c49a20", "#f5c84c", "#ffe070", "#fff6a8"], mate=True, curva=0.65)
R_CARA_N = Rampa(["#a0400c", "#d8601a", "#ff8a4a", "#ffb070", "#ffe0b0"], mate=True, curva=0.65)
# colores planos: para lo que se dibuja por capas (llamas, tajos, pantallas)
R_F1 = Rampa(["#a8201c", "#e8402a"], emisiva=True)
R_F2 = Rampa(["#ff8a2a", "#ffa030"], emisiva=True)
R_F3 = Rampa(["#ffe070", "#fff0a0"], emisiva=True)
R_CIAN_P = Rampa(["#157a9e", "#29c5e6"], emisiva=True)
R_BLANCO_P = Rampa(["#8ff0ff", "#ffffff"], emisiva=True)
R_T1 = Rampa(["#2a0c5a", "#3a1a80"], emisiva=True)
R_T2 = Rampa(["#a01860", "#d01848"], emisiva=True)
R_T3 = Rampa(["#e06a14", "#ff9a30"], emisiva=True)
R_T4 = Rampa(["#f0d040", "#fff8c0"], emisiva=True)
# las tres caras de los dados y sus puntos
R_D1, R_D2, R_D3, R_D4 = [Rampa([c], emisiva=True) for c in ("#ffffff", "#c8c8d8", "#8a8aa4", "#1a1230")]
R_D5, R_D6, R_D7 = [Rampa([c], emisiva=True) for c in ("#f0584a", "#c42b3e", "#7a1630")]
R_CHISPA = Rampa(["#f0c020", "#fff070"], emisiva=True)
RI = [m.R_ACERO, m.R_ORO, m.R_NUCLEO, m.R_NEGRO, m.R_CIAN, m.R_VERDE, m.R_MOTOR, m.R_OXIDO, R_ROJO, R_BLANCO, R_NARANJA, R_TOXICO, R_ROSA_L, R_RAYO,
      R_PIEL, R_MASA, R_QUESO, m.R_VIDRIO, R_MORADO, R_AZUL, R_PLOMO, m.R_AMARILLO, R_ROSADO, R_NITRO, R_F1, R_F2, R_F3, R_CIAN_P, R_BLANCO_P, R_T1, R_T2, R_T3, R_T4, R_CARA_V, R_CARA_A, R_CARA_N, R_D1, R_D2, R_D3, R_D4, R_D5, R_D6, R_D7]
AC, OR, NU, NE, CI, VE, MO, OX, RJ, BL, NA, TX, RL, RY, PI, MA, QU, HI, MD, AZ, PL, AM, RS, NI, F1, F2, F3, CP, BP, T1, T2, T3, T4, CV, CA, CN, D1, D2, D3, D4, D5, D6, D7 = range(len(RI))


def i32(nombre, escena, encuadre=1.0, centro=(0, 0), inclinacion=0.0, post=None):
    """Un icono de 32x32 con la misma cámara y la misma luz de los de la v0.2.
    Se centra solo y se aleja un poco si algo queda cortado por el borde."""
    if not quiere(nombre):
        return
    cx, cy = centro
    for _ in range(10):
        a = renderizar(escena, RI, 32, encuadre=encuadre, centro=(cx, cy), inclinacion=inclinacion, luz=LUZ, ss=4)
        ys, xs = np.where(a[..., 3] > 0)
        dx = (xs.min() + xs.max() + 1) / 2 - 16
        dy = (ys.min() + ys.max() + 1) / 2 - 16
        if abs(dx) >= 1 or abs(dy) >= 1:
            cx += dx * encuadre / 16
            cy -= dy * encuadre / 16
        elif toca_borde(a):
            encuadre *= 1.04
        else:
            break
    if post:
        post(a, lambda x, y: (int(round((x - cx) / encuadre * 16 + 16)), int(round((cy - y) / encuadre * 16 + 16))))
    guardar(nombre, a)


def r_obj(escena, ancho, alto=None, encuadre=1.0, centro=(0, 0), inclinacion=0.0, ss=4):
    return renderizar(escena, RI, ancho, alto, encuadre=encuadre, centro=centro, inclinacion=inclinacion, luz=LUZ, ss=ss)


def diag(p):
    return rot_z(p, -0.70)


def mover(p, x=0.0, y=0.0, z=0.0):
    return p - np.array([x, y, z])


# --- formas que se repiten ---------------------------------------------------
ESCUDO = [(0, 0.90), (0.72, 0.62), (0.68, -0.12), (0, -0.90), (-0.68, -0.12), (-0.72, 0.62)]


def escudo_pts(k, x=0.0, y=0.0):
    return [(a * k + x, b * k + y) for a, b in ESCUDO]


def estrella_pts(n, r1, r2, x=0.0, y=0.0, giro=0.0):
    pts = []
    for k in range(n * 2):
        a = giro + math.pi * k / n
        r = r2 if k % 2 == 0 else r1
        pts.append((x + math.cos(a) * r, y + math.sin(a) * r))
    return pts


def hex_pts(r, x=0.0, y=0.0, giro=0.0):
    return [(x + math.cos(giro + k * math.pi / 3) * r, y + math.sin(giro + k * math.pi / 3) * r) for k in range(6)]


def corazon_pts(k, x=0.0, y=0.0):
    pts = []
    for i in range(22):
        t = i / 22 * 2 * math.pi
        a = 16 * math.sin(t) ** 3
        b = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((x + a / 16 * k, y + (b + 2.5) / 15 * k))
    return pts


def abultado(d2, p, c, r):
    """Le da volumen a una silueta plana: por delante queda la cara de un elipsoide."""
    return np.maximum(d2, elipsoide(p, c, r))


def media_luna(x, y, r, a0, a1, grosor, n=20):
    """Puntos de un tajo: borde exterior parejo y el interior se afina hacia las puntas."""
    pts = []
    for k in range(n + 1):
        a = a0 + (a1 - a0) * k / n
        pts.append((x + math.cos(a) * r, y + math.sin(a) * r))
    for k in range(n - 1, 0, -1):
        t = k / n
        a = a0 + (a1 - a0) * t
        ri = r - grosor * math.sin(math.pi * t) ** 0.8
        pts.append((x + math.cos(a) * ri, y + math.sin(a) * ri))
    return pts


# Llama por capas, en coordenadas de -1 a 1. Se dobla la punta para animarla.
LL_A = [(0.05, 1.0), (0.30, 0.52), (0.60, 0.12), (0.66, -0.35), (0.40, -0.85), (0, -1.0), (-0.40, -0.85), (-0.66, -0.35), (-0.52, 0.10), (-0.30, 0.0), (-0.22, 0.45)]
LL_B = [(0.04, 0.42), (0.24, 0.10), (0.40, -0.25), (0.26, -0.72), (0, -0.86), (-0.26, -0.72), (-0.40, -0.30), (-0.22, -0.12), (-0.10, 0.12)]
LL_C = [(0.02, -0.12), (0.16, -0.38), (0.14, -0.72), (0, -0.80), (-0.14, -0.72), (-0.16, -0.42)]


def _doblar(pts, s, alto=1.0):
    return [(a + s * (b + 1) ** 2 * 0.25, (b + 1) * alto - 1) for a, b in pts]


def llama(p, x, y, k, z=0.0, giro=0.0, s=0.0, alto=1.0, capas=(F1, F2, F3)):
    q = rot_z(mover(p, x, y, z), giro) / k
    return [(poligono(q, _doblar(LL_A, s, alto), 0.02, 0.03) * k, capas[0]),
            (poligono(mover(q, z=0.05), _doblar(LL_B, s, alto), 0.02, 0.01) * k, capas[1]),
            (poligono(mover(q, z=0.09), _doblar(LL_C, s, alto), 0.02, 0.0) * k, capas[2])]


def dado_iso(p, x, y, k, colores=(D1, D2, D3)):
    """Dado de tres caras planas: arriba clara, izquierda media y derecha oscura. Así se lee al tiro."""
    c, ar, ad, ai, ab = (0.0, 0.0), (0.0, 1.0), (0.87, 0.5), (-0.87, 0.5), (0.0, -1.0)
    ii, id_ = (-0.87, -0.5), (0.87, -0.5)

    def pts(lista):
        return [(x + a * k, y + b * k) for a, b in lista]

    return [(poligono(p, pts([c, ad, ar, ai]), 0.02, 0.012), colores[0]),
            (poligono(p, pts([c, ai, ii, ab]), 0.02, 0.012), colores[1]),
            (poligono(p, pts([c, ab, id_, ad]), 0.02, 0.012), colores[2])]


def puntos_dado(a, px, x, y, k, color="#1a1230", caras=(1, 2, 3)):
    """Los puntos del dado: arriba van aplastados y a los lados, angostos."""
    col = hex2rgb(color) + (255,)
    c, ad, ai, ab, ii, id_ = (0.0, 0.0), (0.87, 0.5), (-0.87, 0.5), (0.0, -1.0), (-0.87, -0.5), (0.87, -0.5)
    v = 0.24
    mapa = {1: [(0, 0)], 2: [(-v, v), (v, -v)], 3: [(-v, v), (0, 0), (v, -v)]}
    chico = k < 0.5
    sellos = ((3 if not chico else 2, 2 if not chico else 1), (2 if not chico else 1, 3 if not chico else 2), (2 if not chico else 1, 3 if not chico else 2))
    for (o, ua, ub), n, (w, h) in zip(((c, ad, ai), (ab, ii, c), (ab, c, id_)), caras, sellos):
        for u, t in mapa[n]:
            mx = o[0] + (ua[0] - o[0]) * (0.5 + u) + (ub[0] - o[0]) * (0.5 + t)
            my = o[1] + (ua[1] - o[1]) * (0.5 + u) + (ub[1] - o[1]) * (0.5 + t)
            cx, cy = px(x + mx * k, y + my * k)
            a[cy - h // 2:cy - h // 2 + h, cx - w // 2:cx - w // 2 + w] = col


def tuerca(p, x, y, r, z=0.0, mat=AC):
    q = mover(p, x, y, z)
    return [(resta(poligono(q, hex_pts(r), r * 0.26, r * 0.04), cilindro(q, (0, 0, -1), (0, 0, 1), r * 0.44)), mat)]


def flecha_u(p, x, y, r, g, mat=CI):
    """Flecha en U: la mitad de abajo de un aro, con la punta a la izquierda. Va y vuelve."""
    arco = resta(toro(p, (x, y, 0), (0, 0, 1), r, g), caja(p, (x, y + 1.0, 0), (1.5, 1.0, 1.0)))
    punta = poligono(mover(p, x - r, y + 0.02), [(0, 0.36), (0.27, -0.02), (-0.27, -0.02)], 0.04, 0.01)
    return [(arco, mat), (punta, mat)]


# =============================================================================
# ARMAS
# =============================================================================
def a_firewall(p):
    ds = [(toro(p, (0, 0, -0.30), (0, 0, 1), 0.60, 0.04), CI), (esfera(p, (0, 0, -0.1), 0.15), HI)]
    for x, y in ((-0.44, 0.42), (0.44, -0.42)):
        ds.append((poligono(p, escudo_pts(0.60, x, y), 0.06, 0.04), AC))
        ds.append((poligono(mover(p, z=0.10), escudo_pts(0.44, x, y), 0.02, 0.01), RJ))
        ds += llama(p, x, y - 0.03, 0.27, z=0.14)
    return ds


def bumeran(q, g=0.155, cuerpo=AC, punta=CI):
    d = union_suave(capsula(q, (0, 0.30, 0), (-0.68, -0.30, 0), g), capsula(q, (0, 0.30, 0), (0.68, -0.30, 0), g), 0.06)
    ds = [(d, cuerpo)]
    for s in (-1, 1):
        ds.append((capsula(q, (s * 0.52, -0.16, 0.012), (s * 0.68, -0.30, 0.012), g), punta))
    return ds


def a_rollback(p):
    return bumeran(mover(p, 0.0, 0.46), g=0.17, cuerpo=NA) + flecha_u(p, 0.02, -0.40, 0.46, 0.09)


def mina(p, luz=NU, cuerpo=PL, pua=AC):
    ds = [(esfera(p, (0, 0, 0), 0.56), cuerpo)]
    for k in range(8):
        a = k * math.pi / 4 + math.pi / 8
        c, s = math.cos(a), math.sin(a)
        ds.append((cono_truncado(p, (c * 0.46, s * 0.46, 0), (c * 0.94, s * 0.94, 0), 0.17, 0.03), pua))
    ds.append((toro(p, (0, 0, 0.42), (0, 0, 1), 0.26, 0.05), OR))
    ds.append((esfera(p, (0, 0, 0.36), 0.25), luz))
    return ds


def a_molotov(p):
    # botella verde con su trapo y la llama arriba
    q = rot_z(p, -0.32)
    ds = [(capsula(q, (0, -0.70, 0), (0, -0.22, 0), 0.31), VE),
          (cono_truncado(q, (0, -0.22, 0), (0, 0.10, 0), 0.31, 0.11), VE),
          (cilindro(q, (0, 0.06, 0), (0, 0.42, 0), 0.11), VE),
          (caja(q, (0, -0.44, 0.27), (0.20, 0.17, 0.05), 0.01), BL),
          (caja(q, (0, -0.44, 0.31), (0.11, 0.06, 0.03), 0.01), NA),
          (elipsoide(q, (0, 0.42, 0), (0.16, 0.09, 0.16)), BL),
          (capsula(q, (0.10, 0.40, 0.1), (0.20, 0.16, 0.1), 0.045), BL)]
    return ds + llama(q, 0.0, 0.72, 0.36, z=0.05)


def a_rush_b(p):
    q = diag(mover(p, -0.26, -0.26))
    ds = [(poligono(q, [(-0.11, -0.22), (-0.11, 0.56), (0, 0.88), (0.11, 0.56), (0.11, -0.22)], 0.02, 0.018), AC),
          (caja(q, (0, -0.26, 0), (0.30, 0.055, 0.06), 0.012), OR),
          (capsula(q, (0, -0.34, 0), (0, -0.58, 0), 0.068), OX),
          (esfera(q, (0, -0.66, 0), 0.095), OR)]
    ds.append((poligono(mover(p, z=-0.12), media_luna(-0.30, -0.30, 1.22, 0.05, 1.52, 0.30), 0.02, 0.012), CP))
    ds.append((poligono(mover(p, z=-0.08), media_luna(-0.30, -0.30, 1.20, 0.12, 1.45, 0.20), 0.02, 0.0), BP))
    return ds


def a_quickscope(p):
    q = diag(p)
    ds = [(cilindro(q, (0, -0.10, 0), (0, 0.92, 0), 0.05), AC),
          (cilindro(q, (0, 0.76, 0), (0, 0.98, 0), 0.085), OR),
          (caja(q, (0, -0.26, 0), (0.11, 0.30, 0.07), 0.02), AC),
          (poligono(q, [(-0.09, -0.50), (0.09, -0.50), (0.13, -0.64), (0.17, -1.0), (-0.13, -1.0), (-0.06, -0.68)], 0.05, 0.01), OX),
          (caja(q, (-0.19, -0.16, 0), (0.08, 0.11, 0.05), 0.01), PL),
          (caja(q, (0.13, -0.14, 0), (0.03, 0.05, 0.03)), PL),
          (cilindro(q, (0.25, -0.42, 0.0), (0.25, 0.14, 0.0), 0.09), AC),
          (cilindro(q, (0.25, 0.12, 0), (0.25, 0.22, 0), 0.125), OR),
          (cilindro(q, (0.25, -0.50, 0), (0.25, -0.42, 0), 0.105), OR),
          (esfera(q, (0.25, 0.22, 0), 0.095), CI)]
    c = (0.58, 0.58)
    ds += [(toro(p, (c[0], c[1], 0.1), (0, 0, 1), 0.25, 0.045), RJ), (esfera(p, (c[0], c[1], 0.1), 0.085), NU)]
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ds.append((caja(p, (c[0] + dx * 0.31, c[1] + dy * 0.31, 0.1), (0.04 + abs(dx) * 0.07, 0.04 + abs(dy) * 0.07, 0.03)), RJ))
    return ds


def remolino_viento(p, f=0.0, anillos=6, k=1.0):
    """Embudo de anillos que van subiendo. f va de 0 a 2: al llegar a 2 queda igual que al empezar."""
    ds = [(cono_truncado(p, (0, -0.86 * k, -0.02), (0, 0.72 * k, -0.02), 0.04 * k, 0.60 * k), PL)]
    for i in range(-2, anillos):
        t = (i + f) / anillos
        if t < 0 or t >= 1:
            continue
        y = (-0.80 + 1.60 * t) * k
        r = (0.10 + 0.70 * t) * k
        x = 0.10 * k * math.sin(t * 5.0)
        ds.append((toro(p, (x, y, 0), (0, 1, 0), r, (0.05 + 0.045 * t) * k), BL if i % 2 == 0 else HI))
    return ds


def a_tornado(p):
    ds = remolino_viento(p)
    for x, y, r in ((-0.72, 0.02, 0.07), (0.62, -0.32, 0.06), (0.74, 0.86, 0.05)):
        ds.append((esfera(p, (x, y, 0.1), r), OX))
    return ds


def broca(q, y0, y1, r0, fase=0.0, surcos=4.0, claro=AC, oscuro=PL):
    """Cono de taladro con los filos en espiral: franjas diagonales que suben por el cono."""
    d = cono_truncado(q, (0, y0, 0), (0, y1, 0), r0, 0.012)
    largo = y1 - y0
    banda = np.sin(((q[..., 1] - y0) / largo * surcos + q[..., 0] / r0 * 0.55 + fase) * 2 * np.pi)
    d = d - 0.012 * banda
    return [(np.where(banda > 0, d, d + 0.05), claro), (np.where(banda > 0, d + 0.05, d), oscuro)]


def a_taladro(p):
    q = diag(p)
    ds = broca(q, -0.04, 0.98, 0.42)
    ds += [(cilindro(q, (0, -0.20, 0), (0, -0.02, 0), 0.45), OR),
           (capsula(q, (0, -0.68, 0), (0, -0.32, 0), 0.32), AM),
           (caja(q, (0, -0.72, 0.27), (0.21, 0.045, 0.05), 0.01), NE),
           (caja(q, (0, -0.56, 0.29), (0.21, 0.045, 0.05), 0.01), NE),
           (caja(q, (0, -0.40, 0.29), (0.21, 0.045, 0.05), 0.01), NE)]
    return ds


def a_gacha(p):
    return dado_iso(p, 0.56, 0.54, 0.40, (D5, D6, D7)) + dado_iso(p, -0.18, -0.20, 0.72)


def post_gacha(a, px):
    puntos_dado(a, px, -0.18, -0.20, 0.72)
    puntos_dado(a, px, 0.56, 0.54, 0.40, "#ffffff", (1, 1, 2))


def a_ragequit(p):
    # lanzallamas: boquilla, cuerpo, estanque rojo al lado y empuñadura
    q = diag(p)
    ds = [(cilindro(q, (0, -0.26, 0), (0, 0.06, 0), 0.085), AC),
          (toro(q, (0, 0.06, 0), (0, 1, 0), 0.10, 0.035), OR),
          (capsula(q, (0, -0.90, 0), (0, -0.32, 0), 0.15), PL),
          (capsula(q, (0.33, -0.86, -0.04), (0.33, -0.38, -0.04), 0.17), RJ),
          (caja(q, (0.33, -0.62, 0.11), (0.12, 0.05, 0.03)), BL),
          (caja(q, (0.17, -0.74, -0.02), (0.10, 0.035, 0.035)), AC),
          (caja(q, (0.17, -0.48, -0.02), (0.10, 0.035, 0.035)), AC),
          (poligono(q, [(-0.12, -0.56), (-0.12, -0.38), (-0.40, -0.62), (-0.40, -0.78)], 0.05, 0.01), OX)]
    fuera = [(-0.08, 0.06), (0.08, 0.06), (0.40, 0.46), (0.52, 0.80), (0.28, 0.70), (0.18, 1.02), (-0.04, 0.82), (-0.22, 0.98), (-0.30, 0.68), (-0.52, 0.74), (-0.40, 0.42)]
    medio = [(-0.05, 0.10), (0.05, 0.10), (0.27, 0.44), (0.31, 0.64), (0.13, 0.58), (0.05, 0.78), (-0.09, 0.62), (-0.26, 0.62), (-0.27, 0.40)]
    dentro = [(-0.03, 0.14), (0.03, 0.14), (0.13, 0.38), (0.04, 0.50), (-0.11, 0.40)]
    ds += [(poligono(q, fuera, 0.02, 0.02), F1), (poligono(mover(q, z=0.05), medio, 0.02, 0.01), F2), (poligono(mover(q, z=0.09), dentro, 0.02), F3)]
    return ds


def copo(p, r=0.90, g=0.065, giro=0.0, mat=CI, centro=BP):
    ds = []
    for k in range(6):
        a = math.pi / 2 + k * math.pi / 3 + giro
        c, s = math.cos(a), math.sin(a)
        ds.append((capsula(p, (0, 0, 0), (c * r, s * r, 0), g), mat))
        for sg in (-1, 1):
            b = a + sg * math.pi / 3
            x0, y0 = c * r * 0.58, s * r * 0.58
            ds.append((capsula(p, (x0, y0, 0), (x0 + math.cos(b) * r * 0.32, y0 + math.sin(b) * r * 0.32, 0), g * 0.85), mat))
    ds.append((poligono(mover(p, z=0.04), hex_pts(r * 0.20, giro=giro), 0.03, 0.01), centro))
    return ds


def agujero(p, giro=0.0, r0=0.30, r1=0.96, brazos=3, seg=6, vuelta=2.5, g=0.11):
    """Remolino visto de frente: un centro negro y brazos que caen a él."""
    ds = [(esfera(p, (0, 0, 0.0), r0), NE), (toro(p, (0, 0, 0.0), (0, 0, 1), r0, 0.045), RL)]
    for b in range(brazos):
        for k in range(seg):
            t0, t1 = k / seg, (k + 1) / seg
            a0 = giro + b * 2 * math.pi / brazos + t0 * vuelta
            a1 = giro + b * 2 * math.pi / brazos + t1 * vuelta
            ra, rb = r0 + (r1 - r0) * t0, r0 + (r1 - r0) * t1
            mat = RL if k < 2 else MD
            ds.append((capsula(p, (math.cos(a0) * ra, math.sin(a0) * ra, 0), (math.cos(a1) * rb, math.sin(a1) * rb, 0), g * (1 - 0.72 * t0)), mat))
    return ds


def a_afk(p):
    ds = []
    for x, z in ((-0.56, 0.18), (0.56, 0.18), (0.0, -0.18)):
        ds.append((capsula(p, (-0.06, -0.16, 0), (x - 0.06, -0.90, z), 0.06), AC))
    ds += [(cilindro(p, (-0.06, -0.26, 0), (-0.06, 0.0, 0), 0.10), PL),
           (toro(p, (-0.06, -0.20, 0), (0, 1, 0), 0.11, 0.035), OR),
           (caja(p, (-0.14, 0.20, 0), (0.42, 0.26, 0.30), 0.09), AC),
           (caja(p, (0.04, 0.26, 0.28), (0.18, 0.08, 0.04), 0.015), NE),
           (esfera(p, (0.09, 0.26, 0.31), 0.06), NU),
           (caja(p, (-0.42, -0.14, 0.14), (0.15, 0.13, 0.16), 0.02), OX),
           (caja(p, (-0.42, -0.08, 0.31), (0.09, 0.03, 0.02)), OR)]
    for y in (0.30, 0.09):
        ds.append((cilindro(p, (0.24, y, 0), (0.86, y, 0), 0.052), AC))
        ds.append((cilindro(p, (0.76, y, 0), (0.90, y, 0), 0.07), OR))
    ds.append((caja(p, (0.46, 0.195, 0), (0.04, 0.15, 0.07), 0.01), PL))
    return ds + [letra_z(p, -0.58, 0.72, 0.17), letra_z(p, -0.22, 0.92, 0.11)]


def letra_z(p, x, y, k):
    q = mover(p, x, y, 0.1) / k
    return (poligono(q, [(-1, 1), (1, 1), (1, 0.55), (-0.25, -0.55), (1, -0.55), (1, -1), (-1, -1), (-1, -0.55), (0.25, 0.55), (-1, 0.55)], 0.05) * k, BP)


def navecita(q, k=1.0, x=0.0, y=0.0, ala=AC):
    """Una nave chiquitita apuntando hacia +y, igual en todos los iconos que la necesitan."""
    q = mover(q, x, y) / k
    qq = q.copy()
    qq[..., 0] = np.abs(qq[..., 0])
    return [(cono_truncado(q, (0, -0.34, 0), (0, 0.46, 0), 0.17, 0.012) * k, AC),
            (poligono(qq, [(0.08, 0.12), (0.46, -0.28), (0.46, -0.42), (0.08, -0.28)], 0.015, 0.02) * k, ala),
            (poligono(mover(qq, z=0.03), [(0.22, -0.08), (0.42, -0.28), (0.42, -0.36), (0.22, -0.24)], 0.01) * k, RJ),
            (elipsoide(q, (0, 0.06, 0.10), (0.075, 0.16, 0.07)) * k, CI)]


def a_speedhack(p):
    q = diag(p)
    ds = navecita(q, 0.98, 0, 0.46)
    fuera = [(-0.10, 0.24), (0.10, 0.24), (0.24, -0.10), (0.15, -0.34), (0.24, -0.56), (0.08, -0.52), (0.02, -1.0), (-0.08, -0.66), (-0.24, -0.70), (-0.14, -0.38), (-0.26, -0.12)]
    medio = [(-0.06, 0.22), (0.06, 0.22), (0.14, -0.08), (0.06, -0.34), (0.08, -0.52), (-0.04, -0.58), (-0.11, -0.34), (-0.15, -0.10)]
    dentro = [(-0.03, 0.22), (0.03, 0.22), (0.06, -0.02), (-0.02, -0.26), (-0.07, -0.04)]
    ds += [(poligono(q, fuera, 0.02, 0.02), F1), (poligono(mover(q, z=0.05), medio, 0.02, 0.01), F2), (poligono(mover(q, z=0.09), dentro, 0.02), F3)]
    return ds


i32("icono_firewall", a_firewall)
i32("icono_rollback", a_rollback)
i32("icono_minas", mina)
i32("icono_molotov", a_molotov)
i32("icono_rush_b", a_rush_b)
i32("icono_quickscope", a_quickscope)
i32("icono_tornado", a_tornado, inclinacion=0.30)
i32("icono_taladro", a_taladro)
i32("icono_gacha", a_gacha, post=post_gacha)
i32("icono_ragequit", a_ragequit)
i32("icono_frame_drop", copo)
i32("icono_sumidero", agujero)
i32("icono_afk_farmer", a_afk)
i32("icono_speedhack", a_speedhack)


# =============================================================================
# HABILIDADES
# =============================================================================
def corazon(p, k, x=0.0, y=0.0, z=0.0, mat=RJ):
    return (abultado(poligono(mover(p, z=z), corazon_pts(k, x, y), 1.0), p, (x, y, z), (k * 1.25, k * 1.25, k * 0.42)), mat)


def h_thorns(p):
    ds = [corazon(p, 0.40), (toro(p, (0, 0, -0.1), (0, 0, 1), 0.60, 0.07), VE)]
    for k in range(9):
        a = k * 2 * math.pi / 9 + 0.35
        c, s = math.cos(a), math.sin(a)
        ds.append((cono_truncado(p, (c * 0.56, s * 0.56, -0.1), (c * 0.96, s * 0.96, -0.1), 0.13, 0.012), AC))
    return ds


def h_lagswitch(p):
    ds = [(caja(p, (0, -0.30, -0.06), (0.62, 0.66, 0.08), 0.06), PL),
          (caja(p, (0, -0.04, 0.02), (0.17, 0.34, 0.03), 0.01), NE),
          (capsula(p, (0, -0.06, 0.04), (0, 0.56, 0.20), 0.10), AC),
          (esfera(p, (0, 0.68, 0.22), 0.25), RJ),
          (toro(p, (0, -0.06, 0.05), (0, 0, 1), 0.15, 0.045), OR)]
    for x in (-0.46, 0.46):
        for y in (-0.82, 0.22):
            ds.append((esfera(p, (x, y, 0.02), 0.06), OR))
    # una bala que pasa de largo por encima del interruptor, sin hacerle nada
    for x, r in ((-0.88, 0.05), (-0.60, 0.07), (-0.28, 0.09)):
        ds.append((esfera(p, (x, -0.58, 0.2), r), RS))
    ds.append((esfera(p, (0.24, -0.58, 0.2), 0.20), RL))
    return ds


def tecla(p, x, y, cara=AC, base=PL):
    return [(caja(p, (x, y, 0), (0.42, 0.40, 0.14), 0.05), base), (caja(p, (x, y + 0.03, 0.14), (0.31, 0.29, 0.08), 0.05), cara)]


def h_macrokeys(p):
    return tecla(p, 0.0, 0.42, CP, AZ) + tecla(p, -0.47, -0.44) + tecla(p, 0.47, -0.44)


CHEVRON = ["w..w...", ".w..w..", "..w..w.", ".w..w..", "w..w..."]


def post_macrokeys(a, px):
    x, y = px(0.0, 0.48)
    pegar(a, CHEVRON, x - 3, y - 2, {"w": "#ffffff"})


def h_bunnyhop(p):
    q = mover(p, 0, 0.16)
    ds = [(esfera(q, (0, -0.14, 0), 0.50), BL)]
    for s in (-1, 1):
        o = rot_z(mover(q, s * 0.22, 0.26, -0.05), s * 0.16)
        ds.append((elipsoide(o, (0, 0.30, 0), (0.15, 0.42, 0.10)), BL))
        ds.append((elipsoide(o, (0, 0.28, 0.07), (0.075, 0.30, 0.05)), RS))
        ds.append((elipsoide(q, (s * 0.20, -0.08, 0.42), (0.085, 0.115, 0.06)), NE))
    ds += [(esfera(q, (0, -0.25, 0.49), 0.055), RS), (caja(q, (0, -0.40, 0.44), (0.07, 0.07, 0.03), 0.01), BL)]
    for x in (-0.40, 0.40):
        ds.append((resta(toro(p, (x, -0.92, 0), (0, 0, 1), 0.27, 0.05), caja(p, (x, -1.42, 0), (0.6, 0.5, 0.5))), CI))
    return ds


def h_clutch(p):
    ds = [(poligono(mover(p, z=-0.16), estrella_pts(12, 0.72, 0.98, giro=0.13), 0.03, 0.01), F2),
          (poligono(mover(p, z=-0.12), estrella_pts(12, 0.60, 0.82, giro=0.13), 0.03, 0.01), F3),
          corazon(p, 0.62, 0, -0.02)]
    grieta = [(0.02, 0.56), (-0.12, 0.26), (0.12, 0.06), (-0.10, -0.20), (0.04, -0.62), (0.15, -0.20), (0.26, 0.06), (0.04, 0.26), (0.13, 0.56)]
    ds.append((poligono(mover(p, z=0.20), grieta, 0.10), NE))
    return ds


def gota(p, x, y, r, z=0.0, mat=RJ):
    return (union_suave(esfera(p, (x, y, z), r), cono_truncado(p, (x, y + r * 0.2, z), (x, y + r * 2.1, z), r * 0.92, 0.01), 0.02), mat)


def h_leech(p):
    q = p.copy()
    q[..., 0] = np.abs(q[..., 0])
    ala = [(0.10, 0.36), (0.44, 0.62), (0.56, 0.84), (0.98, 0.34), (0.94, -0.10), (0.76, 0.06), (0.60, -0.22), (0.42, -0.02), (0.26, -0.28), (0.08, -0.14)]
    ds = [(poligono(q, ala, 0.02, 0.025), MD),
          (elipsoide(p, (0, 0.02, 0.08), (0.26, 0.40, 0.20)), MD),
          (esfera(p, (0, 0.28, 0.16), 0.27), MD)]
    for s in (-1, 1):
        ds.append((cono_truncado(p, (s * 0.15, 0.42, 0.12), (s * 0.26, 0.82, 0.08), 0.10, 0.01), MD))
        ds.append((elipsoide(p, (s * 0.11, 0.33, 0.38), (0.06, 0.07, 0.04)), NU))
        ds.append((cono_truncado(p, (s * 0.09, 0.15, 0.36), (s * 0.09, -0.04, 0.36), 0.06, 0.008), BL))
    ds.append(gota(p, 0, -0.74, 0.14))
    return ds


def estallido(p, x, y, r, n=9, giro=0.0, z=0.0):
    q = mover(p, x, y, z)
    return [(poligono(q, estrella_pts(n, r * 0.62, r, giro=giro), 0.02, 0.012), F1),
            (poligono(mover(q, z=0.04), estrella_pts(n, r * 0.44, r * 0.74, giro=giro + 0.2), 0.02), F2),
            (poligono(mover(q, z=0.08), estrella_pts(n, r * 0.24, r * 0.46, giro=giro), 0.02), F3),
            (esfera(q, (0, 0, 0.1), r * 0.14), BP)]


def h_reaccion(p):
    return estallido(p, -0.66, -0.64, 0.30, 7) + estallido(p, -0.20, -0.14, 0.44, 8, 0.3, z=0.15) + estallido(p, 0.42, 0.42, 0.56, 9, 0.1, z=0.30)


def trebol(p, x=0.0, y=0.0, k=0.40):
    """Cuatro hojas con forma de corazón, con la punta al centro y separadas para que se distingan."""
    ds = []
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4
        q = rot_z(mover(p, x, y), -(a - math.pi / 2))
        cy = k * 1.04
        ds.append((abultado(poligono(q, corazon_pts(k, 0, cy), 1.0), q, (0, cy, 0), (k * 1.3, k * 1.3, k * 0.40)), VE))
        ds.append((capsula(mover(q, z=k * 0.33), (0, k * 0.30, 0), (0, k * 1.15, 0), 0.025), TX))
    return ds


def h_rng(p):
    ds = trebol(p, -0.12, 0.14, 0.43)
    ds.append((capsula(p, (-0.12, 0.08, -0.05), (-0.30, -0.92, -0.05), 0.055), VE))
    return ds + dado_iso(p, 0.56, -0.56, 0.40)


def post_rng(a, px):
    puntos_dado(a, px, 0.56, -0.56, 0.40, caras=(1, 2, 2))


def calavera(p, hueso=BL, ojo=NU, y=0.0):
    q = mover(p, 0, y)
    ds = [(elipsoide(q, (0, 0.14, 0), (0.62, 0.56, 0.50)), hueso),
          (caja(q, (0, -0.42, 0.06), (0.33, 0.20, 0.28), 0.06), hueso)]
    for s in (-1, 1):
        ds.append((elipsoide(q, (s * 0.26, 0.06, 0.40), (0.165, 0.19, 0.10)), NE))
        ds.append((esfera(q, (s * 0.26, 0.04, 0.47), 0.075), ojo))
    ds.append((poligono(mover(q, z=0.47), [(0, -0.10), (0.09, -0.26), (-0.09, -0.26)], 0.04), NE))
    for x in (-0.16, 0.0, 0.16):
        ds.append((caja(q, (x, -0.50, 0.32), (0.022, 0.12, 0.05)), NE))
    return ds


def h_hardcore(p):
    ds = calavera(p, y=-0.10)
    cresta = [(-0.44, 0.40), (-0.50, 0.76), (-0.28, 0.62), (-0.26, 0.96), (-0.08, 0.72), (0.02, 1.0), (0.14, 0.72), (0.30, 0.94), (0.30, 0.62), (0.50, 0.74), (0.44, 0.40)]
    ds.append((poligono(mover(p, z=-0.05), cresta, 0.06, 0.02), RJ))
    return ds


def h_battlepass(p):
    q = rot_z(p, 0.16)
    cuerpo = caja(q, (0, 0, 0), (0.94, 0.56, 0.07), 0.04)
    for s in (-1, 1):
        cuerpo = resta(cuerpo, cilindro(q, (s * 0.94, 0, -1), (s * 0.94, 0, 1), 0.22))
    ds = [(cuerpo, MD), (resta(caja(q, (0, 0, 0.04), (0.84, 0.46, 0.05), 0.01), caja(q, (0, 0, 0.04), (0.76, 0.38, 0.2))), OR)]
    ds.append((poligono(mover(q, z=0.07), estrella_pts(5, 0.14, 0.33, -0.28, -0.02, math.pi / 2), 0.03, 0.01), OR))
    for y in (-0.26, -0.09, 0.09, 0.26):
        ds.append((caja(q, (0.22, y, 0.08), (0.025, 0.05, 0.02)), BL))
    ds += tuerca(q, 0.54, 0.0, 0.21, z=0.09)
    return ds


def h_hitboxchica(p):
    ds = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            ds.append((caja(p, (sx * 0.62, sy * 0.86, 0), (0.28, 0.07, 0.05), 0.01), TX))
            ds.append((caja(p, (sx * 0.86, sy * 0.62, 0), (0.07, 0.28, 0.05), 0.01), TX))
    for sx, sy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        q = mover(p, sx * 0.46, sy * 0.46)
        ds.append((poligono(q, [(-sx * 0.20, -sy * 0.20), (sx * 0.15, -sy * 0.16), (-sx * 0.16, sy * 0.15)], 0.04, 0.012), OR))
    ds += [(toro(p, (0, 0, 0), (0, 0, 1), 0.18, 0.04), BL), (esfera(p, (0, 0, 0), 0.11), NU)]
    return ds


def h_overclock(p):
    ds = [(toro(p, (0, 0, 0), (0, 0, 1), 0.84, 0.10), AC), (cilindro(p, (0, 0, -0.2), (0, 0, -0.02), 0.80), NE)]
    cols = [TX, TX, RY, RY, F2, F1, F1]
    for k, col in enumerate(cols):
        a = math.radians(216 - k * 42)
        c, s = math.cos(a), math.sin(a)
        ds.append((capsula(p, (c * 0.48, s * 0.48, 0.02), (c * 0.70, s * 0.70, 0.02), 0.075), col))
    a = math.radians(-14)
    ds.append((capsula(p, (-math.cos(a) * 0.14, -math.sin(a) * 0.14, 0.10), (math.cos(a) * 0.66, math.sin(a) * 0.66, 0.10), 0.05), BL))
    ds.append((esfera(p, (0, 0, 0.12), 0.14), OR))
    return ds


def h_buffstack(p):
    ds = []
    for y in (-0.82, 0.82):
        ds.append((caja(p, (0, y, 0), (0.60, 0.10, 0.32), 0.03), OR))
    for x in (-0.50, 0.50):
        ds.append((capsula(p, (x, -0.76, 0.10), (x, 0.76, 0.10), 0.045), OX))
    arriba = cono_truncado(p, (0, 0.74, 0), (0, 0.02, 0), 0.40, 0.05)
    abajo = cono_truncado(p, (0, -0.74, 0), (0, -0.02, 0), 0.40, 0.05)
    ds.append((arriba, HI))
    ds.append((abajo, HI))
    ds.append((np.maximum(arriba - 0.008, mover(p, y=0.34)[..., 1] * 1.0), QU))
    ds.append((np.maximum(abajo - 0.008, mover(p, y=-0.40)[..., 1] * 1.0), QU))
    ds.append((capsula(p, (0, 0.30, 0.03), (0, -0.46, 0.03), 0.02), QU))
    return ds


def h_framerate(p):
    ds = navecita(p, 1.42, -0.30, -0.26)
    # la bala roza la nave: pasa justo al lado, dejando una estela, y saltan chispas
    ds.append((esfera(p, (0.50, -0.02, 0.05), 0.21), RL))
    ds.append((toro(p, (0.50, -0.02, 0.05), (0, 0, 1), 0.21, 0.035), RS))
    ds.append((cono_truncado(p, (0.50, 0.14, 0), (0.50, 0.96, 0), 0.15, 0.015), RS))
    for x, y, k in ((0.12, 0.10, 0.22), (0.18, -0.36, 0.16), (0.02, 0.48, 0.15)):
        ds.append((poligono(mover(p, x, y, 0.2), estrella_pts(4, k * 0.32, k), 0.02, 0.006), RY))
    return ds


i32("icono_thorns", h_thorns)
i32("icono_lagswitch", h_lagswitch)
i32("icono_macrokeys", h_macrokeys, inclinacion=0.30, post=post_macrokeys)
i32("icono_bunnyhop", h_bunnyhop)
i32("icono_clutch", h_clutch)
i32("icono_leech", h_leech)
i32("icono_reaccion", h_reaccion)
i32("icono_rng", h_rng, post=post_rng)
i32("icono_hardcore", h_hardcore)
i32("icono_battlepass", h_battlepass)
i32("icono_hitboxchica", h_hitboxchica)
i32("icono_overclock", h_overclock)
i32("icono_buffstack", h_buffstack)
i32("icono_framerate", h_framerate)


# =============================================================================
# PIEZAS: la misma familia de las de la v0.2 (reactor, chip, mira, casco, alas, motor)
# =============================================================================
def reactor_base(p, nucleo):
    ds = [(resta(cilindro(p, (0, -0.74, 0), (0, 0.74, 0), 0.52), cilindro(p, (0, -0.42, 0), (0, 0.42, 0), 0.62)), AC)]
    for y in (-0.70, 0.70):
        ds.append((toro(p, (0, y, 0), (0, 1, 0), 0.52, 0.06), OR))
    ds.append((cilindro(p, (0, -0.44, 0), (0, 0.44, 0), 0.34), nucleo))
    for a in (0.0, 2.09, 4.19):
        ds.append((capsula(p, (np.cos(a) * 0.5, -0.5, np.sin(a) * 0.5), (np.cos(a) * 0.5, 0.5, np.sin(a) * 0.5), 0.035), AC))
    return ds


def p_reactor_estable(p):
    ds = reactor_base(p, HI)
    ds.append((poligono(mover(p, z=0.42), escudo_pts(0.42), 0.05, 0.03), OR))
    ds.append((poligono(mover(p, z=0.50), escudo_pts(0.28), 0.02), BL))
    return ds


def p_reactor_fuga(p):
    ds = reactor_base(mover(p, 0, 0.14), TX)
    grieta = [(-0.20, 0.42), (0.03, 0.16), (-0.08, 0.03), (0.16, -0.26), (0.0, -0.08), (0.10, 0.08), (-0.10, 0.32)]
    ds.append((poligono(mover(p, z=0.40), grieta, 0.06), NE))
    ds.append((capsula(p, (0.14, -0.14, 0.34), (0.14, -0.62, 0.34), 0.05), TX))
    ds.append(gota(p, 0.14, -0.84, 0.10, 0.34, TX))
    ds.append(gota(p, -0.34, -0.80, 0.08, 0.34, TX))
    ds.append(gota(p, 0.48, -0.74, 0.06, 0.34, TX))
    return ds


def chip_base(p, placa):
    ds = [(caja(p, (0, 0, 0), (0.56, 0.56, 0.09), 0.02), placa), (caja(p, (0, 0, 0.1), (0.34, 0.34, 0.06), 0.01), NE)]
    for k in (-0.34, 0.0, 0.34):
        for s in (-1, 1):
            ds.append((caja(p, (s * 0.72, k, 0), (0.16, 0.05, 0.04), 0.005), OR))
            ds.append((caja(p, (k, s * 0.72, 0), (0.05, 0.16, 0.04), 0.005), OR))
    return ds


def p_chip_xp(p):
    ds = chip_base(p, AZ)
    ds.append((poligono(mover(p, z=0.18), [(0, 0.33), (0.30, 0.02), (0.11, 0.02), (0.11, -0.30), (-0.11, -0.30), (-0.11, 0.02), (-0.30, 0.02)], 0.03, 0.004), OR))
    return ds


def p_chip_botin(p):
    return chip_base(p, OX) + tuerca(p, 0, 0, 0.30, z=0.20)


def p_mira_termica(p):
    ds = [(toro(p, (0, 0, 0), (0, 0, 1), 0.60, 0.13), AC), (toro(p, (0, 0, 0.09), (0, 0, 1), 0.60, 0.04), NA),
          (caja(p, (0, 0.82, 0), (0.10, 0.13, 0.09), 0.02), OR),
          (cilindro(p, (0, 0, -0.3), (0, 0, -0.02), 0.56), T1),
          (elipsoide(p, (0.03, -0.03, -0.02), (0.42, 0.44, 0.04)), T2),
          (elipsoide(p, (0.06, -0.06, 0.03), (0.28, 0.31, 0.04)), T3),
          (elipsoide(p, (0.08, -0.08, 0.07), (0.15, 0.17, 0.04)), T4)]
    for x, y, w, h in ((-0.44, 0, 0.14, 0.03), (0.44, 0, 0.14, 0.03), (0, 0.44, 0.03, 0.14), (0, -0.44, 0.03, 0.14)):
        ds.append((caja(p, (x, y, 0.13), (w, h, 0.02)), BL))
    return ds


def p_casco_espinas(p):
    ds = [(resta(esfera(p, (0, -0.20, 0), 0.74), caja(p, (0, -1.00, 0), (1.1, 0.6, 1.1))), PL)]
    ds.append((caja(p, (0, -0.22, 0.52), (0.48, 0.14, 0.2), 0.04), NE))
    ds.append((caja(p, (0, -0.22, 0.68), (0.36, 0.05, 0.05), 0.01), F1))
    for a in (20, 55, 90, 125, 160):
        c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
        ds.append((cono_truncado(p, (c * 0.66, s * 0.66 - 0.20, 0.0), (c * 1.14, s * 1.14 - 0.20, 0.0), 0.17, 0.012), RJ))
    return ds


def p_alas_cuchilla(p):
    q = p.copy()
    q[..., 0] = np.abs(q[..., 0])
    ds = [(poligono(q, [(0.05, 0.22), (0.98, 0.72), (0.62, 0.10), (0.05, -0.04)], 0.02, 0.012), AC),
          (poligono(mover(q, z=0.03), [(0.20, 0.25), (0.86, 0.60), (0.58, 0.32), (0.20, 0.16)], 0.005), BL),
          (poligono(mover(q, z=-0.04), [(0.05, 0.02), (0.90, 0.10), (0.52, -0.22), (0.05, -0.26)], 0.02, 0.012), AC),
          (poligono(mover(q, z=-0.01), [(0.20, 0.0), (0.78, 0.06), (0.50, -0.06), (0.20, -0.08)], 0.005), BL),
          (poligono(mover(q, z=-0.08), [(0.05, -0.20), (0.70, -0.52), (0.36, -0.54), (0.05, -0.46)], 0.02, 0.012), AC),
          (elipsoide(p, (0, -0.06, 0.05), (0.15, 0.44, 0.13)), PL),
          (esfera(p, (0, 0.04, 0.14), 0.13), NU)]
    return ds


def p_motor_nitro(p):
    q = rot_z(p, -0.6)
    ds = [(cono_truncado(q, (0, 0.62, 0), (0, -0.12, 0), 0.30, 0.42), AC), (toro(q, (0, -0.16, 0), (0, 1, 0), 0.43, 0.06), OR),
          (elipsoide(q, (0, -0.62, 0), (0.27, 0.54, 0.27)), NI), (cilindro(q, (0, 0.62, 0), (0, 0.80, 0), 0.20), NE),
          (capsula(q, (0.56, 0.10, 0.06), (0.56, 0.50, 0.06), 0.19), AZ), (cilindro(q, (0.56, 0.66, 0.06), (0.56, 0.84, 0.06), 0.07), AC),
          (caja(q, (0.56, 0.30, 0.22), (0.15, 0.08, 0.04), 0.005), BL)]
    return ds


i32("icono_reactor_estable", p_reactor_estable, inclinacion=0.25)
i32("icono_reactor_fuga", p_reactor_fuga, inclinacion=0.25)
i32("icono_chip_xp", p_chip_xp)
i32("icono_chip_botin", p_chip_botin)
i32("icono_mira_termica", p_mira_termica)
i32("icono_casco_espinas", p_casco_espinas)
i32("icono_alas_cuchilla", p_alas_cuchilla)
i32("icono_motor_nitro", p_motor_nitro)


# =============================================================================
# ICONOS VARIOS
# =============================================================================
def pistola_lado(q, k=1.0):
    """Pistola de perfil, mirando a la izquierda: de lado se reconoce al tiro."""
    q = q / k
    return [(caja(q, (-0.08, 0.14, 0), (0.44, 0.115, 0.06), 0.02) * k, AC),
            (poligono(q, [(0.08, 0.06), (0.34, 0.06), (0.30, -0.42), (0.04, -0.42)], 0.05, 0.015) * k, OX),
            (resta(toro(q, (-0.08, -0.03, 0), (0, 0, 1), 0.10, 0.025), caja(q, (-0.08, 0.30, 0), (0.3, 0.3, 0.3))) * k, PL),
            (cilindro(q, (-0.56, 0.14, 0), (-0.48, 0.14, 0), 0.075) * k, OR)]


def o_arsenal(p):
    ds = [(caja(p, (0, 0, -0.08), (0.92, 0.80, 0.07), 0.03), OX), (caja(p, (0, 0, -0.03), (0.78, 0.66, 0.04), 0.01), MA)]
    q = rot_z(mover(p, 0.38, -0.04, 0.08), 0.1)
    ds += [(caja(q, (0, 0, 0), (0.26, 0.46, 0.02), 0.005), BL)]
    for y in (0.20, 0.06, -0.08, -0.22):
        ds.append((caja(q, (0, y, 0.025), (0.17, 0.022, 0.01)), PL))
    ds.append((esfera(p, (0.38, 0.40, 0.12), 0.085), RJ))
    return ds + pistola_lado(mover(p, -0.40, 0.08, 0.08), 0.92) + [(caja(p, (-0.46, 0.46, 0.02), (0.16, 0.03, 0.03)), AC)]


def o_ruleta(p):
    ds = [(caja(p, (-0.10, -0.08, 0), (0.66, 0.72, 0.28), 0.05), RJ),
          (caja(p, (-0.10, -0.84, 0), (0.74, 0.12, 0.32), 0.03), OR),
          (resta(esfera(p, (-0.10, 0.60, -0.02), 0.34), caja(p, (-0.10, 0.10, 0), (1.0, 0.5, 1.0))), OR),
          (esfera(p, (-0.10, 0.92, 0), 0.08), NU),
          (caja(p, (-0.10, 0.10, 0.26), (0.54, 0.30, 0.04), 0.01), OR),
          (caja(p, (-0.10, 0.10, 0.28), (0.48, 0.24, 0.04), 0.005), NE),
          (caja(p, (-0.10, -0.46, 0.26), (0.38, 0.09, 0.05), 0.01), NE)]
    for x in (-0.40, -0.10, 0.20):
        ds.append((caja(p, (x, 0.10, 0.30), (0.125, 0.21, 0.03), 0.004), BL))
    ds += [(capsula(p, (0.62, -0.10, 0), (0.80, -0.10, 0), 0.05), AC), (capsula(p, (0.80, -0.10, 0), (0.80, 0.42, 0), 0.05), AC), (esfera(p, (0.80, 0.50, 0), 0.13), RJ)]
    return ds


SIETE = ["kkk", "..k", ".k.", ".k.", ".k."]


def post_ruleta(a, px):
    rojo = {"k": "#c42b3e"}
    for x in (-0.40, -0.10, 0.20):
        cx, cy = px(x, 0.10)
        pegar(a, SIETE, cx - 1, cy - 2, rojo)


def o_infinito(p):
    ds = []
    n = 28
    pts = []
    for k in range(n + 1):
        t = k / n * 2 * math.pi
        de = 1 + math.sin(t) ** 2
        pts.append((0.92 * math.cos(t) / de, 1.10 * math.sin(t) * math.cos(t) / de, 0.10 * math.sin(t)))
    for a, b in zip(pts[:-1], pts[1:]):
        ds.append((capsula(p, a, b, 0.125), OR))
    return ds


def marco_ranura(p, mat):
    return [(caja(p, (-0.08, -0.08, -0.08), (0.78, 0.78, 0.05), 0.02), NE),
            (resta(caja(p, (-0.08, -0.08, 0), (0.82, 0.82, 0.08), 0.03), caja(p, (-0.08, -0.08, 0), (0.67, 0.67, 0.5))), mat)]


def mas(p, x, y, g=0.075, k=0.25, mat=F3):
    # un + bien visible, con su fondo verde: "se abre una ranura más"
    return [(cilindro(p, (x, y, 0.08), (x, y, 0.14), 0.31), VE), (caja(p, (x, y, 0.20), (k, g, 0.04), 0.01), mat), (caja(p, (x, y, 0.20), (g, k, 0.04), 0.01), mat)]


def o_ranura_arma(p):
    ds = marco_ranura(p, OR) + pistola_lado(mover(p, -0.04, -0.06, 0.02), 1.0)
    return ds + mas(p, 0.60, 0.60)


def o_ranura_hab(p):
    ds = marco_ranura(p, CP)
    for y, col in ((0.26, OR), (-0.12, NA), (-0.50, RJ)):
        ds.append((poligono(p, [(-0.48, y + 0.08), (-0.08, y + 0.34), (0.32, y + 0.08), (0.32, y - 0.10), (-0.08, y + 0.15), (-0.48, y - 0.10)], 0.05, 0.01), col))
    return ds + mas(p, 0.60, 0.60)


def _cara_base(p, mat):
    return [(esfera(p, (0, -0.03, 0), 0.90), mat)]


def o_dif_facil(p):
    ds = _cara_base(p, CV)
    for s in (-1, 1):
        ojo = resta(toro(p, (s * 0.34, 0.10, 0.74), (0, 0, 1), 0.18, 0.075), caja(p, (s * 0.34, -0.42, 0.74), (0.5, 0.5, 0.5)))
        ds.append((ojo, NE))
        ds.append((elipsoide(p, (s * 0.60, -0.16, 0.56), (0.15, 0.09, 0.10)), RS))
    boca = resta(elipsoide(p, (0, -0.22, 0.78), (0.36, 0.36, 0.10)), caja(p, (0, 0.28, 0.78), (0.8, 0.5, 0.5)))
    ds.append((boca, NE))
    ds.append((elipsoide(p, (0, -0.42, 0.84), (0.18, 0.11, 0.05)), RS))
    return ds


def o_dif_normal(p):
    ds = _cara_base(p, CA)
    for s in (-1, 1):
        ds.append((elipsoide(p, (s * 0.30, 0.16, 0.76), (0.14, 0.21, 0.08)), NE))
    ds.append((caja(p, (0, -0.36, 0.78), (0.30, 0.06, 0.07), 0.025), NE))
    return ds


def o_dif_dificil(p):
    ds = _cara_base(p, CN)
    for s in (-1, 1):
        ds.append((elipsoide(p, (s * 0.30, 0.02, 0.76), (0.16, 0.13, 0.08)), BL))
        ds.append((esfera(p, (s * 0.25, -0.01, 0.82), 0.075), NE))
        c = rot_z(mover(p, s * 0.32, 0.20, 0.78), -s * 0.52)
        ds.append((caja(c, (0, 0, 0), (0.32, 0.085, 0.08), 0.01), NE))
        ds.append((cono_truncado(p, (s * 0.50, 0.64, 0.3), (s * 0.80, 1.02, 0.1), 0.18, 0.012), BL))
    ds.append((caja(p, (0, -0.44, 0.74), (0.38, 0.17, 0.06), 0.04), NE))
    for x in (-0.24, -0.08, 0.08, 0.24):
        ds.append((caja(p, (x, -0.44, 0.80), (0.055, 0.12, 0.02)), BL))
    return ds


def o_dif_extremo(p):
    ds = llama(p, -0.50, 0.28, 0.54, z=-0.4, s=-0.2) + llama(p, 0.50, 0.30, 0.54, z=-0.4, s=0.2) + llama(p, 0.0, 0.40, 0.60, z=-0.5)
    return ds + calavera(p, hueso=RJ, ojo=RY, y=-0.22)


def o_rueda_jefe(p):
    # La Grúa en chico y con corona: en el rodillo se tiene que leer "jefe" de una.
    ds = [(caja(p, (0, 0.20, 0), (0.56, 0.34, 0.34), 0.07), AM),
          (caja(p, (-0.12, 0.26, 0.30), (0.28, 0.16, 0.06), 0.02), NE),
          (caja(p, (0.31, 0.24, 0.30), (0.10, 0.18, 0.05), 0.02), OX),
          (caja(p, (0, -0.30, 0.08), (0.11, 0.24, 0.08), 0.02), AM),
          (caja(p, (0, -0.22, 0.14), (0.06, 0.05, 0.04), 0.01), NE), (caja(p, (0, -0.38, 0.14), (0.06, 0.05, 0.04), 0.01), NE),
          (cilindro(p, (0, -0.52, 0), (0, -0.74, 0), 0.60), AC), (toro(p, (0, -0.74, 0), (0, 1, 0), 0.54, 0.05), AM),
          (esfera(p, (0, -0.62, 0.40), 0.24), NU)]
    for s in (-1, 1):
        ds.append((caja(p, (s * 0.80, 0.18, 0), (0.17, 0.44, 0.20), 0.07), AC))
        for y in (-0.12, 0.08, 0.28, 0.48):
            ds.append((caja(p, (s * 0.97, y, 0.05), (0.03, 0.05, 0.10), 0.01), NE))
    ds.append((poligono(p, [(-0.40, 0.52), (-0.48, 0.94), (-0.22, 0.72), (0, 1.0), (0.22, 0.72), (0.48, 0.94), (0.40, 0.52)], 0.10, 0.015), OR))
    return ds


def o_moneda(p):
    q = rot_y(p, 0.45)
    ds = [(cilindro(q, (0, 0, -0.10), (0, 0, 0.10), 0.82), OR), (toro(q, (0, 0, 0.10), (0, 0, 1), 0.72, 0.055), QU)]
    return ds


SIGNO = [".kkk.", "k.k.k", "k.k..", ".kkk.", "..k.k", "k.k.k", ".kkk."]


def post_signo(x, y, color):
    def f(a, px):
        cx, cy = px(x, y)
        pegar(a, SIGNO, cx - 2, cy - 3, {"k": color})
    return f


def o_bolsa(p):
    ds = [(union_suave(elipsoide(p, (0, -0.30, 0), (0.70, 0.62, 0.52)), elipsoide(p, (0, 0.30, 0), (0.22, 0.24, 0.20)), 0.14), MA),
          (toro(p, (0, 0.40, 0), (0, 1, 0), 0.20, 0.06), OR),
          (poligono(p, [(-0.34, 0.92), (-0.14, 0.48), (0.14, 0.48), (0.34, 0.92), (0.14, 0.78), (0, 0.94), (-0.14, 0.78)], 0.12, 0.03), MA)]
    return ds


def o_diamante(p):
    q = rot_y(p, 0.32)
    planos = [((0, 1, 0), 0.50)]
    for k in range(8):
        a = k * math.pi / 4
        c, s = math.cos(a), math.sin(a)
        # corona (arriba) y pabellón (abajo)
        n1 = np.array([c * 0.86, 0.50, s * 0.86])
        n2 = np.array([c * 0.74, -0.67, s * 0.74])
        planos.append((tuple(n1 / np.linalg.norm(n1)), 0.72))
        planos.append((tuple(n2 / np.linalg.norm(n2)), 0.60))
    d = None
    for n, h in planos:
        di = q[..., 0] * n[0] + q[..., 1] * n[1] + q[..., 2] * n[2] - h
        d = di if d is None else np.maximum(d, di)
    return [(d, HI)]


def h_pizza(p):
    ds = [(poligono(p, [(0, -0.92), (0.70, 0.56), (-0.70, 0.56)], 0.06, 0.03), QU), (capsula(p, (-0.72, 0.62, 0.03), (0.72, 0.62, 0.03), 0.13), MA)]
    for x, y in ((-0.20, 0.26), (0.22, 0.20), (0.0, -0.28)):
        ds.append((cilindro(p, (x, y, 0.06), (x, y, 0.12), 0.14), RJ))
    return ds


def o_cofre(p):
    return [(caja(p, (0, -0.32, 0), (0.92, 0.48, 0.40), 0.04), OX), (elipsoide(p, (0, 0.18, 0), (0.92, 0.50, 0.40)), OX),
            (caja(p, (0, 0.04, 0.36), (0.94, 0.06, 0.12)), OR),
            (caja(p, (-0.60, -0.10, 0.34), (0.08, 0.70, 0.10)), OR), (caja(p, (0.60, -0.10, 0.34), (0.08, 0.70, 0.10)), OR),
            (caja(p, (0, -0.08, 0.40), (0.20, 0.22, 0.06), 0.02), OR), (caja(p, (0, -0.12, 0.45), (0.05, 0.09, 0.03)), NE)]


i32("icono_arsenal", o_arsenal)
i32("icono_ruleta", o_ruleta, post=post_ruleta)
i32("icono_infinito", o_infinito)
i32("icono_ranura_arma", o_ranura_arma)
i32("icono_ranura_hab", o_ranura_hab)
i32("dif_facil", o_dif_facil)
i32("dif_normal", o_dif_normal)
i32("dif_dificil", o_dif_dificil)
i32("dif_extremo", o_dif_extremo)
i32("rueda_moneda", o_moneda, post=post_signo(0.0, 0.0, "#8a5220"))
i32("rueda_bolsa", o_bolsa, post=post_signo(0.0, -0.32, "#fff2a0"))
i32("rueda_diamante", o_diamante, inclinacion=0.12)
i32("rueda_pizza", h_pizza)
i32("rueda_cofre", o_cofre)
i32("rueda_jefe", o_rueda_jefe, inclinacion=0.06)
# El compacto es el modelo real de modelos.py, para que se reconozca en los rodillos.
if quiere("rueda_compacto"):
    guardar("rueda_compacto", renderizar(m.compacto(0.0), m.RAMPAS_COMPACTO, 32, encuadre=1.05, inclinacion=0.12, ss=4))


# =============================================================================
# ENEMIGO: LA MOSCA. Chatarra voladora, con los ojos como núcleo rojo.
# =============================================================================
R_MOSCA = Rampa(["#12383c", "#22605f", "#3a9a8c", "#6cd0b4", "#d0ffe8"])
R_OJO_MOSCA = Rampa(["#7a0a2a", "#d01840", "#ff4a4a", "#ffb04a"], emisiva=True, curva=2.2)
R_ALA = Rampa(["#5a7a90", "#8fb0c0", "#c0dce8", "#e8f8ff", "#ffffff"], mate=True)
RAMPAS_MOSCA = [R_MOSCA, R_ALA, R_OJO_MOSCA, m.R_NEGRO, m.R_ACERO]


def mosca(ang):
    def e(p):
        ds = [(elipsoide(p, (0, -0.38, -0.10), (0.26, 0.34, 0.22)), 0),
              (caja(p, (0, -0.30, 0.09), (0.20, 0.035, 0.05)), 3), (caja(p, (0, -0.48, 0.07), (0.15, 0.03, 0.05)), 3),
              (elipsoide(p, (0, 0.10, 0), (0.42, 0.38, 0.32)), 0)]
        for s in (-1, 1):
            ds.append((esfera(p, (s * 0.30, 0.20, 0.18), 0.215), 2))
            ds.append((capsula(p, (s * 0.26, -0.14, 0), (s * 0.62, -0.46, 0), 0.05), 4))
            ds.append((capsula(p, (s * 0.20, -0.26, 0), (s * 0.40, -0.76, 0), 0.05), 4))
            q = rot_z(mover(p, s * 0.22, 0.26, -0.20), -s * ang)
            ds.append((elipsoide(q, (s * 0.40, 0, 0), (0.44, 0.20, 0.04)), 1))
            q2 = rot_z(mover(p, s * 0.22, 0.14, -0.26), -s * (ang * 0.6 - 0.42))
            ds.append((elipsoide(q2, (s * 0.36, 0, 0), (0.38, 0.14, 0.03)), 1))
        return ds
    return e


if quiere("mosca"):
    tira("mosca", [renderizar(mosca(a), RAMPAS_MOSCA, 24, encuadre=1.16, centro=(0, -0.02), inclinacion=0.05, ss=4) for a in (0.70, 0.25, -0.20, 0.25)])

# La horda del rodillo: un Rabioso y sus moscas, con los mismos modelos que en combate.
if quiere("rueda_horda"):
    def encima(lienzo, arr, x, y):
        sel = arr[..., 3] > 0
        lienzo[y:y + arr.shape[0], x:x + arr.shape[1]][sel] = arr[sel]

    lienzo = np.zeros((32, 32, 4), dtype=np.uint8)
    chica = renderizar(mosca(0.5), RAMPAS_MOSCA, 16, encuadre=1.16, centro=(0, -0.02), ss=4)
    for x, y in ((0, 0), (16, 1), (0, 16), (16, 16)):
        encima(lienzo, chica, x, y)
    encima(lienzo, renderizar(m.rabioso(0.0), m.RAMPAS_RABIOSO, 22, encuadre=1.02, centro=(0, 0.08), inclinacion=0.08, ss=4), 5, 6)
    guardar("rueda_horda", lienzo)


# =============================================================================
# OBJETOS DE COMBATE (hojas horizontales)
# =============================================================================
if quiere("tiro_taladro"):
    def s_taladro(f):
        def e(p):
            ds = broca(p, -0.46, 1.34, 0.74, fase=f, surcos=3.0, claro=AC, oscuro=PL)
            ds += [(cilindro(p, (0, -0.68, 0), (0, -0.44, 0), 0.78), OR), (capsula(p, (0, -1.02, 0), (0, -0.74, 0), 0.40), AM)]
            return ds
        return e
    tira("tiro_taladro", [r_obj(s_taladro(f), 14, 20, encuadre=1.04, centro=(0, -0.02)) for f in (0.0, 0.5)])

if quiere("tiro_dado"):
    # a 11 px un dado se dibuja a mano: de frente, y al girar queda de punta
    D = {"k": "#0d0a18", "w": "#ffffff", "g": "#c8c8d8", "n": "#1a1230"}

    def dadito(filas):
        return pegar(np.zeros((11, 11, 4), dtype=np.uint8), filas, 0, 0, D)

    tira("tiro_dado", [
        dadito([".kkkkkkkkk.", "kwwwwwwwwgk", "kwnnwwwnngk", "kwnnwwwnngk", "kwwwwnwwwgk", "kwwwnnnwwgk", "kwwwwnwwwgk", "kwnnwwwnngk", "kwnnwwwnngk", "kgggggggggk", ".kkkkkkkkk."]),
        dadito([".....k.....", "....kwk....", "...kwwwk...", "..kwnwwwk..", ".kwwwwwwwk.", "kwwwwnwwwwk", ".kgwwwwwgk.", "..kgwwngk..", "...kgggk...", "....kgk....", ".....k....."])])

if quiere("tiro_boomerang"):
    tira("tiro_boomerang", [r_obj(lambda p, a=a: bumeran(mover(rot_z(p, a), 0, 0.02), g=0.21, cuerpo=NA), 16, encuadre=1.02) for a in (0.0, math.pi / 2, math.pi, 3 * math.pi / 2)])

if quiere("obj_mina"):
    tira("obj_mina", [r_obj(lambda p, l=l: mina(p, l, AC, BL), 14, encuadre=1.08) for l in (NA, RY)])

if quiere("obj_molotov"):
    def s_molotov(p):
        q = mover(p, 0, -0.20)
        ds = [(capsula(q, (0, -0.56, 0), (0, -0.30, 0), 0.44), VE), (cono_truncado(q, (0, -0.30, 0), (0, 0.0, 0), 0.44, 0.18), VE), (cilindro(q, (0, 0.0, 0), (0, 0.42, 0), 0.18), VE),
              (caja(q, (0, -0.44, 0.38), (0.30, 0.18, 0.05)), BL), (elipsoide(q, (0, 0.44, 0), (0.26, 0.12, 0.2)), BL)]
        return ds + llama(p, 0, 0.60, 0.58, z=0.1)
    guardar("obj_molotov", r_obj(s_molotov, 10, 14, encuadre=1.06, centro=(0, 0.0)))

if quiere("obj_llama"):
    def s_llama(s, alto):
        return lambda p: llama(p, 0, -0.10, 0.84, s=s, alto=alto)
    tira("obj_llama", [r_obj(s_llama(s, h), 14, encuadre=1.10, centro=(0, 0.02)) for s, h in ((-0.20, 1.0), (0.08, 0.90), (0.22, 1.0), (-0.06, 1.06))])

if quiere("fx_tajo"):
    # 64x40: el corte nace de abajo al medio, donde va la nave. El arco cubre unos 140 grados.
    def s_tajo(a0, a1, g, blanco):
        def e(p):
            ds = [(poligono(p, media_luna(0, -0.46, 1.02, a0, a1, g, n=26), 0.02, 0.006), CP)]
            if blanco:
                ds.append((poligono(mover(p, z=0.05), media_luna(0, -0.46, 0.99, a0 + 0.13, a1 - 0.13, g * 0.62, n=24), 0.02), BP))
            return ds
        return e
    medio = math.pi / 2
    ab = math.radians(68)
    tira("fx_tajo", [r_obj(s_tajo(*c), 64, 40, ss=3) for c in ((medio + 0.05, medio + ab, 0.20, True), (medio - ab, medio + ab, 0.36, True), (medio - ab, medio + ab * 0.85, 0.15, False))])

if quiere("obj_tornado"):
    tira("obj_tornado", [r_obj(lambda p, f=f: remolino_viento(p, f), 28, inclinacion=0.30, encuadre=1.08) for f in (0.0, 0.5, 1.0, 1.5)])

if quiere("tiro_hielo"):
    H = {"c": "#29c5e6", "w": "#ffffff", "s": "#8ff0ff"}

    def copito(filas):
        return contornear(pegar(np.zeros((12, 12, 4), dtype=np.uint8), filas, 1, 1, H))

    tira("tiro_hielo", [
        copito(["....cc....", ".c..cc..c.", "..c.cc.c..", "...cwwc...", "cccwwwwccc", "cccwwwwccc", "...cwwc...", "..c.cc.c..", ".c..cc..c.", "....cc...."]),
        copito(["....ww....", ".w..ss..w.", "..s.ss.s..", "...sccs...", "wssccccssw", "wssccccssw", "...sccs...", "..s.ss.s..", ".w..ss..w.", "....ww...."])])

if quiere("obj_agujero"):
    tira("obj_agujero", [r_obj(lambda p, g=g: agujero(p, giro=g), 40, encuadre=1.12, ss=3) for g in (0.0, math.radians(30), math.radians(60), math.radians(90))])

if quiere("obj_torreta"):
    def s_torreta(tiro):
        def e(p):
            ds = []
            for x, z in ((-0.74, 0.18), (0.74, 0.18), (0.0, -0.18)):
                ds.append((capsula(p, (0, -0.30, 0), (x, -0.90, z), 0.09), AC))
            alto = 0.84 - 0.12 * tiro
            ds += [(esfera(p, (0, -0.34, 0), 0.22), PL),
                   (caja(p, (0, -0.06, 0), (0.50, 0.30, 0.28), 0.10), AC),
                   (caja(p, (0, -0.08, 0.27), (0.34, 0.10, 0.04), 0.015), NE),
                   (esfera(p, (0, -0.08, 0.31), 0.095), NU),
                   (caja(p, (0, 0.34 - 0.06 * tiro, 0), (0.30, 0.20, 0.18), 0.03), PL)]
            for s in (-1, 1):
                ds.append((cilindro(p, (s * 0.15, 0.40, 0), (s * 0.15, alto, 0), 0.10), AC))
                ds.append((cilindro(p, (s * 0.15, alto - 0.16, 0), (s * 0.15, alto, 0), 0.125), OR))
                if tiro:
                    ds.append((poligono(mover(p, s * 0.15, alto + 0.08, 0.1), estrella_pts(5, 0.08, 0.20), 0.02, 0.008), MO))
            return ds
        return e
    tira("obj_torreta", [r_obj(s_torreta(t), 22, encuadre=1.08, centro=(0, 0.0)) for t in (0, 1)])

if quiere("obj_escudo"):
    def s_escudo(p):
        return [(poligono(p, escudo_pts(0.98), 0.06, 0.04), AC), (poligono(mover(p, z=0.10), escudo_pts(0.68), 0.02, 0.01), RJ)] + llama(p, 0, -0.05, 0.44, z=0.14)
    guardar("obj_escudo", r_obj(s_escudo, 16))


# =============================================================================
# MASCOTAS: hojas de 6 cuadros, 4 de reposo y 2 de acción (boca abierta o lo que le toque).
# Entre una forma y otra cambia el detalle, no el tamaño: 22, 24 y 28 px por cuadro.
# Todas tienen los mismos ojos enormes con un píxel de brillo, que es lo que les da vida.
# =============================================================================
TAM_PET = (22, 24, 28)
ENC_PET = 1.08
SUBE = (0, 1, 1, 0)  # en píxeles: el reposo sube y baja un píxel, sin apuro
R_TORTUGA = Rampa(["#1f4a24", "#2f7a34", "#5cb84c", "#8ee070", "#d8ffb0"], mate=True, curva=0.85)
R_CONCHA = Rampa(["#0e2a3a", "#1c4a60", "#2f7a90", "#5cb0c0", "#c0f0f0"])
R_CREMA = Rampa(["#ab9ac4", "#dccfe6", "#ece2f0", "#fff6ff", "#fff6ff"], mate=True)


def px_pet(forma):
    return 2 * ENC_PET / TAM_PET[forma]


def r_pet(escena, rampas, forma, centro):
    """El material 2 siempre son los ojos: les pone el brillo."""
    ancho = TAM_PET[forma]
    arr, cod = renderizar(escena, rampas, ancho, encuadre=ENC_PET, centro=centro, inclinacion=0.05, devolver_codigo=True,
                          luz=(-0.45, 0.75, 0.75), oscuro_interior=False, ss=4)
    ys, xs = np.where((cod >= 0) & (cod // 16 == 2))
    if len(xs):
        for lado in (xs < ancho / 2, xs >= ancho / 2):
            if lado.any():
                x0, y0 = xs[lado].min(), ys[lado].min()
                arr[y0 + 1, x0 + 1, :3] = (255, 255, 255)
    return arr


def hoja_pet(nombre, funcion, rampas, centro=(0, -0.18)):
    for forma in range(3):
        n = "%s_%d" % (nombre, forma)
        if quiere(n):
            cuadros = [r_pet(funcion(forma, f, 0.0), rampas, forma, centro) for f in range(4)]
            cuadros += [r_pet(funcion(forma, 1, a), rampas, forma, centro) for a in (0.6, 1.0)]
            tira(n, cuadros)


# --- Mordisco: el de siempre ---------------------------------------------------------------------
RP_MORDISCO = [m.R_PELO, m.R_MANCHA, m.R_OJO, m.R_BOCA, m.R_DIENTE, m.R_ORO, R_ROJO, R_CREMA]


def mordisco(forma, f, boca):
    salto = (SUBE[f] if boca == 0 else 1) * px_pet(forma)
    oreja = (0.0, 0.14, 0.0, -0.14)[f]
    cola = (-0.35, 0.0, 0.35, 0.0)[f]
    cabeza_r = (0.62, 0.58, 0.58)[forma]
    cuerpo_y = (-0.40, -0.46, -0.50)[forma]

    def e(p):
        p = mover(p, 0, salto - 0.04)
        ds = []
        cabeza = elipsoide(p, (0, 0.12, 0.02), (cabeza_r, cabeza_r * 0.86, cabeza_r * 0.86))
        cuerpo = elipsoide(p, (0, cuerpo_y, -0.08), (0.46 + 0.05 * forma, 0.40 + 0.03 * forma, 0.40))
        ds.append((union_suave(cabeza, cuerpo, 0.10), 0))
        for s in (-1, 1):
            q = rot_z(mover(p, s * (cabeza_r - 0.04), 0.32, 0), s * (-0.45 + oreja * s))
            ds.append((elipsoide(q, (s * 0.06, -0.15, 0), (0.17, 0.33, 0.13)), 1))
            ds.append((elipsoide(p, (s * 0.26, cuerpo_y - 0.32 - 0.03 * forma, 0.14), (0.14, 0.11, 0.14)), 0))
        q = rot_z(mover(p, 0.40, cuerpo_y + 0.05, -0.15), -0.7 + cola * 0.5)
        ds.append((elipsoide(q, (0.14, 0, 0), (0.22 + 0.03 * forma, 0.08, 0.08)), 1))
        ds.append((elipsoide(p, (-0.28, 0.42, 0.40), (0.18 + 0.05 * forma, 0.12 + 0.04 * forma, 0.10)), 1))
        for s in (-1, 1):
            ds.append((elipsoide(p, (s * 0.25, 0.14, 0.42 + 0.03 * forma), (0.15, 0.185, 0.12)), 2))
        # la cría no tiene dientes; la joven gana collar y la adulta colmillos y pechera
        if forma >= 1:
            ds.append((toro(p, (0, -0.22, -0.02), (0, 1, 0.22), 0.38, 0.045), 6))
            ds.append((esfera(p, (0, -0.31, 0.37), 0.075), 5))
        if forma == 2:
            ds.append((elipsoide(p, (0, cuerpo_y - 0.06, 0.27), (0.21, 0.17, 0.08)), 7))
            for x, y in ((0.18, 0.62), (0.32, 0.54)):
                ds.append((elipsoide(p, (x, y, 0.20), (0.09, 0.07, 0.07)), 1))
        if boca > 0.05 or forma == 2:
            alto = 0.04 + 0.13 * boca + (0.03 if forma == 2 else 0.0)
            ds.append((elipsoide(p, (0, -0.14, 0.52), (0.15 + 0.08 * boca, alto, 0.06)), 3))
            if forma >= 1:
                for s in (-1, 1):
                    ds.append((cono_truncado(p, (s * 0.09, -0.12 + alto * 0.5, 0.56), (s * 0.09, -0.18, 0.57), 0.035, 0.005), 4))
        else:
            ds.append((elipsoide(p, (0, -0.13, 0.50), (0.07, 0.03, 0.04)), 3))
        return ds

    return e


# --- Chispita: un bicho-batería ------------------------------------------------------------------
RP_CHISPITA = [m.R_AMARILLO, R_PLOMO, m.R_OJO, m.R_BOCA, m.R_ORO, R_RAYO, m.R_ACERO, R_TOXICO, R_CHISPA]


def rayito(p, x, y, k, flip=1):
    a = (x - 0.45 * k * flip, y + 0.85 * k, 0.2)
    b = (x + 0.20 * k * flip, y + 0.12 * k, 0.2)
    c = (x - 0.20 * k * flip, y - 0.12 * k, 0.2)
    d = (x + 0.45 * k * flip, y - 0.85 * k, 0.2)
    return [(capsula(p, a, b, 0.05), 8), (capsula(p, b, c, 0.05), 8), (capsula(p, c, d, 0.05), 8)]


def chispita(forma, f, acc):
    salto = (SUBE[f] if acc == 0 else 0) * px_pet(forma)
    chispas = {0: {1: [(0.74, 0.46, 0.17, 1)], 3: [(-0.74, 0.34, 0.17, -1)]},
               1: {0: [(0.76, 0.48, 0.18, 1)], 1: [(-0.76, 0.22, 0.18, -1)], 2: [(0.76, 0.02, 0.18, 1)], 3: [(-0.76, 0.48, 0.18, -1)]},
               2: {0: [(0.78, 0.50, 0.20, 1), (-0.80, -0.06, 0.16, -1)], 1: [(-0.78, 0.46, 0.20, -1), (0.82, -0.18, 0.16, 1)],
                   2: [(0.80, 0.10, 0.20, 1), (-0.78, 0.54, 0.16, -1)], 3: [(-0.80, 0.14, 0.20, -1), (0.76, 0.56, 0.16, 1)]}}[forma].get(f, [])

    def e(p):
        ds = []
        for x, y, k, fl in chispas if acc == 0 else ():
            ds += rayito(p, x, y, k, fl)
        if acc > 0:
            # descarga: rayos a los cuatro lados, más grandes en el segundo cuadro
            k = 0.18 + 0.10 * acc
            for x, y, fl in ((0.78, 0.46, 1), (-0.78, 0.46, -1), (0.82, -0.28, -1), (-0.82, -0.28, 1)):
                ds += rayito(p, x, y, k, fl)
        p = mover(p, 0, salto)
        cuerpo = capsula(p, (0, -0.26, 0), (0, 0.14, 0), 0.46)
        ds.append((cuerpo, 0))
        ds.append((np.maximum(cuerpo - 0.012, p[..., 1] + 0.32), 1))
        ds.append((toro(p, (0, -0.32, 0), (0, 1, 0), 0.46, 0.035), 4))
        ds.append((cilindro(p, (0, 0.50, 0), (0, 0.80, 0), 0.17), 6))
        ds.append((toro(p, (0, 0.56, 0), (0, 1, 0), 0.22, 0.04), 4))
        for s in (-1, 1):
            ds.append((elipsoide(p, (s * 0.20, 0.12, 0.36), (0.14, 0.175, 0.11)), 2))
            # patitas de bicho
            ds.append((capsula(p, (s * 0.38, -0.26, 0.06), (s * 0.62, -0.46, 0.10), 0.055), 6))
            ds.append((capsula(p, (s * 0.24, -0.62, 0.06), (s * 0.34, -0.84, 0.10), 0.06), 6))
            # antenas: crecen con la forma
            alto = (0.70, 0.76, 0.78)[forma]
            ds.append((capsula(p, (s * 0.30, 0.42, 0), (s * 0.50, alto, 0), 0.03), 6))
            ds.append((esfera(p, (s * 0.51, alto + 0.02, 0), (0.07 + 0.012 * forma) * (1.0 + 0.25 * acc)), 5))
        if acc > 0:
            ds.append((elipsoide(p, (0, -0.10, 0.42), (0.11 + 0.06 * acc, 0.04 + 0.11 * acc, 0.05)), 3))
        else:
            ds.append((elipsoide(p, (0, -0.08, 0.44), (0.07, 0.03, 0.04)), 3))
        # la barra de carga va creciendo: la batería "se llena" con la forma
        for k in range(forma + 1):
            ds.append((caja(p, ((k - forma / 2.0) * 0.20, -0.54, 0.35), (0.06, 0.09, 0.05), 0.005), 7))
        if forma == 2:
            for s in (-1, 1):
                ds.append((capsula(p, (s * 0.56, -0.16, -0.20), (s * 0.56, 0.24, -0.20), 0.12), 6))
                ds.append((toro(p, (s * 0.56, 0.02, -0.20), (0, 1, 0), 0.12, 0.03), 4))
                ds.append((esfera(p, (s * 0.56, 0.38, -0.20), 0.05), 5))
        return ds

    return e


# --- Imancito: un imán en herradura con patitas ------------------------------------------------
RP_IMANCITO = [R_ROJO, R_BLANCO, m.R_OJO, m.R_BOCA, m.R_ACERO, R_CIAN_P, R_AZUL, m.R_ORO, R_CHISPA]


def imancito(forma, f, acc):
    salto = (SUBE[f] if acc == 0 else 1) * px_pet(forma)
    paso = (0, 1, 0, -1)[f] if acc == 0 else 0
    cy = 0.06

    def e(p):
        ds = []
        pp = p
        if acc > 0:
            # el campo del imán: arcos cian y un Bit que viene volando hacia él
            for r in (0.34, 0.54) if acc >= 1 else (0.34,):
                ds.append((resta(toro(p, (0, -0.42, 0.1), (0, 0, 1), r, 0.04), caja(p, (0, 0.58, 0), (1.5, 1.0, 1.0))), 5))
            y_bit = -0.84 if acc < 1 else -0.52
            ds.append((poligono(mover(p, 0, y_bit, 0.2), [(0, 0.15), (0.11, 0), (0, -0.15), (-0.11, 0)], 0.03, 0.005), 8))
        p = mover(pp, 0, salto)
        arco = resta(toro(p, (0, cy, 0), (0, 0, 1), 0.50, 0.30), caja(p, (0, cy - 1.0, 0), (1.5, 1.0, 1.0)))
        puntas = 5 if acc > 0 else 1
        lados = ((-1, 0), (1, 6 if forma == 2 else 0))
        for s, mat in lados:
            # la forma adulta es de dos colores, como los imanes de verdad
            ds.append((np.maximum(arco, -s * p[..., 0]), mat))
            ds.append((caja(p, (s * 0.50, cy - 0.20, 0), (0.30, 0.22, 0.28), 0.03), mat))
            ds.append((caja(p, (s * 0.50, cy - 0.52, 0), (0.31, 0.11, 0.29), 0.03), puntas))
            pie = -0.84 + 0.04 * paso * s
            ds.append((capsula(p, (s * 0.50, cy - 0.62, 0), (s * 0.50, pie + 0.06, 0.02), 0.075), 4))
            ds.append((elipsoide(p, (s * 0.50, pie, 0.08), (0.17, 0.085, 0.17)), 4))
            ds.append((elipsoide(p, (s * 0.27, cy + 0.50, 0.24), (0.155, 0.185, 0.10)), 2))
        ds.append((elipsoide(p, (0, cy + 0.335, 0.22), (0.065 + 0.04 * acc, 0.03 + 0.045 * acc, 0.06)), 3 if acc > 0 else 2))
        if forma >= 1:
            # remaches arriba, y en la adulta unas virutas de fierro pegadas
            for s in (-1, 1):
                ds.append((esfera(p, (s * 0.60, cy + 0.34, 0.20), 0.05), 7))
        if forma == 2:
            for a in (68, 90, 112):
                c, sn = math.cos(math.radians(a)), math.sin(math.radians(a))
                ds.append((cono_truncado(p, (c * 0.70, cy + sn * 0.70, 0.02), (c * 0.90, cy + sn * 0.90, 0.02), 0.06, 0.01), 4))
        return ds

    return e


# --- Caparazón: una tortuga con la concha de escudo ----------------------------------------------
RP_CAPARAZON = [R_TORTUGA, R_CONCHA, m.R_OJO, m.R_BOCA, m.R_ORO, m.R_ACERO, R_CIAN_P, R_BLANCO_P]


def caparazon(forma, f, acc):
    # La tortuga casi no se mueve: solo la cabeza y las patas. Al actuar, se esconde y brilla el escudo.
    px = px_pet(forma)
    cab = (SUBE[f] * px if acc == 0 else 0.0)
    pata = ((0, 0, 1, 0)[f] * px if acc == 0 else 0.0)
    y_c = -0.36 + cab + 0.20 * acc
    z_c = 0.36 - 0.26 * acc

    def e(p):
        ds = [(elipsoide(p, (0, 0.14, -0.14), (0.84, 0.68, 0.52)), 1)]
        ds.append((elipsoide(p, (0, -0.16, -0.10), (0.92, 0.15, 0.58)), 4 if forma >= 1 else 1))
        # placas de la concha: de un hexágono a un escudo
        pl = mover(p, z=0.31)
        if forma == 0:
            ds.append((poligono(pl, hex_pts(0.20, 0, 0.36), 0.08, 0.02), 5))
        elif forma == 1:
            ds.append((poligono(pl, hex_pts(0.22, 0, 0.40), 0.08, 0.02), 5))
            for s in (-1, 1):
                ds.append((poligono(mover(p, z=0.19), hex_pts(0.17, s * 0.48, 0.20), 0.08, 0.02), 5))
        else:
            ds.append((poligono(pl, escudo_pts(0.40, 0, 0.45), 0.09, 0.02), 4))
            ds.append((poligono(mover(pl, z=0.05), escudo_pts(0.27, 0, 0.45), 0.08, 0.005), 5))
            for s in (-1, 1):
                ds.append((poligono(mover(p, z=0.15), hex_pts(0.15, s * 0.58, 0.14), 0.08, 0.02), 5))
                ds.append((cono_truncado(p, (s * 0.46, 0.66, -0.14), (s * 0.60, 0.96, -0.14), 0.09, 0.01), 5))
            ds.append((cono_truncado(p, (0, 0.76, -0.14), (0, 1.0, -0.14), 0.09, 0.01), 5))
        # cabeza y patas
        ds.append((esfera(p, (0, y_c, z_c), 0.45), 0))
        for s in (-1, 1):
            ds.append((elipsoide(p, (s * 0.22, y_c + 0.08, z_c + 0.34), (0.15, 0.185, 0.09)), 2))
            ds.append((elipsoide(p, (s * 0.64, -0.46 - pata, 0.16), (0.21, 0.15 - 0.03 * acc, 0.20)), 0))
        if acc == 0:
            ds.append((elipsoide(p, (0, y_c - 0.19, z_c + 0.40), (0.08, 0.03, 0.04)), 3))
        else:
            # el escudo que le da a tu nave: un arco de luz sobre la concha
            r = 1.02
            ds.append((poligono(mover(p, z=0.5), media_luna(0, -0.10, r, math.radians(30), math.radians(150), 0.12 + 0.08 * acc), 0.02, 0.006), 6))
            if acc >= 1:
                ds.append((poligono(mover(p, z=0.55), media_luna(0, -0.10, r - 0.02, math.radians(48), math.radians(132), 0.10), 0.02), 7))
        return ds

    return e


hoja_pet("mascota", mordisco, RP_MORDISCO)
hoja_pet("mascota_chispita", chispita, RP_CHISPITA, centro=(0, 0.02))
hoja_pet("mascota_imancito", imancito, RP_IMANCITO, centro=(0, -0.04))
hoja_pet("mascota_caparazon", caparazon, RP_CAPARAZON, centro=(0, 0.04))

if FILTRO == "":
    revisar()
print("listo")
