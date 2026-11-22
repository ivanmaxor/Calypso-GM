# -*- coding: utf-8 -*-
"""Efectos de sonido retro con el metodo de sfxr (Tomas Pettersson), escrito en numpy.

Cada efecto se define con parametros: forma de onda, envolvente, barrido de tono y filtros.
No puedo oirlos: reviso que no saturen y que terminen en silencio, pero solo tu oido dice si
suenan bien. Se ajustan cambiando estos numeros.

Uso: python generar_sfx.py <carpeta_salida>
"""
import os
import sys
import wave

import numpy as np

SR = 44100
rng = np.random.default_rng(7)


def sintetizar(onda="cuadrada", f0=440.0, f1=None, ataque=0.002, sostén=0.05, caida=0.12, cuadrada=0.5,
               vibrato=0.0, vib_vel=6.0, arpegio=None, ruido_mezcla=0.0, volumen=0.6, pasa_bajos=None,
               sub=0.0, pegada=0.0):
    n = int((ataque + sostén + caida) * SR)
    t = np.arange(n) / SR
    env = np.ones(n)
    a = max(int(ataque * SR), 1)
    env[:a] = np.linspace(0, 1, a)
    s = int(sostén * SR)
    d = n - a - s
    if d > 0:
        env[a + s:] = np.linspace(1, 0, d) ** 1.6
    if pegada:
        env += pegada * np.exp(-t * 60)
    f1 = f0 if f1 is None else f1
    frec = f0 * (f1 / f0) ** (t / t[-1])
    if vibrato:
        frec *= 1 + vibrato * np.sin(2 * np.pi * vib_vel * t)
    if arpegio:
        for inst, mult in arpegio:
            frec = np.where(t >= inst, frec * mult, frec)
    fase = np.cumsum(frec) / SR
    if onda == "cuadrada":
        y = np.where((fase % 1.0) < cuadrada, 1.0, -1.0)
    elif onda == "sierra":
        y = 2 * (fase % 1.0) - 1
    elif onda == "seno":
        y = np.sin(2 * np.pi * fase)
    elif onda == "triangulo":
        y = 2 * np.abs(2 * (fase % 1.0) - 1) - 1
    elif onda == "ruido":
        # ruido escalonado: la frecuencia cambia su "grano", como en sfxr
        pasos = np.floor(fase * 2).astype(int)
        tabla = rng.uniform(-1, 1, pasos.max() + 2)
        y = tabla[pasos]
    if ruido_mezcla:
        y = (1 - ruido_mezcla) * y + ruido_mezcla * rng.uniform(-1, 1, n)
    if sub:
        y = y + sub * np.sin(2 * np.pi * np.cumsum(frec * 0.5) / SR)
    y = y * env
    if pasa_bajos:
        # filtro de un polo, con frecuencia que puede caer en el tiempo
        fc0, fc1 = pasa_bajos
        fc = fc0 * (fc1 / fc0) ** (t / t[-1])
        k = 1 - np.exp(-2 * np.pi * fc / SR)
        z = 0.0
        sal = np.zeros(n)
        for i in range(n):
            z += k[i] * (y[i] - z)
            sal[i] = z
        y = sal
    return y * volumen


def mezcla(*partes):
    n = max(len(p) for p in partes)
    y = np.zeros(n)
    for p in partes:
        y[:len(p)] += p
    return y


def retraso(y, seg):
    return np.concatenate([np.zeros(int(seg * SR)), y])


def eco(y, seg=0.09, ganancia=0.35, veces=3):
    partes = [y]
    for i in range(1, veces + 1):
        partes.append(retraso(y * ganancia ** i, seg * i))
    return mezcla(*partes)


def nota(sem, base=440.0):
    return base * 2 ** (sem / 12)


def guardar(carpeta, nombre, y):
    y = np.asarray(y, dtype=np.float64)
    fade = min(int(0.004 * SR), len(y) // 4)
    if fade:
        y[-fade:] *= np.linspace(1, 0, fade)
    pico = np.abs(y).max()
    if pico > 0.95:
        y = y * (0.95 / pico)
    datos = (y * 32767).astype(np.int16).tobytes()
    with wave.open(os.path.join(carpeta, nombre + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(datos)
    rms = float(np.sqrt((y ** 2).mean()))
    print(f"{nombre:16} {len(y) / SR:5.2f}s pico {np.abs(y).max():.2f} rms {rms:.2f} fin {abs(y[-1]):.3f}")


def main():
    d = sys.argv[1]
    os.makedirs(d, exist_ok=True)

    # disparos: cortos y suaves porque suenan todo el tiempo
    guardar(d, "disparo", sintetizar("cuadrada", 1040, 360, 0.001, 0.008, 0.055, cuadrada=0.25, volumen=0.28, pasa_bajos=(7000, 2000)))
    guardar(d, "disparo_grueso", mezcla(
        sintetizar("ruido", 3200, 500, 0.001, 0.015, 0.11, volumen=0.34, pasa_bajos=(6000, 1000)),
        sintetizar("cuadrada", 420, 110, 0.001, 0.02, 0.09, volumen=0.28, pasa_bajos=(3000, 700))))
    guardar(d, "disparo_riel", mezcla(
        sintetizar("sierra", 1900, 170, 0.001, 0.05, 0.22, volumen=0.42, pasa_bajos=(9000, 900)),
        sintetizar("seno", 90, 44, 0.001, 0.06, 0.18, volumen=0.55)))
    guardar(d, "disparo_cohete", sintetizar("ruido", 700, 2600, 0.01, 0.07, 0.12, volumen=0.36, pasa_bajos=(3500, 2500)))

    # impactos y muertes
    guardar(d, "impacto", sintetizar("cuadrada", 720, 300, 0.001, 0.004, 0.035, cuadrada=0.5, volumen=0.22, pasa_bajos=(5000, 1500)))
    guardar(d, "kill", mezcla(
        sintetizar("ruido", 2100, 180, 0.001, 0.02, 0.17, volumen=0.6, pasa_bajos=(6000, 700)),
        sintetizar("seno", 170, 48, 0.001, 0.03, 0.13, volumen=0.55)))
    guardar(d, "kill_grande", mezcla(
        sintetizar("ruido", 1500, 70, 0.001, 0.08, 0.55, volumen=0.8, pasa_bajos=(5000, 220)),
        sintetizar("seno", 110, 30, 0.001, 0.12, 0.42, volumen=0.8)))
    guardar(d, "kill_jefe", eco(mezcla(
        sintetizar("ruido", 1100, 40, 0.001, 0.25, 1.3, volumen=0.85, pasa_bajos=(4000, 130)),
        sintetizar("seno", 82, 24, 0.001, 0.3, 1.1, volumen=0.85)), 0.16, 0.34, 3))

    # roce, bits, curacion
    guardar(d, "roce", sintetizar("cuadrada", 3200, 4200, 0.001, 0.004, 0.028, cuadrada=0.12, volumen=0.17))
    guardar(d, "bit", sintetizar("cuadrada", nota(12), nota(19), 0.001, 0.012, 0.05, cuadrada=0.5, volumen=0.22))
    guardar(d, "pizza", mezcla(
        sintetizar("triangulo", nota(7), None, 0.002, 0.04, 0.05, volumen=0.4),
        retraso(sintetizar("triangulo", nota(12), None, 0.002, 0.04, 0.05, volumen=0.4), 0.07),
        retraso(sintetizar("triangulo", nota(16), None, 0.002, 0.08, 0.16, volumen=0.4), 0.14)))
    guardar(d, "nam", mezcla(
        sintetizar("cuadrada", 520, 180, 0.001, 0.02, 0.05, volumen=0.3, pasa_bajos=(3000, 900)),
        retraso(sintetizar("triangulo", 900, 1500, 0.001, 0.02, 0.05, volumen=0.3), 0.07)))

    # subir de nivel: arpegio mayor
    guardar(d, "nivel", eco(mezcla(*[
        retraso(sintetizar("cuadrada", nota(s), None, 0.002, 0.05, 0.12, cuadrada=0.4, volumen=0.3), i * 0.065)
        for i, s in enumerate((0, 4, 7, 12, 16))]), 0.1, 0.25, 2))
    guardar(d, "carta", sintetizar("cuadrada", nota(12), nota(24), 0.001, 0.02, 0.08, cuadrada=0.4, volumen=0.3))
    guardar(d, "racha", sintetizar("cuadrada", nota(5), nota(12), 0.001, 0.05, 0.13, cuadrada=0.25, volumen=0.3))

    # jugador
    guardar(d, "dash", sintetizar("ruido", 900, 4200, 0.003, 0.03, 0.10, volumen=0.3, pasa_bajos=(4000, 7000)))
    guardar(d, "dano", mezcla(
        sintetizar("sierra", 400, 70, 0.001, 0.05, 0.26, volumen=0.55, pasa_bajos=(3500, 500)),
        sintetizar("ruido", 1500, 200, 0.001, 0.03, 0.14, volumen=0.45, pasa_bajos=(6000, 1000))))
    # corazon roto: quiebre seco con trozos de vidrio
    vidrio = [retraso(sintetizar("seno", nota(rng.integers(24, 38)), None, 0.0005, 0.005, 0.06, volumen=0.2), 0.03 + i * 0.024) for i in range(8)]
    guardar(d, "corazon_roto", mezcla(
        sintetizar("ruido", 3800, 900, 0.0005, 0.012, 0.09, volumen=0.65, pasa_bajos=(9000, 2500)),
        sintetizar("seno", 200, 60, 0.001, 0.05, 0.25, volumen=0.55), *vidrio))
    guardar(d, "muerte", eco(mezcla(
        sintetizar("sierra", 620, 34, 0.001, 0.3, 0.9, volumen=0.6, pasa_bajos=(3000, 150)),
        sintetizar("ruido", 800, 60, 0.001, 0.25, 0.8, volumen=0.55, pasa_bajos=(3000, 200))), 0.14, 0.3, 2))

    # desync
    guardar(d, "desync_entra", mezcla(
        sintetizar("sierra", 980, 58, 0.002, 0.34, 0.34, volumen=0.48, pasa_bajos=(6000, 280)),
        sintetizar("seno", 200, 40, 0.002, 0.3, 0.3, volumen=0.5)))
    guardar(d, "desync_tick", sintetizar("cuadrada", 1500, 1100, 0.001, 0.002, 0.016, cuadrada=0.5, volumen=0.13, pasa_bajos=(2500, 1400)))
    guardar(d, "reconectar", mezcla(
        sintetizar("seno", 60, 150, 0.08, 0.1, 0.1, volumen=0.3),
        sintetizar("cuadrada", 180, 900, 0.14, 0.04, 0.06, cuadrada=0.5, volumen=0.14, pasa_bajos=(1500, 5000))))
    # nota de la cascada: el juego le sube el tono en escala con pitch_scale
    guardar(d, "cascada", mezcla(
        sintetizar("cuadrada", nota(0), None, 0.001, 0.03, 0.14, cuadrada=0.4, volumen=0.34),
        sintetizar("ruido", 2200, 400, 0.001, 0.015, 0.07, volumen=0.3, pasa_bajos=(5000, 1000))))
    # final de la cascada: caida de bajo y acorde que resuelve
    guardar(d, "ace", eco(mezcla(
        sintetizar("seno", 150, 34, 0.002, 0.22, 0.95, volumen=0.85),
        sintetizar("ruido", 900, 100, 0.001, 0.05, 0.45, volumen=0.45, pasa_bajos=(5000, 400)),
        *[sintetizar("cuadrada", nota(s), None, 0.003, 0.26, 0.5, cuadrada=0.4, volumen=0.15) for s in (0, 7, 12, 16)]), 0.13, 0.28, 2))

    # jefes
    guardar(d, "aviso_jefe", mezcla(*[
        retraso(sintetizar("sierra", 220 if i % 2 == 0 else 165, None, 0.005, 0.2, 0.08, volumen=0.34, pasa_bajos=(2200, 1500)), i * 0.3)
        for i in range(5)]))
    guardar(d, "fase_jefe", eco(mezcla(
        sintetizar("seno", 95, 42, 0.001, 0.14, 0.5, volumen=0.85),
        sintetizar("ruido", 1800, 300, 0.001, 0.04, 0.25, volumen=0.5, pasa_bajos=(6000, 700))), 0.12, 0.28, 2))
    guardar(d, "aviso", sintetizar("cuadrada", 880, None, 0.002, 0.05, 0.03, cuadrada=0.5, volumen=0.2))

    # interfaz
    guardar(d, "ui_mover", sintetizar("cuadrada", 880, None, 0.001, 0.012, 0.02, cuadrada=0.5, volumen=0.16))
    guardar(d, "ui_ok", mezcla(
        sintetizar("cuadrada", nota(7), None, 0.001, 0.025, 0.03, cuadrada=0.4, volumen=0.24),
        retraso(sintetizar("cuadrada", nota(12), None, 0.001, 0.03, 0.07, cuadrada=0.4, volumen=0.24), 0.055)))
    guardar(d, "ui_no", sintetizar("cuadrada", 210, 150, 0.001, 0.05, 0.05, cuadrada=0.5, volumen=0.26))

    # botin: un sonido por rareza, cada vez mas grande
    for i, (notas, dur, vol) in enumerate((
            ((0, 7), 0.05, 0.22), ((0, 4, 7), 0.05, 0.25), ((0, 4, 7, 12), 0.055, 0.28),
            ((0, 3, 7, 12, 15), 0.06, 0.3), ((0, 4, 7, 12, 16, 19), 0.065, 0.32), ((0, 4, 7, 12, 16, 19, 24, 28), 0.07, 0.34))):
        partes = [retraso(sintetizar("cuadrada", nota(s), None, 0.001, dur, 0.1 + i * 0.02, cuadrada=0.4, volumen=vol), k * (0.055 + 0.004 * i)) for k, s in enumerate(notas)]
        if i >= 4:
            partes.append(sintetizar("seno", 110, 40, 0.001, 0.2, 0.5, volumen=0.55))
        y = mezcla(*partes)
        guardar(d, f"botin_{i}", eco(y, 0.11, 0.24 + i * 0.03, 2))
    guardar(d, "fusion", mezcla(
        sintetizar("seno", 180, 900, 0.03, 0.2, 0.05, volumen=0.3),
        sintetizar("cuadrada", 180, 900, 0.03, 0.2, 0.05, cuadrada=0.3, volumen=0.14, pasa_bajos=(1500, 5000))))
    guardar(d, "mejora", mezcla(
        sintetizar("cuadrada", nota(5), None, 0.001, 0.03, 0.04, cuadrada=0.4, volumen=0.24),
        retraso(sintetizar("cuadrada", nota(9), None, 0.001, 0.03, 0.04, cuadrada=0.4, volumen=0.24), 0.05),
        retraso(sintetizar("cuadrada", nota(12), None, 0.001, 0.04, 0.09, cuadrada=0.4, volumen=0.24), 0.1)))

    # latido cuando queda poca vida
    guardar(d, "latido", mezcla(
        sintetizar("seno", 72, 48, 0.002, 0.05, 0.10, volumen=0.75),
        retraso(sintetizar("seno", 62, 42, 0.002, 0.05, 0.13, volumen=0.6), 0.17)))
    # las voces de Don Tuerca y Calypso ahora salen de generar_voz.py
    guardar(d, "estrella", eco(mezcla(
        sintetizar("triangulo", nota(12), nota(19), 0.001, 0.05, 0.16, volumen=0.5),
        sintetizar("cuadrada", nota(24), None, 0.001, 0.03, 0.09, cuadrada=0.25, volumen=0.14)), 0.09, 0.28, 2))
    guardar(d, "desbloqueo", eco(mezcla(*[
        retraso(sintetizar("cuadrada", nota(s), None, 0.002, 0.08, 0.22, cuadrada=0.4, volumen=0.3), k * 0.09)
        for k, s in enumerate((0, 4, 7, 12, 16, 19, 24))] + [sintetizar("seno", 130, 60, 0.002, 0.3, 0.5, volumen=0.5)]), 0.12, 0.3, 2))
    guardar(d, "nodo", sintetizar("triangulo", nota(7), nota(12), 0.002, 0.03, 0.08, volumen=0.4))


if __name__ == "__main__":
    main()
