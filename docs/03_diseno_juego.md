# 3. Diseño del juego

Describe la versión **0.3**. Los números exactos (armas, habilidades, piezas, niveles, desafíos y dificultades) están en [memorias/inventario.md](../memorias/inventario.md), que se genera desde el código. Si algo de aquí no calza con el código, manda el código.

## La idea

Un bullet hell con el progreso de [Survivor!.io](https://www.pocketgamer.com/survivor-io/guide/): cada partida hace más fuerte a la nave, y entre partidas se arma en el Hangar. Tono de humor gamer, con un guía chatarrero que habla a la chilena.

## Flujo de pantallas

```
TÍTULO → RANURAS (3 partidas) → DIFICULTAD → MAPA DEL MUNDO → panel del nivel → elegir nave → COMBATE
                                                  ↑                                               ↓
                                                  └── Don Tuerca comenta ← premios ← RESULTADO: estrellas y botín
```

- **Ranuras:** 3 partidas, cada una con su dificultad (Fácil, Normal o Difícil). Al terminar el juego se abren **Extremo** y **Nueva Partida +**: se vuelve a empezar conservando lo ganado, con enemigos más duros, hasta el ciclo 7.
- **Mapa del mundo**, como Plantas vs Zombies 2: un camino de niveles que se abren en orden. A la izquierda siempre se ven la nave y la mascota.
- **Panel del nivel:** enemigos (los nuevos, con su ayuda), premio y las condiciones de las 3 estrellas.
- **Elegir nave:** aparece desde que hay dos.
- **Don Tuerca:** el chatarrero que habla al empezar, antes de algunos niveles y después de cada uno, con voz de balbuceo. Sus textos se saltan con Esc, salen una vez y se pueden volver a ver desde Opciones.

## Niveles del Mundo 1

8 niveles en camino, más 2 extras: **1-R, la Ruleta de Don Tuerca** (opcional) y **1-INF, Chatarrera Infinita** (al final del mundo). Duran de unos 100 a 240 segundos.

**Estrellas:** una por terminar, una por recibir pocos golpes y una por llegar a una cadena larga.

**Nada viene de entrada: se gana.** Cada nivel da un premio la primera vez, por ejemplo el Hangar (1-1), el Desync (1-2), la mascota y la fusión (1-3), el Arsenal (1-4) y la nave Camper (1-8). La tabla completa está en el inventario.

## Durante la partida

### Ranuras limitadas
- Se parte con **2 ranuras de arma y 3 de habilidad**. Los desafíos abren más, **hasta 4 y 4**. La nave ya ocupa una ranura de arma con su arma propia.
- Al subir de nivel se elige 1 de 3 cartas. Cada arma llega a nivel 5. Cuando todo está lleno salen cartas de relleno, para que subir siempre sirva.
- Hay **cambios de cartas** limitados por partida.

### Sinergias y evoluciones
**Arma en nivel 5 + su habilidad de sinergia = evolución.** La carta dorada aparece primero en cuanto se cumplen las dos cosas. Las cartas dicen con qué evoluciona cada arma. Las 26 parejas están en el inventario.

### Qué puede salir
- **Base:** 6 armas y 6 habilidades. Cada mundo suma 2 y 2 fijas.
- El resto se gana con **desafíos** (53 en el Mundo 1).
- En el **Arsenal** se prende o se apaga lo ganado, para elegir qué puede salir.

### Objetos
| Objeto | Efecto |
|---|---|
| Pizza | Cura. Sale más seguido con poca vida. No sale en Extremo |
| Imán | Atrae todo lo que hay en pantalla |
| Bomba | Limpia las balas y daña a todos |
| Cofre | Una carta gratis. Lo sueltan los enemigos grandes |

### Sentir el peligro
- Las balas enemigas son **rojas en todos los niveles**, y los Bits (XP) son **dorados**, para no confundirlos.
- Más enemigos y **menos disparos por enemigo**. Las oleadas las arma un director con presupuesto por segundo, formaciones e hitos fijos para presentar enemigos y jefes.
- Un golpe se nota: congela un instante, la pantalla se pone roja y tiembla, sale un número grande y suena fuerte. La vida se ve bajo la nave y en grande en el panel.
- La hitbox se ve siempre como un punto rosado del tamaño real de lo que te puede pegar.

### Reglas contra el abuso
- **AFK:** quedarse unos 5 segundos en el mismo lugar hace caer un bombazo ahí, y se repite.
- **Jefes con tope de daño:** ninguna combinación los mata en menos de unos 40 segundos.
- **Tope de balas propias** en pantalla, y las balas teledirigidas no frenan.
- **Botín:** retirarse de un nivel no da nada, y en el Mundo 1 no caen piezas legendarias ni míticas.

## El momento Tetris: DESYNC

La mecánica estrella. Se inspira en la Zona de Tetris Effect: la recompensa se atrasa y llega toda junta.

1. **Cargar.** La barra sube con kills, roces y lo que come la mascota.
2. **Activar.** El mundo pierde el color y se pone lento. Un **escudo de 3 golpes** protege la nave y se quiebra a la vista; sin escudo, el daño es normal.
3. **Acumular.** Los disparos pegan, **pero no se registran**. Cada enemigo muestra su cuenta.
4. **Silencio.** "RECONECTANDO...". La música casi desaparece. Durante la reconexión y la cascada no se recibe daño.
5. **Cascada.** Los golpes se registran en orden, con tonos que suben. Si caen muchos: **¡ACE!**

## Entre partidas: el Hangar

El Hangar es una habitación (el baño de Don Tuerca convertido en taller). Cada objeto es una estación: se cruza con flechas, WASD o mouse, el objeto con foco brilla y lo demás se oscurece.

| Estación | Para qué |
|---|---|
| **Naves** | Elegir nave y pintura. Lo bloqueado dice cómo se gana |
| **Equipo** | Una pieza por ranura (mira, casco, alas, motor, reactor y chip) y mejorarla con chatarra |
| **Fusionar** | 3 piezas de la misma ranura y rareza dan una de la rareza siguiente. La equipada nunca se pierde y la chatarra invertida se devuelve |
| **Mascota** | Elegir mascota, ver qué hace y su nivel |
| **Arsenal** | Armas, habilidades, piezas y desafíos, con lo bloqueado en silueta |
| **Salida** | Vuelve al mapa |

### Rarezas
Común (gris), Poco común (verde), Raro (azul), Épico (morado), Legendario (dorado) y Mítico (rojo). Cada rareza multiplica la base de la pieza y abre una de sus pasivas.

### De dónde sale cada cosa
| Cosa | Cómo se consigue | Para qué sirve |
|---|---|---|
| **Bits** (rombos dorados) | Los sueltan los enemigos | Subir de nivel *en esa partida* |
| **Chatarra** (tuercas) | La sueltan los enemigos, y hay un premio al terminar | Mejorar piezas |
| **Piezas** | Caen al terminar un nivel | Equiparlas o fusionarlas |

### Mascotas
Vuelan con la nave y actúan solas: **Mordisco** se come las balas cercanas, **Chispita** lanza chispazos, **Imancito** trae los Bits y **Caparazón** da un escudo. Suben de nivel con las fusiones y cambian de forma en los niveles 10 y 25. Hay 6 más en silueta para los otros mundos.

## Modos

- **Ruleta (1-R):** a mitad y al final del nivel se limpia el campo y gira la tragamonedas de Don Tuerca. Cada rodillo suma algo (jefe, horda, chatarra, pizza, cofre…). **Tres iguales** da un castigo o premio grande: Súper Grúa, mega horda, jackpot que vuelve a girar, cura total o 3 cartas.
- **Infinito (1-INF):** no termina. El ritmo, la vida y el daño suben con el tiempo, mezcla todo el mundo y trae jefes cada cierto rato. Guarda el récord.

## Cuánto hay y cuánto falta

| Contenido | v0.3 | Meta |
|---|---|---|
| Mundos | 1 (8 niveles + Ruleta + Infinito) | 7 |
| Naves | 6 | 6 o más |
| Armas | 26 | Crece con cada mundo |
| Habilidades | 30 | Crece con cada mundo |
| Piezas | 22 (6 esperan al Mundo 2) | 30 o más |
| Mascotas | 4 jugables + 6 en silueta | 10 |
| Enemigos | 7 + 2 jefes | Unos 30 y 9 jefes |
