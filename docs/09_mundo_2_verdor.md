# 9. Mundo 2: Verdor

> **Propuesta para aprobar.** Es el entregable 1 del Issue #56. El mapa y los bocetos van después, cuando Iván apruebe este documento. Nada de esto está conectado al juego, y no se conecta hasta que salga la `v0.4.0`.

**Verdor es una selva que no para de hablar.** Es chismosa: lo cuenta todo, lo exagera todo y se entera de todo antes que tú. Su regla son las **nubes de polen, que esconden las balas**.

Este documento sigue la historia **A, Buen Chico** (`docs/04_historia_y_mundos.md`) y la idea del gancho narrativo (#55): un **objetivo por etapa**, y los jefes como **lo que impide seguir el viaje**. Todo lo que podría tocar el giro de la historia está marcado **"a revisar por Iván"**.

Los números son un punto de partida, a la misma escala que el Mundo 1 (`catalogo_niveles.gd`). Se ajustan midiendo con los bots (ver [Cómo se mide](#cómo-se-mide-con-los-bots)).

---

## 1. La historia del mundo, sin spoilers

**Por qué estás ahí.** El Mundo 1 termina con Calypso diciendo que "un mundo se acaba de apagar". Verdor es el mundo vivo más cercano, y la ruta del viaje pasa por él. Llegas para avisarle y ayudarlo antes de que el Hambre llegue.

**Qué pasa en Verdor.** La selva está histérica. Habla sin parar de lo que vio, de lo que escuchó y de lo que le contaron. Madre Flor, el corazón de la selva, se asustó y **cerró el centro con espinas**: nadie entra ni sale. Por ahí pasa tu ruta.

**Para qué te haces más fuerte aquí.** Para pasar a La Cotorra, que cuida el camino al centro, y para romper las espinas de Madre Flor. Sin eso, el viaje se queda en Verdor.

### Objetivo por etapa (la línea "Objetivo: …" del mapa, de #55)

| Etapa | Objetivo |
|---|---|
| Al llegar (2-1 a 2-3) | Averiguar qué le pasa a Verdor |
| 2-4 | Pasar a La Cotorra, que cuida el camino al centro |
| 2-5 a 2-7 | Llegar al centro antes de que Madre Flor lo cierre del todo |
| 2-8 | Abrirse paso hasta Madre Flor |
| Después de 2-8 | Seguir la ruta hacia Jackpot |

### Quién habla
- **Verdor** (nuevo): la voz de la selva. Chismosa y rápida, pregunta y responde sola. Necesita retrato y voz.
- **Don Tuerca, por radio:** se queda en el basural y habla por "la radio de un taxi", con interferencia. Sigue explicando y diciendo leseras.
- **Calypso:** seca, irónica, y en algún momento deja ver que sabe más de lo que dice.
- **Brote** (desde 2-3): la mascota nueva. Habla demasiado.
- **Mordisco**, la mascota de siempre, no habla, pero reacciona: Calypso comenta que mira feo a Brote ("creo que son celos"). Es para que la mascota siga importando (#55).

**A revisar por Iván:**
- qué sabe o qué piensa Madre Flor del Hambre;
- cómo termina Verdor después de 2-8: qué se salva y qué no ("siempre llegan tarde");
- las frases de Calypso que dejan ver que oculta algo;
- cómo calza Brote con la idea de que "tu mascota es lo que hace posibles las fusiones".

---

## 2. La regla del polen

### Qué hace
Hay **nubes de polen** que flotan por el campo. Una bala enemiga dentro de una nube **se ve tenue** (una silueta al 25 %, para probar) en vez de roja entera. Al salir de la nube vuelve a verse entera, al instante.

**La idea de diseño: el polen esconde de dónde vienen las balas, nunca adónde llegan.** Las nubes nacen y flotan en la parte de arriba, donde nacen las balas; cerca de tu nave nunca tapan nada.

### Las reglas que la hacen justa
1. **Burbuja de claridad.** En un radio de **40 px alrededor de la nave**, el polen nunca tapa nada. Una bala a 1,5-2 px por cuadro tarda unos 0,35-0,45 s en cruzarla: alcanza para reaccionar. Brote agranda la burbuja.
2. **Dónde nacen:**
   - solo en la parte de arriba (y < 220 de 360);
   - nunca a menos de 70 px de la nave;
   - bajan despacio (0,15-0,3 px por cuadro) y se deshacen antes de y = 260.
3. **Cuánto tapan.** Un tope de nubes y de cobertura por nivel, del 12 % del campo en el 2-1 al 25 % en el 2-7. Lo controla el director, igual que el tope de balas.
4. **Aparecen de a poco.** Una nube tarda 1 s en formarse: una bala que ya veías no desaparece de golpe.
5. **Siempre se ven, con polen o sin él:**
   - las líneas rojas de aviso (Sniper, Maravilla, Enredadera);
   - los núcleos rojos de los enemigos;
   - la hitbox rosada;
   - los Bits, las pizzas, los cofres y la chatarra.
6. **Tú lo abres:**
   - tus balas cian abren agujeros por donde pasan;
   - las explosiones abren agujeros más grandes;
   - la **esquiva sopla** una nube de 50 px alrededor de la nave.
   Así, el polen se vuelve algo que haces, no solo algo que te pasa.
7. **Los jefes no esconden sus patrones grandes.** En sus peleas hay poco polen, y nunca encima de un patrón nuevo (ver los jefes).
8. **Pista de movimiento (opcional, a probar):** donde pasa una bala oculta, el tramado de la nube se arremolina un poco, sin color rojo. Ves que algo viene, pero no su forma exacta.

### El polen y el Desync
El Desync es lo que más gusta, y el polen **no le quita nada**. Al revés: en Verdor, el Desync es **el momento en que se ve todo**.
- Al activar el Desync, las nubes quedan como un contorno tramado al 15 %. No esconden nada durante el **Desync**, la **reconexión** ni la **cascada**.
- Al terminar la cascada, las nubes de pantalla se deshacen. Es un premio visual más para la cascada, sin destellos.
- El filtro del Desync (`desync.gdshader`) no cambia: desatura y hace glitch igual que en el Mundo 1.
- **A probar:** rozar una bala dentro del polen carga un 50 % más de Desync. Premia arriesgarse sin obligar a nadie.

### Cómo se ve sin romper el código de colores
- **Color del polen:** verde salvia pálido y crema, de luminancia alta y saturación baja. Lejos del **rojo** (balas y núcleos), del **cian** (tus balas), del **dorado** (Bits) y del **rosado** (hitbox). No es amarillo, para no parecerse a los Bits.
- **Forma:** tramado Bayer (el mismo que usa el mapa), con motas chicas. **Nunca rombos**, para no parecer Bits.
- **Las balas** siguen rojas en todos los niveles y conservan el contorno oscuro. Dentro del polen bajan de opacidad, pero no cambian de color.
- **Daltonismo:** el rojo sobre el verde es la combinación más difícil para el daltonismo rojo-verde. Por eso la selva de fondo va **oscura y apagada**, y la bala se distingue por **luminancia y contorno**, no solo por color. Se revisa con una captura pasada por un simulador de daltonismo.
- **Capa de dibujo:** el polen va **debajo** de las balas. No se pinta una nube encima: cada bala calcula su opacidad según la densidad del polen en su punto. Así nada tapa la nave ni el HUD.

### Accesibilidad (las opciones que ya existen, en `juego/nucleo/ajustes.gd`)
| Opción | Qué hace con el polen |
|---|---|
| `atenuar_fondo` (0-100) | El polen cuenta como fondo: se oscurece con él, y la opacidad mínima de una bala tapada sube de 25 % a **70 %** con la opción al máximo (`0,25 + 0,45 × atenuar_fondo / 100`) |
| `reducir_destellos` | El tramado de las nubes no titila (queda quieto y solo se mueve con la nube). Las Esporas revientan sin destello blanco. La floración y los cambios de fase de Madre Flor usan el destello reducido que ya existe (`flash` × 0,25) |
| `sacudida` | Sin cambios: el polen no sacude la pantalla |

**Pregunta para Iván:** ¿basta con `atenuar_fondo` o conviene una opción propia ("Polen suave")? La propuesta es no sumar opciones y usar la que existe.

### Números por nivel
| Nivel | Nubes a la vez | Cobertura máxima | Notas |
|---|---|---|---|
| 2-1 | 2 | 12 % | Presenta la regla |
| 2-2 | 2 | 14 % | |
| 2-3 | 3 | 16 % | |
| 2-4 | 2 antes del jefe | 10 % | En la pelea, ver La Cotorra |
| 2-5 | 3 | 18 % | |
| 2-6 | 3 | 20 % | |
| 2-7 | 4 | 25 % | Con viento: las nubes cruzan más rápido |
| 2-8 | 2 antes del jefe | 10 % | En la pelea, ver Madre Flor |
| 2-C | Según el chisme | Hasta 25 % | |
| 2-INF | De 2 a 4 | Hasta 25 % | Sube con el tiempo |

Tamaño de cada nube: de 60 a 110 px de diámetro. Vida: de 10 a 16 s.

### Qué hace falta en código
- **`combate/polen.gd` (archivo nuevo**, para no agrandar `combate.gd`):
  - una grilla de densidad de celdas de 20 px, con nubes que nacen, flotan y se deshacen;
  - interfaz: `densidad(x, y)`, `abrir(x, y, radio)`, `tick(esc)`, `dibujar(cv)`, `fantasma(bool)` para el Desync y `limpiar()` para la cascada.
- **Dato nuevo en el nivel:** `"polen": {"max": 3, "cobertura": 0.18, "radio": [30, 55], "vida": [10, 16], "viento": 0.0}`. Sin ese campo, no hay polen: el Mundo 1 no cambia.
- **Dibujo de las balas:** su opacidad sale de `densidad()`, con el piso de `atenuar_fondo` y la burbuja de claridad.
- **Estadísticas nuevas en `res`:**
  - `golpes_ocultos`: golpes de balas que estuvieron tapadas en los últimos 24 cuadros;
  - `nubes_disueltas` y `roces_polen`.
- **Bot:** un modo que no ve las balas tapadas fuera de la burbuja, para medir si es justo (ver [Cómo se mide](#cómo-se-mide-con-los-bots)).
- **Pruebas:**
  - dentro de la burbuja, la opacidad siempre es 1;
  - en Desync, reconexión y cascada, la opacidad siempre es 1;
  - con `atenuar_fondo` = 100, nunca baja de 0,7;
  - con `reducir_destellos`, el tramado no cambia entre cuadros si la nube no se mueve;
  - ningún nivel pasa su cobertura máxima;
  - ninguna nube nace a menos de 70 px de la nave.

---

## 3. Niveles

8 niveles en camino y 2 extras, igual que el Mundo 1. Duran de 130 a 250 s, un poco más que en el Mundo 1, porque ya tienes con qué. **Estrellas:** terminar, recibir pocos golpes y llegar a una cadena larga. Las metas de cadena son provisionales: hay que recalibrarlas con lo que resuelva el #62, que propone que dependan de la dificultad.

| Nivel | Nombre | Qué presenta | Duración | Golpes ⭐ | Cadena ⭐ | Premio la primera vez |
|---|---|---|---|---|---|---|
| 2-1 | Aterrizaje con público | El **polen** y las **Esporas** | 130 s | 3 | 70 | **BASE DE VERDOR:** Railgun, Noob Tube, Headshot y Loot Goblin pueden salir siempre |
| 2-2 | Zumbido | Las **Abejas** y su **Panal** | 150 s | 3 | 90 | **PIEZA DE VERDOR:** una pieza del Mundo 2, Poco común |
| 2-3 | Maravillas | Las **Maravillas** (girasoles con puntería) | 170 s | 4 | 110 | **MASCOTA: BROTE** |
| 2-4 | La Cotorra | **Minijefe** | 160 s + jefe | 4 | 100 | **ENCARGOS DE VERDOR:** el Tablón suma los desafíos del Mundo 2 |
| 2-5 | Muralla verde | Las **Enredaderas**, que cierran caminos | 200 s | 5 | 130 | **PIEZA RARA DE VERDOR** (azul) |
| 2-6 | Puro cahuín | El **Zapallo** y la **Copuchenta**: elige bien a quién matar | 220 s | 5 | 140 | **+1 CAMBIO DE CARTAS** |
| 2-7 | Temporada de polen | Todo Verdor junto, con el polen al máximo y con viento | 250 s | 6 | 170 | **BOLSA DE CHATARRA:** 250 |
| 2-8 | Madre Flor | **Jefe del mundo** | 190 s + jefe | 6 | 150 | **PIEZA ÉPICA DE VERDOR** (morada), y se abren la Selva Infinita y la ruta a Jackpot |
| 2-C | El Cahuín | Extra, se abre con 2-4: la selva te cuenta chismes y tú eliges cuál creer | 180 s | 6 | 120 | **MASCOTA: CUNCUNA** (propuesta) |
| 2-INF | Selva Infinita | Extra, se abre con 2-8: todo Verdor, cada vez más fuerte | Sin fin | | | **RÉCORD:** chatarra y piezas según cuánto aguantes |

### Números del director (punto de partida)
Siguen la curva del Mundo 1 (1-1: dureza 1,0 → 1,5; 1-7: 1,3 → 3,8), un escalón más arriba.

| Nivel | Dureza (inicio → fin) | Agresión | Presupuesto de balas | Ritmo (inicio, fin) | Salva |
|---|---|---|---|---|---|
| 2-1 | 1,35 → 2,4 | 1,0 | 90 | 2,0 → 5,0 | 7,5 |
| 2-2 | 1,4 → 2,7 | 0,95 | 110 | 2,1 → 5,8 | 7,5 |
| 2-3 | 1,45 → 3,0 | 0,95 | 120 | 2,2 → 6,4 | 7,0 |
| 2-4 | 1,5 → 3,1 | 0,9 | 130 | 2,3 → 6,0 | 7,0 |
| 2-5 | 1,55 → 3,5 | 0,9 | 150 | 2,4 → 7,4 | 7,0 |
| 2-6 | 1,6 → 3,9 | 0,85 | 160 | 2,5 → 8,0 | 6,5 |
| 2-7 | 1,65 → 4,4 | 0,8 | 175 | 2,6 → 9,5 | 6,0 |
| 2-8 | 1,7 → 4,0 | 0,8 | 180 | 2,6 → 7,2 | 6,5 |
| 2-C | 1,5 → 3,0 | 0,9 | 140 | 3,0 → 7,2 | 5,5 |
| 2-INF | 1,6 | 0,9 | 160 | 3,2 → 10,5 (`ritmo_seg` 300) | 6,0 |

El presupuesto de balas parte **más bajo** que al final del Mundo 1 (1-7 llega a 150), porque el polen ya suma dificultad. La lección del Mundo 1 se mantiene: más enemigos con menos disparos cada uno.

**Las piezas del Mundo 2 empiezan a caer de a poco** (hoy todas tienen `"desde": ""`):
- Mira Térmica y Chip de Botín, desde 2-1;
- Casco de Espinas y Alas Cuchilla, desde 2-3;
- Motor Nitro y Reactor con Fuga, desde 2-5.

### Pistas en combate
| Nivel | Pistas |
|---|---|
| 2-1 | "Las nubes de polen esconden balas. Cerca de tu nave, nunca." · "Tus balas abren el polen. Tu esquiva, también." · "Las Esporas sueltan polen al morir." · "Con el DESYNC, el polen no tapa nada." |
| 2-2 | "Las Abejas se paran un instante antes de picar." · "Rompe el Panal y se acaban las abejas." |
| 2-3 | "Cuando la Maravilla cierra los pétalos, dispara." |
| 2-4 | "Sube de nivel todo lo que puedas: viene La Cotorra." · "La Cotorra repite cada ataque, al revés." |
| 2-5 | "La raya roja dice dónde va a crecer la Enredadera." · "Rompe el bulbo rojo y se seca entera." |
| 2-6 | "La Copuchenta pone nerviosos a los demás: mátala primero." · "Al Zapallo se le rompe la cáscara: ahí le duele." |
| 2-8 | "El pétalo que brilla es el que va a disparar." |

### Diálogos (borrador, cortos)
Mismo formato que `catalogo_dialogos.gd`. Hablantes nuevos: `verdor` y `brote`.

**antes_2-1**
- **Calypso:** "Verdor. Una selva entera, viva. Y por lo que escucho, no se calla nunca."
- **Verdor:** "¡Ay, visitas! ¿Esa nave es tuya o es prestada? Cuéntame todo. No, espera, yo te cuento primero."
- **Don Tuerca:** "¡Cabro! ¿Me escuchai? Te hablo con la radio de un taxi. Ojo con las nubes de polen: esconden las balas."
- **Don Tuerca:** "Si no ves nada, dispárale a la nube, que se abre. Y cerca de tu nave el polen no tapa nada. ¿Cachai?"
- **Calypso:** "Resumen: dispárale a todo. Como siempre."

**despues_2-1**
- **Verdor:** "¡Qué puntería! Se lo voy a contar a todos. Listo, ya se lo conté a todos."
- **Don Tuerca:** "Acá salen otros fierros: la Railgun, el Noob Tube y un par de mañas. Aprovéchalos, que son gratis. Raro, pero gratis."
- **Calypso:** "Nada es gratis."

**antes_2-2**
- **Verdor:** "Las abejas andan pesadas hoy. Bueno, siempre. Y su panal es pura copucha."
- **Don Tuerca:** "Se paran un segundito antes de picar: ahí te corres. Y si rompes el panal, se acaban."

**despues_2-2**
- **Don Tuerca:** "Mira, una pieza de acá. Huele a pasto. Ponle cariño, que pega."

**antes_2-3**
- **Verdor:** "Ojo con las Maravillas: te siguen con la cara. Se creen la muerte."
- **Calypso:** "En mi registro, una maravilla es un girasol. Aquí es un girasol con puntería."

**despues_2-3**
- **Don Tuerca:** "Cabro… ¿qué es esa cosa verde que se te subió a la nave?"
- **Brote:** "¡Hola! Soy Brote. ¿Sabías que la Maravilla tiene tortícolis? Yo sí. Yo sé todo."
- **Don Tuerca:** "Brote le cuenta a todos dónde le duele a cada enemigo. Al que sapea, le pegas más fuerte."
- **Calypso:** "Mordisco lo está mirando feo. Creo que son celos."

**antes_2-4**
- **Verdor:** "Para llegar al centro hay que pasar por La Cotorra. No deja pasar a nadie sin sacarle el chisme."
- **Don Tuerca:** "Esa repite todo, cabro. Lo que te tira, te lo vuelve a tirar al revés. Mira el primero y te salvas del segundo."
- **Calypso:** "Por fin alguien que habla más que Don Tuerca."

**despues_2-4**
- **Verdor:** "¡Le ganaste a La Cotorra! Ya lo sabe toda la selva. La mitad no te cree."
- **Don Tuerca:** "Te colgué encargos nuevos en el TABLÓN, de puras cosas de acá. Me cumples uno y te paso algo."

**antes_2-5**
- **Verdor:** "Las Enredaderas cierran los caminos. Son celosísimas. Como mi prima."
- **Don Tuerca:** "Antes de crecer marcan una raya roja. Y abajo tienen un bulbo rojo: lo rompes y se secan."

**despues_2-5**
- **Don Tuerca:** "¡Una pieza azul! Esta no la saqué de un taxi. Bueno, sí."
- **Calypso:** "Tengo un archivo sobre Verdor. Está bloqueado. Lo bloqueé yo." *(a revisar por Iván, coordinar con #55)*

**antes_2-6**
- **Verdor:** "¿Supiste? La Copuchenta le anda contando cosas a todos. Los pone nerviosísimos."
- **Don Tuerca:** "Mata primero a la Copuchenta. Y al Zapallo pégale hasta que se le rompa la cáscara."
- **Calypso:** "Un zapallo con armadura. Anotado."

**despues_2-6**
- **Don Tuerca:** "Te regalo otro cambio de cartas por partida. Me lo vendió una Copuchenta. No preguntís a cambio de qué."

**antes_2-7**
- **Verdor:** "Llegó la temporada de polen. Yo estornudo, tú esquivas."
- **Don Tuerca:** "Hoy hay polen por todos lados. Dispárale a las nubes y usa el DESYNC: con él, el polen no tapa nada."

**despues_2-7**
- **Don Tuerca:** "Una bolsa de chatarra. Olía a miel. Ya no."
- **Calypso:** "Madre Flor cerró el centro con espinas. Nuestra ruta pasa justo por ahí."

**antes_2-8**
- **Verdor:** "Madre Flor está asustadísima. Cuando se asusta, florece. Y cuando florece… bueno, vas a ver."
- **Don Tuerca:** "El pétalo que brilla es el que dispara, cabro. Rómpeselos. Y al centro rojo, con todo."
- **Calypso:** "No hay otra ruta. Hay que pasar por ella."

**despues_2-8** *(el cierre, a revisar por Iván)*
- **Verdor:** "…"
- **Calypso:** "Se quedó callada. Primera vez desde que llegamos."
- **Don Tuerca:** "¡Cabro! ¡Se abrió el camino! Te dejé abierta la SELVA INFINITA. Y en la radio se escucha una musiquita de casino. Mala señal."
- **Calypso:** "Próxima parada: Jackpot."

**antes_2-C**
- **Verdor:** "¿Te cuento un chisme? Te cuento tres. Tú eliges cuál creer. Lo que creas, pasa."
- **Calypso:** "Una selva que te deja elegir tus problemas. Qué considerada."

**despues_2-C**
- **Verdor:** "Mira quién se vino colgando: una Cuncuna. Te sigue para no perderse ningún chisme."

**antes_2-INF**
- **Don Tuerca:** "La Selva Infinita no para nunca. Igual que la selva cuando habla."

**Frases de combate nuevas:**
- Calypso, con mucho polen: "No veo nada. Tú tampoco." · "Polen. Lo bueno es que no tengo nariz."
- Brote (máximo una cada 30 s, en el panel lateral y nunca durante la reconexión): "Esa abeja me debe plata." · "No le digas a nadie, pero a ese le pegaste fuerte." · "¿Viste? La Enredadera está celosa." · "Uy, eso dolió. Se lo voy a contar a todos."

### Los extras
**2-C, El Cahuín** (el equivalente a la Ruleta de Don Tuerca, pero con elección):
- Tres veces en el nivel (al 30 %, 60 % y 90 %) el campo se limpia y la selva te cuenta **dos chismes**, como dos cartas. **Eliges cuál creer, y ese pasa.**
- Ejemplos:
  - "Dicen que viene un enjambre": una horda de Abejas que da muchos Bits;
  - "Dicen que La Cotorra anda cerca": aparece en chico, con mucha chatarra;
  - "Dicen que se viene el polen": doble polen y doble carga de Desync por roce;
  - "Dicen que hay un cofre perdido": un cofre;
  - "Dicen que Madre Flor anda de malas": una oleada difícil con una pieza de premio.
- **Cahuín completo:** creer tres chismes del mismo tipo da un premio grande, como los tres iguales de la Ruleta.
- **Justicia:** un chisme nunca miente sobre por dónde viene un ataque. Si un chisme "es falso", lo peor que pasa es que no pasa nada.

**2-INF, Selva Infinita:** igual que la Chatarrera Infinita. Mezcla todo Verdor, y el polen sube de 2 a 4 nubes con el tiempo. Cada cierto rato vienen La Cotorra y Madre Flor, por turnos. Guarda el récord.

### Qué hace falta en código para los niveles
- Entradas `2-1` a `2-8`, `2-C` y `2-INF` en `CatalogoNiveles.niveles()`, con el campo `polen`.
- **Datos por mundo en `datos.gd`:** hoy `NODOS`, `ORDEN_NIVELES`, `EXTRAS` y `PORTAL` son solo del Mundo 1. Hay que pasarlos a una estructura por mundo, y que `mapa.gd` sepa cambiar de mundo.
- **`combate.gd` asume el Mundo 1 en varios lugares:**
  - el fondo `fondo_chatarra_*` está fijo: hay que agregar un campo `fondo` por mundo;
  - `idx_nivel` decide cuándo los Bots apuntan adelantado: debe contar dentro del mundo, o pasar a ser un dato del nivel;
  - `_refuerzos_jefe` siempre llama Moscas: debe llamar a los del mundo (Abejas o Esporas);
  - el Infinito alterna La Grúa y El Compactador: debe usar los jefes del mundo.
- **Premios nuevos:**
  - el tipo `base`, una pantalla que muestra lo que se suma a la base;
  - `pieza` con un campo `mundo`;
  - el Tablón con los desafíos de un mundo.
- **El modo `cahuin`:** el director deja huecos como en la Ruleta, y la elección usa las cartas que ya existen.
- Diálogos `antes_` y `despues_` de cada nivel, con los hablantes `verdor` y `brote` (retrato y voz) y Don Tuerca "por radio" (un filtro en su voz y estática en el retrato).

---

## 4. Enemigos

Siete enemigos y dos jefes, como el Mundo 1. **Regla de oro:** todo lo que tiene núcleo rojo se rompe, y el rojo solo se usa en núcleos, balas y avisos.

**Paleta de Verdor:** verde musgo, verde lima apagado, morado orquídea, crema y corteza. Prohibido en los cuerpos: rojo (fuera del núcleo), cian, dorado y el rosado de la hitbox. Por eso **las abejas son moradas**, no amarillas: no se pueden confundir con los Bits, que es justo lo que pasó en la v0.2.

| id | Nombre | Rol (su par en el Mundo 1) | Tamaño | Vida | XP | `ia` | Cómo leerlo | Núcleo rojo |
|---|---|---|---|---|---|---|---|---|
| `espora` | Espora | Básico (Bot) | 32 | 18 | 3 | `ruta` (existe) | Sigue una ruta y dispara a veces, como el Bot. **Al morir suelta una nube chica de polen** (40 px, 3 s). Si muere dentro de la burbuja de la nave, no suelta nada | El ojo en el centro de la bola |
| `abeja` | Abeja | Enjambre (Mosca) | 24 | 9 | 1 | `abeja` (nueva) | Te persigue en picadas cortas. **Se para un instante (0,3 s) antes de cada picada**: se le ven las alas quietas. Muere de un toque | El aguijón encendido |
| `panal` | Panal | Ancla que molesta (Spammer) | 48 | 130 | 10 | `panal` (nueva) | Colgado arriba. **Vibra antes de soltar 3 Abejas** (cada 3,5 s, máximo 9 vivas por panal). Se agrieta con el daño. Mátalo y se acaban las abejas | La celda reina |
| `maravilla` | Maravilla | Francotirador (Sniper) | 40 | 55 | 6 | `maravilla` (nueva) | **Su cara te sigue.** Cuando deja de seguirte y cierra los pétalos (0,5 s, con una raya roja corta), dispara un abanico de 3 semillas hacia donde miraba | El centro de la flor |
| `enredadera` | Enredadera | Control del espacio (nuevo) | Bulbo de 32 y un tallo | 60 (el bulbo) | 6 | `enredadera` (nueva) | Nace del borde izquierdo o derecho. **Una raya roja punteada marca por dónde va a crecer (1 s).** Después el tallo cruza la mitad o dos tercios del campo, se queda 4 s y se recoge. Tocar el tallo duele; tus balas lo atraviesan | El bulbo, en el borde: si lo rompes, se seca entera |
| `copuchenta` | Copuchenta | Apoyo (Reparador) | 32 | 50 | 6 | `chisme` (nueva) | Una flor con oreja. **Se une a otro enemigo con una línea morada** y le "pasa el chisme": ese enemigo parpadea y dispara un 30 % más seguido por 5 s. Mátala primero | La campana de la flor |
| `zapallo` | Zapallo | Tanque (Compacto) | 48 | 280 | 18 | `zapallo` (nueva) | Rueda lento y dispara anillos de pepas, con un hueco cerca de ti. **Con la cáscara entera recibe la mitad del daño.** La cáscara se rompe a pedazos: sin ella recibe un 150 % | Se ve cuando se rompe la cáscara |

**Reservas** (si hace falta otro): la **Atrapamoscas**, una planta carnívora quieta que muerde si te quedas 0,6 s dentro de su radio, marcado con un círculo rojo punteado.

### Reglas para que sean justos
- **Enredaderas:**
  - una por lado como máximo;
  - entre dos tallos siempre queda un hueco de al menos 40 px;
  - nunca cierran la franja de abajo, donde suele estar la nave;
  - su aviso se dibuja encima del polen.
- **Abejas:** su pausa antes de picar es la lectura; con Difícil se acorta de 0,3 a 0,22 s, nunca menos.
- **Esporas:** su nube chica también cuenta para la cobertura máxima del nivel.
- **Copuchenta:** su línea es morada, para no confundirla con la verde del Reparador ni con las rayas rojas de aviso.

### Qué hace falta en código
- Entradas en `CatalogoNiveles.enemigos()`. Las `ia` nuevas, en `combate.gd` (`match e.def.ia`) o mejor en un archivo aparte (`combate/ia_verdor.gd`), por el R02:
  - `abeja`: picadas con pausa;
  - `panal`: suelta Abejas con `pendientes`, con tope;
  - `maravilla`: sigue a la nave, avisa y dispara en abanico;
  - `enredadera`: necesita **colisión de segmento** (tallo contra nave), que hoy no existe;
  - `chisme`: como `apoyo`, pero sube la cadencia en vez de curar;
  - `zapallo`: un `tanque` con cáscara; usa `mult_dano` como las mandíbulas del Compactador.
- Un campo nuevo `al_morir` (por ejemplo `"polen_chico"`), para la Espora.
- En `director.gd`:
  - `COSTO`: Abeja 0,9, Espora 2,2, Maravilla 6,5, Copuchenta 6, Enredadera 7, Panal 11 y Zapallo 17;
  - `TOPE_GRUPO`, `TOPE_VIVOS`, `DURA_VIVO` y `ALTURAS` de cada uno;
  - un origen nuevo para las Enredaderas: el borde lateral, a una altura dada.
- Rutas nuevas opcionales: `liana_izq` y `liana_der` (un balanceo).

---

## 5. Jefes

Los dos son **obstáculos de la historia**: La Cotorra cuida el camino al centro y Madre Flor cerró la ruta. Vencerlos abre el camino, no solo da botín. Ambos usan lo que ya existe:
- `fases`;
- `tope_seg` (el tope de daño: ninguna build los mata antes de tiempo);
- el respiro entre fases con pizza;
- "¡SE ENOJÓ!".

### La Cotorra (minijefe, 2-4)
**96 px · vida 2.000 · fases [0,5] · `tope_seg` 45 · XP 80.** Una cotorra enorme, verde y morada, con el núcleo rojo en el pecho. Se mueve de lado a lado arriba, como La Grúa.

**Su gracia: repite todo.** Cada ataque lo vuelve a tirar **en espejo** (de izquierda a derecha) unos segundos después, y lo anuncia con un globo: "¡…Y ENTONCES!". El primer ataque te enseña a esquivar el segundo.

| Fase | Patrones |
|---|---|
| **1** (100-50 %) | Abanico de 5 semillas apuntado, cada 1,5 s, **y su eco en espejo** 2,5 s después. Graznido: un anillo de 18 balas con hueco cerca de ti (como La Grúa), cada 3,7 s. Pide 6 Abejas cada 7 s, para que haya qué matar y con qué cargar el Desync |
| **2** (50-0 %) | El eco sale **dos veces**: en espejo a 1,8 s y normal a 3,2 s. Suma una "frase larga": una fila ondulada de balas que cruza de un lado al otro, con su eco. El graznido sale cada 3 s. Una nube de polen chica, solo en el borde de arriba |

**Polen en la pelea:** nada en la fase 1. En la fase 2, una nube, y nunca encima de un patrón nuevo: solo pueden quedar tapados los ecos, que ya viste una vez.

**Duración esperada:** 55-80 s con el equipo de la campaña.

### Madre Flor (jefe del mundo, 2-8)
**128 px · vida 8.000 + 6 pétalos de 250 · fases [0,66, 0,33] · `tope_seg` 55 · XP 250.** Una flor gigante anclada arriba al centro. Los pétalos son morados y crema, y el **núcleo rojo es su centro**: el estigma.

**Su gracia: florece en patrones.** Sus balas salen en **rosetones**: anillos con forma de flor, con pétalos de balas y huecos entre los pétalos. Los huecos son los caminos seguros, y el rosetón gira un poco cada vez.

| Fase | Qué es | Patrones |
|---|---|---|
| **1. Capullo** (100-66 %) | Cerrada. Recibe el 70 % del daño | Rosetón de 5 pétalos cada 2,2 s, girando. Un abanico de 3 semillas apuntado. Pide Esporas como refuerzo. Dos nubes de polen lentas, solo en la mitad de arriba |
| **2. Flor abierta** (66-33 %) | Se abre: aparecen **6 pétalos**, cada uno con un núcleo rojo chico | **Los pétalos disparan por turno, en el sentido del reloj, y el que va a disparar brilla 0,6 s antes.** Cada pétalo roto quita su ataque y suelta Bits. Cada 12 s **inhala**: las nubes van hacia ella y desaparecen (un respiro), y luego **exhala** una nube grande arriba |
| **3. Floración** (33-0 %) | Abierta entera. El centro recibe el 130 % | Dos espirales que giran en sentidos contrarios y arman un mandala con huecos claros. Cada 9 s, una Enredadera por lado, con su aviso. Los pétalos rotos **no vuelven**: romperlos en la fase 2 premia la fase 3 |

**Polen en la pelea:**
- se maneja con su inhalar y exhalar, y nunca tapa un patrón nuevo;
- en la fase 3 no hay polen: el mandala tiene que leerse entero.

**Duración esperada:** 100-150 s.

### Qué hace falta en código
- `ia` `cotorra`: una **cola de ecos**. Cada ataque se guarda (tipo, origen y ángulo) y se repite en espejo con su retraso. El globo usa los textos grandes que ya existen.
- `ia` `madre_flor`:
  - **partes de jefe** (los pétalos): un sistema nuevo. La propuesta más simple es que cada pétalo sea un `Enemigo` hijo, con `padre` y su posición relativa;
  - rosetones: una función `_roseton(x, y, petalos, balas, vel, giro)` junto a `_anillo`;
  - inhalar y exhalar le piden al polen que mueva y cree nubes.
- `_refuerzos_jefe` según el mundo.
- Música fija por jefe (ver la música).
- Pruebas: los ecos de La Cotorra son el espejo exacto del ataque; un pétalo roto no vuelve; el tope de daño se respeta con los pétalos.
- Diálogos con barra de jefe y aviso: "¡LA COTORRA!" y "¡MADRE FLOR!".

---

## 6. Brote

> En el catálogo ya está en silueta: "Algo verde. Habla demasiado."

**Qué es:** un brote con dos hojas y una boca muy grande. Se gana en el **2-3**. Mide 22-24 px y tiene 6 cuadros (4 de reposo y 2 de acción), como las demás mascotas. Es verde y crema, sin rojo, cian ni dorado.

**Qué hace: sapea.** Le cuenta a todos dónde le duele a cada enemigo.
- Cada cierto rato **marca al enemigo con más vida en pantalla**, con un globo "!" chico sobre él (blanco y verde). El marcado recibe **más daño por 4 s**.
- **El chisme se esparce:** si el marcado muere, la marca salta una vez al enemigo más cercano.
- Contra jefes también marca, pero **el bono pasa por el tope de daño**: no los mata antes de tiempo.
- **En Verdor, además, sopla el polen:** la burbuja de claridad crece.
- Habla: frases cortas en el panel lateral, como mucho una cada 30 s.

| Valor | Base | Por nivel | Tope |
|---|---|---|---|
| Recarga | 300 cuadros (5 s) | -4 | 150 (2,5 s) |
| Daño extra al marcado | +15 % | +0,5 % | +30 % |
| Burbuja de claridad extra | +6 px | +0,25 px | +12 px |
| `mods_nivel` | `{"crit_dmg": 0.004}` | | |

**Qué hace falta en código:**
- la `ia` `sapeo` en la mascota: la marca, su bono en `golpear` y el salto al morir;
- su sprite en `generar_v3_iconos.py` y sus frases (una clave nueva, como `textos_calypso`);
- la estadística `sapeos`;
- `desbloqueo: {"tipo": "nivel", "nivel": "2-3"}`.

### Cuncuna (propuesta: la segunda mascota de Verdor, premio del 2-C)
Una cuncuna (oruga) que da vueltas alrededor de la nave. **Cada cierto rato se enrolla y frena las balas enemigas cercanas** (radio de 50 px, al 50 % por 1,5 s). La recarga va de 600 a 300 cuadros. `mods_nivel: {"vel": 0.002}`. Necesita la `ia` `freno`, que reusa lo que ya hace la evolución de Frame Drop con las balas.

**Pregunta para Iván:** ¿se suma una segunda mascota en Verdor, o queda solo Brote, como dice hoy el catálogo?

---

## 7. Desafíos del Mundo 2

Hoy no hay ninguno. Se ven en el Tablón desde el **2-4** ("Encargos de Verdor"). Como las 26 armas ya tienen cómo conseguirse, **la propuesta no suma armas nuevas**: los premios son piezas fijas del Mundo 2, pinturas nuevas, chatarra y una pieza épica.

| id | Desafío | `stat` | Meta | Premio |
|---|---|---|---|---|
| `d2_esporas` | Mata a 80 Esporas | `k_espora` | 80 | 150 de chatarra |
| `d2_abejas` | Mata a 60 Abejas | `k_abeja` | 60 | Pintura **Orquídea** |
| `d2_panal` | Rompe 15 Panales | `k_panal` | 15 | Chip de Botín, Raro |
| `d2_maravilla` | Mata a 20 Maravillas | `k_maravilla` | 20 | Mira Térmica, Rara |
| `d2_enredadera` | Seca 20 Enredaderas por el bulbo | `k_enredadera` | 20 | Alas Cuchilla, Raras |
| `d2_copuchenta` | Mata a 15 Copuchentas antes de que pasen el chisme | `copuchentas_calladas` | 15 | Pintura **Musgo** |
| `d2_zapallo` | Rómpele la cáscara a 10 Zapallos | `k_zapallo` | 10 | Casco de Espinas, Raro |
| `d2_nubes` | Disuelve 40 nubes de polen | `nubes_disueltas` | 40 | Motor Nitro, Raro |
| `d2_roce_polen` | Roza 60 balas dentro del polen | `roces_polen` | 60 | Reactor con Fuga, Raro |
| `d2_cotorra` | Vence a La Cotorra 3 veces | `k_cotorra` | 3 | Pintura **Polen** |
| `d2_madre` | Vence a Madre Flor | `k_madre_flor` | 1 | Una pieza épica de Verdor |
| `d2_madre_dificil` | Vence a Madre Flor en Difícil | `v_2-8_dificil` | 1 | Pintura **Floración** |
| `d2_sapeo` | Brote sapea a 150 enemigos | `sapeos` | 150 | 200 de chatarra (requiere Brote) |
| `d2_cahuin` | Completa un cahuín | `cahuines` | 1 | 250 de chatarra |
| `d2_estrellas` | Consigue 20 estrellas en Verdor | `estrellas_m2` | 20 | 300 de chatarra |
| `d2_infinito` | Aguanta 4 minutos en la Selva Infinita | `inf2_seg` | 240 | Una pieza épica de Verdor |

**Qué hace falta en código:**
- `_d()` en `catalogo_progreso.gd` tiene `"mundo": 1` fijo: hay que sumarle un parámetro `mundo`;
- tipos de premio nuevos para los desafíos: `pintura`, `pieza` (id y rareza fijos) y `chatarra`;
- 4 pinturas nuevas en `pinturas()`, y que una pintura pueda venir bloqueada;
- estadísticas nuevas: `k_<enemigo>` de los 7 enemigos y los 2 jefes, `copuchentas_calladas`, `nubes_disueltas`, `roces_polen`, `sapeos`, `cahuines`, `inf2_seg` y estrellas por mundo;
- regenerar `memorias/inventario.md`.

---

## 8. Música y sonido

### Lo que haría falta
| Qué | Cuántos | Cómo debería sonar |
|---|---|---|
| Temas de nivel de Verdor | 3 o 4 | Selva con ritmo: percusión de madera, marimba o flauta, chiptune con swing. Movidos, como los "acción" de hoy |
| Tema de La Cotorra | 1 | Rápido, juguetón, entrecortado, como si hablara |
| Tema de Madre Flor | 1 | Épico y que crezca. Ideal si tiene un quiebre a mitad, para la Floración |
| Tema del mapa del Mundo 2 (opcional) | 1 | Calmo, de selva de noche |

### Reglas, las de siempre (`memorias/guia-arte.md` §9)
- **Licencia verificada en la página de cada obra**, anotada tema por tema en `LICENCIAS_MUSICA.txt`. Los CC-BY van en `CREDITOS.txt` y en Opciones. Sin IA.
- Sirve buscar primero en los autores que ya se usan, con la licencia revisada obra por obra.
- `preparar_musica.py`: -16 LUFS los niveles y -15 los jefes, recortados para partir en lo intenso.
- **Lo aprueba una persona escuchándolo.**

### Efectos nuevos (método sfxr, `generar_sfx.py`)
| Grupo | Efectos |
|---|---|
| Polen | `polen_puf` (soplido suave), `polen_abre` |
| Enemigos | `zumbido` (corto, con tope de voces a la vez para que no canse), `panal_rompe`, `maravilla_carga`, `enredadera_crece`, `enredadera_seca`, `zapallo_cascara` |
| Jefes | `cotorra_graznido`, `cotorra_eco`, `flor_abre`, `flor_petalo` |
| Brote | `brote_sapeo` |

**Voces** (`generar_voz.py`):
- **Verdor:** aguda, rápida, en ráfagas: chismosa;
- **Brote:** un pitito chico;
- **Don Tuerca por radio:** el mismo balbuceo, con un filtro de radio y un crujido.

### El Desync no cambia
La música se apaga y se pone lenta en el Desync, y vuelve con todo en la cascada, igual que hoy. El polen no toca la música.

### Qué hace falta en código
- `Sonido.TEMAS` con un campo `mundo` (0 = todos). En "Aleatorio", la rotación usa los temas del mundo actual más los generales.
- Tema fijo por jefe: un campo `musica` en el enemigo, en vez de la bolsa al azar de `JEFES`.

---

## 9. Arte (para los bocetos del entregable 3)

El motor SDF **sale peor en lo orgánico** (caras y plantas, `guia-arte.md` §1). Por eso todo Verdor se arma con **formas simples**:

| Qué | Formas |
|---|---|
| Espora | Esfera con conos chicos |
| Abeja | Elipsoides, con alas de toro aplanado |
| Panal | Hexágonos (`poligono` extruido) |
| Maravilla | Cilindro, con pétalos de elipsoide en anillo |
| Enredadera | Cápsulas encadenadas, con un bulbo de esfera |
| Copuchenta | Cono truncado, como una campana, con una oreja |
| Zapallo | Esfera achatada, con gajos de toro |
| La Cotorra | Elipsoides, con un pico de cono |
| Madre Flor | 6 pétalos de elipsoide alrededor de un núcleo de esfera roja |

- Rampas nuevas: musgo, lima apagado, orquídea, crema y corteza.
- Mismos tamaños que el Mundo 1: enemigos de 32 a 48 px, jefes de 96 y 128.
- Fondos de combate `fondo_verdor_lejos` y `fondo_verdor_cerca`, oscuros y apagados para que el rojo resalte.
- Se revisan en hoja de contacto **al lado del Mundo 1** y a escala de juego.

**El mapa** (entregable 2): un paisaje de selva de 1040×360 con su camino, hecho con `generar_mapa.py` o uno hermano. Sus nodos van en los datos. Para #55, **un borde de la selva gris o apagado** puede mostrar que el Hambre se acerca (a revisar por Iván).

---

## Cómo se mide con los bots

Los bots dicen si algo es imposible o si se puede abusar, no si es divertido (`aprendizajes.md`). **10 partidas o más por caso.** Los argumentos marcados *(nuevo)* hay que agregarlos.

```bash
# un nivel, bot bueno y torpe, en Normal y en Difícil
bash herramientas/probar.sh bot 10 --nivel=2-1 --generar=2-1 --dificultad=normal
bash herramientas/probar.sh bot 10 torpe --nivel=2-5 --generar=2-5 --dificultad=dificil
# el mismo nivel con la misma semilla, con y sin polen (nuevo: --sin_polen)
bash herramientas/probar.sh bot 10 --nivel=2-7 --generar=2-7 --semilla=7 --sin_polen
# el bot que no ve lo que tapa el polen (nuevo: --bot_polen)
bash herramientas/probar.sh bot 10 --nivel=2-7 --generar=2-7 --bot_polen
# el mundo entero en orden (nuevo: --mundo=2)
bash herramientas/probar.sh campana --mundo=2
```

| Qué se mide | Meta |
|---|---|
| **El polen es justo:** `golpes_ocultos` sobre los golpes, con `--bot_polen` | Menos del 10 %. Si pasa, se agranda la burbuja o se baja la cobertura |
| **El polen no es una muralla:** golpes con polen contra `--sin_polen`, misma semilla | Bot bueno: +1 golpe por nivel como máximo. Torpe: +2 como máximo |
| **El Desync sigue siendo el centro:** `desyncs` y `cascadas` por minuto | Igual que en el Mundo 1, ±15 % |
| **Presión en pantalla** (enemigos y balas, como en #33 y #42) | 2-1 parecido al 1-4, y 2-7 un 10-20 % sobre el 1-7. Difícil, al menos un 30 % más que Normal |
| **Jefes:** `t_jefes` y los golpes durante el jefe | La Cotorra 55-80 s y Madre Flor 100-150 s. Golpes en el jefe: bot bueno 2 o menos, torpe 5 o menos (Normal) |
| **Campaña** | Bot bueno, 24 de 24 estrellas. Torpe, 16 o más (en el Mundo 1 saca 17) |
| **El juego amenaza** | `--ciego` y `--quieto` pierden siempre |

Y lo que los bots no ven: **dos personas jugando Verdor**, una de ellas en Difícil, y una captura del polen pasada por un simulador de daltonismo.

---

## Issues de implementación propuestos

En orden. Los dos primeros destraban el resto.

| # | Título | Alcance |
|---|---|---|
| 1 | Mundo 2: datos por mundo (mapa, nodos, fondo y referencias al Mundo 1) | `NODOS`, `ORDEN_NIVELES`, `EXTRAS` y `PORTAL` por mundo; `mapa.gd` con cambio de mundo; fondo de combate por mundo; `idx_nivel`, `_refuerzos_jefe` y jefes del Infinito por mundo. Con el Mundo 1 igual que hoy, probado con `campana` |
| 2 | Mundo 2: sistema de polen | `combate/polen.gd`, el campo `polen`, la opacidad de las balas, la burbuja, el Desync, `atenuar_fondo` y `reducir_destellos`; las estadísticas `golpes_ocultos`, `nubes_disueltas` y `roces_polen`; el bot `--bot_polen` y `--sin_polen`; sus pruebas |
| 3 | Mundo 2: Espora, Abeja, Panal y Maravilla | Las `ia` `abeja`, `panal` y `maravilla`; el campo `al_morir`; costos y topes en el director; sprites con núcleo rojo |
| 4 | Mundo 2: Enredadera, Copuchenta y Zapallo | Las `ia` `enredadera` (con colisión de segmento), `chisme` y `zapallo`; las reglas de justicia de las Enredaderas; sprites |
| 5 | Mundo 2: minijefe La Cotorra | La `ia` `cotorra` con la cola de ecos, sprite de 96 px, aviso, tema, diálogos y pruebas del espejo |
| 6 | Mundo 2: jefe Madre Flor | La `ia` `madre_flor`, las partes de jefe (pétalos), los rosetones, inhalar y exhalar polen, sprite de 128 px, tema y pruebas |
| 7 | Mundo 2: niveles 2-1 a 2-8, premios y diálogos | Los niveles en el catálogo, las pistas, los premios `base`, `pieza` por mundo y el Tablón del mundo; los diálogos con `verdor`, `brote` y Don Tuerca por radio; la línea "Objetivo" (con #55) |
| 8 | Mundo 2: Brote (y Cuncuna, si se aprueba) | Las `ia` `sapeo` y `freno`, sprites, frases y estadística `sapeos` |
| 9 | Mundo 2: El Cahuín (2-C) y la Selva Infinita (2-INF) | El modo `cahuin` con los chismes como cartas; el Infinito de Verdor con sus jefes |
| 10 | Mundo 2: desafíos | `_d()` con mundo, premios `pintura`, `pieza` y `chatarra`, 4 pinturas, estadísticas nuevas e inventario |
| 11 | Mundo 2: música y efectos | Buscar y verificar licencias, `preparar_musica.py`, `TEMAS` por mundo, tema fijo por jefe y los efectos nuevos. Lo aprueba una persona escuchando |
| 12 | Mundo 2: voces y retratos | Verdor, Brote y Don Tuerca por radio en `generar_voz.py`, y el retrato de Verdor |
| 13 | Mundo 2: balance con bots y con personas | `campana --mundo=2` y las tablas de la sección anterior, antes y después; dos personas jugando |

El mapa (entregable 2) y los bocetos (entregable 3) siguen en el #56.

---

## Preguntas abiertas para Iván

1. **Don Tuerca:** ¿se queda en el basural y habla por radio, como propone esto, o viaja contigo?
2. **Verdor como personaje:** ¿la selva habla con su propio retrato? ¿Cómo te la imaginas: una cara de hojas, una flor, solo una voz?
3. **A revisar por el giro:**
   - qué sabe Madre Flor del Hambre;
   - cómo termina Verdor después del 2-8;
   - la frase de Calypso con el archivo bloqueado;
   - cómo calza Brote con que "tu mascota hace posibles las fusiones".
4. **Polen:** ¿cuánto se ve una bala tapada? La propuesta es 25 %; se puede probar con 0 %, 25 % y 40 % en capturas. ¿Basta con `atenuar_fondo` o quieres una opción "Polen suave"?
5. **Polen y Desync:** ¿te gusta que el Desync deje ver todo y que la cascada limpie el polen? ¿Y el +50 % de carga por rozar dentro del polen?
6. **Segunda mascota (Cuncuna):** ¿sí o no?
7. **Armas nuevas:** la propuesta es no sumar armas en Verdor, solo la base (Railgun, Noob Tube, Headshot y Loot Goblin). ¿De acuerdo?
8. **Premio del 2-8:** ¿una pieza épica basta, o quieres algo más grande, como una nave nueva?
9. **Metas de cadena:** ¿esperamos lo que resuelva el #62 (metas por dificultad) antes de fijarlas?
10. **Enemigos del Mundo 1 en Verdor:** la propuesta es que no aparezcan, ni siquiera en el Infinito. ¿De acuerdo?
11. **Nombres:** Maravilla, Copuchenta, Zapallo, Cuncuna, La Cotorra y El Cahuín, ¿van?
12. **Señal del Hambre en el mapa** (el borde gris): ¿se puede mostrar, o depende del giro?
