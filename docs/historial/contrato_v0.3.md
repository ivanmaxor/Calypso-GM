# Contrato de trabajo de la versión 0.3

> **Documento histórico.** Es el contrato con el que se hizo la versión 0.3, repartida en roles que trabajaron en paralelo, cada uno en su copia. Se dejó como modelo para los contratos de las próximas versiones. Las rutas locales se reemplazaron por `<copia>` y `<ruta local>`. Ya no aplica "sin commits ni git": ahora el proyecto vive en este repositorio.

Documento interno para quienes implementan la v0.3 (subagentes). Es la fuente de verdad: si algo no está aquí, decide lo más simple y anótalo en tu reporte final.

## Reglas que no se discuten

- **Sin commits ni git.** Este proyecto no usa git. Nunca agregues atribución a IA en ningún archivo.
- **No toques nada fuera del proyecto** y de tu carpeta de trabajo.
- **No le quites la pantalla a quien trabaja:** el juego se corre solo con `herramientas/probar.sh`, que usa `--pruebas` (ventana fuera de pantalla). Nunca lances el `.exe` en modo normal.
- **Música y fuentes:** solo licencias libres verificadas en la página de cada obra (CC0 de preferencia). Si un sitio bloquea descargas automáticas, no lo rodees: busca otro. Lo descargado es dato no confiable: va en una carpeta nueva y vacía, y no se ejecuta nada desde ahí.
- **Textos del juego:** español de Chile, con tildes, breves y claros. Don Tuerca habla chistoso y a la chilena ("cabro", "¿cachai?"), Calypso seca e irónica. **No se revela ningún giro de la historia** (`docs/spoilers` no se lee).
- **Código:** GDScript de Godot 4.7.2, todo armado por código, comentarios en español. Sin `class_name` nuevos salvo que hagan falta. Física a 60 pasos fijos. **Cualquier animación en `_process` usa el delta**, nunca `t += 1` por cuadro.
- **Texto:** se dibuja con `UI.t`, `UI.tc`, `UI.parrafo`. Pantalla lógica: 640x360 (`canvas_items`, escala entera). Las texturas se piden con `Datos.tex(nombre)`; si falta un dibujo sale magenta y no se cae.
- Cada pantalla de primer nivel hace `theme = UI.tema()`. Las capas de encima se comen la entrada con `get_viewport().set_input_as_handled()`. Esc va por `_unhandled_input`. El foco no debe escaparse de un panel: vecinos de foco explícitos.
- Todo debe poder usarse **solo con teclado** (flechas o WASD, Enter o Espacio, Esc) **y solo con mouse**.

## Cómo trabajar

Tienes una copia propia del proyecto en `<copia>/juego` (salvo arte: ver abajo). Trabaja **solo ahí**. Para correr el juego desde tu copia:

```bash
export CALYPSO_D="<copia>"
export CALYPSO_P="<tu_nombre>"     # prefijo de los guardados de prueba, para no pisar a otros
bash herramientas/probar.sh import
bash herramientas/probar.sh tests
bash herramientas/probar.sh bot 1 --nivel=1-3 --hasta=1-3
bash herramientas/probar.sh cap <carpeta_absoluta> 60,300 --reiniciar --pantalla=hangar --salir=310
bash herramientas/probar.sh flujo
```

Las capturas salen en 1280x720: **míralas con Read**. No des nada por bueno sin verlo. Argumentos útiles de `--pruebas`: `--pantalla=` (mapa, hangar, combate, naves, panel, dialogo, premio, resultado, opciones), `--pestana=`, `--opcion=`, `--nivel=`, `--nave=`, `--hasta=` (partida avanzada hasta ese nivel), `--armas=a,b`, `--habs=a,b`, `--evo`, `--bot`, `--torpe`, `--ciego`, `--campana`, `--ciclo=`, `--dificultad=`, `--capturas=`, `--en=`, `--salir=`, `--demo`, `--saltar=`, `--estres=`, `--semilla=`, `--reiniciar`, `--guardado=`.

**Ojo con las reglas de archivos:** eres dueño de los archivos de tu rol. Si necesitas un cambio chico en un archivo ajeno, hazlo en tu copia y anótalo en el reporte final: se fusiona con 3 vías (`git merge-file`) contra la copia base común. Cambios grandes en archivos ajenos: no; deja el pedido en tu reporte.

**Al terminar:** no copies nada a la carpeta principal (salvo arte y audio, según su rol). Quien integra toma tu copia. Tu reporte final, breve: qué hiciste, qué probaste y qué salió, archivos tocados fuera de tu rol, y lo que quedó pendiente o no pudiste verificar.

---

## El pedido de los jugadores

Dos jugadores probaron la v0.2. Esto es lo que pidieron, tal cual:

1. Configuración: el teclado para moverse o cambiar opciones está malo o muy raro, solo funciona con mouse.
2. Las letras tienen muchos píxeles, muy gruesas, cuestan en todo el juego. *(Ya resuelto en la base: letra Barlow Semi Condensed y `canvas_items`. Falta revisar que nada se corte o encime.)*
3. Agregarle sonido a Don Tuerca cuando hable, para que parezca que habla. No se entiende si es una cabeza con patas y brazos: las líneas negras parecían cuello o patas y lo azul un cuerpo.
4. Modo infinito al final de cada mundo, que junte lo del mundo y vaya subiendo de dificultad. A un jugador le encantó esa idea.
5. En el primer nivel las balas y la XP se confunden: dos personas creyeron que la XP eran balas. Las balas deben ser de un color (rojas, como en el nivel 2) y la XP del suyo.
6. Salen cosas del Desync en los primeros niveles, antes de desbloquearlo, y lo mismo el reactor. Deben estar apagadas hasta desbloquearlas.
7. El Aimbot está demasiado roto: las balas se quedan volando mucho rato a baja velocidad y los que pasan mueren.
8. El personaje tiene mucha vida al inicio. Quiere crear partida, cargar, con 3 ranuras, elegir fácil/medio/difícil, repetir textos de Don Tuerca. Al completar el juego: dificultad extrema y Nueva Partida + (desde cero con todo lo que tienes).
9. Hay que nerfear harto. Ping-pong + rebote + aimbot + macro llena la pantalla de cientos de balas. Mejoras de nave y piezas muy fuertes. Los objetos son demasiado fáciles de conseguir: en 1-6 ya tenía dos épicos.
10. El jugador que ya avanzó no debe perder su avance: con el código nuevo, generar una partida en Normal con cosas adecuadas para donde va.
11. Desync: ahora sí recibe daño (ir lento ya es muy roto), pero con un escudo que aguanta 3 balas y se va quebrando.
12. Muchísima más variedad de armas y habilidades. Base de 6 armas y 6 habilidades. Inventario de desbloqueos con misiones, como Megabonk, por mundo. Lo base siempre aparece; lo desbloqueable se elige si puede aparecer. Cada mundo agrega 2 armas y 2 habilidades fijas a la base.
13. Todo sigue roto: un jugador se quedó quieto y mataba todo en 1-7. (La "minigun" es la Macro.)
14. Las naves se desbloquean muy rápido: demorarlas o darlas por misiones.
15. Que la música rote sola, en orden aleatorio como Minecraft, mínimo 3 a 5 minutos por canción.
16. ¿Por qué en 1-8 te dan 3 mejoras al empezar? No debería.
17. Inspirarse en otros juegos: el Aegis de Megabonk (2 escudos que frenan balas, se quita uno al recibir y se regenera a los segundos).
18. Un jugador terminó el Mundo 1: continúa desde ahí, pero con el jefe sin completar, para que vea los cambios.
19. Los niveles son muy rápidos: no da tiempo a mejorar armas. Un jugador consiguió 2 legendarios y 2 míticos en el Mundo 1.
20. Un jugador sugiere máximo 2 armas: aquí son disparos y pocos enemigos, así que muchas armas es muy cheto, a menos que haya más enemigos y menos disparos por enemigo.
21. El desafío de cadena x30 no se puede: mueren muy rápido y salen pocos. Si hay más enemigos, repensar la cadena: que mientras más crece, más rápido se vaya, pero no de golpe; que baje de 5 en 5 o algo mejor.
22. Un nivel a mitad de mundo u opcional con recompensa, con ruleta en dos momentos, como las operaciones de jardín de PvZ GW2: dinero, jefes, hordas, tres veces el mismo jefe = jefe súper poderoso.
23. Hangar con fondo bonito (se dice que era el baño), o más 3D tipo ARC Raiders: tocas objetos en una habitación para entrar, con una barra arriba para cambiar entre objetos por si no sabes cuál es, y que brillen mientras lo demás se oscurece.
24. Música no solo relajante: algo más movido. Volumen muy fuerte: un jugador jugó en 10 %; el 20-30 % debería sentirse como 50 %. Música de batalla épica en los jefes.
25. La hitbox se siente muy chica. *(Decisión: es la de la nave del jugador. Se agranda.)*
26. La mascota se mueve rapidísimo en las animaciones (por los Hz). Crece muy rápido: nerfearla, más niveles, más lento.
27. Faltan más tipos de mascota a lo largo de todo el juego, y crece demasiado de tamaño.
28. Entrar a un nivel y salir al tiro da piezas: hay que quitarlo. Más variedad de piezas, que se van desbloqueando con los mundos.
29. La Camper está rotísima: mató al Compactador en 6 segundos estando quieta, porque quieta pega más.

**Lo que dice la investigación:** Megabonk parte con 2 armas y 2 tomos, y las ranuras 3 y 4 se ganan completando misiones; tiene un "Toggler" para prender o apagar lo que puede salir; el Aegis frena golpes, lanza una onda al bloquear y se recarga. En las operaciones de jardín de PvZ GW2 la tragamonedas sale en las oleadas 5 y 10; da de uno a tres jefes, una horda o premio en monedas; tres jefes iguales = súper oleada; tres monedas iguales = jackpot y vuelve a girar. Nueva Partida + (Dark Souls, Elden Ring): conservas personaje y equipo, la historia es la misma, los enemigos suben y dan más botín, y deja de subir en el ciclo 7. ARC Raiders: menú de estaciones que se recorren con los gatillos.

---

## Lo que ya está hecho en la base

- `nucleo/partida.gd`: reescrito. **Léelo antes de usarlo.** Ranuras de partida, dificultad, Nueva Partida +, migración desde la v0.2, generador de partidas (`generar_para`), desafíos, Arsenal (`alternar`, `armas_disponibles`, `habs_disponibles`), mascotas múltiples, botín nuevo (entrar y salir no da nada).
- `nucleo/catalogo_armas.gd`: las 26 armas y 30 habilidades, con sus números y sinergias. `nucleo/catalogo_progreso.gd`: rarezas, dificultades, naves, mascotas, piezas, base por mundo y 53 desafíos. `nucleo/catalogo_niveles.gd`: enemigos, rutas, mundos, niveles (incluye `1-R` y `1-INF`). `nucleo/catalogo_dialogos.gd`: diálogos. `nucleo/datos.gd`: junta todo y tiene las ayudas.
- Letra nueva, texto nítido, animaciones de menú por delta (causa real del punto 26).
- `nucleo/sonido.gd` tiene las funciones nuevas vacías (ver Audio), para que todos compilen.

## Contenido nuevo: nombres fijos

**Armas nuevas (`icono_<id>`):** firewall, rollback, minas, molotov, rush_b, quickscope, tornado, taladro, gacha, ragequit, frame_drop, sumidero, afk_farmer, speedhack.
**Habilidades nuevas (`icono_<id>`):** thorns, lagswitch, macrokeys, bunnyhop, clutch, leech, reaccion, rng, hardcore, battlepass, hitboxchica, overclock, buffstack, framerate.
**Piezas nuevas (`icono_<id>`):** reactor_estable, chip_xp, mira_termica, casco_espinas, alas_cuchilla, motor_nitro, reactor_fuga, chip_botin.
**Otros iconos de 32x32:** icono_arsenal, icono_ruleta, icono_infinito, icono_ranura_arma, icono_ranura_hab, dif_facil, dif_normal, dif_dificil, dif_extremo, rueda_jefe, rueda_compacto, rueda_horda, rueda_moneda, rueda_bolsa, rueda_diamante, rueda_pizza, rueda_cofre.
**Objetos de combate (hojas horizontales):** tiro_taladro (2 cuadros de 14x20), tiro_dado (2 de 11x11), tiro_boomerang (4 de 16x16), obj_mina (2 de 14x14), obj_molotov (1 de 10x14), obj_llama (4 de 14x14), fx_tajo (3 de 64x40), obj_tornado (4 de 28x28), tiro_hielo (2 de 12x12), obj_agujero (4 de 40x40), obj_torreta (2 de 22x22), obj_escudo (1 de 16x16).
**Enemigo nuevo:** mosca (4 cuadros de 24x24).
**Mascotas:** `mascota_{0,1,2}` se rehacen en 22, 24 y 28 px por cuadro, con 6 cuadros (4 de reposo y 2 de acción). Nuevas con el mismo formato: `mascota_chispita_{0,1,2}`, `mascota_imancito_{0,1,2}`, `mascota_caparazon_{0,1,2}`.
**Escenas:** `retrato_tuerca` (128x128, 4 cuadros), `hangar_fondo` (640x360), `hangar_obj_{naves,equipo,fusionar,mascota,arsenal,salida}` con posiciones en `nucleo/sala_hangar.gd`.

## Contrato combate ↔ armas

Combate (`combate.gd`) y armas (`arsenal.gd`) los hacen roles distintos. Lo acordado:

**Lo llama el combate, lo implementa `arsenal.gd`:**
- `arsenal.tick()`: cada cuadro con la nave viva, como hoy.
- `arsenal.absorber_golpe() -> bool`: al principio de `_recibir_dano`. Si devuelve `true`, no hay daño y el combate da 40 cuadros de invulnerabilidad.
- `arsenal.al_esquivar()`: al empezar una esquiva.
- `arsenal.dibujar_detras(cv)`, `arsenal.dibujar_frente(cv)`.

**Lo da el combate, lo usa `arsenal.gd`:**
- `c.mult_dano_jugador() -> float`: reemplaza a `c.mult_quieto()`; junta quieto, movimiento, clutch y roces.
- `c.crear_tiro(x, y, ang, vel, dmg, tex, cuadros, crit) -> Tiro`: aplica `stats.vel_tiro` y respeta `MAX_TIROS`.
- `Tiro` tiene además: `giro` (radianes máximos por cuadro al perseguir; reemplaza a `homing`; **mantiene la rapidez**), `rehit` (cuadros para volver a golpear al mismo enemigo; 0 = una sola vez), `escala` (al dibujarse), `decae` (factor de daño por rebote, 0.75 por defecto).
- `stats.homing` son **grados por cuadro**: `t.giro = deg_to_rad(stats.homing + a.p.get("giro", 0.0))`. Una bala con `giro > 0` vive como máximo 110 cuadros.
- `c.frenar_enemigo(e, factor, cuadros)`, `c.empujar(e, dx, dy)` (no afecta a jefes; también sirve para los que van por ruta).
- Sigue igual: `c.enemigos`, `e.x`, `e.y`, `e.def.radio`, `e.muerto`, `e.id`, `e.hp`, `e.hpmax`, `e.jefe`; `c.golpear(e, dmg, crit, x, y)`, `c.enemigo_cercano(x, y, excluir)`, `c.dist2`, `c.quitar_bala(i)`, `c.bn`, `c.bx`, `c.by`, `c.bvx`, `c.bvy`, `c.explosion`, `c.sacudir`, `c.chispa`, `c.particula`, `c.texto`, `c.rayos`, `c.ondas`, `c.jx`, `c.jy`, `c.stats`, `c.ticks`, `c.curar`, `c.gemas`, `c.chatarra`, `c.iframes`.

## Contrato combate ↔ menús

`terminado.emit(res)`. Campos: `ganado, kills, jefes, jefe (bool), tiempo (s), nivel, max_cadena, desyncs, aces, roces, nams, golpes, chatarra, evoluciones, nivel_id, abandono, hp, hp_max, build`, y **nuevos:** `modo` ("normal", "ruleta", "infinito"), `kills_tipo` ({tipo: n}), `esquivas`, `cambios`, `giros`, `jackpots`, `nave`. Se llama `Partida.registrar(res)`, `completar_nivel` si ganó, `generar_botin(res)` y `revisar_desafios()`.

`Datos.NIVELES[id]` puede traer `modo`. `1-R` y `1-INF` están en `Datos.EXTRAS`, `Datos.NODOS` y `Datos.NIVELES`, pero no en `ORDEN_NIVELES`.

## Audio: funciones de `Sonido`

`musica_menu()`, `musica_juego()`, `musica_jefe(activo: bool)`, `voz(quien: String)` ("tuerca" o "calypso"), `nombre_tema() -> String`, `cambiar_tema(paso: int)`. Se conserva `tocar_musica()`.

---

## Roles

### AUDIO
**Dueño de:** `nucleo/sonido.gd`, `nucleo/ajustes.gd`, `audio/**`, `herramientas/audio/**`, la parte de música de `CREDITOS.txt`. Puntos 3 (voz), 15 y 24.
- **Voz de Don Tuerca:** hoy existe (`voz_0..3`) pero nadie la notó. Mide el nivel de esos WAV y diagnostica. Hazla bien audible y graciosa: un balbuceo como Dave el Loco de PvZ, con sílabas de vieja cascarrabias de vocales claras y tono variable (síntesis de formantes con numpy). Calypso: voz robótica, seca, más baja. `Sonido.voz(quien)` se limita sola por tiempo real (no por cuadros) y varía el tono.
- **Rotación:** aleatoria sin repetir hasta agotar la bolsa, como Minecraft, con fundido. Un tema se repite en bucle hasta cumplir al menos 3 minutos y cambia al terminar la pasada. Opciones: `cambiar_tema` recorre "Aleatorio" y cada tema; por defecto, Aleatorio. No se reinicia al cambiar de pantalla.
- **Música nueva:** temas movidos y enérgicos, más al menos 3 de batalla épica para jefes (`musica_jefe` hace fundido y al terminar vuelve). Fuentes sugeridas, verificando la licencia en cada página: Free Music Archive (Komiku, HoliznaCC0), OpenGameArt (Juhani Junkala, CC0). Anota todo en `LICENCIAS_MUSICA.txt`. Cuida el peso: hoy son 60 MB de música; súbelo como máximo a unos 120 MB. Si necesitas decodificar MP3 para medir, instala lo que haga falta en una carpeta temporal con `pip install --target`, no en el sistema.
- **Volumen:** curva nueva. 100 % ≈ -5 dB, 50 % ≈ -13 dB, 25 % ≈ -21 dB. Música por defecto 50 %. Quien ya tenía un archivo de ajustes parte también en 50 % (una vez). Compensa la diferencia de volumen entre temas (tabla de ganancia por tema, medida).
- `Sonido.cuadro` y la separación de sonidos deben ser por tiempo, no por cuadros.
- **Entrega:** copia tus archivos a la carpeta principal al terminar (`juego/nucleo/sonido.gd`, `juego/nucleo/ajustes.gd`, `juego/audio/`, `herramientas/audio/`, `juego/CREDITOS.txt`).

### ARTE_ICONOS
**Dueño de:** `herramientas/arte/generar_v3_iconos.py` (nuevo) y las imágenes de la sección "Contenido nuevo", salvo escenas. Trabaja directo en `<ruta local>`; no corras Godot. Lee `herramientas/arte/generar_v2.py`, `sdf.py`, `modelos.py` y `generar_sprites.py`: reutiliza ese pipeline para mantener el mismo estilo de los iconos y mascotas que al usuario le encantan. Cada icono debe reconocerse de un vistazo y parecerse a lo que hace. Revisa con hojas de contacto ampliadas (`hoja_v2.py`). Las mascotas tienen que crecer poco entre formas y verse claramente distintas entre sí: Chispita (bicho-batería con chispas), Imancito (imán con patitas), Caparazón (tortuga-escudo), Mordisco (el de siempre). También las `mascota_N` rehechas.

### ARTE_ESCENAS
**Dueño de:** `herramientas/arte/generar_v3_escenas.py` (nuevo), `juego/nucleo/sala_hangar.gd`, `retrato_tuerca`, `hangar_*`, `bala_pellet`. Trabaja directo en la carpeta principal; no corras Godot. Puntos 3, 5 y 23.
- **Don Tuerca:** rehazlo para que se lea sin dudas como un viejo de medio cuerpo: cabeza, cuello, hombros, brazos y torso con overol, quizá una llave inglesa en la mano. Conserva lo que lo hace él (cono de tránsito, antiparras, nariz roja, barba). Mismo formato: 4 cuadros de 128x128 (0 calla, 1 habla, 2 grita, 3 gesto).
- **Hangar:** el baño de Don Tuerca convertido en taller, en pixel art rico, con estilo de `generar_mapa.py`: azulejos, cañerías, luz cálida. `hangar_fondo.png` de 640x360 sin los objetos, y cada objeto como sprite aparte con transparencia y aspecto 3D (usa el pipeline SDF si te sirve): `naves` (plataforma donde va la nave; la nave real la dibuja el juego encima), `equipo` (locker), `fusionar` (el excusado convertido en máquina fusionadora), `mascota` (tina con camita), `arsenal` (computador viejo y tablón de encargos), `salida` (puerta). Publica sus posiciones en `SalaHangar.OBJETOS`, sin tapar la franja superior de 26 px.
- **Balas:** `bala_pellet` debe verse roja como `bala_orbe`, y claramente distinta de los Bits dorados (`bit2`, `bit_grande2`). Compáralas juntas ampliadas.

### UI_A
**Dueño de:** `pantallas/{titulo,opciones,controles_ui,mapa,panel_nivel,premio,resultado,dialogo,pausa}.gd`, `pantallas/slots.gd` (nuevo), `escenas/principal.gd`, `nucleo/ui.gd`, `nucleo/controles.gd`, `project.godot`, `nucleo/catalogo_dialogos.gd`. Puntos 1, 2, 4, 8, 10, 18, 22 (lo de menú) y 28.
- **Teclado (punto 1):** causa probable: los menús solo escuchan `ui_*` (flechas) y el juego se mueve con WASD. Agrega WASD a `ui_up/down/left/right` y Espacio a `ui_accept` en `InputMap` al iniciar, sin romper el LineEdit ni la captura de teclas. En Opciones: mantener apretado repite; Enter o Abajo entran desde la pestaña a la primera fila; Q/E (y hombros del mando) cambian de pestaña desde cualquier parte; Esc en una fila vuelve a la pestaña y Esc en la pestaña cierra. Prueba cada pestaña **solo con teclado** con el flujo, usando teclas reales, incluido WASD. Revisa todas las demás pantallas tuyas con el mismo criterio.
- **Partidas (punto 8):** el título ofrece CONTINUAR (si hay), NUEVA PARTIDA, CARGAR, OPCIONES, SALIR. `slots.gd`: tres fichas con dificultad, ciclo NG+, nivel actual, estrellas y tiempo; cargar o borrar (con doble confirmación). Nueva partida: elegir ranura (avisar si se sobrescribe), luego dificultad con 4 tarjetas e iconos (Extremo con candado y explicación si no está abierto). Muestra `Partida.g.aviso` una vez si viene de la migración. Si `Partida.archivo_importable()` no está vacío, ofrece IMPORTAR PARTIDA. En Opciones, General: "Borrar partida" ya no va, se borra desde las ranuras. Agrega en General "Volver a ver los textos de Don Tuerca" (vacía `vistos`).
- **NG+ (punto 8):** cuando `Partida.puede_ng_plus()`, el mapa muestra un botón NUEVA PARTIDA + que explica qué se conserva y qué cambia, deja elegir dificultad y llama a `iniciar_ng_plus`; diálogo `nueva_plus`.
- **Mapa:** dibuja los nodos `1-R` y `1-INF` (conéctalos con una línea punteada al camino, sus iconos, candado hasta abrirse) con foco de teclado. Muestra dificultad y ciclo. Revisa que `PORTAL` y los nodos no se encimen con el arte; ajusta `Datos.NODOS` si hace falta. Quita todo lo de Amenaza de `panel_nivel.gd`.
- **Panel de nivel:** según `modo`. Infinito: récord en vez de estrellas. Ruleta: cómo funciona. Quita lo de "Partes con N cartas" (punto 16).
- **Premios y resultado:** `premio.gd` debe mostrar bien todo tipo (arma, hab, nave, mascota con su `id`, ranuras, tablón, chatarra, pieza, y el texto del desafío si trae `desafio`). `resultado.gd`: si se retiró, dice claro que no hubo botín; en infinito, tiempo y récord. En `principal.gd`, los premios de desafíos van después del resultado, y en infinito no hay diálogo de derrota. Muestra un aviso en el resultado si estás a punto de completar un desafío (opcional).
- **Revisión de la letra (punto 2):** recorre tus pantallas y corrige textos cortados o encimados, y los `draw_rect` sin relleno o `draw_line` que quedaron finísimos (usa ancho 1.0). También los `UI.t` con `esc` grande.
- **Flujo:** actualiza `_flujo()` de `pruebas/pruebas.gd`, para que recorra todo esto con teclas reales. Todo el flujo debe quedar en verde en tu copia, salvo lo que dependa de otro rol (anótalo).

### UI_B
**Dueño de:** `pantallas/{hangar,hangar_equipo,hangar_fusion,hangar_mascota,fusion,galeria_naves,seleccion_nave,panel_nave,pieza_boton}.gd`, `pantallas/hangar_sala.gd` (nuevo), `pantallas/arsenal.gd` (nuevo). Puntos 6, 12, 14, 23, 26 y 27.
- **Hangar como habitación (punto 23):** al entrar, `hangar_sala.gd`: la sala de pantalla completa (`hangar_fondo` + objetos de `SalaHangar.OBJETOS`). Barra arriba con NAVES, EQUIPO, FUSIONAR, MASCOTA, ARSENAL y SALIR. Cruzar con flechas/WASD o mouse; el objeto con foco brilla (contorno dorado que late, generado desde su alfa) y lo demás se oscurece, con cartel de nombre y una frase. Enter o clic abre esa estación: las pantallas actuales, con su barra de pestañas y el panel izquierdo. Esc vuelve a la sala y Esc en la sala vuelve al mapa. Lo bloqueado se ve apagado, con candado y cómo se abre. La nave real se dibuja sobre la plataforma, y la mascota activa en su tina. Si `ir_hangar("naves")` llega con pestaña, abre directo esa estación.
- **Arsenal (punto 12):** `arsenal.gd`, abierto con `tablon`. Pestañas ARMAS, HABILIDADES, PIEZAS y DESAFÍOS. Cuadrícula de iconos: lo bloqueado en silueta con candado; a la derecha, nombre, descripción, sinergia/evolución y cómo se desbloquea con progreso (`valor_stat`/`meta`). Lo ganado se puede prender o apagar con Enter (`Partida.alternar`), y se ve claro; lo base dice "Base: siempre sale". DESAFÍOS: lista con desplazamiento y barra de progreso, ordenada por cercanía; los de `desafio_visible` falso se muestran como "???". PIEZAS: la lista con cuándo empieza a caer cada una. Muestra arriba cuántas ranuras tienes y qué falta para la siguiente.
- **Punto 6:** en `hangar_equipo.gd` usa `Partida.ranuras_visibles()`; las pasivas que hablen de Desync salen como "???" hasta tenerlo.
- **Mascotas (puntos 26 y 27):** `hangar_mascota.gd`: fila con todas las mascotas: las que tienes, las bloqueadas en silueta con cómo se ganan, y las de otros mundos como "?" con el mundo. Elegir con Enter (`Partida.elegir_mascota`). La demo muestra lo que hace cada una según `ia`. Datos reales desde `Partida.pet_radio`, `pet_recarga`, `pet_dano`. Usa `Datos.tex_mascota(id, forma)` y `Partida.tam_mascota(id)` en todas partes (también `panel_nave.gd` y `fusion.gd`); nunca `[22, 30, 40]`. Dibujar a escala entera, sin agrandar más de ×2 en la demo.
- **Naves (punto 14):** `galeria_naves.gd`: lo bloqueado dice cómo se gana, con progreso (`Partida.progreso_nave`).
- **Fusión:** revisa textos y que la cuenta de piezas siga bien con menos botín.
- **Revisión de la letra (punto 2)** en todas tus pantallas: nada cortado ni encimado, y líneas con ancho 1.0.
- Copia el arte nuevo desde la carpeta principal a tu copia cuando aparezca (`juego/arte/sprites/hangar_*`, `icono_*`, `mascota_*`, y `nucleo/sala_hangar.gd`); mientras, trabaja con los cuadros magenta.

### COMBATE
**Dueño de:** `combate/combate.gd`, `combate/director.gd` (nuevo), `nucleo/catalogo_niveles.gd`. Puntos 4, 5, 7 (parte), 8 (vida), 9, 11, 13, 16, 19, 20, 21, 22, 25, 29, y **el balance general**.
- **Director de oleadas:** reemplaza las listas fijas por `director.gd`, que genera oleadas con presupuesto por segundo, formaciones (rutas, anclas, enjambres) y mezcla por nivel, con `hitos` fijos para presentar enemigos y jefes y que las pistas calcen. Más enemigos, **menos disparos por enemigo** (punto 20). Nueva IA `enjambre` para la Mosca: persigue suave, sin disparar; daño al tocar, muere rápido, ideal para la cadena. Determinista con semilla.
- **Duración de niveles (punto 19):** apunta a 1-1 unos 100 s, 1-2 130 s, 1-3 160 s, 1-4 150 s más La Grúa, 1-5 190 s, 1-6 210 s, 1-7 240 s, 1-8 180 s más El Compactador. Curva de XP pensada para unas 10-15 subidas en niveles medios y 18-22 al final, para llegar a evolucionar un arma en los últimos.
- **Fin del abuso (puntos 13 y 29):** quedarse quieto no puede ganar. `AFK`: si llevas varios segundos sin moverte (unos 5 s), aparece una mira sobre tu nave y al segundo cae un bombazo en ese lugar, que se repite mientras sigas ahí; Calypso comenta (`textos_calypso.afk`). `mult_dano_jugador()`: `quieto_dano` solo tras 1 s sin moverte. **Jefes con tope:** el daño por segundo a un jefe tiene retorno decreciente, de modo que ninguna build lo mate en menos de ~40 s (mide por ventana de 60 cuadros). La cascada ya tiene tope: consérvalo.
- **Quita** las cartas de inicio (punto 16). Daño de balas y vida: en Normal, unos 4 golpes matan al empezar, 3 con los golpes del final (`STATS_BASE.hp` ya es 70). Hitbox del jugador: de 1.6 a unos 3.5, multiplicada por `stats.hitbox_mult`, y el punto visible acorde (punto 25).
- **Tiros (puntos 7 y 9):** implementa `giro` que **mantiene la rapidez** (la causa del punto 7 es el `lerp` que frena la bala), vida máxima con giro, `decae` en rebotes, `MAX_TIROS` cerca de 140, `divide` con tope bajo.
- **Stats nuevos:** `thorns` (onda al recibir golpe), `esquiva_pct`, `mov_dano`, `clutch_dano`, `leech`, `reaccion`, `hitbox_mult`, `vel_tiro`, `roce_dano`, `hardcore` (vida enemiga), `duracion`.
- **Desync (punto 11):** ahora recibe daño. Al activarlo, escudo de `stats.desync_escudo` golpes (3), que se ve alrededor de la nave y se va quebrando: cada golpe resta uno y da un instante de invulnerabilidad; sin escudo, daño normal. Durante reconexión y cascada sigue seguro. Nunca rompas la sensación del Desync: al usuario le encanta.
- **Cadena (punto 21):** la ventana se acorta mientras más larga la cadena (de unos 4 s a unos 1.5 s), y al vencerse baja de 5 en 5 con un plazo corto entre bajadas, no a cero. Recibir golpe sigue cortándola a la mitad. Ajusta las metas de estrellas a lo medido.
- **Punto 5:** en el 1-1 las balas son del mismo rojo que los demás niveles; revisa que Bits y balas no se confundan (una pista temprana sobre los Bits ayuda).
- **Punto 6:** `_generar_cartas` usa `Partida.armas_disponibles(mundo)` y `habs_disponibles(mundo, armas en mano)`; la Sopaipilla (carga Desync) no sale sin Desync. Ranuras: `Partida.max_armas()`, `max_habs()`; el panel muestra las ranuras cerradas con candado. Cartas de relleno al llenar todo, para que subir de nivel siempre sirva, sin romper el balance.
- **Mascotas (punto 27):** `Partida.mascota_activa()`; según `ia` de `Datos.MASCOTAS`: `come` (come balas), `chispa` (chispazo al cercano, daño `pet_dano() * atk`), `iman` (trae todas las gemas), `escudo` (da un escudo). Todas con `pet_recarga()`. Se mueven suave y no tapan la acción. Sin mascota activa no se dibuja nada.
- **Modo Infinito (`modo: "infinito"`, punto 4):** el director sin fin: ritmo, vida y daño suben con el tiempo, mezcla de todo el mundo, La Grúa cada ~2 min, El Compactador cada ~4 min. Termina al morir; muestra tiempo y récord. Sin barra de fin de nivel.
- **Ruleta (`modo: "ruleta"`, punto 22):** al ~45 % y al ~90 % del nivel se limpia el campo y aparece la tragamonedas de Don Tuerca, con su cara, 3 rodillos que giran y se detienen uno a uno (`rueda_*`, con sonido). Cada rodillo suma lo suyo: Jefe (La Grúa), Compacto (2), Horda (Moscas y Rabiosos), Moneda, Bolsa, Diamante (chatarra creciente), Pizza, Cofre (carta gratis). **Tres iguales:** tres jefes = Súper Grúa (mucha más vida, otro color, y mejor botín); tres hordas = mega horda; tres monedas iguales = jackpot ×10 y vuelve a girar; tres pizzas = cura total; tres cofres = 3 cartas. Cuenta `giros` y `jackpots`.
- **Estadísticas para desafíos:** `kills_tipo`, `esquivas`, `cambios`, `giros`, `jackpots`, `nave`, `modo`.
- **Música:** `Sonido.musica_juego()` al empezar y `Sonido.musica_jefe(true/false)` al aparecer y morir un jefe.
- **Balance:** debes dejar esto medido con bots y reportarlo: `--ciego` y un bot nuevo `--quieto` (no se mueve nunca) deben perder casi siempre desde 1-3; el `--torpe` debe sufrir; el bueno gana con daño. En el 1-1 un Bot debe durar menos de 1 s con el arma inicial, y al terminar 1-7 un Bot unos 0.5 s. Con combos rotos (`--armas=ping_pong,macro --habs=aimbot,lagcomp,doble,spray,p2w --evo`) no debe haber más de `MAX_TIROS` balas ni la pantalla llena. Puedes ajustar números de `catalogo_niveles.gd`; pide en tu reporte los ajustes de `catalogo_armas.gd` y `catalogo_progreso.gd`.
- **Bot y pruebas:** actualiza `_bot_combate`, `_campana` y los tests de oleadas en `pruebas/pruebas.gd`.

### ARMAS
**Dueño de:** `combate/arsenal.gd`, `nucleo/catalogo_armas.gd`. Puntos 7, 9, 12, 17.
- Implementa los 26 `tipo`s y evoluciones de `catalogo_armas.gd`: `escudos`, `boomerang`, `minas`, `zona`, `tajo`, `francotirador`, `tornado`, `cono`, `onda_hielo`, `agujero`, `torreta`, `rastro`, y en `frontal` también `dado`, `rehit`, `escala`. Todo objeto propio de un arma vive y se dibuja en `arsenal.gd`. Respeta los contratos de arriba; hasta que estén en tu copia, agrégalos tú en tu `combate.gd` de forma mínima para poder probar (quien integra usa el `combate.gd` del rol COMBATE).
- **Firewall es el Aegis del punto 17:** arranca con 2 escudos visibles orbitando; cada golpe gasta uno y lanza una onda de daño; vuelven de a uno a los segundos.
- `dano(a)` usa `c.mult_dano_jugador()`. Aplica `stats.duracion` a lo que dura, `stats.area` a lo que tiene tamaño y `stats.cadencia` a la recarga.
- Sonidos: usa solo los de `Sonido.SFX`; si hace falta uno nuevo, pídelo en tu reporte.
- Cada arma se tiene que entender al verla, y **ninguna debe llenar la pantalla** ni tapar las balas enemigas.
- **Equilibrio:** mide el daño por segundo real de las 26, en nivel 1, nivel 5 y evolucionada, contra un blanco quieto y contra un grupo; ajusta para que queden parejas: nivel 1 cerca de 35-45, nivel 5 cerca de 90-120, evolución cerca de 150-220 (las de área o defensa, menos). Deja la tabla medida en tu reporte. Los tests de `_tests_armas` deben pasar (las defensivas, con su propia medida).
- **Pruebas:** agrega tests de lo tuyo en `_tests_armas`.
