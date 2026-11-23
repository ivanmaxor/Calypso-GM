# Arquitectura

Cómo está hecho Calypso en la versión 0.3 y cómo se extiende sin romperlo. Si cambias algo de aquí (una interfaz, una carpeta, un autoload), actualiza este archivo **en el mismo PR**.

## Motor y configuración

- **Godot 4.7.2**, renderer **GL Compatibility**, GDScript.
- **Todo se arma por código.** Hay una sola escena: `escenas/principal.tscn`, un `Node` con `principal.gd`. Las pantallas y el combate se crean con `.new()` desde sus scripts.
- **Pantalla lógica de 640×360**, `stretch_mode = canvas_items`, `aspect = keep` y escala entera. Filtro *nearest* y *snap* a píxel. La ventana parte en 1280×720.
- **Física a 60 pasos fijos** (`physics_ticks_per_second = 60`, sin interpolación). La lógica del combate corre en `_physics_process`.
- `config/name = "Calypso v2"`. **No se cambia sin migrar las partidas:** de ese nombre sale la carpeta de `user://` (ver `decisiones.md`).

## Carpetas

```
juego/                      proyecto de Godot (abrir juego/project.godot)
  escenas/principal.*       raíz: une las pantallas y maneja el flujo
  nucleo/                   autoloads, catálogos y utilidades
  combate/                  combate.gd, director.gd (oleadas), arsenal.gd (armas en partida)
  pantallas/                título, ranuras, mapa, panel de nivel, diálogo, premios, resultado, pausa,
                            opciones, teclas, hangar (sala + estaciones), arsenal, fusión, naves
  pruebas/                  autoload Pruebas: tests, recorridos de menús, bots, capturas
  arte/                     sprites/ (generados), fuente/, nave.gdshader, desync.gdshader
  audio/                    musica/ (con LICENCIAS_MUSICA.txt), sfx/ (generados)
herramientas/
  arte/                     generadores de sprites (Python + numpy + PIL)
  audio/                    generadores de efectos y voces, preparación de música
  probar.sh                 import, tests, flujos, bots, capturas y exportación
  volcar_catalogos.gd       vuelca los catálogos a JSON
  inventario.py             genera memorias/inventario.md desde ese JSON
docs/                       diseño, investigación, historia, arte, controles, tecnología, historial
memorias/                   memoria viva del proyecto (este archivo y los demás)
```

## Autoloads (`project.godot`)

| Nombre | Script | Qué hace |
|---|---|---|
| `Datos` | `nucleo/datos.gd` | Junta los catálogos y expone constantes (ranuras, stats base, nodos del mapa). Caché de texturas `Datos.tex(nombre)`, fuentes y ayudas de texto |
| `Ajustes` | `nucleo/ajustes.gd` | Opciones de video, sonido y juego (`user://ajustes.cfg`) |
| `Controles` | `nucleo/controles.gd` (+ `asignaciones.gd`) | Teclas principales y secundarias y mando. Se guardan como datos simples y se reconstruyen al abrir |
| `Partida` | `nucleo/partida.gd` | Ranuras de partida, dificultad, NG+, inventario, equipo, fusión, mascotas, desafíos, Arsenal, botín y migración de partidas antiguas |
| `Sonido` | `nucleo/sonido.gd` | Efectos, música con rotación y fundidos, música de jefe, voces y volumen |
| `Pruebas` | `pruebas/pruebas.gd` (+ los módulos de abajo) | Solo se activa con `--pruebas`. Sin ese argumento no hace nada |

### Las pruebas, por módulos
`Pruebas` es una cadena de scripts: cada uno hereda (`extends`) del anterior, así que todos comparten el mismo estado y las mismas herramientas. Un script solo puede llamar funciones suyas o de los de **más arriba** en la cadena (Godot lo revisa al compilar).

| Archivo | Qué tiene |
|---|---|
| `pruebas/pruebas_base.gd` | Estado compartido y herramientas: teclas, clics (`_raton`), esperas, fotos, `_ok` y `_check`, preparar un combate o una partida |
| `pruebas/pruebas_armas.gd` | `--tests` de las armas: medición de cada arma y los `_test_*` de mecánicas propias |
| `pruebas/pruebas_reglas.gd` | `--tests` del resto: teclas, partida, datos, combate, interfaz. `_tests()` llama todo en orden |
| `pruebas/pruebas_bot.gd` | `--bot` y `--campana`: el bot, la presión en pantalla, los resúmenes y `--auto` |
| `pruebas/pruebas_menus.gd` | `--flujo`: los menús con teclas, mando y mouse |
| `pruebas/pruebas_hangar.gd` | `--flujo_hangar` y `--demo_arsenal` |
| `pruebas/pruebas.gd` | El autoload: lee los argumentos, prepara la partida y reparte a cada módulo |

Si una función nueva se necesita en dos módulos, va en `pruebas_base.gd`.

## Catálogos: el contenido es dato

Todo el contenido y casi todo el balance viven en clases estáticas (`class_name`) de `juego/nucleo/`:

| Archivo | Qué trae |
|---|---|
| `catalogo_armas.gd` | `armas()`: 26 armas (tipo, base, 4 mejoras, sinergia y evolución). `habilidades()`: 30 habilidades |
| `catalogo_progreso.gd` | Rarezas, dificultades, cuánto sube cada mejora de pieza según la dificultad (`MEJORA_POR_NIVEL`), naves, pinturas, mascotas, piezas, base por mundo y desafíos |
| `catalogo_niveles.gd` | Enemigos, rutas, mundos y niveles (incluye `1-R` y `1-INF`), con pistas, ritmo, mezcla e hitos |
| `catalogo_dialogos.gd` | Diálogos de Don Tuerca y Calypso, y frases de Calypso en combate |

`Datos` los carga en variables (`Datos.ARMAS`, `Datos.NIVELES`, etc.). La lista legible está en `inventario.md`, que se genera desde estos archivos.

## Flujo de pantallas (`escenas/principal.gd`)

`ir_titulo()` → ranuras y dificultad → `ir_mapa()` → panel de nivel → `ir_seleccion()` (si hay 2 naves o más) → diálogo `antes_<id>` → `ir_combate()` → `ir_resultado(res)` → premios y desafíos → diálogo `despues_<id>` → mapa. `ir_hangar(pestana)` abre la sala o una estación directa. Sin pestaña, la sala parte sin foco si la opción de luz lo permite (`OPCIONES_LUZ` en `hangar_sala.gd`, #63). Cada pantalla reemplaza a la anterior con un fundido (`_poner`).

## Combate

- **`combate/combate.gd`** (~3.400 líneas) extiende `Node2D` y es una pantalla de 400×360 con paneles a los lados.
  - Dibuja en **capas** (`Capa`, un `Node2D` que llama a un método en su `_draw`): fondo, mundo, frente, HUD y cartas.
  - Clases internas: `Enemigo`, `Tiro` (bala del jugador) y `Gema` (Bits y chatarra).
  - **Las balas enemigas no son nodos ni objetos:** viven en arreglos paralelos (`bx`, `by`, `bvx`, `bvy`…) y se dibujan en lote. Topes: `MAX_BALAS` 1200 enemigas y `MAX_TIROS` 140 propias.
  - Estados: jugando, desync, reconectando, cascada, cartas, pausa, muerte y victoria.
  - Al terminar emite `terminado(res)`.
- **`combate/director.gd`** arma el **guion** de oleadas: cada enemigo cuesta puntos (`COSTO`) y el ritmo (`ritmo(t)`) sube y respira en olas. Los `hitos` del catálogo son fijos (presentar enemigos y jefes). Usa un generador propio: **la misma semilla da el mismo guion**. `tramo()` alimenta el Modo Infinito. La dificultad le pasa `ritmo` e `inicio` (`Director.new(nivel, semilla, ritmo, inicio)`, desde `Partida.mods_enemigos()`): en Difícil hay más enemigos a la vez y desde el comienzo.
- **`combate/arsenal.gd`** implementa los tipos de arma y sus evoluciones. Todo objeto propio de un arma (escudos, minas, torretas, tornados…) vive y se dibuja aquí.

### Contrato combate ↔ armas
- Lo llama el combate y lo implementa `arsenal.gd`:
  - `tick()` cada cuadro;
  - `absorber_golpe() -> bool` (si devuelve true, no hay daño);
  - `al_esquivar()`;
  - `dibujar_detras(cv)` y `dibujar_frente(cv)`.
- Lo da el combate:
  - `mult_dano_jugador()`;
  - `crear_tiro(x, y, ang, vel, dmg, tex, cuadros, crit) -> Tiro` (respeta `MAX_TIROS`);
  - `golpear(e, dmg, crit, x, y)`, `enemigo_cercano`, `frenar_enemigo`, `empujar`, `explosion`, `sacudir`, `texto` y `curar`.
- `Tiro` tiene:
  - `giro`: radianes por cuadro al perseguir; **mantiene la rapidez**;
  - `rehit`, `escala` y `decae` (daño por rebote).

### Contrato combate ↔ menús
El diccionario `res` que emite `terminado` trae:
- resultado: `ganado`, `abandono`, `tiempo`, `nivel`, `nivel_id`, `modo` ("normal", "ruleta" o "infinito"), `jefe` y `nave`;
- combate: `kills`, `kills_tipo`, `jefes`, `golpes`, `hp` y `hp_max`;
- desempeño: `max_cadena`, `desyncs`, `aces`, `roces`, `nams` y `esquivas`;
- botín y build: `chatarra`, `evoluciones`, `build` y `cambios`;
- Ruleta: `giros` y `jackpots`.

Luego se llaman `Partida.registrar(res)`, `completar_nivel` (si ganó), `generar_botin(res)` y `revisar_desafios()`.
La meta de cadena de la 3.ª estrella sale siempre de `Partida.meta_cadena(id)`: la del catálogo por el multiplicador `cadena` de la dificultad (#62). La usan `completar_nivel`, el HUD, la pausa, el resultado y el panel del nivel.

## Partidas

- `user://partida3_N.json` por ranura (N = 1 a 3) y `user://global3.json` para lo común.
- Una partida de una versión anterior (`partida2.json`) se lee una vez y se convierte. No se borra.
- En Windows, `user://` es `%APPDATA%\Godot\app_userdata\Calypso v2\`.

## Rendimiento

- Balas en arreglos y dibujo por lotes en `_draw`. Medido: ~235 cuadros por segundo con ~900 balas, y ~266 con 1.000 en una prueba aislada, en una GPU de entrada de 4 GB.
- Topes duros: 1200 balas enemigas, 140 tiros propios y 60 para las balas que se dividen. Una bala que persigue vive como máximo 110 cuadros.
- Texturas cacheadas en `Datos.tex()`. Si falta un PNG, sale un cuadro magenta y el juego no se cae.

## Cómo se agrega…

**Un arma**
1. Entrada en `CatalogoArmas.armas()`. Si su `tipo` no existe, se implementa en `arsenal.gd`.
2. Elegir su sinergia (una habilidad) y su evolución.
3. Icono `icono_<id>` (32×32) y, si dispara algo propio, su sprite. Ambos se hacen en `generar_v3_iconos.py` (ver `guia-arte.md`).
4. Hacerla obtenible: en `base_por_mundo()` o como premio de un desafío en `desafios()`.
5. Medir su daño por segundo (`--tests --medir_armas`) y agregar pruebas en `_tests_armas`.
6. Regenerar `inventario.md`.

**Un enemigo**
1. Entrada en `CatalogoNiveles.enemigos()`. Si su `ia` no existe, se implementa en `combate.gd` (`match e.def.ia`).
2. Su costo y sus topes en `director.gd` (`COSTO`, `TOPE_GRUPO` y otros).
3. El sprite, con núcleo rojo como punto débil.
4. Agregarlo a la `mezcla` de los niveles y presentarlo con un `hito`, una `pista` y, si corresponde, un diálogo.
5. Correr el bot y la campaña.

**Un nivel**
1. Entrada en `CatalogoNiveles.niveles()`: nombre, desc, duración, estrellas, premio, enemigos, pistas, ritmo, mezcla e hitos.
2. Su posición en `Datos.NODOS`, y en `ORDEN_NIVELES` o `EXTRAS`.
3. Regenerar el mapa (`generar_mapa.py`): lee las posiciones de `datos.gd` y avisa si un nodo nuevo cae encima de la utilería del dibujo.
4. Diálogos `antes_<id>` y `despues_<id>` en `catalogo_dialogos.gd`.

**Una pantalla**
- Script en `pantallas/` que hace `theme = UI.tema()`.
- Se come la entrada si es una capa encima, y Esc va por `_unhandled_input`.
- Vecinos de foco explícitos: tiene que funcionar solo con teclado y solo con mouse.
- Se agrega su recorrido en `pruebas_menus.gd` (o en `pruebas_hangar.gd` si es del Hangar).

## Reglas de modularidad

1. El contenido nuevo va en los catálogos, no repartido en el código.
2. Las balas no son nodos. Nada que exista por cientos va como nodo.
3. Toda animación usa el delta (`_process(delta)`) o la física fija; nunca "un cuadro = un paso" en `_process`.
4. Un archivo nuevo antes que agrandar uno gigante. **Pendiente para la v0.4:** partir `combate.gd` (~3.400 líneas) y `arsenal.gd` (~1.400), que son los puntos de choque cuando dos personas trabajan a la vez. `pruebas.gd` ya está partido (R01).
5. Las interfaces entre sistemas (las de arriba) se acuerdan antes de programar y se documentan aquí.
6. Los textos se dibujan con `UI.t`, `UI.tc` y `UI.parrafo`, y se miden con `UI.ancho` y `UI.partir` para no cortarse.
