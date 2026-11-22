"""Separa los PNG que cambiaron de verdad de los que solo cambiaron en bytes.

Según la versión de Pillow (y de zlib), un generador puede escribir los mismos píxeles con bytes
distintos. Git los marca como modificados aunque se vean idénticos. Este script compara los PNG
modificados con su versión en HEAD **píxel a píxel** (en RGBA) y dice cuáles cambiaron.

Uso (desde cualquier carpeta del repo):
    python herramientas/arte/png_sin_cambios.py              # solo informa
    python herramientas/arte/png_sin_cambios.py --restaurar  # deja como en HEAD los que no cambiaron

Con --restaurar, los PNG con píxeles idénticos vuelven a su versión de HEAD (git checkout), así el
commit lleva solo lo que cambió de verdad. Los que cambiaron no se tocan.
"""
import io
import os
import subprocess
import sys

from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(AQUI))  # herramientas/arte -> raíz del repo


def git(*args, binario=False):
    r = subprocess.run(["git", *args], cwd=REPO, capture_output=True, check=True)
    return r.stdout if binario else r.stdout.decode("utf-8")


def png_modificados():
    """Los PNG que git ve modificados (no los nuevos ni los borrados), con ruta desde la raíz."""
    salida = git("diff", "--name-only", "--diff-filter=M", "-z", "HEAD", "--", "*.png")
    return [r for r in salida.split("\0") if r]


def pixeles_distintos(ruta):
    """Cuántos píxeles distintos hay entre el PNG del disco y el de HEAD. -1 si cambió el tamaño."""
    antes = Image.open(io.BytesIO(git("show", "HEAD:" + ruta, binario=True))).convert("RGBA")
    ahora = Image.open(os.path.join(REPO, ruta)).convert("RGBA")
    if antes.size != ahora.size:
        return -1
    a = antes.tobytes()
    b = ahora.tobytes()
    if a == b:
        return 0
    return sum(1 for i in range(0, len(a), 4) if a[i:i + 4] != b[i:i + 4])


def main():
    restaurar = "--restaurar" in sys.argv[1:]
    rutas = png_modificados()
    if not rutas:
        print("no hay PNG modificados")
        return
    iguales = []
    for ruta in rutas:
        n = pixeles_distintos(ruta)
        if n == 0:
            iguales.append(ruta)
            print("  solo bytes  ", ruta)
        elif n < 0:
            print("  CAMBIÓ      ", ruta, "(otro tamaño)")
        else:
            print("  CAMBIÓ      ", ruta, f"({n} {'píxel' if n == 1 else 'píxeles'})")
    print(f"{len(rutas)} PNG modificados: {len(rutas) - len(iguales)} cambiaron, {len(iguales)} solo en bytes")
    if iguales and restaurar:
        git("checkout", "HEAD", "--", *iguales)
        print(f"restaurados {len(iguales)} como en HEAD")
    elif iguales:
        print("para no commitearlos: python herramientas/arte/png_sin_cambios.py --restaurar")


if __name__ == "__main__":
    main()
