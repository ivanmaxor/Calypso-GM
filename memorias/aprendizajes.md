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
- **Mejoras de piezas:** con un 4 % de la base por nivel y la ficha redondeando a entero, parecía que "no sube" (M13). Ahora cada nivel suma un 8 % (`Partida.MEJORA_POR_NIVEL`), la ficha muestra un decimal y "Al mejorar: …" antes de pagar. Una prueba revisa que cada nivel de cada pieza cambie algún número visible: con 4 % fallaba en 5 piezas.

## Entorno Windows

- **Git Bash:**
  - los heredocs con comillas o barras invertidas rompen el código Python: escribe el script a un archivo y córrelo;
  - el directorio actual se reinicia entre llamadas: usa rutas absolutas o `cd` en la misma línea;
  - `robocopy` falla con sus argumentos: usa PowerShell `Copy-Item`.
- **Python:**
  - usa `PYTHONIOENCODING=utf-8`: la consola usa cp1252 y se cae con las tildes;
  - si un paquete instalado para el usuario (PIL) no aparece con `python -I`, usa `-P`.
- Exportar falla si el `.exe` está abierto o si la carpeta de salida está abierta en otro programa.
- Rutas con espacios (`Calypso GM`): siempre entre comillas.

## Trabajo en equipo

- En la v0.3 trabajaron 7 roles en paralelo, cada uno en su copia, dueño de sus archivos, con un contrato común (`docs/historial/contrato_v0.3.md`). Funcionó, pero:
  - gastó mucho uso;
  - los archivos compartidos (`pruebas.gd`) chocaron.
- Con git, lo mismo se hace con un Issue por tarea, ramas cortas y PR chicos.
- Reportar con honestidad qué se probó con personas, qué solo con bots y qué no se probó.

## Registro

| Fecha | Qué pasó | Dónde |
|---|---|---|
| 2026-11-22 | `probar.sh` tenía rutas absolutas y el motor escrito a mano: ahora calcula su ubicación y usa `GODOT` o el PATH | `herramientas/probar.sh` |
| 2026-11-22 | Al volcar los catálogos con `--script`, los autoloads reescribieron `partida3_1.json`, `global3.json` y `ajustes.cfg` reales (sin pérdida: era la conversión automática). Ahora el volcado exige `--pruebas --guardado=volcado` | `herramientas/volcar_catalogos.gd` |
