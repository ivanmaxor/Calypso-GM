# Guía de arte

Cómo se hace el arte de Calypso y cómo hacer arte nuevo que se vea igual. **Léela antes de tocar cualquier dibujo.**

## 1. Filosofía

- **Todo el arte sale de código.** No se usan generadores de imágenes con IA ni artistas externos. Es la técnica de Dead Cells (modelos 3D renderizados como sprites), escrita en Python con numpy y PIL.
- **Ventajas:**
  - todo tiene el mismo estilo;
  - una animación sale cambiando un número;
  - se puede rehacer cualquier sprite;
  - el resultado es **reproducible byte a byte**.
- **Límites conocidos:** sale peor en lo orgánico (caras, manos, plantas). Las manos de Don Tuerca son puños simples.
- A los jugadores **les encantan los diseños**. Lo nuevo tiene que verse igual a lo que ya está: **mismo motor, misma luz y mismas rampas de color**.
- **Nunca se edita a mano un PNG que sale de un generador:** se cambia el generador y se vuelve a generar.

## 2. El motor (`herramientas/arte/sdf.py`)

- **Formas:** `esfera`, `elipsoide`, `capsula`, `caja`, `cono_truncado`, `toro`, `cilindro` y `poligono` (un polígono extruido).
- **Operaciones y rotaciones:** `resta`, `union_suave` (une con una curva suave), `rot_x`, `rot_y` y `rot_z`.
- **`Rampa([5 colores])`:** paleta cerrada de oscuro a claro, una por material. Las de siempre están en `modelos.py` (casco morado, bocina rosada, oro y acero).
- **`renderizar(escena, rampas, ancho, alto, encuadre, centro, inclinacion, luz, ss, contorno, ...)`:**
  - raymarching a muy baja resolución, con supermuestreo `ss` (3 o 4);
  - **luz por escalones** desde arriba a la izquierda (`luz ≈ (-0.55, 0.75, 0.6)`; los iconos v3 usan `(-0.5, 0.7, 0.7)`) y luz de borde;
  - **contorno oscuro `#0d0a18`**.
  Devuelve RGBA con **alfa binario**: nada de semitransparencias en los sprites.
- **Revisión:** `a_imagen` y `escalar` para ampliar; `vista_previa.py` y `hoja_v2.py` arman hojas de contacto.

## 3. Qué genera cada script (y es dueño de eso)

Todos se usan como `python herramientas/arte/<script> juego [filtro]`. El filtro regenera solo los nombres que lo contienen (por ejemplo `mascota` o `icono_`).

| Script | Es dueño de |
|---|---|
| `modelos.py` + `generar_sprites.py` | Enemigos originales, explosiones, fondos de combate, cofres. Las mascotas ya **no** salen de aquí |
| `generar_v2.py` | Naves (48×48, 10 cuadros), iconos de las armas, habilidades y piezas originales, objetos, retratos y planetas |
| `generar_mapa.py` | El mapa del Mundo 1 (1040×360, con tramado Bayer). Dibuja el camino por `Datos.NODOS`: si cambian los nodos, se regenera |
| `generar_v3_iconos.py` | Iconos nuevos, proyectiles y objetos de combate, la Mosca y todas las mascotas. `--revisar` comprueba nombres, tamaños y transparencia |
| `generar_v3_escenas.py` | Don Tuerca de medio cuerpo, el Hangar (fondo + 6 estaciones) y `bala_pellet`. **Escribe las posiciones del Hangar en `juego/nucleo/sala_hangar.gd`**. Con `--montajes=<carpeta>` arma maquetas como se ven en el juego |
| `hoja_v2.py`, `vista_previa.py` | Hojas de revisión ampliadas |

Después de generar PNG nuevos, corre `bash herramientas/probar.sh import`.

Sobre el tiempo: `generar_v3_iconos.py` tarda unos 3 minutos y `generar_v3_escenas.py` unos 4. Con filtro, segundos.

## 4. Especificación

| Cosa | Valor |
|---|---|
| Pantalla lógica | 640×360, escala entera (`canvas_items`), filtro *nearest*, *snap* a píxel |
| Zona de combate | 400×360, con paneles a los lados |
| Naves | 48×48, 10 cuadros por hoja: índice = inclinación × 2 + llama |
| Iconos | 32×32. **Deben entenderse también a 16 px** y parecerse a lo que hacen: el misil se ve igual en la carta y en combate |
| Enemigos | 32 a 48 px. Jefes, de 96 a 128 px |
| Mascotas | 22, 24 y 28 px según su forma, 6 cuadros (4 de reposo y 2 de acción). Crecen poco entre formas y se distinguen bien entre sí |
| Don Tuerca | 128×128, 4 cuadros: 0 calla, 1 habla, 2 grita, 3 gesto |
| Calypso | 96×96 |
| Proyectiles | Miran hacia arriba. Hojas horizontales |
| Hangar | Fondo de 640×360 sin objetos, más 6 estaciones como sprites aparte. Nada tapa la franja superior de 26 px, y todo termina antes de y = 321, donde parte el cartel |

### Código de colores del combate (no se rompe)

| Qué | Color |
|---|---|
| Punto débil de los enemigos | **Siempre un núcleo rojo** |
| Balas enemigas | Rojas, rosadas o naranjas. **Rojas en todos los niveles** |
| Tus balas | Cian |
| XP (Bits) | Dorados, en rombo |
| Hitbox del jugador | Punto rosado `#ff6fb5` del tamaño real de lo que te puede pegar, con centro blanco |

En la v0.2, dos jugadores confundieron la XP con balas en el 1-1, porque ahí las balas tenían otro color. Por eso desde la v0.3 son rojas siempre.

### Naves con colores clave
- Las naves se dibujan con colores puros:
  - **rojo puro = casco**;
  - **verde puro = franja**;
  - **azul puro = llama**.
- Van en escalones de 40 por canal: 40, 80, 120…
- `juego/arte/nave.gdshader` los reemplaza por la pintura elegida y por los colores de la rareza de las alas y del motor.
- **Nunca uses esos colores puros para otra cosa en una nave.**

El efecto de pantalla del Desync es `juego/arte/desync.gdshader`: desatura y hace glitch con `hint_screen_texture`.

## 5. Cómo se revisa (nada se da por bueno sin verlo)

1. Hoja de contacto ampliada, **al lado del arte antiguo**, para comparar el estilo.
2. Maqueta a escala de juego, y el icono también a 16 px.
3. Revisión automática:
   - tamaño exacto, RGBA y fondo transparente;
   - sin alfas a medias ni cuadros vacíos;
   - nada cortado en el borde;
   - cada id de los catálogos tiene su icono.
4. Captura real dentro del juego, **mirada** antes de cerrar:
   ```bash
   bash herramientas/probar.sh cap <carpeta_absoluta> 60,300 --reiniciar --pantalla=hangar --salir=310
   ```
   Sale en 1280×720. Pantallas posibles: `mapa`, `hangar`, `combate`, `naves`, `panel`, `dialogo`, `premio`, `resultado` y `opciones`.
5. Si falta un dibujo, `Datos.tex()` devuelve un cuadro **magenta**: el juego no se cae y la falta se nota al probar.
6. En el PR van capturas de antes y después.

## 6. Identidad y tono

- **Don Tuerca:** viejo chatarrero chileno, buena onda y gritón; es el guía del juego, al estilo de Crazy Dave.
  - Rasgos que no se pierden: cono de tránsito de sombrero, antiparras disparejas, nariz roja, barba, overol azul con tirantes y llave inglesa.
  - En la v0.2 no se entendía su cuerpo (parecía una cabeza con patas); por eso desde la v0.3 es de medio cuerpo, con cuello, hombros y un mesón abajo.
- **Calypso:** la IA de la nave, seca e irónica.
- **El Hangar es el baño de Don Tuerca convertido en taller.** Es una sola habitación 3D con una sola cámara, y las estaciones son el locker, el excusado-fusionadora, el plato de la nave, la tina con camita, el computador y la puerta. Tiene chistes en el fondo:
  - "BAÑO" tachado sobre "HANGAR";
  - "EMPLEADO DEL MES" con Don Tuerca;
  - "FAVOR TIRAR LA CADENA AL FUSIONAR";
  - "CUIDADO: MUERDE";
  - "PISO MOJADO".
- **Orden de dibujo del Hangar:** las estaciones se dibujan **encima** del fondo. Un detalle del fondo que deba quedar delante de una estación tiene que ser un sprite aparte, dibujado después. Ese es el origen de M02.
- Los nombres de armas, habilidades y enemigos son humor gamer: Rush B, Ragequit, Lagswitch, Spawn Trap, Frame Drop…
- Los textos van en español de Chile, con tildes y cortos.

## 7. Historia de la letra

| Versión | Letra | Qué dijeron los jugadores |
|---|---|---|
| v0.1 | Bitmap propia de 5×7 | — |
| v0.2 | Jersey 10 (pixel, OFL) | "Muchos píxeles, muy gruesas, cuesta leer" |
| v0.3 | Barlow Semi Condensed (OFL), dibujada a la resolución real de la ventana; Jersey 10 solo en el logo | "Muy limpia, perdió el pixel art" (M05) y "la barra del jefe se ve demasiado HD" (M08) |

Para encontrar el punto medio:
1. Compara 3 o 4 opciones en **capturas reales** del diálogo, el Arsenal, las cartas y la barra de jefe, y que elijan las personas. Opciones posibles: otra fuente pixel más legible, la misma a otro tamaño, o dibujar el texto a la resolución lógica en vez de la de la ventana.
2. Verifica la licencia de cada fuente en su página.
3. Revisa que tenga **todos los glifos del español** (tildes, ñ, ¿ ¡). A una fuente vieja le faltaba el "·".

Las letras viven en `juego/arte/fuente/` y se cargan en `nucleo/datos.gd`.

## 8. Lo que quedó menos logrado (candidatos a pulir)

| Qué | Problema |
|---|---|
| `icono_ragequit` | Silueta enredada |
| `icono_lagswitch` | Recargado |
| `rueda_horda` | A 32 px los bichos quedan apretados |
| `obj_molotov` | Botella muy fina |
| Chispita | Puede leerse como abeja |
| Caparazón | Los hexágonos de la concha quedan como cuadrados |
| Puerta del Hangar | Se ve muy de lado |
| Oscurecido del Hangar (`OSCURO = 0.42` en `hangar_sala.gd`) | Apaga los chistes del fondo. Se sugirió 0,5-0,55 |

## 9. Audio (también es arte)

- **Efectos:** `herramientas/audio/generar_sfx.py`, con el método sfxr en numpy. Se ajustan cambiando números.
- **Voces:** `generar_voz.py`, con síntesis por formantes. Don Tuerca balbucea como Crazy Dave; Calypso es robótica y plana. `Sonido.voz()` encadena las sílabas por tiempo real y baja la música unos 4 dB mientras alguien habla.
- **Música:**
  - Solo con licencia verificada en la página de cada obra, anotada tema por tema en `juego/audio/musica/LICENCIAS_MUSICA.txt`. Los temas CC-BY exigen nombrar al autor (`CREDITOS.txt` y Opciones). Si un sitio bloquea las descargas automáticas, no se rodea: se busca otro o la baja una persona.
  - `preparar_musica.py` recorta, recodifica y mide: normaliza a -16 LUFS (los jefes a -15).
  - Curva de volumen: 100 % ≈ -5 dB, 50 % ≈ -13 dB y 25 % ≈ -21 dB.
  - Rotación aleatoria sin repetir, de al menos 3 minutos por tema, con fundido. Los jefes tienen tema de batalla.
- **Quien genera audio con código no puede escucharlo:** lo aprueba una persona.
