# 8. Gancho narrativo (N01)

> **Estado: propuesta.** Es el paso 1 del Issue #55. No hay nada programado: Iván la aprueba o la corrige, y recién después se implementa en `feature/N01-gancho-narrativo`.
>
> **Sin spoilers.** Este documento se escribió sin leer `docs/spoilers/`. Lo que podría chocar con el giro o tener doble sentido va marcado como **[revisar por el giro]**, y está todo junto en la sección 11.

## 1. Resumen

Hoy el combate engancha, pero el jugador no sabe por qué está en el basural ni para qué se hace más fuerte. La propuesta es amarrar el Mundo 1 a un motivo simple, que se ve y se repite:

1. **Prólogo de menos de un minuto:** vas a ayudar a un mundo chico, llegas tarde, algo enorme se lo traga (**el Hambre**), la onda de choque te bota y caes en el basural. Ahí te despierta un cachorrito alienígena, y después Don Tuerca.
2. **Objetivo grande:** arreglar la nave, cruzar el portal de Don Tuerca y, por una vez, **llegar a tiempo** al próximo mundo.
3. **Objetivo inmediato**, siempre escrito en el mapa: recuperar los pedazos de la nave, rescatar al cachorro, botar a La Grúa (que tapa la salida) y botar al Compactador (que se tragó la pieza del portal).
4. **Para qué te haces más fuerte:** la nave tiene que quedar entera para cruzar el portal ("pasa entera o llega en cachitos"), y los dos jefes son lo que impide salir.
5. **El Hambre se ve en el mapa:** una mancha que crece en el cielo, y Verdor pidiendo auxilio en la fila de mundos.

Casi todo se hace con lo que ya existe: diálogos con clave y `Partida.visto`, el mapa y los diálogos `antes_`/`despues_`. Lo nuevo es **una pantalla** (el prólogo), **un hablante** en el diálogo (la mascota) y **un dato** por nivel (el objetivo).

## 2. Qué entiende el jugador en los primeros 2 minutos

Cuenta desde que elige "Nueva partida": unos 15 s en ranuras y dificultad, unos 55 s de prólogo, unos 15 s del diálogo del mapa, y entra al 1-1.

| Pregunta del Issue | Cómo la contesta | Dónde |
|---|---|---|
| Quién soy y por qué estoy en el basural | Eres chatarrero, con tu nave y su IA. Ibas a ayudar a un mundo, la onda de choque te botó y caíste aquí | Prólogo, P1 a P5 y P9 |
| Qué es el Hambre y por qué me importa | Algo enorme que se traga mundos enteros. Lo viste pasar, y no era el último mundo de su ruta | Prólogo, P2, P3, P11 y P12 |
| Mi objetivo inmediato | Recuperar los pedazos de la nave, que se están llevando los robots | Prólogo P13, y la línea "Objetivo" del mapa |
| Mi objetivo grande | Arreglar la nave, cruzar el portal y llegar a tiempo al próximo mundo | Diálogo `inicio`, I2 |
| Para qué me hago más fuerte | Por el portal la nave pasa entera o llega en cachitos, y los jefes tapan la salida | `inicio`, I3, y los diálogos de los jefes |
| Por qué me importa la mascota | Es lo primero que ves al despertar. Se asusta, se esconde, y los robots la persiguen. Rescatarla es el objetivo del 1-2 y el 1-3 | Prólogo P6 y P8, y el mapa |

## 3. El prólogo, guion a guion

### Cómo se ve

Es una pantalla nueva, `juego/pantallas/prologo.gd`. Dibuja cuadros simples por código y encima usa la misma caja de diálogo de siempre. Cada línea trae el **cuadro** que se ve detrás:

| Cuadro | Qué se ve | Con qué se arma |
|---|---|---|
| `espacio` | Estrellas, un mundo chico a lo lejos y tu nave volando hacia él | Estrellas por código, `nave2_<nave>` y un planeta nuevo, `prologo_mundo` |
| `sombra` | Algo oscuro le tapa la luz al mundo y crece | Por código, con tramado como el del mapa. **Cómo se ve el Hambre lo decide Iván [revisar por el giro]** |
| `apagado` | El mundo queda negro. Silencio | El mismo planeta, oscurecido |
| `golpe` | Destello, la pantalla tiembla y la nave sale girando | Por código, más el efecto de explosión que ya existe |
| `negro` | Pantalla negra con un cursor de reinicio | Por código |
| `basural` | El basural, con tu nave enterrada entre un refri y una lavadora | Un trozo de `mapa_chatarra` y la nave. El cachorro, con `Datos.tex_mascota("mordisco", 0)` |

Toda animación usa el delta. La música: silencio en el espacio y `Sonido.musica_menu()` al llegar al basural.

### Las líneas

`(...)` en la línea de la mascota es una acción, no un diálogo: se escribe en gris. El nombre de la mascota se muestra como **???** hasta que la tienes (sección 5).

| # | Cuadro | Quién | Línea |
|---|---|---|---|
| P1 | espacio | Calypso | Registro de vuelo. Íbamos por chatarra, pero un mundo chico pidió auxilio. Ya casi llegamos. |
| P2 | sombra | Calypso | Algo le está tapando la luz. Es enorme y no sale en ningún mapa. |
| P3 | apagado | Calypso | Se lo tragó. Entero. Llegamos tarde. |
| P4 | golpe | Calypso | Onda de choque. Agárrate. Esto te va a doler más a ti que a mí. |
| P5 | negro | Calypso | Reiniciando. Registro de vuelo: dañado. Perdí los últimos minutos. **[revisar por el giro]** |
| P6 | basural | ??? (mascota) | (Algo chiquito y tibio te olfatea la cara. Huele a atún.) |
| P7 | basural | Don Tuerca | ¡Cabro! ¡Despertaste! Ya le había puesto precio a tus zapatos. |
| P8 | basural | ??? (mascota) | (Del susto, se esconde entre la chatarra.) |
| P9 | basural | Don Tuerca | Soy Don Tuerca, dueño de este basural. Caíste entre un refri y una lavadora. La lavadora quedó mejor. |
| P10 | basural | Calypso | Soy Calypso, la IA de la nave. Vengo incluida, como los virus. |
| P11 | basural | Don Tuerca | ¿Viste el cielo? Aquí le decimos el Hambre. Pasa, se come un mundo y sigue de largo. **[revisar por el giro]** |
| P12 | basural | Calypso | Y ese no era el último de su ruta. Hay que arreglar la nave y salir de aquí. |
| P13 | basural | Don Tuerca | Tu nave quedó repartida por todo el basural, y los robots locos se están llevando los pedazos. Anda a quitárselos, ¿cachai? |

**Duración:** son unos 930 caracteres. A la velocidad actual de `dialogo.gd` (0,9 letras por cuadro, unas 54 por segundo) se escriben en unos 17 s; con la lectura quedan entre 45 y 60 s. Enter completa la línea al tiro, así que quien lee rápido termina antes.

**Saltar:** Esc (o B en el mando, o el clic en "saltar todo") se salta **el prólogo entero**, no solo la línea. Se marca como visto con la clave `prologo` y no vuelve a salir.

**Lo que sale del `inicio` actual:** el zapato, el refri y la lavadora, y "Vengo incluida, como los virus" pasan al prólogo. "¿Ves esa nave? Es tuya. Bueno, ahora es tuya" se va, porque ahora la nave sí es tuya. "Si te matan, vuelves. Aquí nadie se muere de verdad: sale muy caro" pasa al `inicio` nuevo.

### El diálogo `inicio` (en el mapa, después del prólogo)

Se muestra la primera vez que se abre el mapa, como hoy. Presenta el camino y la línea de objetivo.

| # | Quién | Línea |
|---|---|---|
| I1 | Don Tuerca | Este es mi basural. El camino llega hasta mi portal, el único que sale de aquí. |
| I2 | Calypso | Plan: recuperamos la nave pieza por pieza, cruzamos el portal y llegamos a tiempo al próximo mundo. |
| I3 | Don Tuerca | Mientras más fuerte la nave, mejor. Por mi portal pasa entera o llega en cachitos. |
| I4 | Don Tuerca | Y si te matan, vuelves. Aquí nadie se muere de verdad: sale muy caro. |
| I5 | Calypso | Te dejé el objetivo escrito arriba. Por si se te olvida. Te conozco. |

## 4. El objetivo visible por etapa del Mundo 1

Una franja arriba del campo del mapa, bajo la fila de mundos: **OBJETIVO:** en dorado y el texto en blanco. Muestra el objetivo del **nivel que toca jugar** (`Partida.nivel_actual()`). Cuando cambia, parpadea "¡NUEVO OBJETIVO!" una sola vez (clave vista `objetivo_<id>`).

| Mientras toca... | Objetivo | Lo cuenta el diálogo |
|---|---|---|
| 1-1 | Recupera los pedazos de tu nave. Los tienen los robots. | Prólogo P13 |
| 1-2 | Encuentra al cachorro antes que los robots. | `despues_1-1` |
| 1-3 | Rescata al cachorro: lo tienen arrinconado. | `antes_1-3` |
| 1-4 | La Grúa tapa la salida del basural. Bótala. | `antes_1-4` |
| 1-5, 1-6 y 1-7 | Llega al Compactador: se tragó la pieza del portal. | `despues_1-4` y `antes_1-8` |
| 1-8 | Bota al Compactador y saca la pieza del portal. | `antes_1-8` |
| Mundo 1 terminado (hoy) | Verdor pide auxilio. Don Tuerca arregla el portal. | `despues_1-8` |
| Mundo 1 terminado (con Mundo 2 listo) | Cruza el portal y llega a Verdor antes que el Hambre. | Lo escribe la tarea del Mundo 2 |

Todos miden 55 caracteres o menos, para caber en una línea de unos 400 px.

**Para qué te haces más fuerte**, dicho en el juego:
- `inicio`, I3: el portal solo lo cruza una nave entera;
- `antes_1-4`: La Grúa no te deja salir;
- `antes_1-8`: sin la pieza que se tragó el Compactador no hay portal;
- `despues_1-4` y `despues_1-8`: Verdor pidió auxilio y el tiempo corre.

## 5. La mascota desde el principio

**Supuesto:** el cachorro de "Buen Chico" es **Mordisco**, la mascota del 1-3, que se come las balas y hace posibles las fusiones. Chispita, Imancito y Caparazón son otras criaturas. Si no es así, hay que cambiar esta sección (pregunta 1).

Su arco en el Mundo 1:
1. **Prólogo:** es lo primero que ves al despertar. Te olfatea y se esconde del grito de Don Tuerca.
2. **1-1 y 1-2:** se asoma en el mapa, sobre el camino, un poco más adelante que tu nave. Cuando ganas un nivel, aparece más adelante: va huyendo de los robots.
3. **1-3:** lo rescatas. Estaba metido en una lata de atún (el premio del 1-3 ya dice "Algo salió de una lata de atún"). Don Tuerca le pone Mordisco y te explica la fusión.
4. **Después:** vuela contigo, sale en el panel del mapa como hoy y reacciona en los diálogos.

**Un hablante nuevo, `mascota`:** no habla, hace cosas. Su línea va entre paréntesis y en gris, con su retrato (el sprite de la mascota en grande) y un chillido corto en vez de la voz. Su nombre es el que le puso el jugador (`Partida.nombre_mascota("mordisco")`), o **???** si todavía no la tiene.

**`{mascota}` en los textos:** se reemplaza por ese mismo nombre, como hoy se reemplaza `{esquivar}` por la tecla. Así, si el jugador le puso "Pelusa", Don Tuerca le dice Pelusa. El nombre puede tener hasta 14 letras: la prueba de que todo cabe usa uno de 14.

**Sus momentos** (las líneas están en la sección 7 y en la tabla de diálogos):

| Cuándo | Qué hace |
|---|---|
| Prólogo | Te olfatea. Se asusta y se esconde |
| `despues_1-3` | Te reconoce, se sube a la nave y no se quiere bajar. Mueve algo parecido a una cola |
| `antes_1-4` | Se esconde detrás de tu asiento: no le gustan las grúas |
| `despues_1-4` | Se come un perno de La Grúa y queda orgulloso |
| `despues_1-5` | Persigue al mapache y vuelve con tu billetera, sin una esquina |
| `despues_1-8` | Se come el sánguche de Don Tuerca. Y el plato |

A propósito, **la mascota nunca reacciona al Hambre** ni al cielo: eso podría insinuar algo del giro. Si Iván quiere ese momento, lo escribe él.

## 6. Lo que Calypso oculta, sin spoiler

Tres toques, cada vez un poco más claros. Calypso no dice qué hay: solo que hay algo.

1. **Prólogo, P5:** "Registro de vuelo: dañado. Perdí los últimos minutos."
2. **`despues_1-6`:** Don Tuerca le pregunta qué pasó antes de caer. Ella recuperó casi todo, pero hay un archivo que no va a abrir. "¿Por qué?" "Porque no."
3. **`despues_1-8`:** Don Tuerca le vuelve a preguntar, y ella le cambia el tema con sarcasmo.

**[revisar por el giro]:** si el registro dañado o el archivo cerrado chocan con lo que de verdad oculta Calypso, se cambian. No llevan número ni nombre a propósito.

**Opcional (pregunta 5):** una estación en el Hangar, "Archivo de Calypso", con un candado que nunca se abre en el Mundo 1. Necesita arte nuevo en `generar_v3_escenas.py`, así que no va en la primera implementación.

## 7. Los jefes como obstáculo de la historia

Hoy La Grúa y El Compactador son peleas con premio. La propuesta es que **sean lo que impide seguir el viaje**:
- **La Grúa** está apilando autos en la salida del basural: si no la botas, no sale nadie;
- **El Compactador** se tragó la bobina del portal de Don Tuerca: sin ella no se llega a Verdor.

En el mapa:
- mientras el 1-4 no esté ganado, el camino después de él se ve tapado por una pila de autos;
- el cartel del portal deja de decir "próximamente": antes del 1-8 dice "Portal a Verdor: le falta una pieza", y después, "Portal a Verdor: Don Tuerca lo está arreglando".

### La Grúa (1-4)

**`antes_1-4`** (cambia):

| Quién | Línea |
|---|---|
| Don Tuerca | ¿Escuchas ese ruido? Es La Grúa. Está apilando autos en la salida del basural. |
| Don Tuerca | Si no la botas, de aquí no sale nadie. Ni tú, ni {mascota}, ni yo, que igual salgo poco. |
| Mascota | (Se esconde detrás de tu asiento. No le gustan las grúas.) |
| Don Tuerca | Dispárale al núcleo rojo. Regla de oro: si tiene núcleo rojo, se rompe. |

**`despues_1-4`** (cambia; se conservan el Tablón y el Arsenal):

| Quién | Línea |
|---|---|
| Don Tuerca | ¡Botaste a La Grúa! Se me cayó encima de la caseta, pero el camino quedó libre. |
| Mascota | (Se come un perno de La Grúa. Parece orgulloso.) |
| Calypso | Llegó un pedido de auxilio. Viene de Verdor, el mundo al otro lado del portal. |
| Don Tuerca | ¿Verdor? Pucha. No paran de hablar, pero son buena gente. |
| Calypso | Si el Hambre va para allá, esta vez llegamos antes. No es una sugerencia. |
| Don Tuerca | Te colgué un TABLÓN en el Hangar. Ahí anoto encargos: me cumples uno y te paso un fierro nuevo. |
| Calypso | En el ARSENAL puedes prender o apagar lo que vayas ganando, para que solo te salgan las cartas que quieres. |

### El Compactador (1-8)

**`antes_1-8`** (cambia):

| Quién | Línea |
|---|---|
| Don Tuerca | Llegó la hora. El Compactador. Se comió mi camioneta, mi otra camioneta y a mi cuñado, que no hizo tanta falta. |
| Don Tuerca | Y la semana pasada se tragó la bobina de mi portal. Sin bobina, no hay Verdor. |
| Calypso | Cuando abre las mandíbulas se le ve el núcleo. Ahí recibe mucho más daño. |

**`despues_1-8`** (cambia; se conservan la Camper, la elección de nave, la Chatarrera Infinita, Nueva Partida + y Extremo):

| Quién | Línea |
|---|---|
| Don Tuerca | ¡LO HICISTE! ¡CAYÓ EL COMPACTADOR! ¡Y escupió mi bobina! Con baba, pero sirve. |
| Don Tuerca | Adentro venía también esta nave vieja: la CAMPER. Lenta, pero pega de lejos. Como mi abogado. |
| Don Tuerca | Ahora, antes de cada nivel, eliges con qué nave sales. Cada una trae su propia arma. |
| Calypso | La señal de Verdor se está debilitando. No nos sobra tiempo. |
| Don Tuerca | Dame un rato con el portal. Mientras, ¿quieres un sánguche? |
| Mascota | (Se come el sánguche. Y el plato.) |
| Don Tuerca | Oye, Calypso, ¿y el archivo ese? |
| Calypso | Sigue cerrado. Como tu caseta, pero con más dignidad. |
| Don Tuerca | Te abrí la CHATARRERA INFINITA, al final del camino: enemigos sin parar hasta que revientes. |
| Don Tuerca | Y si quieres, puedes partir de cero con todos tus fierros: NUEVA PARTIDA +, más duro y con mejor botín. O probar el modo EXTREMO. |

Se va la línea "Detecto algo raro más allá del basural. Un mundo se acaba de apagar": el mundo apagado ya se vio en el prólogo, y ahora la urgencia es Verdor.

### Los otros diálogos que cambian o se suman

| Clave | Cambio | Líneas |
|---|---|---|
| `despues_1-1` | Se suman dos líneas al final, para el objetivo nuevo | Calypso: "Los robots vieron al cachorro de esta mañana. Lo andan buscando." · Don Tuerca: "¡Encuéntralo tú primero, cabro! Pobre bicho, es chico y anda solo." |
| `antes_1-3` | **Nuevo** | Don Tuerca: "Los robots arrinconaron al cachorro aquí cerca. ¡Ándate rapidito!" · Calypso: "Rescatar mascotas no estaba en el plan. Me parece bien." |
| `despues_1-3` | Se reescribe: el cachorro ya lo conocías | Don Tuerca: "¡Cabro, cabro, cabro! ¡Mira quién estaba metido en una lata de atún!" · Mascota: "(Te reconoce. Se sube a la nave y no se quiere bajar.)" · Don Tuerca: "Muerde, pero muerde balas: las que pasen cerca de tu nave, se las come." · Don Tuerca: "Y se come cualquier fierro. Le das tres piezas iguales en el HANGAR y te escupe una mejor. Eso es FUSIONAR." · Don Tuerca: "Yo le diría Mordisco. Si quieres otro nombre, se lo cambias en el Hangar." · Mascota: "(Mueve algo parecido a una cola.)" · Calypso: "No sé qué le das de comer a esa cosa." |
| `despues_1-5` | Se suma una línea al final | Mascota: "(Persigue al mapache. Vuelve con tu billetera. Le falta una esquina.)" |
| `despues_1-6` | Se suman cuatro líneas | Don Tuerca: "Oye, Calypso, ¿y qué pasó antes de que cayeran?" · Calypso: "Recuperé casi todo el registro. Hay un archivo que no voy a abrir." · Don Tuerca: "¿Por qué?" · Calypso: "Porque no." **[revisar por el giro]** |
| `antes_1-7` | **Nuevo** | Calypso: "La señal de Verdor se corta a ratos. Si vamos a ir, que sea luego." · Don Tuerca: "Tranquila, la máquina. El Compactador no se va a ningún lado. Ese es el problema." |

Se quedan como están: `despues_1-2`, `antes_1-2`, `antes_1-5`, `despues_1-7`, `derrota`, la Ruleta, la Infinita y `nueva_plus`.

## 8. Señales del Hambre en el mapa

Que la amenaza se vea, no solo se cuente:

1. **Una mancha en el cielo** del mapa, sobre el portal, que crece en tres etapas: chica al empezar, más grande al ganar el 1-4 y enorme al ganar el 1-8. Late despacio (con el delta). Es una capa aparte, `mapa_hambre` (3 cuadros), que genera `generar_mapa.py` para que su chequeo de choques la conozca. Ojo: no debe tapar el 1-INF, que está arriba del portal. **Cómo se ve: [revisar por el giro]**.
2. **Verdor pide auxilio:** desde que ganas el 1-4, su planeta en la fila de arriba tiene un anillo que late, y su cartel suma "Pidió auxilio." al final.
3. **El portal** cambia de cartel (sección 7).
4. **La pila de autos** de La Grúa tapa el camino hasta que la botas (sección 7). No es el Hambre, pero hace visible el obstáculo.

Lo que **no** se propone, para no insinuar nada: que la mascota reaccione al cielo, que el basural mismo se oscurezca (daría a entender que el Hambre viene por Chatarra) y apagar planetas de la fila de mundos.

## 9. Qué cambia en el código, archivo por archivo

### Datos

| Archivo | Cambio |
|---|---|
| `juego/nucleo/catalogo_dialogos.gd` | Clave nueva `prologo`, cuyas líneas llevan un tercer elemento: el cuadro (`["calypso", "…", "espacio"]`). Hablante nuevo `mascota`. Cambian `inicio`, `despues_1-1`, `despues_1-3`, `antes_1-4`, `despues_1-4`, `despues_1-5`, `despues_1-6`, `antes_1-8` y `despues_1-8`. Nuevas `antes_1-3` y `antes_1-7` |
| `juego/nucleo/catalogo_niveles.gd` | Campo `"objetivo"` en los niveles 1-1 a 1-8. En `mundos()`, Chatarra suma `"objetivo_fin"` y Verdor suma `"auxilio": "1-4"` (el nivel desde el que pide ayuda) |
| `juego/nucleo/datos.gd` | `con_teclas()` también reemplaza `{mascota}`. Función nueva `objetivo_actual()`: el `objetivo` del nivel que toca, o el `objetivo_fin` del mundo si ya está todo ganado |
| `juego/nucleo/partida.gd` | `generar_para()` suma `prologo` a los vistos. Al cargar una partida que ya ganó el 1-1, se marca `prologo` como visto, para no frenar a quien ya juega (pregunta 3) |
| `memorias/inventario.md` | Se regenera, porque cambia un catálogo |

### Pantallas

| Archivo | Cambio | ¿Pantalla nueva? |
|---|---|---|
| `juego/pantallas/prologo.gd` | Dibuja los cuadros y usa `dialogo.gd` encima. Al terminar o con Esc, emite `terminado` | **Sí, la única** |
| `juego/pantallas/dialogo.gd` | Hablante `mascota` (retrato, nombre o ???, texto gris, chillido). Opción `velo := true` para no oscurecer el fondo en el prólogo. Señal `linea(i)` al pasar de línea, para que el prólogo cambie de cuadro | No |
| `juego/escenas/principal.gd` | Al entrar desde el título: si no se vio `prologo`, va a `ir_prologo()`, y de ahí a `ir_mapa()` con `inicio` | No |
| `juego/pantallas/mapa.gd` | La franja de objetivo, con "¡NUEVO OBJETIVO!" una vez. La mancha del Hambre por etapa. El anillo de Verdor. El cachorro asomándose sobre el camino (en un punto de `curva`, que ya está libre de utilería). La pila de autos después del 1-4. Los carteles nuevos del portal. El cartel del mundo enfocado tapa la franja mientras se muestra | No |
| `juego/pantallas/nueva_plus.gd` | Marca `prologo` como visto, igual que hoy marca `inicio` | No |
| `juego/pantallas/opciones.gd` | Sin cambio obligatorio: "Volver a verlos" ya borra los vistos, y con eso el prólogo vuelve a salir | No |

### Arte y audio (con los generadores, nunca a mano)

| Archivo | Qué genera |
|---|---|
| `herramientas/arte/generar_mapa.py` | La capa `mapa_hambre` (3 cuadros) y la pila de autos. Sube `FRANJA_ARRIBA` de 58 a unos 78 px, para que la franja del objetivo no tape utilería (hay que revisar el planeta rojo decorativo del cielo) |
| `herramientas/arte/generar_v2.py` | El planeta del prólogo, `prologo_mundo`, distinto de los 7 mundos |
| `herramientas/audio/generar_voz.py` (o `generar_sfx.py`) | Tres o cuatro chillidos cortos para la mascota |
| `juego/nucleo/sonido.gd` | `voz("mascota")` usa esos chillidos |

### Documentación del mismo PR de implementación

- `memorias/arquitectura.md`: el flujo suma `prologo` antes del primer mapa, y `dialogo.gd` el hablante `mascota`.
- `memorias/historia.md`: el prólogo y el objetivo del Mundo 1, sin spoilers.

## 10. Cómo se prueba

En `juego/pruebas/`:

- **Reglas (`pruebas_reglas.gd`):**
  - quien habla está en `tuerca`, `calypso` o `mascota`;
  - no queda ningún `{` después de `con_teclas()`, contando `{mascota}`;
  - **cada línea cabe en 3 líneas de 470 px** (hoy la prueba permite 4), con `{mascota}` reemplazado por un nombre de 14 letras anchas;
  - cada línea del prólogo tiene un cuadro que existe;
  - el prólogo entero suma 1.100 caracteres o menos (el presupuesto de un minuto);
  - cada nivel del 1-1 al 1-8 tiene `objetivo`, y el texto cabe en la franja medido con `UI.ancho`.
- **Recorrido de menús (`pruebas_menus.gd`):**
  - partida nueva: sale el prólogo; **un solo Esc** lo cierra entero y lleva al mapa con `inicio`;
  - partida nueva: el prólogo recorrido con Enter hasta el final llega al mismo lugar;
  - lo mismo con B del mando y con el clic en "saltar todo";
  - salir al título y volver a entrar: el prólogo no se repite;
  - Nueva Partida + y `generar_para()` no muestran el prólogo;
  - partida de antes que ya ganó el 1-1: no muestra el prólogo;
  - el objetivo del mapa cambia al ganar el 1-1, el 1-3, el 1-4 y el 1-8, y "¡NUEVO OBJETIVO!" sale una sola vez.
- **Capturas** (`probar.sh cap`): los 6 cuadros del prólogo, la caja de la mascota con un nombre de 14 letras, y el mapa en tres momentos (al empezar, tras el 1-4 y tras el 1-8). Nada se da por bueno sin mirarlas.
- Antes del commit, como siempre: `import`, `tests`, `flujo` y `flujo_hangar`. No toca combate ni balance, así que no hacen falta bots.

## 11. Preguntas abiertas para Iván

**Lo que hay que revisar por el giro:**
1. **El mundo del prólogo y cómo se ve el Hambre** (cuadros `sombra` y `apagado`, P2 y P3): ¿el mundo chico debe tener nombre? ¿El Hambre es una sombra, una boca, nada visible?
2. **El registro dañado (P5) y el archivo que Calypso no abre** (`despues_1-6` y `despues_1-8`): ¿calzan con lo que ella oculta de verdad?
3. **De dónde sale el cachorro:** en esta propuesta ya vivía en el basural y no tiene nada que ver con la caída. ¿Está bien, o su origen tiene que ser otro?
4. **P11, "Aquí le decimos el Hambre":** que Don Tuerca le tenga nombre implica que el Hambre ya pasó cerca antes. ¿Sirve, o es mejor que el nombre lo diga Calypso, o nadie?
5. **"Los robots locos":** hoy nadie dice por qué están locos, y la propuesta lo deja así a propósito. Si se quisiera culpar al Hambre, eso lo decide Iván.
6. **La mancha del Hambre en el mapa:** cómo se ve y si debe acercarse.
7. **"Buen Chico":** la propuesta no usa esa frase en el juego, por si tiene doble sentido. ¿Se puede usar (por ejemplo, que Don Tuerca le diga "¿quién es un buen chico?")?

**Lo demás:**
1. ¿El cachorro de la historia es Mordisco?
2. ¿El jugador le pone nombre al cachorro en el prólogo o en el 1-3, en vez de "Mordisco" por defecto? Sería un apego más rápido, pero suma un campo de texto al flujo.
3. Las partidas que ya ganaron el 1-1, ¿ven el prólogo una vez o se lo saltan? La propuesta se lo salta. Se podría sumar "Ver el prólogo" en Opciones.
4. ¿La línea de objetivo va siempre, o se puede apagar en Opciones?
5. ¿Se hace la estación "Archivo de Calypso" en el Hangar, con candado? Necesita arte, así que iría después.
6. ¿Un indicador de "nave reparada: 40 %" en el panel del mapa? Haría aún más concreto el "para qué me hago más fuerte", pero hay que decidir de qué sale ese número (estrellas, niveles de las piezas). La propuesta no lo incluye.
7. Al llegar el Mundo 2: el diálogo de cruzar el portal y el primer objetivo en Verdor se escriben en esa tarea, con este mismo formato.
