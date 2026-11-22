# -*- coding: utf-8 -*-
"""Modelos 3D del juego, escritos con formas simples.

Reglas para todos: contorno oscuro, luz arriba a la izquierda y NUCLEO ROJO = punto debil.
Los colores "clave" de la nave (solo rojo, solo verde o solo azul) los cambia un shader en
el juego: asi la pintura, la franja y la llama dependen de lo que tengas equipado.
"""
import random

import numpy as np

from sdf import (Rampa, capsula, caja, cilindro, cono_truncado, elipsoide, esfera, poligono,
                 renderizar, resta, rot_x, rot_y, rot_z, toro, union_suave)

R_CASCO = Rampa(["#1b1430", "#2e2352", "#4a3a80", "#6f5bb0", "#b6a6ee"])
R_BOCINA = Rampa(["#3a0f3d", "#6e1a5e", "#b02a7e", "#e64fa0", "#ffb0dc"])
R_ORO = Rampa(["#4a2a1a", "#8a5220", "#d08f2e", "#f5c84c", "#fff2a0"])
R_ACERO = Rampa(["#1e2433", "#3a4660", "#66788f", "#9fb3c4", "#e3eef5"])
R_NUCLEO = Rampa(["#7a0a2a", "#d01840", "#ff4a4a", "#ffb04a", "#fff4c0"], emisiva=True, curva=1.4)
R_CIAN = Rampa(["#157a9e", "#29c5e6", "#8ff0ff", "#ffffff"], emisiva=True, curva=1.0)
R_NEGRO = Rampa(["#0d0a18", "#1a1230", "#2a1a44", "#3a1f55", "#4a2566"], mate=True)
R_PANTALLA = Rampa(["#0e1a2e", "#0e1a2e", "#0e1a2e", "#0e1a2e"], emisiva=True)
R_OXIDO = Rampa(["#2a1410", "#54281a", "#8a4522", "#c47330", "#f0b060"], curva=0.95)
R_LATA = Rampa(["#20262e", "#3c4852", "#5f7078", "#8ea0a2", "#d4dcd2"], curva=0.95)
R_VERDE = Rampa(["#10301e", "#1c5a34", "#2f8f4c", "#5ccb6c", "#b8f5a8"])
R_VIDRIO = Rampa(["#0e3a55", "#157a9e", "#29c5e6", "#8ff0ff", "#ffffff"])
R_MOTOR = Rampa(["#b02a00", "#ff7a1a", "#ffd24a", "#fff8d0"], emisiva=True, curva=0.8)
R_AMARILLO = Rampa(["#3a2a08", "#7a5a10", "#c49a20", "#f5d040", "#fff6a8"])

# Colores clave de la nave. El shader los reemplaza en el juego.
R_CLAVE_CASCO = Rampa(["#280000", "#500000", "#780000", "#a00000", "#c80000"], curva=0.85)
R_CLAVE_FRANJA = Rampa(["#002800", "#005000", "#007800", "#00a000", "#00c800"], mate=True)
R_CLAVE_LLAMA = Rampa(["#000028", "#000050", "#000078", "#0000a0"], emisiva=True, curva=0.8)


# ---------------------------------------------------------------------------
# NAVE: cambia segun el cañon equipado
# ---------------------------------------------------------------------------
RAMPAS_NAVE = [R_CLAVE_CASCO, R_ACERO, R_VIDRIO, R_CLAVE_LLAMA, R_CLAVE_FRANJA, R_ORO]


def _canones(q, ds, arma):
    """q: punto reflejado (solo lado derecho). Agrega los cañones de cada arma."""
    if arma == "pistola":
        ds.append((capsula(q, (0.86, -0.62, -0.02), (0.86, -0.02, -0.02), 0.038), 1))
    elif arma == "escopeta":
        ds.append((capsula(q, (0.62, -0.42, 0.0), (0.62, 0.06, 0.0), 0.075), 1))
        ds.append((toro(q, (0.62, 0.06, 0.0), (0, 1, 0), 0.075, 0.03), 5))
        ds.append((capsula(q, (0.86, -0.62, -0.02), (0.86, -0.26, -0.02), 0.038), 1))
    elif arma == "railgun":
        ds.append((capsula(q, (0.86, -0.62, -0.02), (0.86, -0.20, -0.02), 0.03), 1))
    elif arma == "macro":
        ds.append((caja(q, (0.56, -0.28, 0.0), (0.11, 0.22, 0.09), 0.03), 1))
        for dx in (-0.055, 0.055):
            ds.append((capsula(q, (0.56 + dx, -0.10, 0.04), (0.56 + dx, 0.34, 0.04), 0.03), 1))
        ds.append((capsula(q, (0.86, -0.62, -0.02), (0.86, -0.30, -0.02), 0.03), 1))
    elif arma == "ping_pong":
        ds.append((esfera(q, (0.86, -0.20, 0.0), 0.15), 5))
        ds.append((esfera(q, (0.86, -0.20, 0.09), 0.08), 2))
    elif arma == "cohetes":
        ds.append((capsula(q, (0.60, -0.42, 0.0), (0.60, 0.08, 0.0), 0.10), 1))
        ds.append((esfera(q, (0.60, 0.13, 0.0), 0.085), 4))
        ds.append((capsula(q, (0.86, -0.62, -0.02), (0.86, -0.34, -0.02), 0.03), 1))


def nave(arma="pistola", banco=0.0, t=0.0):
    llama = 0.24 + 0.06 * np.sin(2 * np.pi * t * 2)

    def escena(p):
        p = rot_y(p, banco * 0.6)
        ds = []
        fus = cono_truncado(p, (0, -0.42, 0), (0, 0.48, 0.0), 0.235, 0.10)
        fus = union_suave(fus, cono_truncado(p, (0, 0.46, 0), (0, 0.90, 0.0), 0.10, 0.018), 0.05)
        ds.append((fus, 0))
        q = p.copy()
        q[..., 0] = np.abs(q[..., 0])
        q2 = rot_y(q, -0.30)
        ala = poligono(q2, [(0.10, 0.22), (0.86, -0.42), (0.86, -0.62), (0.52, -0.50), (0.10, -0.48)], 0.015, 0.03)
        ds.append((ala, 0))
        franja = poligono(q2 - np.array([0, 0, 0.035]), [(0.36, -0.15), (0.78, -0.47), (0.74, -0.53), (0.33, -0.25)], 0.012, 0.0)
        ds.append((franja, 4))
        _canones(q, ds, arma)
        ds.append((elipsoide(q, (0.20, -0.46, -0.03), (0.105, 0.24, 0.10)), 1))
        ds.append((elipsoide(q, (0.20, -0.74 - llama * 0.3, -0.03), (0.062, llama * 0.75, 0.05)), 3))
        ds.append((elipsoide(p, (0, 0.20, 0.13), (0.10, 0.25, 0.10)), 2))
        ds.append((elipsoide(p, (0, -0.72 - llama * 0.3, 0), (0.08, llama, 0.06)), 3))
        if arma == "railgun":
            for s in (-0.07, 0.07):
                ds.append((caja(p, (s, 0.72, 0.03), (0.022, 0.46, 0.02), 0.006), 5))
            ds.append((capsula(p, (0, 0.30, 0.03), (0, 1.12, 0.03), 0.012), 2))
        elif arma == "pistola":
            ds.append((capsula(p, (0, 0.76, 0.0), (0, 1.02, 0.0), 0.022), 1))
        return ds

    return escena


def render_nave(arma="pistola", banco=0.0, t=0.0, ancho=40):
    return renderizar(nave(arma, banco, t), RAMPAS_NAVE, ancho, encuadre=1.31, centro=(0, -0.02),
                      luz=(-0.55, 0.45, 0.75), oscuro_interior=False)


# ---------------------------------------------------------------------------
# ENEMIGOS DEL MUNDO 1
# ---------------------------------------------------------------------------
RAMPAS_BOT = [R_ACERO, R_CIAN, R_NUCLEO, R_NEGRO, R_MOTOR]


def bot(t=0.0):
    bob = 0.03 * np.sin(2 * np.pi * t)

    def escena(p):
        p = p - np.array([0, bob, 0])
        ds = [(caja(p, (0, 0.20, 0), (0.62, 0.44, 0.38), 0.15), 0),
              (caja(p, (0, 0.27, 0.34), (0.44, 0.16, 0.06), 0.05), 3)]
        for s in (-0.21, 0.21):
            ds.append((elipsoide(p, (s, 0.27, 0.39), (0.11, 0.09, 0.05)), 1))
        ds.append((caja(p, (0, -0.32, 0.0), (0.32, 0.16, 0.26), 0.06), 0))
        ds.append((esfera(p, (0, -0.34, 0.22), 0.11), 2))
        ds.append((capsula(p, (0, 0.62, 0), (0, 0.90, 0), 0.03), 0))
        ds.append((esfera(p, (0, 0.94, 0), 0.07), 2))
        for s in (-1, 1):
            ds.append((cilindro(p, (s * 0.60, 0.22, 0), (s * 0.78, 0.22, 0), 0.15), 0))
            ds.append((elipsoide(p, (s * 0.28, -0.58, 0), (0.06, 0.13 + 0.03 * np.sin(4 * np.pi * t), 0.05)), 4))
        return ds

    return escena


def render_bot(t=0.0, ancho=32):
    return renderizar(bot(t), RAMPAS_BOT, ancho, encuadre=1.08, centro=(0, 0.16), inclinacion=0.1)


RAMPAS_RABIOSO = [R_OXIDO, R_ACERO, R_NUCLEO, R_NEGRO, R_MOTOR]


def rabioso(t=0.0):
    giro = 2 * np.pi * t

    def escena(p):
        ds = []
        cuerpo = esfera(p, (0, 0.10, 0), 0.44)
        ds.append((cuerpo, 0))
        # pinchos de chatarra que giran
        q = rot_z(p - np.array([0, 0.10, 0]), giro / 4)
        for k in range(6):
            a = k * np.pi / 3
            c, s = np.cos(a), np.sin(a)
            ds.append((cono_truncado(q, (c * 0.34, s * 0.34, 0), (c * 0.82, s * 0.82, 0), 0.12, 0.012), 1))
        # ojo-nucleo enojado, mira hacia abajo
        ds.append((esfera(p, (0, -0.02, 0.32), 0.21), 2))
        q2 = p - np.array([0, 0.18, 0.47])
        ds.append((caja(rot_z(q2 - np.array([0.13, 0, 0]), 0.45), (0, 0, 0), (0.17, 0.035, 0.05), 0.01), 3))
        ds.append((caja(rot_z(q2 + np.array([0.13, 0, 0]), -0.45), (0, 0, 0), (0.17, 0.035, 0.05), 0.01), 3))
        ds.append((elipsoide(p, (0, 0.74, -0.05), (0.09, 0.15 + 0.04 * np.sin(4 * np.pi * t), 0.06)), 4))
        return ds

    return escena


def render_rabioso(t=0.0, ancho=32):
    return renderizar(rabioso(t), RAMPAS_RABIOSO, ancho, encuadre=1.02, centro=(0, 0.08), inclinacion=0.08)


RAMPAS_SPAMMER = [R_CASCO, R_BOCINA, R_ORO, R_ACERO, R_NUCLEO, R_CIAN, R_NEGRO, R_PANTALLA]
_C, _B, _O, _A, _N, _Y, _K, _S = range(8)


def spammer(t=0.0, disparo=0.0):
    bob = 0.03 * np.sin(2 * np.pi * t)
    balanceo = 0.12 * np.sin(2 * np.pi * t)
    pulso = 1.0 + 0.04 * np.sin(4 * np.pi * t) + 0.12 * disparo
    retro = 0.12 * disparo

    def escena(p):
        p = p - np.array([0, bob, 0])
        p = rot_z(p, balanceo * 0.3)
        ds = []
        cuerpo = elipsoide(p, (0, 0.36, -0.12), (0.56, 0.42, 0.40))
        for yy in (0.60, 0.48):
            cuerpo = resta(cuerpo, caja(p, (0, yy, 0.0), (0.75, 0.011, 0.8)))
        ds.append((cuerpo, _C))
        ds.append((caja(p, (0, 0.40, 0.20), (0.24, 0.115, 0.08), 0.02), _S))
        ds.append((resta(caja(p, (0, 0.40, 0.17), (0.28, 0.155, 0.08), 0.03),
                         caja(p, (0, 0.40, 0.25), (0.24, 0.115, 0.08), 0.02)), _A))
        a = (0, 0.20, 0.02 + retro * 0.3)
        b = (0, -0.34, 0.50 + retro)
        R2 = 0.60 * pulso
        exterior = cono_truncado(p, a, b, 0.16, R2)
        interior = cono_truncado(p, (0, 0.13, 0.09 + retro * 0.3), (0, -0.40, 0.56 + retro), 0.05, R2 - 0.065)
        ds.append((resta(exterior, interior), _B))
        eje = (0, -0.54, 0.48)
        ds.append((toro(p, b, eje, R2 - 0.012, 0.05), _O))
        ds.append((esfera(p, (0, -0.02, 0.20 + retro * 0.5), 0.27), _K))
        ds.append((toro(p, (0, -0.19, 0.35 + retro * 0.7), eje, 0.30, 0.016), _B))
        ds.append((esfera(p, (0, -0.10, 0.34 + retro * 0.7), 0.16 * (1 + 0.15 * disparo)), _N))
        for sx, alto, tip in ((-0.30, 1.05, 0.075), (0.30, 0.95, 0.065), (0.0, 1.14, 0.085)):
            tope = (sx * 1.45 + balanceo * 0.6, alto, -0.12)
            ds.append((capsula(p, (sx * 0.8, 0.66, -0.12), tope, 0.026), _A))
            ds.append((esfera(p, tope, tip), _Y))
        for s in (-1, 1):
            ds.append((caja(p, (s * 0.72, 0.30, -0.08), (0.16, 0.26, 0.15), 0.05), _C))
            ds.append((cilindro(p, (s * 0.72, 0.30, 0.03), (s * 0.72, 0.30, 0.09), 0.115), _A))
            ds.append((esfera(p, (s * 0.72, 0.30, 0.08), 0.07), _K))
            ds.append((capsula(p, (s * 0.72, 0.58, -0.08), (s * 0.86, 0.72, -0.08), 0.03), _A))
        return ds

    return escena


_EXCL = ["#.#.#", "#.#.#", "#.#.#", ".....", "#.#.#"]


def render_spammer(t=0.0, disparo=0.0, ancho=48):
    arr, cod = renderizar(spammer(t, disparo), RAMPAS_SPAMMER, ancho, encuadre=1.13,
                          centro=(0, 0.28), inclinacion=0.12, devolver_codigo=True)
    ys, xs = np.where((cod >= 0) & (cod // 16 == _S))
    if len(xs):
        cx, cy = (xs.min() + xs.max()) // 2, (ys.min() + ys.max()) // 2
        for j, f in enumerate(_EXCL):
            for i, ch in enumerate(f):
                if ch == "#":
                    x, y = cx - 2 + i, cy - 2 + j
                    if 0 <= y < arr.shape[0] and 0 <= x < arr.shape[1] and cod[y, x] // 16 == _S:
                        arr[y, x, :3] = (255, 90, 170)
    return arr


RAMPAS_SNIPER = [R_LATA, R_ACERO, R_NUCLEO, R_NEGRO, R_VERDE, R_CIAN]


def sniper(t=0.0, brillo=0.0):
    bob = 0.02 * np.sin(2 * np.pi * t)

    def escena(p):
        p = p - np.array([0, bob, 0])
        ds = [(elipsoide(p, (0, 0.34, -0.02), (0.46, 0.34, 0.34)), 0)]
        # capa de camuflaje hecha con restos
        random.seed(5)
        d = None
        for _ in range(16):
            a = random.uniform(-1.6, 1.6)
            x = np.sin(a) * 0.46
            y = 0.48 + np.cos(a) * 0.20 + random.uniform(-0.05, 0.05)
            z = 0.10 + random.uniform(-0.12, 0.08)
            di = esfera(p, (x, y, z), random.uniform(0.07, 0.11))
            d = di if d is None else np.minimum(d, di)
        ds.append((d, 4))
        # rifle que apunta al jugador
        ds.append((caja(p, (0, 0.06, 0.20), (0.11, 0.26, 0.09), 0.03), 1))
        ds.append((cilindro(p, (0, 0.0, 0.22), (0, -0.92, 0.24), 0.045), 1))
        ds.append((cilindro(p, (0, -0.84, 0.24), (0, -0.98, 0.24), 0.07), 1))
        ds.append((cilindro(p, (0.16, 0.20, 0.22), (0.16, -0.14, 0.22), 0.055), 1))
        # mira con brillo: es el aviso del disparo
        ds.append((esfera(p, (0.16, -0.16, 0.22), 0.05 + 0.05 * brillo), 5 if brillo > 0 else 3))
        ds.append((esfera(p, (0, 0.33, 0.30), 0.12), 2))
        for s in (-1, 1):
            ds.append((capsula(p, (s * 0.34, 0.14, 0), (s * 0.54, -0.28, -0.02), 0.04), 1))
        return ds

    return escena


def render_sniper(t=0.0, brillo=0.0, ancho=40):
    return renderizar(sniper(t, brillo), RAMPAS_SNIPER, ancho, encuadre=1.10, centro=(0, 0.02), inclinacion=0.05)


RAMPAS_COMPACTO = [R_OXIDO, R_LATA, R_NUCLEO, R_NEGRO, R_ORO]


def compacto(t=0.0):
    giro = 0.10 * np.sin(2 * np.pi * t)

    def escena(p):
        p = rot_z(p, giro)
        ds = []
        cubo = caja(p, (0, 0, 0), (0.70, 0.70, 0.50), 0.05)
        ds.append((cubo, 0))
        # placas aplastadas de distintos metales
        random.seed(3)
        for _ in range(9):
            x, y = random.uniform(-0.55, 0.55), random.uniform(-0.55, 0.55)
            if abs(x) < 0.25 and abs(y) < 0.25:
                continue
            q = rot_z(p - np.array([x, y, 0.50]), random.uniform(-0.6, 0.6))
            ds.append((caja(q, (0, 0, 0), (random.uniform(0.12, 0.26), random.uniform(0.06, 0.16), 0.04), 0.01), 1))
        for sx in (-0.60, 0.60):
            for sy in (-0.60, 0.60):
                ds.append((esfera(p, (sx, sy, 0.47), 0.05), 4))
        ds.append((toro(p, (0, 0, 0.50), (0, 0, 1), 0.27, 0.05), 3))
        ds.append((esfera(p, (0, 0, 0.42), 0.23), 2))
        return ds

    return escena


def render_compacto(t=0.0, ancho=48):
    return renderizar(compacto(t), RAMPAS_COMPACTO, ancho, encuadre=1.05, centro=(0, 0), inclinacion=0.12)


RAMPAS_REPARADOR = [R_VERDE, R_ACERO, R_NUCLEO, R_NEGRO, R_MOTOR, R_AMARILLO]


def reparador(t=0.0):
    bob = 0.03 * np.sin(2 * np.pi * t)
    brazo = 0.3 * np.sin(2 * np.pi * t)

    def escena(p):
        p = p - np.array([0, bob, 0])
        ds = [(elipsoide(p, (0, 0.12, 0), (0.46, 0.34, 0.34)), 0),
              (esfera(p, (0, 0.10, 0.28), 0.14), 2)]
        for s in (-1, 1):
            c = (s * 0.78, 0.30 + s * brazo * 0.3, 0.02)
            ds.append((capsula(p, (s * 0.36, 0.14, 0), c, 0.05), 1))
            ds.append((toro(p, c, (0, 0, 1), 0.12, 0.04), 5))
        ds.append((caja(p, (0, 0.52, 0), (0.10, 0.09, 0.08), 0.02), 1))
        for s in (-0.42, 0.42):
            ds.append((cilindro(p, (s * 0.6, 0.62, 0), (s, 0.62, 0), 0.02), 1))
        ds.append((elipsoide(p, (0, -0.32, 0), (0.08, 0.12 + 0.03 * np.sin(4 * np.pi * t), 0.06)), 4))
        return ds

    return escena


def render_reparador(t=0.0, ancho=32):
    return renderizar(reparador(t), RAMPAS_REPARADOR, ancho, encuadre=1.02, centro=(0, 0.12), inclinacion=0.08)


RAMPAS_GRUA = [R_AMARILLO, R_ACERO, R_NUCLEO, R_NEGRO, R_OXIDO]


def grua(t=0.0):
    gira = 0.14 * np.sin(2 * np.pi * t)

    def escena(p):
        ds = []
        # cabina
        ds.append((caja(p, (0, 0.46, 0), (0.56, 0.34, 0.34), 0.08), 0))
        ds.append((caja(p, (-0.14, 0.52, 0.30), (0.24, 0.14, 0.06), 0.02), 3))
        ds.append((caja(p, (0.28, 0.50, 0.30), (0.10, 0.17, 0.05), 0.02), 4))
        # orugas
        for s in (-1, 1):
            ds.append((caja(p, (s * 0.80, 0.42, 0), (0.18, 0.46, 0.20), 0.08), 1))
            for yy in (0.06, 0.26, 0.46, 0.66):
                ds.append((caja(p, (s * 0.98, yy, 0.05), (0.03, 0.05, 0.10), 0.01), 3))
        # brazo y electroiman, se balancean
        q = rot_z(p - np.array([0, 0.28, 0.12]), gira)
        ds.append((caja(q, (0, -0.45, 0), (0.09, 0.50, 0.08), 0.02), 0))
        for yy in (-0.15, -0.40, -0.65):
            ds.append((caja(q, (0, yy, 0.06), (0.05, 0.06, 0.05), 0.01), 3))
        ds.append((cilindro(q, (0, -0.96, 0), (0, -1.16, 0), 0.46), 1))
        ds.append((toro(q, (0, -1.16, 0), (0, 1, 0), 0.40, 0.05), 0))
        ds.append((esfera(q, (0, -1.05, 0.34), 0.20), 2))
        return ds

    return escena


def render_grua(t=0.0, ancho=96):
    return renderizar(grua(t), RAMPAS_GRUA, ancho, encuadre=1.42, centro=(0, -0.36), inclinacion=0.10, ss=2)


RAMPAS_JEFE = [R_OXIDO, R_ACERO, R_NUCLEO, R_NEGRO, R_AMARILLO, R_LATA, R_CIAN]


def compactador(apertura=0.0, t=0.0, enojo=0.0):
    """apertura 0 cerrado, 1 abierto del todo (se le ve el nucleo)."""
    bob = 0.015 * np.sin(2 * np.pi * t)

    def escena(p):
        p = p - np.array([0, bob, 0])
        ds = []
        # cuerpo superior: caja gigante remachada
        ds.append((caja(p, (0, 0.52, 0), (1.08, 0.50, 0.46), 0.06), 0))
        for sx in (-0.98, -0.5, 0.5, 0.98):
            for sy in (0.14, 0.92):
                ds.append((esfera(p, (sx, sy, 0.45), 0.035), 1))
        # visera y ojos de pantalla
        ds.append((caja(p, (0, 0.60, 0.42), (0.74, 0.20, 0.08), 0.03), 3))
        ang = 0.20 + 0.25 * enojo
        for s in (-1, 1):
            q = rot_z(p - np.array([s * 0.38, 0.60, 0.50]), -s * ang)
            ds.append((caja(q, (0, 0, 0), (0.24, 0.08 - 0.03 * enojo, 0.02), 0.012), 6))
        # chimeneas
        for s in (-1, 1):
            ds.append((cilindro(p, (s * 0.72, 1.0, -0.1), (s * 0.72, 1.32, -0.1), 0.11), 5))
            ds.append((toro(p, (s * 0.72, 1.32, -0.1), (0, 1, 0), 0.11, 0.03), 1))
        # pistones
        for s in (-1, 1):
            ds.append((cilindro(p, (s * 0.84, 0.10, 0.1), (s * (0.84 + 0.10 * apertura), -0.40, 0.1), 0.075), 1))
        # nucleo central, expuesto cuando abre
        ds.append((caja(p, (0, -0.10, 0.08), (0.42, 0.24, 0.26), 0.04), 3))
        ds.append((toro(p, (0, -0.16, 0.30), (0, 0, 1), 0.27, 0.05), 4))
        ds.append((esfera(p, (0, -0.16, 0.22), 0.25 + 0.03 * enojo), 2))
        # mandibulas de prensa
        sep = 0.08 + 0.62 * apertura
        for s in (-1, 1):
            cx = s * (0.30 + sep * 0.75)
            q = p - np.array([cx, -0.60, 0.1])
            ds.append((caja(q, (0, 0, 0), (0.46, 0.34, 0.36), 0.05), 5))
            # placa con franjas de peligro
            for k in range(4):
                yy = -0.24 + k * 0.16
                ds.append((caja(q, (s * -0.30, yy, 0.34), (0.11, 0.045, 0.03), 0.005), 4 if k % 2 == 0 else 3))
            # dientes hacia el centro
            for k in range(4):
                yy = -0.27 + k * 0.18
                ds.append((cono_truncado(q, (s * -0.42, yy, 0.05), (s * -0.68, yy, 0.05), 0.085, 0.01), 1))
        return ds

    return escena


def render_compactador(apertura=0.0, t=0.0, enojo=0.0, ancho=128):
    return renderizar(compactador(apertura, t, enojo), RAMPAS_JEFE, ancho, encuadre=1.52, centro=(0, 0.14),
                      inclinacion=0.10, ss=2)


# ---------------------------------------------------------------------------
# MASCOTA: tres formas. Va creciendo a medida que se come tus fusiones.
# ---------------------------------------------------------------------------
R_PELO = Rampa(["#4a3a6a", "#7a689c", "#ab9ac4", "#dccfe6", "#fff6ff"], mate=True, curva=0.8)
R_MANCHA = Rampa(["#2f2348", "#4a3a6a", "#6a5688", "#8d78aa", "#ab9ac4"], mate=True, curva=0.8)
R_OJO = Rampa(["#120c1e", "#120c1e", "#120c1e", "#1c1430", "#2a2048"], mate=True)
R_BOCA = Rampa(["#5a1a3a", "#9a2a50", "#d84a70", "#ff8aa0", "#ffb8c8"], mate=True)
R_DIENTE = Rampa(["#b8a8a8", "#d8cec8", "#f5eee8", "#ffffff", "#ffffff"], mate=True)
RAMPAS_PET = [R_PELO, R_MANCHA, R_OJO, R_BOCA, R_DIENTE]


def mascota(forma=0, t=0.0, boca=0.0):
    """forma: 0 cria, 1 joven, 2 adulto."""
    salto = 0.06 * abs(np.sin(2 * np.pi * t))
    oreja = 0.14 * np.sin(2 * np.pi * t)
    cola = 0.5 * np.sin(4 * np.pi * t)
    cabeza_r = (0.62, 0.56, 0.58)[forma]
    cuerpo_y = (-0.40, -0.46, -0.52)[forma]

    def escena(p):
        p = p - np.array([0, salto - 0.04, 0])
        ds = []
        cabeza = elipsoide(p, (0, 0.12, 0.02), (cabeza_r, cabeza_r * 0.86, cabeza_r * 0.86))
        cuerpo = elipsoide(p, (0, cuerpo_y, -0.08), (0.46 + 0.06 * forma, 0.40 + 0.04 * forma, 0.40))
        ds.append((union_suave(cabeza, cuerpo, 0.10), 0))
        # orejas caidas
        for s in (-1, 1):
            q = rot_z(p - np.array([s * (cabeza_r - 0.04), 0.32, 0]), s * (-0.45 + oreja * s))
            ds.append((elipsoide(q, (s * 0.06, -0.15, 0), (0.17, 0.33, 0.13)), 1))
        # patitas
        for s in (-1, 1):
            ds.append((elipsoide(p, (s * 0.26, cuerpo_y - 0.32 - 0.04 * forma, 0.14), (0.14, 0.11, 0.14)), 0))
        # cola
        q = rot_z(p - np.array([0.40, cuerpo_y + 0.05, -0.15]), -0.7 + cola * 0.5)
        ds.append((elipsoide(q, (0.14, 0, 0), (0.22, 0.08, 0.08)), 1))
        # manchas (crecen con la forma)
        ds.append((elipsoide(p, (-0.28, 0.42, 0.40), (0.18 + 0.05 * forma, 0.12 + 0.04 * forma, 0.10)), 1))
        # ojos enormes
        for s in (-1, 1):
            ds.append((elipsoide(p, (s * 0.25, 0.14, 0.42 + 0.03 * forma), (0.15, 0.185, 0.12)), 2))
        # boca: en la adulta asoman dientes
        abre = boca
        if abre > 0.05 or forma == 2:
            alto = 0.04 + 0.13 * abre + (0.03 if forma == 2 else 0.0)
            ds.append((elipsoide(p, (0, -0.14, 0.52), (0.15 + 0.08 * abre, alto, 0.06)), 3))
            if forma >= 1:
                for s in (-1, 1):
                    ds.append((cono_truncado(p, (s * 0.09, -0.12 + alto * 0.5, 0.56), (s * 0.09, -0.18, 0.57), 0.035, 0.005), 4))
        else:
            ds.append((elipsoide(p, (0, -0.13, 0.50), (0.07, 0.03, 0.04)), 3))
        return ds

    return escena


def render_mascota(forma=0, t=0.0, boca=0.0, ancho=24):
    arr, cod = renderizar(mascota(forma, t, boca), RAMPAS_PET, ancho, encuadre=1.08, centro=(0, -0.18),
                          inclinacion=0.05, devolver_codigo=True, luz=(-0.45, 0.75, 0.75), oscuro_interior=False)
    # brillo en los ojos: un pixel blanco que los hace vivos
    ys, xs = np.where((cod >= 0) & (cod // 16 == 2))
    if len(xs):
        medio = ancho / 2
        for lado in (xs < medio, xs >= medio):
            if lado.any():
                x0, y0 = xs[lado].min(), ys[lado].min()
                extra = 1 if ancho >= 30 else 0
                arr[y0 + 1, x0 + 1, :3] = (255, 255, 255)
                if extra:
                    arr[y0 + 1, x0 + 2, :3] = (255, 255, 255)
                    arr[y0 + 2, x0 + 1, :3] = (255, 255, 255)
    return arr
