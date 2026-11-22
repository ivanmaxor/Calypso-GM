# 2. Investigación de videojuegos

Revisado el 1 de noviembre de 2026. Cuando una cifra viene de un tercero o de un análisis y no del estudio, se indica.

## Qué le robamos a cada juego

| Juego | Qué hace bien | Qué tomamos | Fuente |
|---|---|---|---|
| **Survivor!.io** | Equipo por rareza, de gris a rojo. Tres piezas se fusionan en una mejor. Habilidades que evolucionan y mascotas | **Todo el progreso de la nave y la mascota** | [Guía](https://www.pocketgamer.com/survivor-io/guide/), [Mascotas](https://www.pocketgamer.com/survivor-io/pets-guide) |
| **Cult of the Lamb** | Roguelite lineal: 4 biomas, 3 incursiones que suben de dificultad y una cuarta para el jefe. Unos 10 minutos por incursión, y el avance hacia la puerta del jefe se guarda | **La estructura de los mundos** | [Destructoid](https://www.destructoid.com/reviews/review-cult-of-the-lamb-pc-version-town-builder-action-roguelite/), [MP1st](https://mp1st.com/reviews/cult-of-the-lamb-review-the-sacrificial-lamb-pc) |
| **Hades** | Morir hace avanzar la historia y volver a casa da gusto. El Modo Dios sube tu resistencia con cada muerte | Morir tiene un motivo dentro de la historia. Ayuda opcional que crece al perder | [Inlander](https://inlander.com/culture/hades-writer-greg-kasavin-on-how-he-made-video-game-deaths-drive-a-feel-good-story-22725237), [GDC](https://gdconf.com/news/dive-dialogue-hades-gdc-2021), [MP1st](https://mp1st.com/news/hades-ps5-review-a-roguelite-god) |
| **Tetris Effect** | La Zona: llenas una barra, el tiempo se detiene, las líneas no se borran al tiro sino todas al final. Ayuda al novato y da profundidad al experto | **Desync, la mecánica central** | [Blog de PlayStation](https://blog.playstation.com/archive/2018/06/25/how-tetris-effect-adds-a-new-strategic-layer-to-a-decades-old-formula), [Prima](https://primagames.com/tips/how-zone-mechanic-works-tetris-effect-connected) |
| **Vampire Survivors** | Un novato se siente poderoso rápido. El cofre es un evento en sí mismo. Las armas evolucionan | Evoluciones y la escena del cofre | [The Conversation](https://theconversation.com/vampire-survivors-how-developers-used-gambling-psychology-to-create-a-bafta-winning-game-203613), [Boger](https://jboger.substack.com/p/the-secret-sauce-of-vampire-survivors) |
| **Balatro** | Los números suben por capas y el sonido escala (análisis de terceros) | La cascada de Desync y la cadena | [Crosley](https://blakecrosley.com/es/guides/design/balatro), [KrASIA](https://kr-asia.com/how-balatro-became-2024s-indie-darling) |
| **Brotato** | Oleadas de 20 a 90 segundos con tienda entre medio. Muchas opciones en total, pocas a la vez. Hecho en Godot por una persona | Combates cortos con decisión al final | [Adrian Hon](https://adrianhon.substack.com/p/brotato), [nota de prensa](https://www.gamespress.com/Brotato-10-Release), [Godot](https://godotengine.org/showcase/brotato/) |
| **Nova Drift** | Roguelite arcade espacial con builds. El rival más parecido, con cerca de 96 % de reseñas positivas (cifra aproximada). Sus controles de inercia dividen opiniones | Confirma que hay público. Evitamos la inercia | [Steam](https://store.steampowered.com/app/858210/Nova_Drift/), [Rogueliker](https://rogueliker.com/nova-drift-review/) |
| **NieR: Automata** | En el final E, partidas de otros jugadores te ayudan en un bullet hell | Tus partidas perdidas vuelven a ayudarte, sin servidor | [Kotaku](https://kotaku.com/theres-a-difficult-decision-at-the-end-of-nier-automat-1793071026) |
| **Celeste** | Modo Asistencia opcional: velocidad 50-100 %, invencibilidad | Modo Asistencia sin castigo | [Guidelines](https://gameaccessibilityguidelines.com/?p=3195), [New Normative](https://newnormative.com/2018/01/25/celestes-assist-mode-brings-welcome-accessibility-options) |
| **HoloCure** | Gratis para siempre en Steam, con reseñas abrumadoramente positivas | Prueba de que un juego gratis puede llegar lejos. Tenía una comunidad enorme detrás, que nosotros no tenemos | [Wikipedia](https://en.wikipedia.org/wiki/HoloCure_%E2%80%93_Save_the_Fans!), [PCGamesN](https://www.pcgamesn.com/holocure/update-new-characters), [3DJuegos](https://www.3djuegos.com/pc/noticias/uno-50-mejores-juegos-historia-steam-su-creador-no-ha-ganado-centimo-se-niega-a-monetizarlo-solo-quiere-que-gente-pruebe-holocure) |
| **Dead Cells** | Modelos 3D renderizados como sprites, porque el equipo no daba abasto dibujando a mano | La técnica de la prueba de arte | [80.lv](https://80.lv/articles/interview-with-the-developers-of-dead-cells), [Hardcore Gamer](https://hardcoregamer.com/previews/pax-east-2017-dead-cells-turns-constant-death-into-killer-metroidvania-action/250542/) |

## La idea del Tetris

La referencia más cercana a la gratificación que se buscaba es la **Zona de Tetris Effect**: en vez de borrar cada línea al completarla, se acumulan y se borran todas juntas al final. Eso es lo que da tanto gusto: **la recompensa se atrasa y se junta**.

La traducción a este juego es directa, y tiene una ventaja: el juego ya habla de lag. El peor momento de un gamer, que sus disparos no se registren, se vuelve el mejor momento del juego cuando todos se registran de golpe.

## Lo que dicen los shmups sobre la dificultad

- **Hitbox mínima.** En un bullet hell la zona que recibe daño es mucho más chica que la nave, y eso es lo que hace jugable una pantalla llena de balas ([Significant Bits](https://significant-bits.com/the-1-pixel-collision-box), [Shmups Wiki](https://shmups.wiki/library/Boghog's_bullet_hell_shmup_101)).
- **Roce (*graze*).** Pasar cerca de las balas da recompensa. Convierte el peligro en una decisión ([Crit Points](https://critpoints.net/2016/05/20/shmup-design/)).
- **Cancelar balas.** Al matar a quien disparó, sus balas se vuelven puntaje ([Nook Gaming](https://www.nookgaming.com/star-hunter-dx-review/)).

## Sensación de juego (*game feel*)

Las referencias de siempre son *The Art of Screenshake* y *Juice it or lose it* ([lista de Kenney](https://kenney.nl/learn/must-see-videos-for-indie-developers), [desglose de efectos](https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog/451576/quick-breakdown-of-all-the-effects)): pausa al impactar, retroceso, destello al disparar, sacudida. Son baratos y cambian todo. Por eso van en la primera fase, no al final.

## Publicar gratis

- El argumento a favor de lo gratis es alcance, público de prueba y portafolio. Las listas de deseados y gran parte del marketing están pensadas para juegos pagados ([Theorycraft](https://www.theorycraftmarketing.com/the-complete-steam-marketing-guide-for-indie-developers-2026), [Igor's Lab](https://www.igorslab.de/en/steam-is-giving-away-four-free-games-small-titles-clear-strategy/)). Son fuentes interesadas o de segunda mano: solo sirven de orientación.
- Por ahora el juego no se publica en tiendas. Si eso cambia, hay que revisar antes las reglas de la tienda sobre IA y marcas.

## Lo que no se pudo confirmar

- No se encontró un juego publicado en Steam con un análisis detallado de cómo se hizo con Claude Code. Sí hay proyectos en Godot hechos así, por ejemplo [Brandon Wu](https://thebrandonwu.substack.com/p/building-a-visual-novel-with-claude) y los de [esta recopilación](https://chierhu.medium.com/claude-code-for-game-development-7a88fcd19992), que además advierte que Claude no siempre conoce las rarezas de Godot.
- No hay una cifra publicada de cuántas balas aguanta cada plugin de Godot. Hay que medirlo.
- No se encontraron precios confiables de pixel art. Los valores van desde [US$10-40 la hora](https://freeup.net/hire/pixel-artist/) hasta [anécdotas sueltas](https://discussions.unity.com/t/how-much-would-i-likely-spend-on-my-game/647327). Hay que pedir cotizaciones.
