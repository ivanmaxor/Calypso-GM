# Registro de sesiones

La más reciente arriba. Cada entrada: fecha, **quién**, qué se hizo, archivos o módulos tocados, commits (hash corto) y pendientes.

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
