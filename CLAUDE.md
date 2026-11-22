# Calypso: instrucciones para Claude Code

Calypso es un bullet hell con progreso tipo Survivor!.io, hecho en **Godot 4.7.2 (GDScript)** entre dos personas. Este archivo vale para la sesión de **cualquier** colaborador.

## Al empezar
1. Lee el `README.md` y `memorias/fases.md` (qué toca ahora). Después lee, según la tarea:
   - `memorias/arquitectura.md`;
   - `memorias/aprendizajes.md`;
   - `memorias/decisiones.md`;
   - `memorias/guia-arte.md`, **siempre antes de tocar arte**.
2. Mira la última entrada de `memorias/session-log.md` y pregunta **quién está trabajando**, para anotarlo.
3. Si la tarea no tiene Issue, propón crearlo antes de programar.

## Reglas del proyecto
- **Arquitectura:**
  - el contenido es dato (`juego/nucleo/catalogo_*.gd`);
  - las balas no son nodos;
  - la lógica corre a 60 pasos fijos;
  - **toda animación usa el delta, nunca los cuadros**;
  - todo se arma por código.
  Respeta las interfaces de `arquitectura.md`. Si cambias una, actualízala en el mismo PR.
- **Arte:**
  - se respeta el código de colores del combate (punto débil rojo, balas enemigas rojas, tus balas cian, Bits dorados);
  - el arte se hace con los generadores de `herramientas/arte/`, **nunca editando a mano un PNG generado**;
  - nada se da por bueno sin mirar una captura.
- **No rompas la sensación del Desync**, la mecánica que más gusta.
- **Textos del juego:** español de Chile, con tildes y breves. Don Tuerca habla chistoso y a la chilena; Calypso es seca e irónica.
- **Spoilers:** no abras `docs/spoilers/` si nadie lo pide, y no reveles giros de la historia en código, commits, Issues ni PR.
- **No cambies `config/name` en `project.godot`:** de ahí sale la carpeta de las partidas.

## Antes de cada commit
- Corre `bash herramientas/probar.sh import`, `tests`, `flujo` y `flujo_hangar`. Si tocaste combate o balance, también bots (`bot`, `campana`, `--torpe`, `--ciego`).
- Las pruebas usan `--pruebas`, que abre la ventana fuera de la pantalla. **Nunca lances el juego en modo normal para probar.**
- Si cambiaste un catálogo, regenera `memorias/inventario.md` (ver el final de ese archivo).
- **Reporta con honestidad** qué se verificó y qué no: "solo bots", "no se escuchó el audio", "no se probó con mando".

## Git y GitHub
- **Ramas y Pull Request.** Nada directo a `main`.
- Commits chicos, en español, **sin firmas ni atribución de IA**: sin `Co-Authored-By` ni "Generated with".
- **Nunca incluyas datos personales ni claves:** apellidos, RUT, correos personales, teléfonos, direcciones, rutas con el usuario del PC ni tokens. Git se configura con el correo noreply de GitHub.
- **No publiques Releases ni cambies la configuración del repo sin el OK de Iván.**
- No instales skills, plugins ni MCP de terceros sin proponerlo antes en un Issue: pueden ejecutar código en el PC de quien los usa.

## Al terminar la sesión
- Agrega una entrada arriba en `memorias/session-log.md`: fecha, **quién**, qué se hizo, qué archivos se tocaron, commits y pendientes.
- Si corresponde, actualiza `fases.md`, `decisiones.md`, `aprendizajes.md` o `inventario.md`.
