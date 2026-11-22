# Aprendizajes

Trampas ya pagadas, para no volver a caer. **Agrega una entrada cada vez que algo cueste más de lo esperado**, con fecha y en qué archivo pasó.

## Godot 4.7.2 y GDScript

- **Una textura sin referencia persistente se dibuja blanca.** Las texturas se piden siempre con `Datos.tex(nombre)`, que las guarda en caché. En la v0.1 la mascota del Hangar salía como un cuadro blanco por esto.
- **El tema no se hereda a través de un `Node` o `Node2D` simple.** Cada pantalla de primer nivel hace `theme = UI.tema()`.
- **Entrada por capas:**
  - las capas que van encima (diálogo, premio, fusión) se comen la entrada en `_input` con `get_viewport().set_input_as_handled()`;
  - Esc va por `_unhandled_input`, así la capa de más arriba lo recibe primero.
  - Antes, consultar `Input.is_action_just_pressed` "atravesaba" las capas: Esc en la captura de tecla también cerraba Opciones, y una capa encima apretaba el botón con foco que estaba debajo.
- **Foco:**
  - pon vecinos de foco explícitos para que el foco no se escape de un panel;
  - todo debe poder usarse **solo con teclado** (flechas o WASD, Enter o Espacio, Esc) **y solo con mouse**;
  - WASD y Espacio se agregan a `ui_*` al iniciar;
  - el mando no trae A y B para aceptar y volver: se agregan a mano.
- **Animaciones por delta, nunca por cuadro.** Con `t += 1` por cuadro, la mascota iba rapidísimo en pantallas de muchos Hz. La lógica de juego va en `_physics_process` a 60 pasos fijos.
- **Errores de tipos que aparecieron:**
  - `round()` devuelve Variant: usa `roundf`;
  - en bucles sobre arreglos sin tipo, declara el tipo de la variable;
  - un ternario con una llamada `void` (por ejemplo `grab_focus.call_deferred()`) da error: usa una función aparte.
- **Texto:**
  - se dibuja con `UI.t`, `UI.tc` y `UI.parrafo`;
  - `UI.ancho` lo mide y `UI.partir` lo divide en líneas;
  - las líneas finas (`draw_line`, `draw_rect` sin relleno) usan ancho 1.0;
  - antes de usar un carácter raro, revisa que la letra lo tenga.
- **Escala:** con `canvas_items` el texto se dibuja a la resolución de la ventana (por eso se ve "HD"), mientras el arte sigue en píxeles de 640×360.
- **`config/name` define la carpeta de `user://`.** Cambiarlo deja a los jugadores sin sus partidas.
- **Los `.uid` se versionan.** Godot 4.7 crea uno por script y los usa para resolver rutas.
- **`--script` también carga los autoloads.** Un script de herramienta corrido con `--path juego --script ...` hace que `Partida` y `Ajustes` lean y **reescriban las partidas reales** de `user://` (y conviertan una partida antigua). Toda herramienta que corra el proyecto lleva `--pruebas --guardado=<prefijo>` después del `--`.

## Pruebas

- Comandos de `herramientas/probar.sh`:
  - `import`: errores de compilación;
  - `tests`: las reglas (7.588 en la v0.3);
  - `flujo`: los menús con teclas y clics simulados (615);
  - `flujo_hangar`: el Hangar y el Arsenal (189);
  - `bot <veces> [torpe]`, `campana`, `cap <carpeta> <cuadros>` y `exe`.
- `--pruebas` abre la ventana fuera de la pantalla. **Nunca se lanza el juego normal para probar:** se le quita la pantalla a quien está trabajando.
- `CALYPSO_P` cambia el prefijo de los guardados de prueba y `CALYPSO_D` corre sobre otra copia del repo. Así dos pruebas a la vez no se pisan.
- **Bots:**
  - bueno (ve todas las balas);
  - `--torpe` (reacciona lento y se equivoca);
  - `--ciego` (nunca esquiva). **Si gana, el juego no amenaza**;
  - `--quieto` (no se mueve). Debe perder siempre, porque comprueba el anti-AFK.
- **Argumentos útiles:**
  - para elegir qué se prueba: `--nivel=`, `--hasta=`, `--generar=` (equipo acorde a ese punto), `--dificultad=`, `--armas=a,b`, `--habs=a,b`, `--evo`;
  - para la ejecución: `--semilla=` y `--repetir=`.
- **Combo roto** para medir abusos: `--armas=ping_pong,macro --habs=aimbot,lagcomp,doble,spray,p2w --evo`.
- **Trampas ya pagadas:**
  - los bots soltaban y apretaban una tecla en el mismo cuadro, y por eso casi no usaban Desync ni esquiva;
  - los tiempos de las pruebas van en **cuadros** (`Engine.get_process_frames()`), no en milisegundos, porque las pruebas corren más rápido que el tiempo real;
  - **3 partidas no alcanzan** para distinguir dificultades: en la v0.3, Fácil y Difícil no se diferenciaban con esa muestra. Usa 10 o más;
  - una prueba que falla puede estar mal ella misma: en la v0.3 una suponía mal dónde caía el foco. Se revisa antes de "arreglar" el juego;
  - cuando dos personas agregan pasos al recorrido de menús, pueden chocar en el número de paso: cada uno trabaja en su propia función.
- **Godot reescribe `juego/project.godot` al correr las pruebas:** reordena líneas y borra las que tienen el valor por defecto. El juego queda igual, pero no se commitea: `git checkout -- juego/project.godot` después de probar, y revisar `git status` antes de cada commit.
- **Una prueba tiene que fallar sin el arreglo.** Compruébalo quitando el arreglo un momento. En esta sesión pasaron pruebas que no probaban nada:
  - una de M14 llamaba `_tick_botin()`, que no mueve los Bits (los mueve `_tick_gemas()`);
  - una de M15 creaba una bala nueva en cada vuelta, en vez de dejar la misma varios cuadros;
  - una de M16 probaba cada arma en un solo estado.
- **Pruebas en paralelo desde varias copias** (`git worktree`):
  - `herramientas/godot/` no viaja a la copia, porque está ignorada: usa `GODOT` con ruta absoluta;
  - usa un `CALYPSO_P` distinto en cada copia;
  - corre `import` primero en una copia nueva.
  Con varias pruebas a la vez, `flujo` falló una vez de forma intermitente (613 de 615) y pasó entero al repetirlo. Repítelo antes de culpar al cambio, y anota qué paso falló.
- Al terminar, se borran los guardados de prueba (`pruebas_*` o tu prefijo) de `user://`. **Nunca se tocan las partidas reales.**
- **Los bots dicen si algo es imposible o si se puede abusar, no si es divertido.** Lo que se siente lo deciden las personas.

## Balance

- Los números viven en los catálogos (`juego/nucleo/catalogo_*.gd`).
- **Reglas anti-abuso que se conservan:**
  - **AFK:** a los ~5 s en el mismo lugar (con 16 px de margen) cae un bombazo;
  - el bono por estar quieto solo cuenta después de 1 s;
  - **tope de daño a jefes:** retorno decreciente por ventana de 60 cuadros, para que nada los mate en menos de ~40 s. La cascada del Desync también tiene tope;
  - las balas teledirigidas **mantienen su rapidez** y viven como máximo 110 cuadros. Antes un `lerp` las frenaba y dejaba balas lentas flotando: así se rompió el Aimbot.
- **Lecciones:**
  - Subir mucho la vida de los enemigos rompió el ciclo de matar y subir de nivel: se volvió a valores medios.
  - Un nivel que se vuelve muralla se suaviza con las oleadas, no regalando cartas: las cartas de inicio se quitaron a pedido de los jugadores.
  - Se ganaba botín entrando y saliendo de un nivel: ahora retirarse no da nada. En el Mundo 1 no caen legendarios ni míticos.
  - La Camper mataba al jefe final en 6 s estando quieta: de ahí salieron el AFK y el tope a jefes.
  - Más enemigos con menos disparos cada uno se siente mejor que pocos enemigos que disparan mucho.
- **Meta de daño por segundo de un arma** (Ataque 12, contra un blanco): 35-45 en nivel 1, 90-120 en nivel 5 y 150-220 evolucionada. Las de área o defensa, menos contra un blanco. Se mide con `--tests --medir_armas`.
- **Mejoras de piezas:** cada nivel suma solo un 4 % de la base de la pieza, y la pantalla redondea a entero. Por eso parece que "no sube" (M13).

## Entorno Windows

- **Git Bash:**
  - los heredocs con comillas o barras invertidas rompen el código Python: escribe el script a un archivo y córrelo;
  - el directorio actual se reinicia entre llamadas: usa rutas absolutas o `cd` en la misma línea;
  - `robocopy` falla con sus argumentos: usa PowerShell `Copy-Item`.
- **Python:**
  - usa `PYTHONIOENCODING=utf-8`: la consola usa cp1252 y se cae con las tildes;
  - si un paquete instalado para el usuario (PIL) no aparece con `python -I`, usa `-P`.
- **GitHub CLI recién instalado** (`winget install --id GitHub.cli -e`) no aparece en una terminal que ya estaba abierta:
  - recarga el PATH con `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`, o cierra todas las terminales;
  - en Git Bash funciona con la ruta completa `"/c/Program Files/GitHub CLI/gh.exe"`.
- **PowerShell 5.1 se come las comillas dobles internas** de `gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"'`. Saca los valores por separado (`--jq .id` y `--jq .login`) o usa Git Bash.
- **Pillow y PNG "byte a byte":** según la versión de Pillow, un generador puede dar los mismos píxeles con bytes distintos. Para saber si un PNG cambió de verdad, compara píxeles, no hashes.
- `.claude/` (las copias de trabajo de Claude Code) va en `.git/info/exclude` de cada PC, no en el `.gitignore` del repo.
- Exportar falla si el `.exe` está abierto o si la carpeta de salida está abierta en otro programa.
- Rutas con espacios (`Calypso GM`): siempre entre comillas.

## Trabajo en equipo

- En la v0.3 trabajaron 7 roles en paralelo, cada uno en su copia, dueño de sus archivos, con un contrato común (`docs/historial/contrato_v0.3.md`). Funcionó, pero:
  - gastó mucho uso;
  - los archivos compartidos (`pruebas.gd`) chocaron.
- Con git, lo mismo se hace con un Issue por tarea, ramas cortas y PR chicos.
- Reportar con honestidad qué se probó con personas, qué solo con bots y qué no se probó.
- **Cada PR que agrega pruebas choca en `pruebas.gd`:** agrega una línea en `_tests()` y una función en el mismo lugar. En la sesión del 2026-11-22 chocaron 15 pares de PR. Se resuelve fácil, conservando ambas, pero pasa siempre: por eso R01 (partir `pruebas.gd`) va primero.
- **Una segunda revisión encuentra lo que las pruebas no ven.** Una auditoría de solo lectura, hecha por la otra persona o por un agente revisor, encontró bugs reales en 4 de 8 PR que pasaban todas las pruebas.

## Registro

| Fecha | Qué pasó | Dónde |
|---|---|---|
| 2026-11-22 | `probar.sh` tenía rutas absolutas y el motor escrito a mano: ahora calcula su ubicación y usa `GODOT` o el PATH | `herramientas/probar.sh` |
| 2026-11-22 | Godot reescribe `project.godot` al correr las pruebas: no se commitea | `juego/project.godot` |
| 2026-11-22 | Pruebas que pasaban sin probar el arreglo (M14, M15, M16): se corrigieron tras la auditoría | `juego/pruebas/pruebas.gd` |
| 2026-11-22 | Al volcar los catálogos con `--script`, los autoloads reescribieron `partida3_1.json`, `global3.json` y `ajustes.cfg` reales (sin pérdida: era la conversión automática). Ahora el volcado exige `--pruebas --guardado=volcado` | `herramientas/volcar_catalogos.gd` |
