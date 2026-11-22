# -*- coding: utf-8 -*-
"""Voces de Don Tuerca y Calypso: sílabas sintetizadas con formantes, escrito en numpy.

Don Tuerca balbucea como un viejo cascarrabias al estilo de Dave el Loco: voz aguda y rasposa que
tiembla, vocales claras y mucho sube y baja de tono. Calypso es un robot seco: tono plano y más baja.

Cada sílaba es un WAV corto. Sonido.voz() las encadena por tiempo real y les varía el tono, así que
aquí solo se fabrica el material. No puedo oírlas: reviso nivel y formantes con números; lo gracioso
lo decide el oído. Se ajustan cambiando estas tablas.

Uso: python generar_voz.py <carpeta_salida>
"""
import os
import sys
import wave

import numpy as np

SR = 44100
rng = np.random.default_rng(23)

# F1, F2, F3 y F4 de cada vocal (voz aguda, valores medios del español)
VOCALES = {
    "a": (820, 1320, 2700, 3700),
    "e": (500, 2050, 2800, 3800),
    "i": (320, 2500, 3200, 4000),
    "o": (520, 940, 2650, 3700),
    "u": (350, 760, 2600, 3600),
}
ANCHOS = (70, 95, 150, 200)

# Consonante de entrada: de dónde parten F1, F2 y F3, cuánto dura en segundos, cuánto suena mientras
# dura y el ruido de la explosión (frecuencia y volumen; 0 si no explota).
CONSONANTES = {
    "w": ((300, 650, 2200), 0.055, 0.55, 0, 0.0),
    "b": ((250, 900, 2200), 0.022, 0.10, 1100, 0.25),
    "p": ((250, 900, 2200), 0.030, 0.00, 1100, 0.55),
    "m": ((260, 1000, 2200), 0.060, 0.32, 0, 0.0),
    "d": ((260, 1750, 2700), 0.020, 0.10, 3800, 0.30),
    "t": ((260, 1750, 2700), 0.028, 0.00, 4500, 0.55),
    "n": ((260, 1650, 2600), 0.055, 0.30, 0, 0.0),
    "g": ((260, 1900, 2300), 0.024, 0.12, 2100, 0.35),
    "k": ((260, 1900, 2300), 0.030, 0.00, 2300, 0.60),
    "y": ((290, 2350, 3000), 0.050, 0.45, 0, 0.0),
    "r": ((320, 1500, 2300), 0.018, 0.30, 0, 0.0),
    "l": ((320, 1200, 2700), 0.040, 0.50, 0, 0.0),
    "s": ((400, 1700, 2800), 0.060, 0.00, 5500, 0.45),
}


def resonar(x, f, ancho):
    """Filtro de dos polos con frecuencia que puede variar en el tiempo y ganancia 1 en continua."""
    f = np.broadcast_to(np.asarray(f, dtype=np.float64), x.shape)
    r = np.exp(-np.pi * ancho / SR)
    c2 = r * r
    c1 = -2 * r * np.cos(2 * np.pi * f / SR)
    g = 1 + c1 + c2
    sal = np.zeros_like(x)
    z1 = z2 = 0.0
    for i in range(len(x)):
        v = g[i] * x[i] - c1[i] * z1 - c2 * z2
        sal[i] = v
        z2 = z1
        z1 = v
    return sal


def banda(x, f, ancho):
    """Deja pasar solo una banda: el resonador normalizado en su pico."""
    y = resonar(x, f, ancho)
    return y * (ancho / f) * 1.2


def contorno_tono(forma, n):
    """Cómo se mueve el tono dentro de la sílaba, como multiplicador."""
    u = np.linspace(0, 1, n)
    if forma == "sube":
        return 0.88 + 0.26 * u ** 1.3
    if forma == "baja":
        return 1.14 - 0.30 * u ** 0.9
    if forma == "pico":
        return 0.90 + 0.30 * np.sin(np.pi * u) ** 1.2
    if forma == "valle":
        return 1.10 - 0.22 * np.sin(np.pi * u)
    return np.ones(n)


def fuente_viejo(f0, temblor=0.035, vel_temblor=8.0, doblez=0.25, soplo=0.05):
    """Cuerdas vocales de viejo: tiemblan, raspan y dejan pasar aire."""
    n = len(f0)
    t = np.arange(n) / SR
    fase_temblor = rng.uniform(0, 6.28)
    f = f0 * (1 + temblor * np.sin(2 * np.pi * vel_temblor * t + fase_temblor))
    # un pequeño desorden del tono, como una voz gastada
    f = f * (1 + 0.012 * np.cumsum(rng.normal(0, 1, n)) / np.sqrt(n))
    fase = 2 * np.pi * np.cumsum(f) / SR
    y = np.zeros(n)
    for k in range(1, 46):
        y += (k * f < 9000) * np.sin(k * fase) / k ** 0.75
    # raspa: los golpes de glotis se alternan fuerte y débil, lo que agrega un tono a la mitad
    y *= 1 + doblez * np.sign(np.sin(fase / 2))
    pulso = (0.5 + 0.5 * np.sin(fase)) ** 3
    y += soplo * pulso * rng.normal(0, 1, n)
    return y * (1 + 0.12 * np.sin(2 * np.pi * vel_temblor * t + fase_temblor + 1.0))


def fuente_robot(f0):
    """Pulso rígido: sin temblor ni aire. Solo escalones de tono."""
    fase = 2 * np.pi * np.cumsum(f0) / SR
    y = np.zeros(len(f0))
    for k in range(1, 70):
        # pulso cuadrado del 30 %: armónicos con la forma de su espectro
        y += (k * f0 < 9000) * np.sin(k * np.pi * 0.3) / k * np.cos(k * fase)
    return y


def silaba(consonante, vocal, f0_base, forma, dur_vocal, fuente, cola=0.035, escala=1.0):
    """Arma una sílaba: consonante de entrada, deslizamiento hacia la vocal y final suave."""
    locus, t_c, amp_c, f_ruido, vol_ruido = CONSONANTES[consonante]
    n_c = int(t_c * SR)
    n_v = int(dur_vocal * SR)
    n_cola = int(cola * SR)
    n = n_c + n_v + n_cola
    meta = np.array(VOCALES[vocal], dtype=np.float64) * escala
    inicio = np.array(tuple(locus) + (meta[3],), dtype=np.float64)
    # los formantes viajan de la consonante a la vocal en unos 45 ms
    u = np.clip((np.arange(n) - n_c * 0.4) / (0.045 * SR), 0, 1)
    u = u * u * (3 - 2 * u)
    formantes = inicio[None, :] + (meta - inicio)[None, :] * u[:, None]
    # envolvente: casi nada durante el cierre, abre en 12 ms, cae al final
    env = np.full(n, amp_c, dtype=np.float64)
    a = int(0.012 * SR)
    env[n_c:n_c + a] = np.linspace(max(amp_c, 0.0), 1.0, a)
    env[n_c + a:] = 1.0
    env[-n_cola:] *= np.linspace(1, 0, n_cola) ** 1.5
    if amp_c == 0.0:
        env[:n_c] = 0.0
    else:
        ini = int(0.006 * SR)
        env[:ini] *= np.linspace(0, 1, ini)
    f0 = f0_base * contorno_tono(forma, n)
    y = fuente(f0)
    for j in range(4):
        y = resonar(y, formantes[:, j], ANCHOS[j])
    y = y * env
    if vol_ruido > 0:
        # explosión o siseo de la consonante, justo antes de abrir la vocal
        largo = int((0.012 if consonante != "s" else t_c) * SR)
        ruido = rng.normal(0, 1, largo)
        ruido = banda(ruido, f_ruido, f_ruido * 0.5) * np.linspace(1, 0.15, largo)
        ruido = ruido / (np.abs(ruido).max() + 1e-9) * np.abs(y).max() * vol_ruido
        ini = max(n_c - largo + int(0.004 * SR), 0)
        y[ini:ini + largo] += ruido[:len(y[ini:ini + largo])]
    return y


def agudos(y, corte):
    """Lo que queda sobre la frecuencia de corte: filtro de un polo restado de la señal."""
    k = 1 - np.exp(-2 * np.pi * corte / SR)
    z = 0.0
    sal = np.zeros_like(y)
    for i in range(len(y)):
        z += k * (y[i] - z)
        sal[i] = y[i] - z
    return sal


def terminar(y, rms_meta, empuje, presencia=2.2):
    """Le da cuerpo: sube todo lo que está sobre 1.5 kHz para que corte la música y satura suave para subir el nivel."""
    y = y - resonar(y, 90.0, 120.0)
    y = y + presencia * agudos(y, 1500.0)
    y = y / (np.abs(y).max() + 1e-9)
    y = np.tanh(y * empuje) / np.tanh(empuje)
    # ajusta el nivel medido en la parte que suena y cuida el pico
    v = int(0.01 * SR)
    trozos = np.array([np.sqrt((y[i:i + v] ** 2).mean()) for i in range(0, len(y) - v, v)])
    activo = trozos[trozos > np.abs(y).max() * 0.1]
    rms = float(np.sqrt((activo ** 2).mean()))
    y = y * (10 ** (rms_meta / 20) / rms)
    pico = np.abs(y).max()
    if pico > 0.95:
        y = y * 0.95 / pico
    # sin clics al principio ni al final
    f = int(0.002 * SR)
    y[:f] *= np.linspace(0, 1, f)
    y[-f:] *= np.linspace(1, 0, f)
    return y


def guardar(carpeta, nombre, y):
    datos = (np.clip(y, -1, 1) * 32767).astype(np.int16).tobytes()
    with wave.open(os.path.join(carpeta, nombre + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(datos)
    rms = float(np.sqrt((y ** 2).mean()))
    print(f"{nombre:10} {len(y) / SR:5.3f}s pico {np.abs(y).max():.2f} rms {20 * np.log10(rms):6.1f} dB")


# Don Tuerca: consonante, vocal, tono base en Hz, forma del tono, largo de la vocal en segundos
TUERCA = (
    ("w", "a", 225, "pico", 0.100),
    ("b", "a", 250, "baja", 0.085),
    ("b", "o", 205, "sube", 0.095),
    ("w", "o", 190, "baja", 0.115),
    ("g", "a", 270, "pico", 0.080),
    ("g", "o", 215, "valle", 0.095),
    ("d", "a", 240, "sube", 0.085),
    ("d", "e", 260, "baja", 0.080),
    ("m", "e", 235, "pico", 0.075),
    ("m", "a", 200, "baja", 0.095),
    ("w", "i", 290, "baja", 0.075),
    ("b", "i", 305, "sube", 0.070),
    ("y", "a", 255, "valle", 0.090),
    ("y", "o", 220, "pico", 0.090),
    ("b", "u", 180, "sube", 0.100),
    ("p", "a", 245, "baja", 0.080),
)

# Calypso: consonante, vocal y escalón de tono en Hz (siempre plano)
CALYPSO = (
    ("t", "e", 124),
    ("k", "a", 124),
    ("d", "o", 117),
    ("n", "e", 131),
    ("r", "i", 131),
    ("l", "o", 117),
    ("s", "a", 124),
    ("m", "u", 110),
)


def main():
    d = sys.argv[1]
    os.makedirs(d, exist_ok=True)

    for i, (c, v, f0, forma, dur) in enumerate(TUERCA):
        y = silaba(c, v, f0, forma, dur, fuente_viejo)
        guardar(d, f"voz_{i}", terminar(y, -10.0, 1.9))

    for i, (c, v, f0) in enumerate(CALYPSO):
        y = silaba(c, v, f0, "plano", 0.085, lambda f: fuente_robot(f), cola=0.012, escala=1.04)
        # timbre metálico: un poco de modulación en anillo y menos resolución, sin tapar la vocal
        t = np.arange(len(y)) / SR
        y = y * (0.72 + 0.28 * np.sign(np.sin(2 * np.pi * 62.0 * t)))
        paso = 2
        y = np.repeat(y[::paso], paso)[:len(y)]
        guardar(d, f"voz_ia_{i}", terminar(y, -13.5, 1.3, presencia=2.0))


if __name__ == "__main__":
    main()
