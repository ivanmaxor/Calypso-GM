# -*- coding: utf-8 -*-
"""Prepara la música nueva: recorta, recodifica a MP3 y mide el volumen de cada tema.

Las obras se bajan a mano de las URL anotadas en juego/audio/musica/LICENCIAS_MUSICA.txt, cada álbum en
su propia carpeta dentro de <descargas>. Este script no baja nada ni ejecuta nada de esas carpetas.
Necesita un ffmpeg (por ejemplo: pip install --target <carpeta> imageio-ffmpeg).

Mide con el filtro ebur128 y escribe las filas listas para las tablas de nucleo/sonido.gd: cada ganancia
lleva el tema a -16 LUFS (los de jefe a -15, para que se sientan más grandes).

Uso: python preparar_musica.py <ffmpeg.exe> <descargas> <carpeta_musica>
"""
import os
import re
import subprocess
import sys

CALIDAD_VBR = "4"  # calidad de LAME: unos 165 kbps en promedio, varía con la densidad del tema
META_TEMA = -16.0
META_JEFE = -15.0

# archivo de salida, nombre visible, tipo, carpeta y archivo de origen, desde, hasta (segundos)
UP1 = "lfm_Komiku-ULTRA-PERSON-VOL1/x/Komiku - ULTRA PERSON VOL1 - "
UP2 = "lfm_Komiku-ULTRA-PERSON-VOL2/x/Komiku - ULTRA PERSON VOL2 - "
UP4 = "lfm_Komiku-ULTRA-PERSON-VOL4/x/Komiku - ULTRA PERSON VOL4 - "
KART = "lfm_Komiku-Incredible-Kart-Game/x/Komiku - Incredible Kart Game - "
TEMAS = [
    ("up_jump_and_shoot", "Jump and Shoot Stuff", "accion", UP1 + "02 Level 1 - Jump and shoot stuff 101.mp3", None, None),
    ("up_coming_to_the_city", "Coming to the City", "accion", UP1 + "05 Level 2 - Coming to the city.mp3", None, None),
    ("up_run_on_the_expressway", "Run on the Expressway", "accion", UP1 + "10 Level 3 - Run on the expressway.mp3", None, None),
    ("up_first_infiltration", "First Infiltration", "accion", UP2 + "01 Level 4 - First infiltration in Unresponsible Tech.mp3", None, None),
    ("up_time_for_retribution", "Time for Retribution", "accion", UP2 + "03 Level 5 - Time for retribution.mp3", None, None),
    ("up_second_strike", "Second Strike", "accion", UP2 + "06 Level 6 - Second strike.mp3", None, None),
    ("up_finally_together", "Finally Together", "accion", UP4 + "01 Level 10 - Finally together.mp3", None, None),
    ("up_high_risk", "High Risk Infiltration", "accion", UP4 + "05 Level 11 - High risk infiltration.mp3", None, None),
    ("kart_punk_rock", "Punk Rock Circuit", "accion", KART + "11 Punk Rock Circuit.mp3", None, None),
    ("kart_metal", "Metal Circuit", "accion", KART + "08 Metal Circuit.mp3", None, None),
    ("adv_200_segundos", "200 Seconds to Escape", "accion", "lfm_Komiku-Its-time-for-adventure-vol-5/x/Komiku - It's time for adventure vol 5 - 03 You have 200 seconds to escape.mp3", None, None),
    ("lfm_mega_metal", "MEGA METAL", "accion", "lfm_Loyalty-Freak-Music-HYPER-METAL-/x/Loyalty Freak Music - HYPER METAL ! - 03 MEGA METAL.mp3", None, None),
]
# Los de Scott Buckley parten con una introducción larga: se recortan a donde ya está intenso (medido)
JEFES = [
    ("jefe_goliath", "Goliath", "jefe", "sb_sb_goliath/sb_goliath.mp3", 48.0, 208.0),
    ("jefe_simulacra", "Simulacra", "jefe", "sb_Simulacra/Simulacra.mp3", 52.0, None),
    ("jefe_legionnaire", "Legionnaire", "jefe", "sb_legionnaire/sb_legionnaire.mp3", 12.0, None),
    ("jefe_forja", "Song of the Forge", "jefe", "sb_SongOfTheForge/SongOfTheForge.mp3", 56.0, 197.0),
    ("jefe_last_boss", "Let's See What We Got", "jefe", UP4 + "07 Last Boss - Let's what we got.mp3", None, None),
    ("jefe_swoop", "Swoop Attack", "jefe", UP4 + "03 Boss 6 - Swoop attack.mp3", None, None),
]
CALMA = ["ruby_1", "ruby_2", "ruby_3", "ruby_4", "ruby_5", "amethyst_1", "amethyst_2", "amethyst_3", "amethyst_4", "amethyst_5"]


def medir(ff, ruta):
    r = subprocess.run([ff, "-hide_banner", "-nostats", "-i", ruta, "-af", "ebur128=peak=true", "-f", "null", "-"], capture_output=True)
    t = r.stderr.decode("utf-8", "replace")
    t = t[t.rfind("Summary:"):]
    return float(re.search(r"I:\s+(-?[\d.]+) LUFS", t).group(1)), float(re.search(r"Peak:\s+(-?[\d.]+) dBFS", t).group(1))


def duracion(ff, ruta):
    r = subprocess.run([ff, "-hide_banner", "-i", ruta], capture_output=True)
    m = re.search(r"Duration: (\d+):(\d+):([\d.]+)", r.stderr.decode("utf-8", "replace"))
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3))


def preparar(ff, origen, salida, desde, hasta):
    dur = duracion(ff, origen)
    if desde is None and hasta is None:
        filtros = ["afade=t=in:d=0.02"]
        corte = []
        largo = dur
    else:
        ini = desde or 0.0
        fin = hasta or dur
        largo = fin - ini
        corte = ["-ss", str(ini), "-t", str(largo)]
        filtros = ["afade=t=in:d=0.05"]
        # si no llega al final de la obra, cierra con un fundido corto para que el bucle no pegue un salto
        if hasta is not None and hasta < dur - 0.5:
            filtros.append(f"afade=t=out:st={largo - 1.5}:d=1.5")
    cmd = [ff, "-hide_banner", "-loglevel", "error", "-y"] + corte + ["-i", origen, "-vn", "-af", ",".join(filtros),
           "-ar", "44100", "-ac", "2", "-c:a", "libmp3lame", "-q:a", CALIDAD_VBR, "-map_metadata", "-1", "-id3v2_version", "0", salida]
    subprocess.run(cmd, check=True)
    return duracion(ff, salida)


def main():
    ff, descargas, carpeta = sys.argv[1:4]
    os.makedirs(carpeta, exist_ok=True)
    total = 0
    filas_temas = []
    filas_jefes = []
    for lista, meta in ((TEMAS, META_TEMA), (JEFES, META_JEFE)):
        for archivo, nombre, tipo, rel, desde, hasta in lista:
            salida = os.path.join(carpeta, archivo + ".mp3")
            seg = preparar(ff, os.path.join(descargas, rel), salida, desde, hasta)
            i, p = medir(ff, salida)
            g = round(meta - i, 1)
            mb = os.path.getsize(salida) / 1e6
            total += mb
            print(f"{archivo:26} {seg:6.1f} s {mb:5.1f} MB {mb * 8000 / seg:4.0f} kbps  {i:6.1f} LUFS  pico {p:5.1f}  ganancia {g:+.1f}")
            (filas_temas if lista is TEMAS else filas_jefes).append(f'["{nombre}", "{archivo}", {g}, "{tipo}"]')
    filas_calma = []
    for archivo in CALMA:
        salida = os.path.join(carpeta, archivo + ".mp3")
        if os.path.exists(salida):
            i, p = medir(ff, salida)
            mb = os.path.getsize(salida) / 1e6
            total += mb
            g = round(META_TEMA - i, 1)
            nombre = archivo.replace("_", " ").title()
            print(f"{archivo:26} {duracion(ff, salida):6.1f} s {mb:5.1f} MB               {i:6.1f} LUFS  pico {p:5.1f}  ganancia {g:+.1f}")
            filas_calma.append(f'["{nombre}", "{archivo}", {g}, "calma"]')
    print(f"peso total de la musica: {total:.1f} MB")
    print("\n# filas para TEMAS")
    print(",\n".join(filas_calma + filas_temas))
    print("\n# filas para JEFES")
    print(",\n".join(filas_jefes))


if __name__ == "__main__":
    main()
