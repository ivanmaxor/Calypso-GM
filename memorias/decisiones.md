# Decisiones

Cada decisión con fecha, qué se decidió, alternativas, por qué y qué implica. **La más reciente arriba.** Si una decisión se revierte, no se borra: se agrega una nueva que la reemplaza.

---

### 2026-11-22: Historia A, Buen Chico
- **Qué:** de las tres historias (`docs/04_historia_y_mundos.md`) se elige la **A, Buen Chico**: el chatarrero, su mascota alienígena y los mundos que el Hambre se va tragando.
- **Alternativas:** B, Clon 412; C, Cartucho.
- **Por qué:** a Iván le gustó mucho más su giro final. Además, el giro ocurre en el sistema central del juego, así que el jugador es parte de él.
- **Implica:**
  - el giro vive solo en `docs/spoilers/`;
  - todo lo que se escriba en el juego (diálogos, mapas, jefes, mascotas) tiene que calzar con la A;
  - quien no quiera saber el giro trabaja con lo que está fuera de `docs/spoilers/`, y lo que dependa del giro lo revisa Iván.
- **Observación de Iván al elegirla:** el combate ya engancha (mejorar, matar más, hacer cadenas), pero **falta un gancho narrativo**. Al principio y durante la historia no se entiende por qué estás ahí ni cuál es tu objetivo, y entonces el jugador no sabe para qué sube de nivel. Es la tarea N01 de la v0.5.

### 2026-11-22: Indicador de hitbox discreto, entero en foco y en Desync (M01)
- **Qué:** jugando normal, la hitbox se ve como un aro rosado fino del tamaño real con un centro chico. Con foco (Shift) o durante el Desync (también al reconectar y en la cascada), se ve el disco entero como antes. La hitbox real no cambia (3,5). Reemplaza el "se ve siempre como un punto rosado" de la v0.3.
- **Alternativas:** más chico o semitransparente siempre; verse solo en foco; integrarlo a la cabina de cada nave.
- **Por qué:** los jugadores lo confundían con una bala pegada a la nave (mismo color y forma que las balas enemigas), pero hay que seguir sabiendo dónde pegan.
- **Implica:** la opacidad del aro (70 %) y si conviene el anillo punteado del foco también en el Desync quedan a decidir por Iván al jugar.

### 2026-11-22: Repositorio público en GitHub, sin código anterior
- **Qué:** el juego pasa a un repositorio público (`Calypso-GM`), con `main` protegido y Pull Request obligatorio. Parte limpio, sin historial de otros proyectos. La carpeta local pasa a llamarse `Calypso GM`.
- **Alternativas:** repo privado; o traer el historial de proyectos anteriores.
- **Por qué:** para desarrollarlo entre dos personas y que cualquiera pueda descargar y jugar.
- **Implica:** regla permanente de cero datos personales y cero claves; trabajar en ramas y por PR; Releases con el `.exe`.

### 2026-11-22: El nombre interno sigue siendo "Calypso v2"
- **Qué:** `config/name` en `project.godot` no se cambia. Solo cambian la carpeta y el repo.
- **Alternativas:** renombrar a "Calypso GM" y migrar las partidas.
- **Por qué:** de ese nombre sale la carpeta de `user://`. Cambiarlo deja a los jugadores sin su avance.
- **Implica:** el título de la ventana y el nombre del ejecutable pueden decir "Calypso", pero `config/name` queda igual mientras no haya una migración.

### 2026-11-22: Licencia "todos los derechos reservados"
- **Qué:** sin licencia abierta. `LICENSE.md` lo dice y lista las licencias de terceros (música, letras, motor).
- **Alternativas:**
  - código con MIT y arte reservado;
  - todo con licencia abierta (MIT o CC).
- **Por qué:** cualquiera puede ver, descargar y jugar, pero nadie puede reusar el arte ni el código. Deja abierta cualquier decisión futura, como publicar en una tienda.
- **Implica:** los aportes al repo quedan bajo los mismos términos del proyecto. Si en el futuro se quiere abrir el código, hay que decidirlo entre los autores.

### 2026-11-22: Sin Git LFS
- **Qué:** el audio y el arte se versionan en git normal.
- **Alternativas:** Git LFS para los `.mp3`, `.wav` y `.png`.
- **Por qué:**
  - el archivo más grande pesa ~8,6 MB, muy lejos del límite de GitHub para un archivo (100 MB);
  - todo el audio suma ~117 MB;
  - en un repo público, LFS gasta la cuota de descargas del dueño cada vez que alguien clona.
- **Implica:** evitar subir y bajar música muchas veces. Un tema que se reemplaza queda en el historial. Si el audio crece mucho (cientos de MB por mundo), se revisa la decisión.

### 2026-11-22: Spoilers en un archivo aparte
- **Qué:** los giros de la historia viven solo en `docs/spoilers/historias_con_giro.md`. `historia.md` solo enlaza con aviso.
- **Alternativas:** una sección de spoilers al final de `historia.md`.
- **Por qué:** así nadie se los lee por accidente al revisar la historia.
- **Implica:** ninguna sesión de Claude abre `docs/spoilers/` si nadie lo pide. Los Issues y commits no revelan giros.

### 2026-11-22: No se reorganiza el código antes de la v0.3.0
- **Qué:** el primer commit es el código de la v0.3 tal cual (solo se arregló `probar.sh` y se sacó una letra que no se usaba). Partir los archivos grandes queda para la v0.4.
- **Por qué:** el tag `v0.3.0` tiene que corresponder exactamente al `.exe` de la Release. Además, la reorganización sirve para estrenar el flujo de PR entre los dos.

### 2026-11-22: El código de la v0.2 no va al repo
- **Qué:** el código de la v0.2 queda en el respaldo local, no en el repo.
- **Por qué:** es solo código, sin el arte ni el audio de esa versión, así que no corre por sí solo.

### 2026-11-22: Commits sin firmas de IA
- **Qué:** ningún commit ni PR lleva `Co-Authored-By` de una IA ni "Generated with". Vale para los dos colaboradores.

---

### 2026-11-03: Versión 0.3 (29 observaciones de dos jugadores)
- **Partidas:** 3 ranuras, con Fácil, Normal y Difícil. Al terminar el juego se abren Extremo y Nueva Partida + (hasta el ciclo 7).
- **Contenido y desbloqueos:**
  - 26 armas y 30 habilidades. La base es 6 y 6, cada mundo suma 2 y 2, y el resto se gana con desafíos (53).
  - El Arsenal prende o apaga lo ganado, como el "Toggler" de Megabonk.
  - Se parte con 2 ranuras de arma y 3 de habilidad, hasta 4 y 4.
- **Combate:**
  - Más enemigos y menos disparos por enemigo (sugerencia de un jugador), con un director de oleadas determinista.
  - Anti-abuso: AFK, tope de daño a jefes y botín cero al retirarse.
  - **Desync con escudo de 3 golpes:** antes era invulnerable. La alternativa era quitar la lentitud, pero se descartó porque el Desync es lo que más gusta.
- **Modos:**
  - Infinito, como recompensa de fin de mundo;
  - Ruleta de Don Tuerca, inspirada en la tragamonedas de Plants vs Zombies: Garden Warfare 2.
- **Letra:** Barlow Semi Condensed nítida, porque la pixel "costaba leer". Luego resultó "demasiado limpia" (M05).
- **Hangar como habitación** recorrida por estaciones, inspirado en el menú de ARC Raiders.
- **Hitbox:** se agrandó de 1,6 a 3,5, porque los jugadores la sentían muy chica. Se ve siempre como un punto rosado.
- **Música:** temas más movidos, de batalla para los jefes, en rotación aleatoria de al menos 3 minutos. El volumen se bajó, porque al 10 % ya sonaba fuerte.

### 2026-11-02: Versión 0.2 (10 observaciones tras jugar la 0.1)
- **Ranuras limitadas** de armas y habilidades, con **sinergias y evoluciones**, como en Survivor!.io y Megabonk.
- **Mapa de niveles** estilo Plantas vs Zombies 2, con premios por nivel. Nada viene de entrada: todo se gana.
- **Don Tuerca:** guía que habla entre niveles, al estilo de Crazy Dave.
- **Varias naves** con arma y pasiva propias, elegidas antes de cada nivel, como en Megabonk.
- **Se quitó la Radio:** nadie la miraba ni la entendía.
- **Opciones por pestañas** (Pantalla, Sonido, Teclas y General). **Teclas principales y secundarias** por acción.
- **Iconos propios** para cada arma, habilidad y pieza, que se reconocen en la carta y en combate.

### 2026-11-02: Fundamentos del proyecto
- **Motor: Godot 4.7.2.** Es gratis y de código abierto, tiene buen 2D y lo usan juegos como Brotato. Todo se arma por código, con una sola escena raíz.
- **Proyecto personal, sin tiendas por ahora.** Si se considera publicar, hay que revisar antes las reglas de la tienda sobre IA y marcas.
- **Progreso tipo Survivor!.io:**
  - nave personalizable;
  - piezas de Común a Mítico que se fusionan (3 → 1) y se mejoran con chatarra;
  - mascotas.
  Solo apariencias no bastaban.
- **Mundos con personalidad propia**, cada uno con su regla, enemigos y jefe. La historia con un giro: se descartó la de la Odisea por aburrida. Se eligió la A el 2026-11-22 (ver arriba).
- **Desync, la mecánica central:** inspirada en la Zona de Tetris Effect, la gratificación diferida.
- **Arte por código sin IA de imágenes:** modelos 3D simples renderizados a pixel art (técnica de Dead Cells). **Música** solo con licencias libres verificadas. **Efectos** generados con el método sfxr.
- **Pantalla de 640×360** con escala entera.
- **Herramientas propias antes que plugins de terceros.** No se instaló ningún skill ni MCP: pueden ejecutar código en el PC de quien los usa. Si se quiere uno, se propone en un Issue.
