# Registro de sesiones

La más reciente arriba. Cada entrada: fecha, **quién**, qué se hizo, archivos o módulos tocados, commits (hash corto) y pendientes.

---

### 2026-11-22 (tarde): Iván (con Claude Code)
**Qué se hizo**
- Se revisaron los 19 PR de Alexander (#25 a #43): código, pruebas, correo privado y sin firmas de IA.
- **Se fusionaron 18** en el orden de su auditoría. Antes se integraron todos en una rama local y se corrió la batería completa.
- **El #34 (letras) queda abierto como borrador:** es donde se elige la letra.
- **Choques resueltos:**
  - `pruebas.gd`: se conservaron todas las pruebas nuevas;
  - `combate.gd`: M14 con M08, queda el destello "¡NIVEL N!" y después la placa del jefe.
- **Versión de prueba `v0.4.0-rc.1`** publicada como *pre-release*.
- **Issues creados:**
  - **#44** (fijado): guía de prueba con personas;
  - **#45**, **#46** y **#47**: herramientas.

**Verificado**
- Con todo integrado:
  - `tests` 11.271 de 11.271;
  - `flujo` 615 de 615 y `flujo_hangar` 189 de 189;
  - bot bueno en 1-6 Difícil, 3 de 3;
  - bot torpe en 1-3 Normal, 3 de 3;
  - `campana` en Normal, 22 de 24 estrellas en 8 intentos (faltó la de cadena de 1-8).
- `main` fusionado tiene el mismo código del juego. Solo cambia el orden de las pruebas en `pruebas.gd`.
- El `.exe` de la rc.1: `tests` 11.271 de 11.271, y `flujo` sin ventana 576 de 577 (el paso de mouse necesita ventana).

**Sin verificar**
- Las corridas **con ventana** posteriores fallaron al azar: entraban teclas reales del PC y había ajustes compartidos entre corridas (#47).
- Nada se jugó con personas todavía: para eso está la rc.1 y el #44.

**Pendientes**
- Iván y Alexander juegan la rc.1 con la guía del #44 y comentan ahí.
- Alexander: #47, después R01 (#19); #45 y #46 cuando pueda.
- Iván: decidir I01 (#22) e I02 (#23), y la letra (#34) junto con Alexander.

---

### 2026-11-22: Alexander (con Claude Code)
**Qué se hizo**
- Primera sesión de Alexander:
  - Git y GitHub CLI conectados;
  - clon del repo con el correo noreply;
  - Godot 4.7.2 en `herramientas/godot/`;
  - pruebas en verde sobre `main`: `tests` 7.588, `flujo` 615 y `flujo_hangar` 189, sin fallas.
- Un PR por Issue de la v0.4. Parte con Claude y parte con agentes en paralelo, cada uno en su copia del repo (`git worktree`) y con su propio prefijo de pruebas:

  | PR | Issue | Qué hace |
  |---|---|---|
  | #25 | M09 | Diálogo que presenta a las Moscas antes de 1-2 |
  | #26 | M15 | El número del Desync sigue subiendo aunque el enemigo ya esté sentenciado (solo visual) |
  | #27 | M07 | La sinergia y el OK caben en la carta (`_layout_carta`) |
  | #28 | M06 | Aire entre títulos y ranuras del HUD; candado de DESYNC separado |
  | #29 | M18 | Premios sin ganar en silueta en Arsenal → Desafíos |
  | #30 | M13 | Ficha de pieza con un decimal y "Al mejorar: …" antes de pagar (solo interfaz) |
  | #40 | M13 | Balance: mejora de piezas de 4 % a 8 % por nivel. Apilado sobre #30, retroactivo, a decidir por Iván |
  | #31 | M16, M17 | La pausa muestra armas, habilidades y estrellas del nivel |
  | #32 | M14 | Tras el Desync, las cartas esperan a que lleguen los Bits de la cascada y destella "¡NIVEL N!" |
  | #33 | M10 | El bot mide enemigos y balas en pantalla (código de pruebas) |
  | #42 | M10, M12 | Difícil con más enemigos y balas desde el inicio, y jefes que atacan más seguido. Nuevas perillas por dificultad (`ritmo`, `inicio`, `ganas`, `salva`, `jefe_cd`); vida y daño de Difícil bajan un poco |
  | #43 | M11 | El Reportado (`rayo`) pierde fuerza en cada salto; la Macro queda igual, porque está dentro de la meta |
  | #34 | M05 | Borrador: 4 opciones de letra en hojas de comparación, para que elijan las personas |
  | #35 | M04 | Ruleta centrada en un círculo más grande |
  | #36 | M01 | Hitbox discreta jugando normal y entera en foco o Desync |
  | #37 | M02 | Hangar: lo del fondo que va delante se dibuja después de las estaciones |
  | #38 | M08 | El nombre del jefe va en su placa y ya no tapa la barra |
  | #39 | M03 | Mapa sin encimados; `generar_mapa.py` lee los nodos de `datos.gd` y revisa choques |
- I01 (#22) e I02 (#23): propuesta de diseño escrita en cada Issue, **sin implementar**. Esperan el OK de Iván.
- **Dos auditorías de solo lectura** sobre los PR, hechas por un agente revisor. Encontraron bugs reales que las pruebas no veían, y ya están corregidos:
  - en #27, el bloque de sinergia no subía con la carta seleccionada;
  - en #29, la nave tapaba el candado;
  - en #30, el signo de la esquiva estaba al revés;
  - en #32, la prueba no ejercía el camino principal y el destello quedaba pegado al ganar;
  - en #36, el aro no se veía con la hitbox mínima;
  - en #39, la revisión suponía una nave chica.

**Archivos o módulos tocados** (entre todos los PR)
- `combate/combate.gd`, `pantallas/pausa.gd`, `pantallas/arsenal.gd`, `pantallas/hangar_equipo.gd`, `pantallas/pieza_boton.gd`, `pantallas/mapa.gd`, `pantallas/hangar_sala.gd`.
- `nucleo/partida.gd`, `nucleo/datos.gd`, `nucleo/catalogo_dialogos.gd`, `nucleo/sala_hangar.gd`, `pruebas/pruebas.gd`.
- `herramientas/arte/generar_mapa.py`, `generar_v3_escenas.py`, `herramientas/inventario.py`.
- Sprites del mapa y del Hangar.
- `memorias/guia-arte.md`, `arquitectura.md`, `decisiones.md`, `aprendizajes.md`, `inventario.md` y `docs/capturas/m05/`.

**Commits** (punta de cada rama al cerrar la sesión)
- #25 `59f2475`, #26 `c2c2a97`, #27 `afd8c83`, #28 `54657bd`, #29 `0af0e9b`, #30 `773350c`, #31 `ebe3e1c`, #32 `9ab21fd`;
- #33 `f7edbbb`, #34 `fff0f21`, #35 `464bba4`, #36 `48bf39c`, #37 `a46f01a`, #38 `e67a784`, #39 `d2e7a23`, #40 `8a6edc2`;
- #42 `4a21567`, #43 `39413cb`.

**Verificado**
- Cada PR con `import`, `tests`, `flujo` y `flujo_hangar` en verde, y capturas mirando el cambio.
- Los que tocan combate, además, con bots (bueno, `torpe` y `--ciego`).
- `campana` completa:
  - en #32: 24 de 24 estrellas;
  - en #40: 23 de 24.
- **Balance (#42, #43) con 10 partidas o más por caso, antes y después.** En Difícil:
  - 1-6 pasa de 8,7 a 12,9 balas en pantalla (Normal: 6,0);
  - el Compactador gana 13 de 20, y el jugador recibe entre 1,5 y 2,5 golpes en la pelea;
  - con la misma semilla, Normal da exactamente lo mismo que antes.

**Sin verificar**
- **Nada se jugó con personas.** Cómo se sienten M14 y M01, la letra (M05) y el balance lo tienen que decir dos personas jugando, Difícil incluido.
- No se probó con mando físico ni se escuchó el audio.

**Pendientes**
- **Revisar y fusionar.** Orden sugerido por las auditorías:
  - primero #25 y #28;
  - después #26, #27, #32, #29 y #31;
  - y #35, #39, #38, #36 y #37.
  - Los que agregan pruebas chocan en `_tests()` de `pruebas.gd`, pero es trivial: se conservan ambas líneas.
- Decisiones de Iván:
  - el 8 % de #40;
  - las perillas de Difícil de #42;
  - la letra de #34;
  - los puntos marcados "a decidir" en #36, #37, #38 y #39;
  - I01 e I02.
- Balance: medir juntos #40 (piezas al 8 %), #42 y #43, porque se midieron por separado sobre `main`. No se corrió la campaña completa en las 3 dificultades.
- **R01 a R03** (partir `pruebas.gd`, `combate.gd` y `arsenal.gd`): después de fusionar, porque chocan con casi todos los PR abiertos.
- Con #35 y #39 juntos, el cartel de la Ruleta tapa su "¡NUEVO!" si se enfoca durante el parpadeo.

---

### 2026-11-22: Iván (con Claude Code)
**Qué se hizo**
- Se preparó el repositorio público a partir de la carpeta local de la v0.3 (copiada a `Calypso GM`; la original queda como respaldo).
- `herramientas/probar.sh` ahora es portable: calcula su ubicación y busca el motor en `GODOT`, en `herramientas/godot/` o en el PATH. La exportación sale a `build/`.
- Herramientas nuevas: `volcar_catalogos.gd` e `inventario.py`, que generan `memorias/inventario.md` desde el código.
- Se escribieron el README, el CLAUDE.md y las memorias, más las plantillas de Issue y PR y la licencia.
- Los `docs/` se reescribieron en tono neutral, y `03_diseno_juego.md` se actualizó a la v0.3.
- Se sacó lo que venía de un prototipo anterior: una letra bitmap sin uso, su generador y dos documentos.
- Barrido de privacidad sin hallazgos pendientes (ver el PR o la Release).

**Verificado en la carpeta nueva**
- `import` sin errores;
- `tests` 7.588 de 7.588;
- `flujo` 615 de 615;
- `flujo_hangar` 189 de 189;
- bot en 1-3: gana 2 de 2.

**Incidente menor**
- Al volcar los catálogos, los autoloads reescribieron las partidas reales de la PC de Iván (`partida3_1.json`, `global3.json`, `ajustes.cfg`). Sin pérdida: la ranura 1 quedó con la conversión automática de la partida antigua, que no se tocó. La herramienta ahora exige `--pruebas --guardado=volcado` (ver `aprendizajes.md`).

**Publicado**
- Repo: https://github.com/ivanmaxor/Calypso-GM, con `main` protegido (PR + 1 aprobación, sin force push ni borrado).
- Release `v0.3.0` con `Calypso-v0.3.0-windows.zip`. El `.exe` se exportó desde el repo y pasó 615 de 615 pasos de menú.
- Issues #1 a #23 (M01-M18, R01-R03, I01-I02) en el hito "v0.4: Pulido y balance".
- Commits: `d214b60`, `0856615`, `8c6b27a`, `bd48afd` (tag `v0.3.0`).

**Pendientes**
- Agregar a Alexander como colaborador.
- Empezar la v0.4 por R01 (partir `pruebas.gd`) y M10-M13 (balance).

---

### 2026-11-03: v0.3 (resumen histórico)
- 29 observaciones de dos jugadores, hechas en paralelo por 7 roles con un contrato común (`docs/historial/contrato_v0.3.md`).
- Partidas con 3 ranuras, dificultades, Extremo y NG+. 26 armas, 30 habilidades, 53 desafíos y Arsenal.
- Director de oleadas, Moscas, anti-AFK, tope a jefes y Desync con escudo. Infinito y Ruleta. Hangar como habitación. Mascotas, voz de Don Tuerca, música y volumen.
- Pruebas: 7.588 reglas, 615 y 189 pasos de menú, campaña con bots.
- Lo que no se verificó: juego de personas, audio y mando físico.

### 2026-11-02: v0.2 (resumen histórico)
- 10 observaciones después de jugar la 0.1.
- Ranuras limitadas con sinergias y evoluciones, mapa de niveles, Don Tuerca, 6 naves, Opciones por pestañas y teclas dobles.
- Se quitó la Radio.
- Pruebas: 5.240 reglas y 107 pasos de menú sobre el `.exe`.

### 2026-11-02: v0.1 (resumen histórico)
- Primera versión jugable en Godot 4.7.2: combate con Desync, Hangar, piezas con rareza y fusión, mascota.
- Arte con el motor SDF, efectos generados y música CC0.
- Pruebas: 171 reglas, 43 pasos de menú y 1.000 balas a 264 cuadros por segundo.
