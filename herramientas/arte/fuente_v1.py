# -*- coding: utf-8 -*-
"""
Letra pixel de 5x7 (solo libreria estandar de Python).

La usa generar_v3_escenas.py, con glifo(), para escribir los carteles del Hangar. El juego ya no la usa como letra.

Cada letra se dibuja en una cuadricula de 5x7 pixeles (los "#" son pixeles encendidos). Las vocales con tilde,
la enie y la dieresis se arman poniendo una marca encima. Las minusculas usan la misma forma que las mayusculas
(estilo arcade). Corrido solo, el script crea:
    pixel.png  -> imagen con todos los caracteres (cada pixel de la fuente se ve de 2x2 pixeles)
    pixel.fnt  -> descripcion en formato BMFont

Uso:  python fuente_v1.py <carpeta_de_salida>
"""
import os
import struct
import sys
import zlib

ESCALA = 2          # cada pixel de la fuente = ESCALA x ESCALA pixeles en la imagen
FILAS_MARCA = 2     # filas reservadas arriba para tildes
FILAS_CUERPO = 7    # alto de las letras
FILAS_BAJO = 2      # filas reservadas abajo (para la coma, el guion bajo, etc.)
ALTO_CELDA = FILAS_MARCA + FILAS_CUERPO + FILAS_BAJO


def g(*filas):
    return list(filas)


# ----------------------- letras y numeros (cuerpo de 7 filas) -----------------------
CUERPO = {
    "A": g(".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"),
    "B": g("####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."),
    "C": g(".####", "#....", "#....", "#....", "#....", "#....", ".####"),
    "D": g("####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."),
    "E": g("#####", "#....", "#....", "####.", "#....", "#....", "#####"),
    "F": g("#####", "#....", "#....", "####.", "#....", "#....", "#...."),
    "G": g(".####", "#....", "#....", "#..##", "#...#", "#...#", ".###."),
    "H": g("#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"),
    "I": g("###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"),
    "J": g("..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."),
    "K": g("#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"),
    "L": g("#....", "#....", "#....", "#....", "#....", "#....", "#####"),
    "M": g("#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"),
    "N": g("#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"),
    "O": g(".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."),
    "P": g("####.", "#...#", "#...#", "####.", "#....", "#....", "#...."),
    "Q": g(".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"),
    "R": g("####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"),
    "S": g(".####", "#....", "#....", ".###.", "....#", "....#", "####."),
    "T": g("#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."),
    "U": g("#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."),
    "V": g("#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."),
    "W": g("#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"),
    "X": g("#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"),
    "Y": g("#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."),
    "Z": g("#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"),
    "0": g(".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."),
    "1": g("..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."),
    "2": g(".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"),
    "3": g("####.", "....#", "....#", ".###.", "....#", "....#", "####."),
    "4": g("...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."),
    "5": g("#####", "#....", "####.", "....#", "....#", "#...#", ".###."),
    "6": g(".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."),
    "7": g("#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."),
    "8": g(".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."),
    "9": g(".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."),
    # signos
    ".": g(".", ".", ".", ".", ".", ".", "#"),
    ":": g(".", "#", ".", ".", ".", "#", "."),
    "!": g("#", "#", "#", "#", "#", ".", "#"),
    "?": g(".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."),
    "¡": g("#", ".", "#", "#", "#", "#", "#"),
    "¿": g("..#..", ".....", ".#...", "#....", "#...#", "#...#", ".###."),
    "-": g(".....", ".....", ".....", "####.", ".....", ".....", "....."),
    "+": g(".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."),
    "/": g("....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."),
    "|": g("#", "#", "#", "#", "#", "#", "#"),
    "(": g(".#", "#.", "#.", "#.", "#.", "#.", ".#"),
    ")": g("#.", ".#", ".#", ".#", ".#", ".#", "#."),
    "'": g("#", "#", ".", ".", ".", ".", "."),
    '"': g("#.#", "#.#", "...", "...", "...", "...", "..."),
    "%": g("##..#", "##.#.", "...#.", "..#..", ".#...", ".#.##", "#..##"),
    "*": g(".....", "#.#.#", ".###.", "#####", ".###.", "#.#.#", "....."),
    "=": g(".....", ".....", "#####", ".....", "#####", ".....", "....."),
    "<": g("...#.", "..#..", ".#...", "#....", ".#...", "..#..", "...#."),
    ">": g(".#...", "..#..", "...#.", "....#", "...#.", "..#..", ".#..."),
    "#": g(".#.#.", "#####", ".#.#.", ".#.#.", "#####", ".#.#.", "....."),
    "[": g("###", "#..", "#..", "#..", "#..", "#..", "###"),
    "]": g("###", "..#", "..#", "..#", "..#", "..#", "###"),
    " ": g("...", "...", "...", "...", "...", "...", "..."),
}
# signos con parte debajo de la linea base (hasta 2 filas)
BAJO = {
    ",": (g(".", ".", ".", ".", ".", "#", "#"), g("#", ".")),
    ";": (g(".", "#", ".", ".", ".", "#", "#"), g("#", ".")),
    "_": (g(".....", ".....", ".....", ".....", ".....", ".....", "....."), g("#####", ".....")),
}

# marcas (2 filas) para letras de ancho 5 y de ancho 3
MARCAS = {
    "acute": {5: ["...#.", "..#.."], 3: ["..#", ".#."]},
    "diaer": {5: [".#.#.", "....."], 3: ["#.#", "..."]},
    "tilde": {5: [".##.#", "#.##."], 3: [".##", "#.."]},
}
CON_MARCA = {
    "Á": ("A", "acute"), "É": ("E", "acute"), "Í": ("I", "acute"), "Ó": ("O", "acute"), "Ú": ("U", "acute"),
    "Ü": ("U", "diaer"), "Ñ": ("N", "tilde"),
}


def glifo(caracter):
    """Devuelve (matriz de ALTO_CELDA filas, ancho)."""
    marca = None
    bajo = ["", ""]
    if caracter in CUERPO:
        cuerpo = CUERPO[caracter]
    elif caracter in BAJO:
        cuerpo, bajo = BAJO[caracter]
    elif caracter in CON_MARCA:
        base, tipo = CON_MARCA[caracter]
        cuerpo = CUERPO[base]
        marca = tipo
    else:
        raise KeyError(caracter)
    ancho = len(cuerpo[0])
    filas_marca = ["." * ancho] * FILAS_MARCA
    if marca:
        filas_marca = MARCAS[marca][5 if ancho >= 5 else 3]
    filas_bajo = [(bajo[i] if i < len(bajo) else ".") for i in range(FILAS_BAJO)]
    filas_bajo = [(f if f else "." * ancho).ljust(ancho, ".") for f in filas_bajo]
    todas = list(filas_marca) + list(cuerpo) + filas_bajo
    assert all(len(f) == ancho for f in todas), caracter
    return todas, ancho


# ------------------------------ escritura de PNG ------------------------------
def escribir_png(ruta, ancho, alto, pixeles):
    crudo = bytearray()
    for fila in pixeles:
        crudo.append(0)
        for (r, gg, b, a) in fila:
            crudo.extend((r, gg, b, a))

    def chunk(tipo, datos):
        c = struct.pack(">I", len(datos)) + tipo + datos
        return c + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(crudo), 9))
    png += chunk(b"IEND", b"")
    open(ruta, "wb").write(png)


def main():
    destino = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(destino, exist_ok=True)

    # caracteres a generar: (codigo, caracter con la forma a dibujar)
    caracteres = []
    for c in list(CUERPO.keys()) + list(BAJO.keys()) + list(CON_MARCA.keys()):
        caracteres.append((ord(c), c))
    for i in range(26):                                   # minusculas = mayusculas
        caracteres.append((ord("a") + i, chr(ord("A") + i)))
    for minus, mayus in (("á", "Á"), ("é", "É"), ("í", "Í"), ("ó", "Ó"), ("ú", "Ú"), ("ü", "Ü"), ("ñ", "Ñ")):
        caracteres.append((ord(minus), mayus))

    ANCHO_IMG = 512
    x = y = 0
    fila_alto = ALTO_CELDA * ESCALA
    colocados = []   # (codigo, forma, x, y, ancho_px, adelanto)
    for codigo, forma in caracteres:
        matriz, ancho = glifo(forma)
        ancho_px = ancho * ESCALA
        if x + ancho_px + 2 > ANCHO_IMG:
            x = 0
            y += fila_alto + 2
        colocados.append((codigo, matriz, x, y, ancho_px, (ancho + 1) * ESCALA))
        x += ancho_px + 2
    alto_img = y + fila_alto + 2

    pix = [[(0, 0, 0, 0) for _ in range(ANCHO_IMG)] for _ in range(alto_img)]
    for (codigo, matriz, gx, gy, ancho_px, adel) in colocados:
        for fy, fila in enumerate(matriz):
            for fx, c in enumerate(fila):
                if c == "#":
                    for dy in range(ESCALA):
                        for dx in range(ESCALA):
                            pix[gy + fy * ESCALA + dy][gx + fx * ESCALA + dx] = (255, 255, 255, 255)
    escribir_png(os.path.join(destino, "pixel.png"), ANCHO_IMG, alto_img, pix)

    lineas = []
    lineas.append('info face="Pixel" size=-%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 '
                  'padding=0,0,0,0 spacing=0,0' % (ALTO_CELDA * ESCALA))
    lineas.append("common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0"
                  % (fila_alto + 2, fila_alto, ANCHO_IMG, alto_img))
    lineas.append('page id=0 file="pixel.png"')
    lineas.append("chars count=%d" % len(colocados))
    for (codigo, matriz, gx, gy, ancho_px, adel) in sorted(colocados, key=lambda t: t[0]):
        lineas.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
                      % (codigo, gx, gy, ancho_px, fila_alto, adel))
    open(os.path.join(destino, "pixel.fnt"), "w", encoding="utf-8", newline="\n").write("\n".join(lineas) + "\n")

    # vista previa (texto de ejemplo sobre fondo oscuro, 3x)
    texto = ["OLEADA 7: ¡LOS CHEATERS ATACAN!", "Presiona F para presentar tus respetos", "Ñandú, pingüino, canción, ÁÉÍÓÚ 0123456789", "(x) [ok] 50% +1 vida - 10/10 ?¿ ¡! .,;:"]
    mapa = {c[0]: c for c in colocados}
    K = 3
    W, H = 760, (len(texto) * (ALTO_CELDA * ESCALA + 6)) + 20
    prev = [[(20, 20, 50, 255) for _ in range(W)] for _ in range(H)]
    for li, linea in enumerate(texto):
        cx, cy = 10, 10 + li * (ALTO_CELDA * ESCALA + 6)
        for ch in linea:
            if ord(ch) == 32:
                cx += 4 * ESCALA
                continue
            c = mapa[ord(ch)]
            _, matriz, gx, gy, ancho_px, adel = c
            for fy, fila in enumerate(matriz):
                for fx, p in enumerate(fila):
                    if p == "#":
                        for dy in range(ESCALA):
                            for dx in range(ESCALA):
                                px, py = cx + fx * ESCALA + dx, cy + fy * ESCALA + dy
                                if 0 <= py < H and 0 <= px < W:
                                    prev[py][px] = (255, 255, 255, 255)
            cx += adel
    escribir_png(os.path.join(destino, "_preview_fuente.png"), W, H, prev)
    print("fuente generada:", len(colocados), "caracteres")


if __name__ == "__main__":
    main()
