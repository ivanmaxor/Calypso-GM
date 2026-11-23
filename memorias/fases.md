# Fases

Cada fase es una versión jugable. Ciclo:
1. Se juega y se anotan observaciones numeradas.
2. Se abre un Issue por punto.
3. Se implementa en PR chicos.
4. Se prueba con bots **y con personas**.
5. Se publica la Release.

Una fase grande se puede escribir como contrato, siguiendo el modelo de `docs/historial/contrato_v0.3.md`.

## ✅ Completadas

### v0.1: Primera versión jugable (2026-11-02)
- [x] Motor elegido (Godot 4.7.2), combate base con balas en arreglos, Desync, Hangar, piezas con rareza y fusión, mascota.
- [x] Arte por código (motor SDF), efectos generados y música CC0.
- [x] Pruebas automáticas y bots.

### v0.2: Progreso y flujo (2026-11-02)
- [x] Ranuras limitadas, sinergias y evoluciones. 12 armas y 16 habilidades.
- [x] Mapa estilo Plantas vs Zombies 2, 8 niveles con premios y estrellas.
- [x] Don Tuerca como guía, 6 naves, Opciones por pestañas, teclas principales y secundarias.
- [x] Fuera la Radio. HUD con vida y peligro más visibles.

### v0.3: Las 29 observaciones de dos jugadores (2026-11-03)
- [x] 3 ranuras de partida, con dificultades, Extremo y Nueva Partida +.
- [x] 26 armas, 30 habilidades, 53 desafíos, Arsenal y ranuras que se ganan.
- [x] Director de oleadas, Moscas, anti-AFK, tope a jefes y Desync con escudo.
- [x] Modo Infinito y Ruleta de Don Tuerca. Hangar como habitación.
- [x] 4 mascotas jugables, nueva voz de Don Tuerca, música en rotación y volumen corregido.
- [x] Verificado: 7.588 reglas, 615 pasos de menú y 189 del Hangar, sin fallas. Campaña con bots: el bueno saca 24 de 24 estrellas; el torpe, 17 de 24; el que no esquiva se atasca en 1-2.
- [ ] Sin verificar: que una persona sienta bien el balance, el audio y el mando físico.

### Repositorio (2026-11-22)
- [x] Repo público, memorias, guías, plantillas y Release `v0.3.0`.

## 🔨 En curso: v0.4 (Pulido y balance)

**Estado (2026-11-22):** M01 a M18 implementados y fusionados (salvo la elección de letra, #34). En prueba con personas con la versión `v0.4.0-rc.1`, siguiendo la guía del Issue #44.

Observaciones de una prueba real con jugadores. **Prioridad sugerida:** 🔴 alta · 🟡 media · 🟢 baja. Cada punto es un Issue.

### Arte y escenario
| ID | Prioridad | Descripción | Pista |
|---|---|---|---|
| M01 | 🔴 | La nave tiene una bola rosa encima que parece un error | Es el **indicador de hitbox** (`combate.gd`, `HITBOX := 3.5`). Decidir cómo se ve: más chico o semitransparente, solo en modo foco, o integrado a la cabina. No basta con borrarlo |
| M02 | 🟡 | Hangar: el cartel queda detrás del bate, el papel detrás del equipo y la caja de herramientas detrás de la puerta | Las estaciones se dibujan encima del fondo: lo que deba ir delante tiene que ser un sprite aparte (`generar_v3_escenas.py`, `sala_hangar.gd`) |
| M03 | 🟡 | Mapa: elementos encimados sin sentido | El dibujo (`generar_mapa.py`) y `Datos.NODOS`/`PORTAL` deben calzar; si cambian los nodos, se regenera |
| M04 | 🟡 | Mapa: la ruleta de Don Tuerca está mal centrada en su círculo | Agrandar el círculo y centrarla |

### Texto, letras y UI
| ID | Prioridad | Descripción | Pista |
|---|---|---|---|
| M05 | 🟡 | La letra es muy limpia y le quitó el pixel art: buscar un punto medio | Ver la historia de la letra en `guia-arte.md` §7. Comparar 3 o 4 opciones en capturas reales |
| M06 | 🟡 | Armas y Habilidades: el texto va pegado a los recuadros, y el candado está pegado a la "C" de "DESYNC" | Margen interno; medir con `UI.ancho` |
| M07 | 🔴 | Al comprar una habilidad que evoluciona un arma, "Hace evolucionar:" y el "OK" se salen de la tarjeta | Partir con `UI.partir` y revisar el alto |
| M08 | 🟡 | Barra del jefe: el texto tapa la barra (La Grúa) y se ve demasiado HD | Ligado a M05 |

### Diálogos
| ID | Prioridad | Descripción |
|---|---|---|
| M09 | 🟡 | En 1-2 falta un diálogo que presente a las Moscas (`catalogo_dialogos.gd`) |

### Dificultad y balance
| ID | Prioridad | Descripción | Pista |
|---|---|---|---|
| M10 | 🔴 | Difícil se siente como Fácil-Normal: pocos enemigos y pocas balas, sin presión desde el inicio. En 1-2 se logró una cadena x180 | 1) agregar al bot la medición de enemigos y balas en pantalla; 2) 10 partidas o más por caso; 3) tabla antes/después. Perillas: dificultades en `catalogo_progreso.gd`, niveles en `catalogo_niveles.gd`, presupuesto en `director.gd` |
| M11 | 🔴 | Macro y sobre todo el Rayo ("Reportado") son demasiado fuertes para la cantidad de enemigos | Rebalancear junto con M10. Meta de daño por segundo: 35-45 / 90-120 / 150-220. El Rayo salta entre enemigos, así que con más enemigos pega más |
| M12 | 🔴 | Los jefes en Difícil se sienten "normal un poco más alto" | Subir su ataque en Difícil. El tope de daño recibido se conserva (anti-abuso) |
| M13 | 🔴 | Mejorar la mira varias veces casi no sube el daño | **Revisado:** cada nivel suma solo un 4 % de la base de la pieza (`Partida.stats_item`), y `hangar_equipo.gd` redondea a entero. Mostrar decimales y/o subir lo que da cada nivel, y mostrar qué se gana antes de pagar |

### Desync
| ID | Prioridad | Descripción | Pista |
|---|---|---|---|
| M14 | 🔴 | Al terminar el Desync no debe saltar de inmediato "elige una mejora": primero ver cómo la XP llega a la nave y sube la barra, y recién al subir de nivel, con un pequeño retraso, la elección | Cambia solo cómo se ve y se siente, no las reglas: es la mecánica favorita |
| M15 | 🟡 | El multiplicador del Desync se corta en lo justo para matar. Mostrar el número completo (por ejemplo x99) | Solo visual |

### Pausa e información
| ID | Prioridad | Descripción |
|---|---|---|
| M16 | 🟡 | La pausa (Tab o Esc) debe mostrar las armas y habilidades equipadas, con descripción y nivel |
| M17 | 🟢 | Evaluar repetir en la pausa la info del nivel (cómo sacar las 3 estrellas) |

### Arsenal
| ID | Prioridad | Descripción |
|---|---|---|
| M18 | 🟡 | En Arsenal → Desafíos, lo no desbloqueado no debe mostrar su apariencia (mantener el misterio) |

### Orden y herramientas (para trabajar de a dos)
| ID | Prioridad | Descripción |
|---|---|---|
| R01 | 🔴 | Partir `pruebas/pruebas.gd` (~4.400 líneas) en módulos por área: tests, recorridos de menús, bots y capturas. Va primero, porque lo tocan todos |
| R02 | 🟡 | Partir `combate/combate.gd` (~3.400 líneas): HUD, Desync, Ruleta y modos |
| R03 | 🟢 | Partir `combate/arsenal.gd` (~1.400 líneas) por familias de arma |
| I01 | 🟢 | **Propuesta, sin implementar:** una GitHub Action que exporte el `.exe` al crear un tag. Necesita el motor y las plantillas en la máquina de GitHub (Windows o Linux con exportación a Windows) y subir el zip a la Release |
| I02 | 🟢 | **Propuesta, sin implementar:** aviso en el juego de "hay una versión nueva". Consultaría la API pública de Releases de GitHub al abrir; necesita aviso de privacidad y opción para apagarlo |

**Para cerrar la v0.4:**
- todas las pruebas en verde;
- campaña con bots en las 3 dificultades, con 10 partidas o más por caso;
- **al menos dos personas** jugando Difícil;
- Release `v0.4.0`.

## ⏳ Pendientes

| Versión | Objetivo |
|---|---|
| ✅ Decisión | Historia elegida: **A, Buen Chico** (2026-11-22) |
| v0.5 | **Gancho narrativo (N01):** motivo y objetivo claros desde el inicio, y para qué te haces más fuerte. **Mundo 2 (Verdor):** enemigos, jefe, música, regla propia, mascota Brote y sus 2 armas y 2 habilidades. Hito "v0.5: Historia y Mundo 2" |
| v0.6 | Mundo 3 (Jackpot) |
| v0.7 a v0.9 | Mundos 4 a 6 |
| v0.10 | El giro, el acto final y el jefe final |
| v1.0 | Modos extra, pulido final y mundo secreto |

Con 3 mundos más el acto final, la historia igual funciona: si hay que recortar, se recortan mundos, no calidad.
