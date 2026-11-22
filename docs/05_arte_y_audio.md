# 5. Arte y audio

Decisión del proyecto: sin artistas ni músicos contratados, y sin pagar. El arte y los efectos se hacen con código; la música es material gratis hecho por personas, con licencia verificada. La guía práctica está en [memorias/guia-arte.md](../memorias/guia-arte.md).

## ¿Más bits?

No hacen falta. Lo que hace bonito un pixel art es la resolución, la paleta, la luz y la animación.

## Cómo se hace el arte

Es la técnica de [Dead Cells](https://80.lv/articles/interview-with-the-developers-of-dead-cells): modelos 3D renderizados como sprites. Hay un motor en Python ([herramientas/arte](../herramientas/arte)) que no usa IA de imágenes. Cada enemigo es una figura 3D hecha con formas simples, que se renderiza con paleta cerrada, luz por escalones y contorno.

| Ventaja | Límite |
|---|---|
| Las animaciones salen cambiando un número | Es peor con cosas orgánicas, como caras o plantas |
| Todo queda con el mismo estilo | Un buen pixel artist lo haría mejor |
| Un sprite tarda segundos | Lo tiene que aprobar una persona que juega |

## Especificación

| Cosa | Valor |
|---|---|
| Resolución base | 640×360, [la recomendada por Godot](https://docs.godotengine.org/en/latest/tutorials/rendering/multiple_resolutions.html) |
| Escalado | Solo enteros: exacto en 1080p (×3) |
| Zona de juego | 400×360, con paneles a los lados |
| Naves | 48×48 por cuadro, 6 modelos de 10 cuadros |
| Mapa del mundo | 1040×360: un paisaje con su camino de niveles |
| Iconos | 32×32: las 12 armas, 16 habilidades y 14 piezas tienen dibujo propio |
| Personajes | Don Tuerca a 128×128 y Calypso a 96×96, con boca animada |
| Letra | [Jersey 10](https://fonts.google.com/specimen/Jersey+10), licencia libre OFL. Se eligió comparando varias, para que los textos largos se lean bien |
| Enemigos | 32 a 48 píxeles |
| Jefes | 96 a 128 píxeles |
| Punto débil | Siempre un núcleo rojo |
| Balas enemigas | Siempre rosadas o naranjas |
| Tus balas | Siempre cian |
| Bits | Siempre dorados |

## Audio

**Límite real: quien genera el audio con código no puede escucharlo.** Se revisa que los sonidos no saturen y terminen en silencio; si suenan bien lo decide una persona.

### Música: 10 temas hechos por una persona

Son de [HoliznaCC0](https://freemusicarchive.org/music/holiznacc0/), de los álbumes [Ruby](https://freemusicarchive.org/music/holiznacc0/ruby-chiptunes) y [Amethyst](https://freemusicarchive.org/music/holiznacc0/amethyst-chiptunes). Licencia CC0 y marcados como no generados por IA, comprobado tema por tema al bajarlos ([detalle](../juego/audio/musica/LICENCIAS_MUSICA.txt)).

El tema se elige en Opciones. Desde la v0.3 hay más temas (ver abajo).

### Efectos: generados por código

La voz de Don Tuerca es un balbuceo hecho de sonidos cortos, como el de Dave en Plantas vs Zombies.

Usan el método de sfxr, el clásico de los juegos retro. Se cambian editando números en [generar_sfx.py](../herramientas/audio/generar_sfx.py). Para pedir un cambio conviene decir cuál y cómo: "muy agudo", "muy fuerte", "muy largo".

### Otras fuentes de audio gratis

| Opción | Qué es | Qué necesita |
|---|---|---|
| **[Kenney](https://kenney.nl/assets/sci-fi-sounds)** | Packs CC0 de efectos, gratis. Su sitio bloquea las descargas automáticas | Bajarlos a mano |
| **[Pack de The Game Creator](https://jonathan-so.itch.io/creatorpack)** | CC0, 12 temas retro, valorado 4,8 de 5, sin IA. Bloquea las descargas automáticas | Bajarlo a mano, en la opción gratis |
| **[ACE-Step](https://lilting.ch/en/articles/ace-step-1-5-music-generation)** | IA de música gratis, licencia MIT, corre en un PC propio | Python 3.11 y una GPU con varios GB (4 GB queda justo). Haría música a medida, con capas. Calidad sin evaluar |
| **Componer por código** | La música se escribe como código | [Strudel](https://glama.ai/mcp/servers/williamzujkowski/strudel-mcp-server) o MIDI con SoundFont. Es a ciegas, y la música hecha así en la v0.1 no convenció |

## Lo que todavía no hace

La música dinámica por capas. Los temas son archivos completos, así que no se pueden agregar instrumentos según la cadena. Sí se apaga y se pone lenta durante el Desync, y vuelve con todo en la cascada. Para tener capas se necesitan temas separados por instrumento.

## Cambios de la versión 0.3

- **Letra:** Barlow Semi Condensed en todo; Jersey 10 queda solo en el logo. El texto se dibuja a la resolución real de la pantalla y el arte sigue en pixel.
- **Generadores nuevos:** `herramientas/arte/generar_v3_iconos.py` y `generar_v3_escenas.py`; `herramientas/audio/generar_voz.py` y `preparar_musica.py`.
- **Música:** 28 temas, 120 MB. Licencias, tema por tema, en `juego/audio/musica/LICENCIAS_MUSICA.txt`. Los temas de Scott Buckley son CC-BY 4.0 y exigen nombrarlo: va en `CREDITOS.txt`, junto al juego, y en Opciones. Komiku pide no registrar su música en Content ID.
- **Volumen:** al 100 % son -5 dB, al 50 % son -13 dB y al 25 % son -21 dB. Cada tema tiene su ganancia medida para que no salten de volumen.
