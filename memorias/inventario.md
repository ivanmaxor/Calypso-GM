# Inventario

> **Archivo generado.** No se edita a mano: sale de `juego/nucleo/catalogo_*.gd`. Para actualizarlo, ver la sección
> "Regenerar" al final. Si cambias el contenido del juego, regenera este archivo en el mismo PR.

Resumen: 26 armas, 30 habilidades, 6 naves, 10 mascotas, 22 piezas, 9 enemigos y jefes, 10 niveles, 53 desafíos.

Unidades: `cad`, `dur` y similares van en cuadros (60 por segundo). `dmg` se multiplica por el Ataque de la nave.

## Armas

| id | Nombre | Tipo | Qué hace | Daño base | Recarga (cuadros) | Sinergia | Evolución | Cómo se consigue |
|---|---|---|---|---|---|---|---|---|
| `pistola` | Pistola Doble | frontal | Dos disparos rectos y rápidos. | 0,3 | 12 | Doble Clic | Akimbo Total: Dos balas más y +25 % de daño | Base desde el Mundo 1 |
| `escopeta` | Escopeta | frontal | Abanico corto. Brutal de cerca. | 0,45 | 40 | Dedo Gordo | Point Blank: Más perdigones y más fuertes, y atraviesan | Base desde el Mundo 1 |
| `railgun` | Railgun | frontal | Lenta, atraviesa todo y pega fuerte. | 4 | 70 | Headshot | One Shot: Siempre es crítico y +30 % de daño | Base desde el Mundo 2 |
| `macro` | Macro | frontal | Una lluvia de balas poco precisa. | 0,3 | 6 | Spray and Pray | Macro Infinita: Sin dispersión, atraviesa y +70 % de daño | Base desde el Mundo 1 |
| `ping_pong` | Ping-Pong | frontal | Sus balas rebotan en los bordes y pierden fuerza. | 1,2 | 24 | Lag Compensation | DDoS: Al rebotar, la bala se divide en dos, y +70 % de daño | Base desde el Mundo 3 |
| `cohetes` | Noob Tube | frontal | Cohetes que explotan al impactar. | 1,3 | 50 | Reacción en Cadena | Tsar Noob: Explosiones enormes y +45 % de daño | Base desde el Mundo 2 |
| `misiles` | Misiles | misil | Lanza misiles que buscan enemigos y explotan. | 5 | 100 | Pay to Win | Ataque Premium: Un misil más y +25 % de daño | Base desde el Mundo 1 |
| `drones` | Duo Queue | drones | Dos drones te orbitan y le disparan al enemigo más cercano. | 0,8 | 30 | Buffer | Full Party: Dos drones más, y disparan más rápido | Base desde el Mundo 3 |
| `aura` | Tóxico | aura | Un aura daña a todo lo que se acerque. | 0,8 | 20 | Copium | Tilt Total: Aura enorme que además te cura un poco | Base desde el Mundo 4 |
| `rayo` | Reportado | rayo | Un rayo salta de enemigo en enemigo. | 2 | 80 | Stonks | Ban Masivo: Salta a muchos más y +30 % de daño | Base desde el Mundo 1 |
| `sierras` | Sierras | sierras | Sierras que giran a tu alrededor y cortan al tocar. | 1,2 | 16 | Pizza Fría | Cortapizza: Además cortan las balas enemigas, y +40 % de daño | Base desde el Mundo 1 |
| `laser` | Streamer Beam | laser | Cada cierto tiempo, un rayo continuo hacia arriba. | 0,85 | 170 | Ping 0 | Fibra Óptica: Mucho más ancho y sale más seguido | Base desde el Mundo 5 |
| `firewall` | Firewall | escudos | Dos escudos te orbitan. Cada uno frena un golpe, lanza una onda y vuelve a los segundos. | 3 |  | Main Tank | Muro de Fuego: Ondas enormes que además borran balas | Base desde el Mundo 7 |
| `rollback` | Rollback | boomerang | Sale, atraviesa todo y vuelve a tu nave. Pega a la ida y a la vuelta. | 1,7 | 60 | Aimbot | Ctrl+Z: Un boomerang más, y vuelven persiguiendo enemigos | Base desde el Mundo 4 |
| `minas` | Spawn Trap | minas | Lanza minas que estallan cuando alguien las toca. | 3,5 | 90 | Karma | Campo Minado: Cada mina suelta tres más chicas, y pegan más | Base desde el Mundo 5 |
| `molotov` | Molotov | zona | Revienta una botella en el enemigo y deja fuego en el suelo. | 0,55 | 110 | Buff Stacking | Incendio Forestal: Tira dos botellas y el fuego crece y quema más | Base desde el Mundo 6 |
| `rush_b` | Rush B | tajo | Un corte enorme por delante. Pega a todos, pero hay que estar cerca. | 2,5 | 40 | Bunny Hop | No Stop: Corta en círculo completo y rompe las balas de cerca | Desafío: Mata a 60 Moscas |
| `quickscope` | Quickscope | francotirador | De vez en cuando, un tiro certero al enemigo con más vida. | 7 | 120 | Frame Perfect | Montage: Un objetivo más y siempre es crítico | Base desde el Mundo 6 |
| `tornado` | Spin to Win | tornado | Suelta un remolino que vaga por el campo y golpea lo que toca. | 0,6 | 240 | Loot Goblin | Aspiradora: Además te trae los Bits y la chatarra | Base desde el Mundo 7 |
| `taladro` | Perforadora | frontal | Un taladro lento que atraviesa y sigue pegando mientras pasa. | 0,92 | 70 | Wallbang | Túnel: Mucho más grande y pega más seguido | Desafío: Mata a 1.000 enemigos |
| `gacha` | Gacha | frontal | Dados con daño al azar: de casi nada a una locura. | 0,8 | 18 | RNG Manipulado | Jackpot: Un dado más, y los dados altos estallan | Desafío: Gira la ruleta 4 veces |
| `ragequit` | Ragequit | cono | Un lanzallamas corto. Quema todo lo que tengas enfrente. | 0,36 | 6 | Clutch | Alt+F4: Más fuego, y con poca vida se vuelve enorme | Desafío: Pierde 10 veces |
| `frame_drop` | Frame Drop | onda_hielo | Una onda de hielo que daña y frena a los enemigos. | 3 | 150 | Lag Switch | Pantalla Congelada: También frena las balas enemigas | Desafío: Aguanta 3 minutos en el Modo Infinito |
| `sumidero` | Packet Loss | agujero | Abre un agujero que atrae enemigos y se traga las balas cercanas. | 0,5 | 300 | Combo Breaker | Pérdida Total: Al cerrarse, explota con todo lo que tragó | Desafío: Vence a El Compactador |
| `afk_farmer` | AFK Farmer | torreta | Deja una torreta donde estás. Dispara sola un buen rato. | 0,95 | 240 | Battle Pass | Bot Farm: Una torreta más, salen antes y sus kills dan chatarra | Desafío: Aguanta 5 minutos en el Modo Infinito |
| `speedhack` | Speedhack | rastro | Dejas fuego por donde pasas, y el fuego sube. Solo sirve si te mueves. | 0,7 |  | Macro de Teclado | Teletransporte: Tu esquiva deja una explosión, y el fuego quema más | Desafío: Consigue 15 estrellas |

## Habilidades

| id | Nombre | Qué hace | Por nivel | Nivel máximo | Hace evolucionar | Cómo se consigue |
|---|---|---|---|---|---|---|
| `spray` | Spray and Pray | Todas tus armas disparan más rápido. | +8 % de cadencia | 5 | Macro | Base desde el Mundo 1 |
| `p2w` | Pay to Win | Más daño. Punto. | +10 % de daño | 5 | Misiles | Base desde el Mundo 1 |
| `headshot` | Headshot | Más golpes críticos. | +5 % de crítico y +10 % de daño crítico | 5 | Railgun | Base desde el Mundo 2 |
| `aimbot` | Aimbot | Tus balas se curvan un poco hacia los enemigos. | Balas más teledirigidas | 3 | Rollback | Base desde el Mundo 5 |
| `doble` | Doble Clic | Tus armas frontales disparan más balas, un poco más débiles. | +1 bala, unos 25 % más de daño | 2 | Pistola Doble | Base desde el Mundo 1 |
| `wallbang` | Wallbang | Tus balas atraviesan enemigos. | Atraviesan +1 | 2 | Perforadora | Base desde el Mundo 3 |
| `lagcomp` | Lag Compensation | Tus balas rebotan en los bordes. | Rebotan +1 vez | 2 | Ping-Pong | Base desde el Mundo 4 |
| `fatfinger` | Dedo Gordo | Más grandes: explosiones, auras y órbitas. | +10 % de tamaño | 5 | Escopeta | Base desde el Mundo 1 |
| `ping0` | Ping 0 | Eres más rápido. | +6 % de velocidad | 5 | Streamer Beam | Desafío: Esquiva 50 veces |
| `buffer` | Buffer | La barra de Desync se llena más rápido. | +15 % de carga | 5 | Duo Queue | Desafío: Usa el Desync 10 veces |
| `combo` | Combo Breaker | La cascada del Desync pega más fuerte. | +15 % de daño en cascada | 5 | Packet Loss | Desafío: Usa el Desync 25 veces |
| `goblin` | Loot Goblin | Atraes los Bits y la chatarra desde más lejos. | +30 de imán | 5 | Spin to Win | Base desde el Mundo 2 |
| `stonks` | Stonks | Subes de nivel más rápido. | +10 % de experiencia | 5 | Reportado | Base desde el Mundo 1 |
| `copium` | Copium | Recuperas vida con el tiempo. | +0,3 de vida por segundo | 5 | Tóxico | Base desde el Mundo 3 |
| `pizza` | Pizza Fría | Más vida máxima, y te cura. | +15 de vida | 5 | Sierras | Base desde el Mundo 1 |
| `tank` | Main Tank | Un escudo absorbe un golpe y se recarga. | Se recarga antes | 3 | Firewall | Base desde el Mundo 4 |
| `thorns` | Karma | Cuando te golpean, sale una onda que daña a los que están cerca. | Onda más fuerte | 5 | Spawn Trap | Base desde el Mundo 7 |
| `lagswitch` | Lag Switch | A veces las balas te atraviesan sin hacerte nada. | +6 % de librarte | 3 | Frame Drop | Desafío: Esquiva 150 veces |
| `macrokeys` | Macro de Teclado | Tu esquiva se recarga antes. | Esquiva 10 % más seguido | 5 | Speedhack | Desafío: Esquiva 300 veces |
| `bunnyhop` | Bunny Hop | Mientras te mueves, pegas más fuerte. | +6 % de daño en movimiento | 5 | Rush B | Base desde el Mundo 6 |
| `clutch` | Clutch | Con poca vida, pegas mucho más fuerte. | +20 % de daño bajo 40 % de vida | 3 | Ragequit | Base desde el Mundo 5 |
| `leech` | Vampiro | Cada enemigo que matas te cura un poquito. | +0,1 de vida por kill | 5 | — | Base desde el Mundo 7 |
| `reaccion` | Reacción en Cadena | A veces, los enemigos explotan al morir. | +8 % de explotar | 5 | Noob Tube | Base desde el Mundo 6 |
| `rng` | RNG Manipulado | Más suerte y más cambios de cartas. | +1 cambio y +10 % de suerte | 3 | Gacha | Desafío: Cambia cartas 15 veces |
| `hardcore` | Hardcore | Los enemigos aguantan más, pero subes de nivel mucho más rápido. | +8 % de vida enemiga y +15 % de experiencia | 5 | — | Desafío: Gana un nivel en Difícil |
| `battlepass` | Battle Pass | Consigues más chatarra. | +20 % de chatarra | 5 | AFK Farmer | Desafío: Mejora piezas 20 veces |
| `hitboxchica` | Hitbox Chica | Tu punto débil se achica. | -15 % de hitbox | 3 | — | Desafío: Gana 3 niveles sin recibir golpes |
| `overclock` | Overclock | Tus balas vuelan más rápido. | +12 % de velocidad de bala | 5 | — | Desafío: Saca 3 estrellas en 5 niveles |
| `buffstack` | Buff Stacking | Fuego, torretas, rayos y remolinos duran más. | +12 % de duración | 5 | Molotov | Desafío: Fusiona piezas 10 veces |
| `framerate` | Frame Perfect | Rozar balas te da más daño por unos segundos. | +2 % de daño por roce | 5 | Quickscope | Desafío: Roza 600 balas |

## Naves

| id | Nombre | Arma inicial | Pasiva | Números | Cómo se consigue |
|---|---|---|---|---|---|
| `tryhard` | Tryhard | Pistola Doble | +1 cambio de cartas por partida | Vida 70, Velocidad normal | Desde el inicio |
| `camper` | Camper | Railgun | +15 % de daño tras 1 s sin moverte | Vida 60, Lenta | Vence a El Compactador (1-8) |
| `support` | Main Support | Duo Queue | Se cura con cada Desync y con el tiempo | Vida 100, Algo lenta | Usa el Desync 40 veces |
| `ballena` | La Ballena | Escopeta | +8 % de armadura | Vida 120, Muy lenta | Recibe 150 golpes |
| `speedrunner` | Speedrunner | Macro | Esquiva 35 % más seguido | Vida 55, Muy rápida | Evoluciona 2 armas |
| `smurf` | Smurf | Ping-Pong | +25 % de daño y carga Desync más rápido | Vida 45, Rápida | Haz una cadena de 200 |

## Mascotas

| id | Nombre | Mundo | Comportamiento (`ia`) | Qué hace | Cómo se consigue |
|---|---|---|---|---|---|
| `mordisco` | Mordisco | 1 | come | Se come las balas que pasan cerca. | Completa el nivel 1-3 |
| `chispita` | Chispita | 1 | chispa | Le da chispazos al enemigo más cercano. | Tu mascota come 150 balas |
| `imancito` | Imancito | 1 | iman | Te trae los Bits y la chatarra de todo el campo cada cierto rato. | Gana la Ruleta de Don Tuerca |
| `caparazon` | Caparazón | 1 | escudo | Cada cierto rato te da un escudo que frena un golpe. | Vence al Compactador en Difícil |
| `brote` | Brote | 2 |  | Algo verde. Habla demasiado. | Mundo 2: Verdor |
| `ficha` | Ficha | 3 |  | Apuesta tu suerte. | Mundo 3: Jackpot |
| `burbujin` | Burbujín | 4 |  | Tímido. Muy tímido. | Mundo 4: Abismo |
| `tetrin` | Tetrín | 5 |  | Odia el desorden. | Mundo 5: Tetra |
| `ascua` | Ascua | 6 |  | Ama pelear. | Mundo 6: Forja |
| `tomito` | Tomito | 7 |  | Se acuerda de todo. | Mundo 7: Archivo |

## Rarezas

| id | Nombre | Multiplicador | Probabilidad de caer |
|---|---|---|---|
| `gris` | Común | ×1 | 78 % |
| `verde` | Poco común | ×1,25 | 18,5 % |
| `azul` | Raro | ×1,6 | 3 % |
| `morado` | Épico | ×2 | 0,5 % |
| `dorado` | Legendario | ×2,5 | 0 % |
| `rojo` | Mítico | ×3,2 | 0 % |

## Piezas

Cada pieza da su base por rareza (× multiplicador) y suma un porcentaje de esa base por nivel de mejora, según la
dificultad de la partida: Fácil 12 %, Normal 10 %, Difícil 8 %, Extremo 8 %. Las pasivas se abren
según la rareza (`r`: 2 Poco común, 3 Raro, 4 Épico, 5 Legendario).

| id | Ranura | Nombre | Qué hace | Base | Pasivas | Mundo | Empieza a caer |
|---|---|---|---|---|---|---|---|
| `mira_laser` | mira | Mira Láser | Más ataque y más críticos. | atk 2, crit 0,01 | r2 +3 % de crítico; r3 +15 % de daño crítico; r4 +6 % de crítico; r5 +35 % de daño crítico | 1 | desde el inicio |
| `casco_lata` | casco | Casco de Lata | Vida extra, con algo de cariño. | hp 12 | r2 Recupera 0,15 de vida por segundo; r3 +3 % de armadura; r4 +5 % de armadura; r5 Revive una vez por partida | 1 | desde el inicio |
| `alas_ligeras` | alas | Alas Ligeras | Más velocidad. | vel 0,03 | r2 Roce más amplio; r3 +4 % de velocidad; r4 +25 de imán; r5 Roce mucho más amplio | 1 | desde el inicio |
| `motor_turbo` | motor | Motor Turbo | La esquiva se recarga antes. | dash_cd -0,03 | r2 +3 % de velocidad; r3 Esquiva 10 % más seguido; r4 Esquiva protege más tiempo; r5 Esquiva 15 % más seguido | 1 | desde el inicio |
| `chip_suerte` | chip | Chip de Suerte | Mejor botín y más chatarra. | suerte 0,04, chatarra 0,04 | r2 +6 % de experiencia; r3 +12 % de suerte; r4 +15 % de chatarra; r5 +30 % de suerte | 1 | desde el inicio |
| `reactor_lag` | reactor | Reactor de Lag | La barra de Desync se llena más rápido. | desync_carga 0,05 | r2 +0,3 s de Desync; r3 +10 % de carga; r4 +0,6 s de Desync; r5 +20 % de carga | 1 | 1-2 |
| `cargador` | mira | Cargador Rápido | Más ataque, y todo dispara más rápido. | atk 1,5, cadencia 0,01 | r2 +5 % de cadencia; r3 +6 % de daño; r4 +10 % de cadencia; r5 +15 % de daño | 1 | 1-3 |
| `casco_blindado` | casco | Casco Blindado | Menos vida, pero reduce todo el daño. | hp 7, armadura 0,02 | r2 +3 % de armadura; r3 +3 % de armadura; r4 +0,3 de vida por segundo; r5 Revive una vez por partida | 1 | 1-3 |
| `alas_iman` | alas | Alas Imán | Atrae Bits y chatarra desde más lejos. | iman 12, vel 0,01 | r2 +6 % de experiencia; r3 +25 de imán; r4 +10 % de experiencia; r5 +15 % de chatarra | 1 | 1-3 |
| `reactor_cascada` | reactor | Reactor de Cascada | La cascada del Desync pega más fuerte. | cascada 0,06 | r2 +6 % de carga de Desync; r3 +15 % de cascada; r4 +0,3 s de Desync; r5 +35 % de cascada | 1 | 1-4 |
| `mun_perforante` | mira | Munición Perforante | Mucho ataque. Tus balas atraviesan. | atk 2,5 | r2 Atraviesa +1; r3 +6 % de daño; r4 Atraviesa +1; r5 +1 bala en armas frontales | 1 | 1-5 |
| `motor_fantasma` | motor | Motor Fantasma | La esquiva te protege más tiempo. | dash_iframes 1,5 | r2 Esquiva 6 % más seguido; r3 +6 % de carga de Desync; r4 Esquiva protege mucho más; r5 +15 % de carga de Desync | 1 | 1-5 |
| `chip_critico` | chip | Chip Crítico | Más probabilidad de golpe crítico. | crit 0,01 | r2 +15 % de daño crítico; r3 +3 % de crítico; r4 +30 % de daño crítico; r5 +6 % de crítico | 1 | 1-5 |
| `mun_explosiva` | mira | Munición Explosiva | Más ataque y áreas más grandes. | atk 1,75, area 0,01 | r2 +6 % de tamaño; r3 +6 % de daño; r4 +10 % de tamaño; r5 +20 % de tamaño | 1 | 1-6 |
| `reactor_estable` | reactor | Reactor Estable | El escudo del Desync aguanta más. | desync_carga 0,02 | r2 +1 golpe de escudo en Desync; r3 +6 % de carga; r4 +1 golpe de escudo en Desync; r5 +0,5 s de Desync | 1 | 1-6 |
| `chip_xp` | chip | Chip de Experiencia | Subes de nivel más rápido en cada partida. | xp 0,03 | r2 +25 de imán; r3 +6 % de experiencia; r4 +1 cambio de cartas; r5 +15 % de experiencia | 1 | 1-6 |
| `mira_termica` | mira | Mira Térmica | Más daño a los enemigos con mucha vida. | atk 2,5, crit 0,01 | r2 +4 % de crítico; r3 +8 % de daño; r4 +25 % de daño crítico; r5 +15 % de daño | 2 | desde el inicio |
| `casco_espinas` | casco | Casco de Espinas | Al recibir un golpe, devuelve una onda. | hp 10, thorns 0,3 | r2 Onda más fuerte; r3 +3 % de armadura; r4 Onda mucho más fuerte; r5 Revive una vez por partida | 2 | desde el inicio |
| `alas_cuchilla` | alas | Alas Cuchilla | Más velocidad y daño al moverte. | vel 0,03, mov_dano 0,02 | r2 +3 % de daño en movimiento; r3 +4 % de velocidad; r4 +6 % de daño en movimiento; r5 +6 % de velocidad | 2 | desde el inicio |
| `motor_nitro` | motor | Motor Nitro | Esquivas más lejos y más seguido. | dash_cd -0,04 | r2 Esquiva 8 % más seguido; r3 +4 % de velocidad; r4 Esquiva protege más tiempo; r5 Esquiva 15 % más seguido | 2 | desde el inicio |
| `reactor_fuga` | reactor | Reactor con Fuga | Mucha carga de Desync, pero menos vida. | desync_carga 0,08, hp -3 | r2 +10 % de cascada; r3 +10 % de carga; r4 +25 % de cascada; r5 +20 % de carga | 2 | desde el inicio |
| `chip_botin` | chip | Chip de Botín | Mucha más chatarra. | chatarra 0,08 | r2 +6 % de suerte; r3 +15 % de chatarra; r4 +12 % de suerte; r5 +30 % de chatarra | 2 | desde el inicio |

## Enemigos y jefes

| id | Nombre | Vida | XP | Comportamiento (`ia`) | Jefe | Ayuda que ve el jugador |
|---|---|---|---|---|---|---|
| `mosca` | Mosca | 7 | 1 | enjambre |  | Chica y rápida. Viene en montón y te persigue. |
| `bot` | Bot | 16 | 3 | ruta |  | Básico. Sigue una ruta y dispara a veces. |
| `rabioso` | Rabioso | 20 | 3 | kamikaze |  | Parpadea y se lanza hacia ti. |
| `sniper` | Sniper | 50 | 6 | sniper |  | Muestra una línea roja y dispara por ahí. |
| `spammer` | Spammer | 100 | 10 | spammer |  | Sus burbujas se rompen a balazos. |
| `compacto` | Compacto | 240 | 18 | tanque |  | Muy resistente. Dispara anillos. |
| `reparador` | Reparador | 45 | 6 | apoyo |  | Cura a los demás: mátalo primero. |
| `grua` | La Grúa | 1200 | 60 | grua | Sí, fases en 0,5 | Minijefe. |
| `compactador` | El Compactador | 5000 | 200 | compactador | Sí, fases en 0,66, 0,33 | Jefe. Recibe más daño con las mandíbulas abiertas. |

## Mundos

1. **Chatarra**: Un basural con mal genio.
2. **Verdor**: Una selva que no para de hablar. *(cerrado)*
3. **Jackpot**: Un planeta casino. *(cerrado)*
4. **Abismo**: Un océano tímido y oscuro. *(cerrado)*
5. **Tetra**: Un mundo que odia el desorden. Caen bloques. *(cerrado)*
6. **Forja**: Un volcán que ama pelear. *(cerrado)*
7. **Archivo**: La memoria del universo. *(cerrado)*

## Niveles

| id | Nombre | Duración | Estrella 2 (golpes máx.) | Estrella 3 (cadena) | Enemigos | Jefe | Premio |
|---|---|---|---|---|---|---|---|
| `1-1` | Despertar en el basural | 100 s | 2 | 30 | bot |  | HANGAR |
| `1-2` | Algo se mueve | 130 s | 3 | 60 | bot, rabioso, mosca |  | DESYNC |
| `1-3` | ¿Y esa barra? | 160 s | 3 | 90 | bot, rabioso, mosca, sniper |  | MASCOTA Y FUSIÓN |
| `1-4` | La Grúa | 150 s | 4 | 90 | bot, rabioso, mosca, sniper, grua | grua | TABLÓN Y ARSENAL |
| `1-5` | Gritones | 190 s | 4 | 110 | bot, rabioso, mosca, sniper, spammer |  | PIEZA RARA |
| `1-6` | Mantención | 210 s | 5 | 120 | bot, rabioso, mosca, sniper, spammer, compacto, reparador |  | +1 CAMBIO DE CARTAS |
| `1-7` | Hora punta | 240 s | 5 | 150 | bot, rabioso, mosca, sniper, spammer, compacto, reparador |  | BOLSA DE CHATARRA |
| `1-8` | El Compactador | 180 s | 5 | 130 | bot, rabioso, mosca, sniper, spammer, compactador | compactador | NAVE: CAMPER |
| `1-R` | La Ruleta de Don Tuerca | 170 s | 6 | 100 | bot, rabioso, mosca, sniper, spammer, compacto, grua |  | MASCOTA: IMANCITO |
| `1-INF` | Chatarrera Infinita | sin fin | — | — | bot, rabioso, mosca, sniper, spammer, compacto, reparador, grua, compactador |  | RÉCORD |

## Dificultades

Multiplicadores sobre Normal: `hp` y `dano` de los enemigos, `vel` de sus balas, `disparo` = tiempo entre disparos
(menos es más seguido), `botin` y `chatarra`.
Presión: `ritmo` multiplica los enemigos por segundo del director, `inicio` sube además el comienzo,
`ganas` es cuánto disparan los Bots al empezar el nivel, `salva` = tiempo entre salvas y `jefe cd` = tiempo
entre ataques de los jefes (menos es más seguido).

| id | Nombre | hp | daño | vel | disparo | botín | chatarra | ritmo | inicio | ganas | salva | jefe cd | Notas |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `facil` | Fácil | 0,8 | 0,7 | 0,9 | 1,25 | 0,85 | 1 | 1 | 1 | 0,35 | 1 | 1 |  |
| `normal` | Normal | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0,35 | 1 | 1 |  |
| `dificil` | Difícil | 1,15 | 1,2 | 1,1 | 0,9 | 1,2 | 1,2 | 1,4 | 1,3 | 0,7 | 0,75 | 0,85 |  |
| `extremo` | Extremo | 1,45 | 1,5 | 1,2 | 0,8 | 1,5 | 1,5 | 1,6 | 1,4 | 0,85 | 0,65 | 0,75 | sin pizzas, requiere terminar |

## Desafíos

| id | Mundo | Desafío | Meta | Premio |
|---|---|---|---|---|
| `a_cohetes` | 1 | Mata a 25 Rabiosos | 25 | arma Noob Tube |
| `a_ping_pong` | 1 | Roza 80 balas | 80 | arma Ping-Pong |
| `a_railgun` | 1 | Mata a 15 Snipers | 15 | arma Railgun |
| `a_firewall` | 1 | Gana un nivel sin recibir golpes | 1 | arma Firewall |
| `a_drones` | 1 | Usa el Desync 5 veces | 5 | arma Duo Queue |
| `a_aura` | 1 | Gana 8 niveles | 8 | arma Tóxico |
| `a_rollback` | 1 | Haz una cadena de 60 | 60 | arma Rollback |
| `a_minas` | 1 | Mata a 15 Spammers | 15 | arma Spawn Trap |
| `a_laser` | 1 | Haz 3 ACE | 3 | arma Streamer Beam |
| `a_molotov` | 1 | Mata a 10 Compactos | 10 | arma Molotov |
| `a_rush_b` | 1 | Mata a 60 Moscas | 60 | arma Rush B |
| `a_quickscope` | 1 | Vence a La Grúa 3 veces | 3 | arma Quickscope |
| `a_tornado` | 1 | Recoge 1.500 de chatarra | 1500 | arma Spin to Win |
| `a_taladro` | 1 | Mata a 1.000 enemigos | 1000 | arma Perforadora |
| `a_gacha` | 1 | Gira la ruleta 4 veces | 4 | arma Gacha |
| `a_ragequit` | 1 | Pierde 10 veces | 10 | arma Ragequit |
| `a_sumidero` | 1 | Vence a El Compactador | 1 | arma Packet Loss |
| `a_frame_drop` | 1 | Aguanta 3 minutos en el Modo Infinito | 180 | arma Frame Drop |
| `a_afk_farmer` | 1 | Aguanta 5 minutos en el Modo Infinito | 300 | arma AFK Farmer |
| `a_speedhack` | 1 | Consigue 15 estrellas | 15 | arma Speedhack |
| `h_goblin` | 1 | Recoge 300 de chatarra | 300 | hab Loot Goblin |
| `h_copium` | 1 | Gana 3 niveles | 3 | hab Copium |
| `h_headshot` | 1 | Haz una cadena de 40 | 40 | hab Headshot |
| `h_ping0` | 1 | Esquiva 50 veces | 50 | hab Ping 0 |
| `h_aimbot` | 1 | Mata a 500 enemigos | 500 | hab Aimbot |
| `h_wallbang` | 1 | Mata a 30 Snipers | 30 | hab Wallbang |
| `h_lagcomp` | 1 | Roza 250 balas | 250 | hab Lag Compensation |
| `h_buffer` | 1 | Usa el Desync 10 veces | 10 | hab Buffer |
| `h_combo` | 1 | Usa el Desync 25 veces | 25 | hab Combo Breaker |
| `h_tank` | 1 | Recibe 50 golpes | 50 | hab Main Tank |
| `h_thorns` | 1 | Mata a 30 Moscas | 30 | hab Karma |
| `h_lagswitch` | 1 | Esquiva 150 veces | 150 | hab Lag Switch |
| `h_macrokeys` | 1 | Esquiva 300 veces | 300 | hab Macro de Teclado |
| `h_bunnyhop` | 1 | Gana 20 niveles | 20 | hab Bunny Hop |
| `h_clutch` | 1 | Gana un nivel con menos de 15 % de vida | 1 | hab Clutch |
| `h_leech` | 1 | Mata a 2.500 enemigos | 2500 | hab Vampiro |
| `h_reaccion` | 1 | Evoluciona 3 armas | 3 | hab Reacción en Cadena |
| `h_rng` | 1 | Cambia cartas 15 veces | 15 | hab RNG Manipulado |
| `h_hardcore` | 1 | Gana un nivel en Difícil | 1 | hab Hardcore |
| `h_battlepass` | 1 | Mejora piezas 20 veces | 20 | hab Battle Pass |
| `h_hitboxchica` | 1 | Gana 3 niveles sin recibir golpes | 3 | hab Hitbox Chica |
| `h_overclock` | 1 | Saca 3 estrellas en 5 niveles | 5 | hab Overclock |
| `h_buffstack` | 1 | Fusiona piezas 10 veces | 10 | hab Buff Stacking |
| `h_framerate` | 1 | Roza 600 balas | 600 | hab Frame Perfect |
| `n_speedrunner` | 1 | Evoluciona 2 armas | 2 | nave Speedrunner |
| `n_support` | 1 | Usa el Desync 40 veces | 40 | nave Main Support |
| `n_ballena` | 1 | Recibe 150 golpes | 150 | nave La Ballena |
| `n_smurf` | 1 | Haz una cadena de 200 | 200 | nave Smurf |
| `m_chispita` | 1 | Tu mascota come 150 balas | 150 | mascota Chispita |
| `m_caparazon` | 1 | Vence a El Compactador en Difícil | 1 | mascota Caparazón |
| `r_hab4` | 1 | Completa 8 desafíos | 8 | ranura_hab  |
| `r_arma3` | 1 | Completa 15 desafíos | 15 | ranura_arma  |
| `r_arma4` | 1 | Completa 35 desafíos | 35 | ranura_arma  |

## Regenerar

```bash
cd juego
<godot> --headless --path . --script ../herramientas/volcar_catalogos.gd -- ../build/catalogos.json --pruebas --guardado=volcado
cd ..
python herramientas/inventario.py build/catalogos.json memorias/inventario.md
```
