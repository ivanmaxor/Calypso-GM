# 7. Tecnología y herramientas

Datos de GitHub revisados el 1 de noviembre de 2026.

## El motor: Godot 4.7.2

**Godot es el programa con el que se hacen juegos.** Maneja la ventana, los gráficos, el sonido, el teclado y el mando. El código define las reglas y el motor hace el resto. Es gratis, de código abierto y sin cobros: con él se hicieron [Brotato](https://godotengine.org/showcase/brotato/) y [Slay the Spire 2](https://www.gamingonlinux.com/2026/03/slay-the-spire-2-becomes-the-biggest-roguelike-deck-builder-on-steam-ever/).

**Rendimiento medido:** con 1.000 balas va a unos 266 cuadros por segundo en una GPU de entrada de 4 GB.

El motor no va en el repositorio: el [README](../README.md) explica cómo bajar la versión exacta y dónde van las plantillas de exportación.

## Cómo está hecho

```
juego/
  nucleo/     datos del juego, guardado, teclas, sonido
  combate/    combate.gd, director.gd (oleadas) y arsenal.gd (las 26 armas)
  pantallas/  título, mapa, panel de nivel, elegir nave, diálogo, resultado, premio,
              hangar y sus pestañas, fusión, opciones, teclas, pausa
  arte/       sprites generados
  audio/      música y efectos
  pruebas/    bot y pruebas automáticas
herramientas/
  godot/      el motor
  arte/       genera los sprites
  audio/      genera los efectos
  probar.sh   corre pruebas, bot y exportación
```

**El contenido son datos.** Agregar una pieza, una habilidad o un nivel es agregar una entrada en los catálogos (`juego/nucleo/catalogo_*.gd`). Por eso se puede hacer mucho contenido rápido. Ver [memorias/arquitectura.md](../memorias/arquitectura.md).

**Las balas no son objetos.** Son listas de números, así que se pueden tener muchas sin perder velocidad.

**Todo el flujo está en un solo lugar:** [principal.gd](../juego/escenas/principal.gd) une las pantallas.

## Herramientas para programar con IA

Se buscaron skills y MCP para crear el juego. **No se instaló ninguno:** lo necesario se escribió directamente, y así no corre código de terceros en el PC de nadie.

La [documentación oficial](https://code.claude.com/docs/en/plugins/security.md) avisa que un plugin "can execute arbitrary code on your machine with your user privileges". Por eso solo instalaría algo si de verdad hace falta, y revisándolo antes.

| Necesidad | Qué se usa | Alternativa encontrada |
|---|---|---|
| Correr y ver el juego | El propio Godot, un bot y capturas | [godot-mcp](https://github.com/Coding-Solo/godot-mcp) (6,5 mil estrellas). Solo desde la 0.1.1, [por una falla de seguridad](https://www.cvelogic.com/cve/CVE-2026-25546) |
| Documentación de Godot | Context7 (MCP de documentación) | |
| Arte | El motor propio en Python | [mcp-for-blender](https://github.com/ahujasid/mcp-for-blender) (33 mil estrellas), si algún modelo lo pide. [PixelLab](https://www.pixellab.ai/docs/ways-to-use-pixellab) es de pago |
| Música | Temas CC0 | [ACE-Step](https://lilting.ch/en/articles/ace-step-1-5-music-generation), [Strudel](https://glama.ai/mcp/servers/williamzujkowski/strudel-mcp-server) |
| Efectos | El generador propio | [ElevenLabs](https://github.com/elevenlabs/elevenlabs-mcp), con cuenta |
| Diseño de juegos | Investigación propia | [gamedev-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) (6,5 mil estrellas), con una skill de [game feel](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/game-feel) |
| Estudio completo | No hace falta | [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) (32 mil estrellas, 49 agentes): demasiado para esto |

En el [marketplace oficial](https://github.com/anthropics/claude-plugins-official), de 315 entradas hay plugins de Unity y Unreal, pero **ninguno de Godot ni pixel art**.

**Si se instala uno:** primero se propone en un Issue y se revisa. El candidato era gamedev-skills, solo la de game feel.

## Cambios de la versión 0.3

- **Pantalla:** `canvas_items` con escala entera, en vez de `viewport`.
- **Animaciones de menú:** van por tiempo real. Antes dependían de los Hz de la pantalla.
- **Guardado:** `partida3_N.json` por ranura y `global3.json` para lo común. La partida antigua (`partida2.json`) no se toca: se lee una vez y se convierte.
- **Pruebas:** `probar.sh flujo_hangar`, además de lo anterior; con `CALYPSO_D` y `CALYPSO_P` se puede correr sobre otra copia.
