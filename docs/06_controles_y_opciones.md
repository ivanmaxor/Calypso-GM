# 6. Controles y opciones

## Teclas principales y secundarias

Lo pidieron los jugadores de prueba, y **ya está en el juego**: Opciones, pestaña Teclas.

```
CONTROLES                                  [Teclado]  Mando

ACCIÓN            PRINCIPAL    SECUNDARIA      MANDO
Arriba            [ W ]        [ ↑ ]           Stick / Cruceta
Abajo             [ S ]        [ ↓ ]           Stick / Cruceta
Izquierda         [ A ]        [ ← ]           Stick / Cruceta
Derecha           [ D ]        [ → ]           Stick / Cruceta
Disparar          [ J ]        [ Z ]           RT
Foco (ir lento)   [ Shift ]    [ K ]           LT
Esquivar          [ Espacio ]  [ L ]           A
Desync            [ X ]        [ Clic der ]    Y
Pausa             [ Esc ]      [ P ]           Start

   Enter: cambiar   Supr: borrar      [Restaurar esta]  [Restaurar todas]
```

### Reglas

1. **Dos espacios de teclado y uno o dos de mando** por acción. Los botones del mouse cuentan como teclas.
2. **Conflictos.** Si eliges una tecla ocupada:
   > "X ya está en Desync." **[Intercambiar]** [Quitar de allá] [Cancelar]
3. **Nadie puede dejarse sin salida:**
   - Una acción no puede quedar sin ninguna tecla.
   - Los menús **siempre** aceptan flechas, Enter y Esc, aunque hayas cambiado todo.
   - Esc cancela la captura de tecla.
4. **Restaurar** una acción o todas.
5. **Lo que se ve en pantalla sigue a tu dispositivo.** Si usas mando, los avisos muestran botones de mando. Si usas teclado, tu tecla real.
6. **Opciones de accesibilidad:** Foco mantener o alternar, disparo mantener o automático.

### Cómo se hace

En Godot una acción puede tener varias teclas: [`InputMap.action_add_event`](https://docs.godotengine.org/en/latest/classes/class_inputmap.html) agrega más de una. Lo que **no** hace es guardarlas: [la documentación aclara](https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html) que eso lo tiene que hacer cada juego.

Hay una trampa conocida: [guardar los eventos directo no funciona](https://forum.godotengine.org/t/need-help-saving-controller-remaps/142711), porque se recuperan como referencias vacías. Por eso se guardan como datos simples y se reconstruyen al abrir:

```ini
; user://controles.cfg
[version]
numero=1

[teclado]
disparar=["key:J","key:Z"]
foco=["key:SHIFT","key:K"]
desync=["key:X","mouse:RIGHT"]

[mando]
disparar=["axis:RT"]
```

Si el archivo está dañado o viene de una versión antigua, se usan los valores por defecto sin caerse.

**Pruebas automáticas:** intercambio, conflicto, borrar la última tecla (debe impedirlo), guardar y cargar, archivo dañado.

## Lo que ya está en el juego

Las opciones se ordenan con una barra de pestañas arriba. Cada fila se cambia con izquierda y derecha, o con un clic.

| Pestaña | Opciones |
|---|---|
| **Pantalla** | Pantalla completa (también con F11), sacudida, reducir destellos, oscurecer el fondo |
| **Sonido** | Música, efectos, tema de música |
| **Teclas** | La tabla de arriba |
| **General** | Disparo automático, foco mantener o alternar, números de daño, borrar partida (pide confirmar) |

## Plan completo

Lo que sigue son ideas para más adelante.

### Video

| Opción | Valores |
|---|---|
| Ventana | Ventana, pantalla completa, sin bordes |
| Escala | Automática o entera a elección |
| V-Sync y límite de FPS | Sí/No, 60/120/144/sin límite |
| Filtro CRT | Apagado, suave, fuerte |
| Atenuar fondo | 0-80 %. Para ver mejor las balas |

### Audio

| Opción | Valores |
|---|---|
| Volumen | General, música, efectos, interfaz, chat |
| Mono | Sí/No |
| Silenciar sin foco | Sí/No |

### Jugabilidad

| Opción | Valores |
|---|---|
| Idioma | Español, inglés |
| Dificultad | Casual, Normal, Sweaty |
| Velocidad del chat | Lenta, normal, rápida |
| Omitir escenas vistas | Sí/No |
| Vibración | 0-100 % |

### Accesibilidad

Habría ayudado a un jugador de prueba que pasó 3 horas atascado en un jefe.

| Opción | Valores |
|---|---|
| **Modo Asistencia** | Velocidad 50-100 %, corazones extra, invencible, hitbox siempre visible |
| Sacudida de pantalla | 0-100 % |
| Reducir destellos | Sí/No |
| **Balas para daltonismo** | 3 paletas, y formas distintas por tipo |
| Tamaño de la interfaz | 100-200 % |
| Tamaño del chat | Normal, grande |
| Sin chat durante el combate | Sí/No |

### Streaming y datos

| Opción | Valores |
|---|---|
| Modo streamer | Oculta tu nombre real y lo sensible del chat. La música es propia, así que no da problemas de copyright |
| Estadísticas anónimas | **Apagadas por defecto.** Solo con permiso, para saber dónde muere la gente |
| Exportar partida | Abre la carpeta de guardado |

## Cambios de la versión 0.3

- **Menús con WASD además de flechas,** y Espacio además de Enter. Mantener una tecla repite.
- **En Opciones:** Enter o Abajo entran desde la pestaña, Q y E cambian de pestaña, y Esc retrocede de a un nivel.
- **"Borrar partida"** pasó a la pantalla de ranuras. En General hay un botón para volver a ver los textos de Don Tuerca.
