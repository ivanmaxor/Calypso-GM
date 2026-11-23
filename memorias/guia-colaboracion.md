# Guía de colaboración

Para cualquiera que se sume a Calypso, con o sin una IA que le ayude.

## Antes de empezar
1. Lee el [README](../README.md) y prepara el entorno (motor, plantillas y pruebas).
2. Lee las memorias, en este orden:
   - `fases.md` (qué toca ahora);
   - `arquitectura.md`;
   - `aprendizajes.md`;
   - `decisiones.md`;
   - `guia-arte.md` antes de tocar cualquier dibujo.
3. Mira el `session-log.md`, para saber qué hizo el otro hace poco.

## Regla permanente: cero datos personales y cero claves
- Nada de claves, tokens, contraseñas ni valores de `.env`.
- Nada de apellidos, RUT, correos personales, teléfonos ni direcciones. Tampoco rutas con el usuario del PC (`C:\Users\<nombre>\...`) ni nombres de terceros.
- Los textos se escriben neutrales, para cualquier jugador; nada dirigido a una persona.
- Git se configura con tu nombre de pila y tu **correo privado de GitHub**:
  ```bash
  git config user.name "TuNombre"
  git config user.email "<id>+<usuario>@users.noreply.github.com"
  ```
  Ese correo está en GitHub, en Settings → Emails. Activa también "Block command line pushes that expose my email".
- Si algo personal llega a subirse, avisa al tiro: hay que borrarlo del historial, no basta con un commit que lo quite.

## Flujo de trabajo
- **Nadie sube directo a `main`.** Está protegido.
- **Cada tarea es un Issue.** Te lo asignas antes de empezar, así el otro sabe que está tomado. Las ideas nuevas también van como Issue, con la plantilla "Idea".
- **Una rama por tarea:**
  - `feature/<id>-<corto>` para algo nuevo (`feature/M16-pausa-equipo`);
  - `fix/<id>-<corto>` para un error;
  - `arte/<id>-<corto>` para arte;
  - `balance/<id>-<corto>` para números.
- **Commits chicos** con mensaje claro en español: qué cambia y por qué (`M13: mostrar decimales en las mejoras de pieza`). **Sin firmas de IA** (`Co-Authored-By`, "Generated with").
- **Pull Request a `main`**, con la plantilla llena:
  - qué pruebas corriste;
  - capturas, si cambia algo visible;
  - qué quedó sin verificar;
  - **`Closes #N`** en el cuerpo, para enlazar el Issue. Tiene que ir **en inglés** (`Closes`, `Fixes` o `Resolves`): GitHub cierra el Issue por su cuenta solo con esas palabras. Con "Cierra #N" el Issue queda abierto aunque el PR se fusione.
  **El otro lo revisa y lo aprueba.** Después se fusiona.
- **Antes de abrir el PR** corre, como mínimo, `probar.sh import`, `tests`, `flujo` y `flujo_hangar`. Si tocaste combate o balance, también bots.

## Cómo no pisarse las ideas
- Una idea o tarea nueva es un **Issue** antes de ser código.
- Las ideas de diseño se discuten en el Issue. Cuando se decide, se anota en `decisiones.md` (con fecha, alternativas y por qué) en el PR que lo implementa.
- Si no están de acuerdo, se prueban las dos opciones en una rama y se juegan. Gana lo que se siente mejor al jugar.

## Cómo no pisarse en el código
Casi todo el juego se arma por código: hay **una sola escena** (`escenas/principal.tscn`). Los choques no van a ser en escenas, sino en estos archivos:

| Archivo | Por qué choca | Cómo evitarlo |
|---|---|---|
| `nucleo/catalogo_*.gd` | Todo el contenido y el balance vive ahí | Avisar en el Issue qué entradas tocas. Los cambios de balance van en un PR aparte del código |
| `pruebas/pruebas_*.gd` | Todos agregan pruebas | Desde R01 están partidas por área (ver `arquitectura.md`). Cada uno agrega lo suyo en **su propia función**, en el módulo de su área. No renumeres pasos ajenos. `_tests()` sigue siendo una lista compartida: si chocan ahí, se conservan ambas líneas |
| `combate/combate.gd`, `combate/arsenal.gd` | Muy grandes | Avisar qué parte tocas. Partirlos son las tareas R02 y R03 |

Regla: **en el Issue se dice qué archivos se van a tocar.** Si dos Issues tocan el mismo archivo grande, se hacen uno después del otro.

## Cómo no pisarse en el arte
- Cada generador de `herramientas/arte/` es dueño de ciertos sprites (ver `guia-arte.md` §3). Se regenera solo lo propio, con su filtro.
- **Nunca se edita a mano un PNG que sale de un generador:** se cambia el generador.
- `generar_v3_escenas.py` escribe `nucleo/sala_hangar.gd`. Si lo regeneras, ese archivo cambia también.

## Resolver un conflicto de merge
1. Trae lo último y mezcla en tu rama:
   ```bash
   git fetch
   git merge origin/main
   ```
   Git marca los conflictos con `<<<<<<<`, `=======` y `>>>>>>>`.
2. Según el tipo de archivo:
   - **En un `.gd`:** quédate con los dos cambios cuando se puede. Revisa que la indentación (tabs) quede bien y que no se dupliquen funciones.
   - **En un catálogo:** cada entrada es un diccionario. Si los dos cambiaron la misma entrada, decide número por número y anótalo en el PR. Ojo con las comas al final de cada entrada.
   - **En un `.tscn` o `.tres`** (si en el futuro hay más escenas): son texto, pero los `id` y `load_steps` se enredan fácil. Lo más seguro es quedarse con una versión entera (`git checkout --ours` o `--theirs` en ese archivo) y volver a aplicar a mano el cambio del otro en Godot.
   - **En `.import` o `.uid`:** quédate con una versión y corre `probar.sh import`.
   - **En un PNG generado:** no se mezcla. Corre el generador sobre la rama ya mezclada.
3. Después de resolver: `probar.sh import`, `tests` y `flujo`. Recién ahí el commit.

## Al terminar cada sesión
- Agrega tu entrada arriba en `session-log.md`: fecha, **tu nombre**, qué hiciste, qué tocaste, commits (hash corto) y pendientes.
- Si corresponde, actualiza:
  - `inventario.md` (regenerándolo);
  - `decisiones.md`;
  - `fases.md`;
  - `aprendizajes.md`.

## Versiones y Releases
- **Numeración `vMAYOR.MENOR.PARCHE`**:
  - `v0.4.0` = una fase nueva;
  - `v0.4.1` = arreglos sobre esa fase;
  - `v1.0.0` = el juego completo.
- **Solo Iván publica Releases** y cambia la configuración del repo.
- **Cómo se crea una Release:**
  1. `main` con todo fusionado y todas las pruebas en verde.
  2. Exportar: `bash herramientas/probar.sh exe`, que deja `build/Calypso.exe`.
  3. Probar los menús sobre el `.exe` exportado:
     ```bash
     build/Calypso.exe --audio-driver Dummy --fixed-fps 60 -- --pruebas --flujo --guardado=rel --reiniciar
     ```
  4. Armar el zip: `Calypso.exe` + `CREDITOS.txt` + `LEEME.txt` + `LICENCIAS_GODOT.txt` + `LICENCIAS_MUSICA.txt`.
  5. Crear el tag y la Release:
     ```bash
     gh release create v0.4.0 Calypso-v0.4.0-windows.zip --title "Calypso v0.4.0" --notes-file notas.md
     ```
- **Notas de la versión:**
  - qué hay de nuevo, para el jugador;
  - qué se arregló (con el ID del Issue);
  - cómo se probó: con personas, con bots, o qué no se probó;
  - si las partidas anteriores siguen sirviendo.
