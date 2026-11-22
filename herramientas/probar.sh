#!/bin/bash
# Herramienta de desarrollo. Uso:
#   probar.sh import                 reimporta recursos y muestra errores de compilacion
#   probar.sh tests                  reglas de teclas, fusiones, guardado y datos
#   probar.sh bot <veces> [torpe] [--otros args]   partidas del bot, sin ventana
#   probar.sh cap <carpeta> <frames> [--otros args]  capturas reales del juego
#   probar.sh flujo [carpeta]        recorre los menus con teclas reales
#   probar.sh flujo_hangar [carpeta] recorre la sala y las estaciones del Hangar con teclas y mouse
#                                    Los dos corren sin ventana (--headless): asi no les llegan teclas ni mando
#                                    del PC. Con [carpeta] abren la ventana, porque las capturas la necesitan.
#   probar.sh campana [--otros args] juega el mundo entero en orden
#   probar.sh exe                    exporta build/Calypso.exe
# Variables opcionales:
#   GODOT      ruta al motor (Godot 4.7.2, la version de consola en Windows). Si no esta, se busca en
#              herramientas/godot/ y despues en el PATH (godot o godot4).
#   CALYPSO_D  carpeta con otra copia del repo (con su juego/ adentro), para probar sin pisar la principal.
#   CALYPSO_P  prefijo de los guardados de prueba, para que dos pruebas a la vez no se pisen.
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="${CALYPSO_D:-$RAIZ}"
P="${CALYPSO_P:-pruebas}"
G="${GODOT:-}"
if [ -z "$G" ]; then
  for c in "$RAIZ/herramientas/godot/Godot_v4.7.2-stable_win64_console.exe" "$(command -v godot 2>/dev/null)" "$(command -v godot4 2>/dev/null)"; do
    if [ -n "$c" ] && [ -x "$c" ]; then G="$c"; break; fi
  done
fi
if [ -z "$G" ]; then
  echo "No encuentro Godot 4.7.2. Define GODOT con la ruta al ejecutable (ver README)." >&2
  exit 1
fi
FILTRO="^Godot Engine|^$|BUG: Unref|Thread object|wait_to_finish|~Thread|RID alloc|Pages in use|PagedAllocator|string_name|ObjectDB|object.cpp|resources still|resource.cpp|^OpenGL|^Vulkan|^WASAPI|renderer_canvas_cull|was leaked"
cd "$D/juego" || exit 1
accion="$1"; shift
case "$accion" in
  import)
    "$G" --headless --path . --import 2>&1 | grep -E "SCRIPT ERROR|Parse Error|at: GDScript|^ERROR: Failed" | head -30
    ;;
  tests)
    timeout 120 "$G" --headless --path . --fixed-fps 60 -- --pruebas --tests --guardado="${P}_tests" --reiniciar 2>&1 | grep -vE "$FILTRO" | grep -E "FALLA|tests\]|SCRIPT|ERROR|Invalid" | head -70
    ;;
  bot)
    veces="$1"; shift
    extra=""
    if [ "$1" = "torpe" ]; then extra="--torpe"; shift; fi
    timeout 560 "$G" --headless --path . --fixed-fps 60 --disable-vsync -- --pruebas --bot $extra --pantalla=combate --guardado="${P}_bot" --reiniciar --repetir="$veces" "$@" 2>&1 | grep -vE "$FILTRO" | head -60
    ;;
  cap)
    carpeta="$1"; frames="$2"; shift 2
    timeout 200 "$G" --path . --audio-driver Dummy --fixed-fps 60 -- --pruebas --guardado="${P}_cap" --capturas="$carpeta" --en="$frames" "$@" 2>&1 | grep -vE "$FILTRO" | head -150
    ;;
  flujo)
    carpeta="$1"
    if [ -n "$carpeta" ]; then cap="--capturas=$carpeta"; ventana=""; else cap=""; ventana="--headless"; fi
    timeout 400 "$G" $ventana --path . --audio-driver Dummy --fixed-fps 60 --disable-vsync -- --pruebas --flujo --guardado="${P}_flujo" --reiniciar $cap 2>&1 | grep -vE "$FILTRO" | head -160
    ;;
  flujo_hangar)
    carpeta="$1"
    if [ -n "$carpeta" ]; then cap="--capturas=$carpeta"; ventana=""; else cap=""; ventana="--headless"; fi
    timeout 400 "$G" $ventana --path . --audio-driver Dummy --fixed-fps 60 --disable-vsync -- --pruebas --flujo_hangar --guardado="${P}_fh" --reiniciar $cap 2>&1 | grep -vE "$FILTRO" | head -400
    ;;
  campana)
    timeout 590 "$G" --headless --path . --fixed-fps 60 --disable-vsync -- --pruebas --bot --campana --guardado="${P}_camp" --reiniciar "$@" 2>&1 | grep -vE "$FILTRO" | head -120
    ;;
  exe)
    mkdir -p "$D/build"
    "$G" --headless --path . --export-release "Windows" "$D/build/Calypso.exe" 2>&1 | grep -E "ERROR:|Failed" | head -20
    ls -la "$D/build"
    ;;
esac
