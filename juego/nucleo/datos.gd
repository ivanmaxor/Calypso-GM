extends Node
## Catálogo del juego. Las listas viven en los catalogo_*.gd; aquí se juntan y están las ayudas.

var fuente: Font
var fuente_negrita: Font
var fuente_logo: Font
var _tex := {}

const NIVEL_MAX_CARTA := 5
## Armas y habilidades: se empieza con pocas ranuras y se ganan más con desafíos (Partida.max_armas()).
const RANURAS_ARMA_INICIO := 2
const RANURAS_HAB_INICIO := 3
const TOPE_ARMAS := 4
const TOPE_HABS := 4
const FUSION_PIEZAS := 3

const RANURAS := ["mira", "casco", "alas", "motor", "reactor", "chip"]
const NOMBRE_RANURA := {"mira": "Mira", "casco": "Casco", "alas": "Alas", "motor": "Motor", "reactor": "Reactor", "chip": "Chip"}
const QUE_DA_RANURA := {"mira": "Ataque", "casco": "Vida", "alas": "Velocidad", "motor": "Esquiva", "reactor": "Desync", "chip": "Suerte y crítico"}

## Valores iniciales. Todos los mods se suman a estos.
const STATS_BASE := {
	"atk": 10.0, "hp": 70.0, "dano": 1.0, "vel": 1.0, "dash_cd": 1.0, "dash_iframes": 14.0, "iman": 60.0,
	"crit": 0.05, "crit_dmg": 1.5, "cadencia": 1.0, "balas": 0, "perfora": 0, "rebote": 0, "area": 1.0,
	"homing": 0.0, "desync_carga": 1.0, "desync_dur": 5.0, "desync_escudo": 3, "cascada": 0.0, "suerte": 1.0, "armadura": 0.0,
	"regen": 0.0, "xp": 1.0, "roce_rad": 18.0, "chatarra": 1.0, "revives": 0, "cambios": 1, "quieto_dano": 0.0,
	"cura_cascada": 0.0, "pet_vel": 1.0,
	"thorns": 0.0, "esquiva_pct": 0.0, "mov_dano": 0.0, "clutch_dano": 0.0, "leech": 0.0, "reaccion": 0.0,
	"hitbox_mult": 1.0, "vel_tiro": 1.0, "duracion": 1.0, "roce_dano": 0.0, "hardcore": 0.0,
}

## Lo que se muestra de una pieza.
const NOMBRE_STAT := {
	"atk": "Ataque", "hp": "Vida", "vel": "Velocidad", "iman": "Imán", "crit": "Crítico", "dash_cd": "Recarga de esquiva",
	"dash_iframes": "Invulnerable", "desync_carga": "Carga de Desync", "cascada": "Daño de cascada", "suerte": "Suerte",
	"chatarra": "Chatarra", "armadura": "Armadura", "cadencia": "Cadencia", "area": "Tamaño", "xp": "Experiencia",
	"thorns": "Onda de Karma", "mov_dano": "Daño en movimiento",
}

# --- los mapas: dónde está cada nivel --------------------------------------------------------
const NODOS := {"1-1": Vector2(70, 282), "1-2": Vector2(178, 226), "1-3": Vector2(288, 280), "1-4": Vector2(398, 204), "1-5": Vector2(516, 266), "1-6": Vector2(628, 210), "1-7": Vector2(740, 274), "1-8": Vector2(872, 208),
	"1-R": Vector2(462, 314), "1-INF": Vector2(944, 124)}
const PORTAL := Vector2(984, 240)
const ORDEN_NIVELES := ["1-1", "1-2", "1-3", "1-4", "1-5", "1-6", "1-7", "1-8"]
## Niveles fuera del camino principal: se abren al terminar "requiere".
const EXTRAS := {"1-R": {"requiere": "1-4"}, "1-INF": {"requiere": "1-8"}}
## El último nivel que existe hoy. Terminarlo cuenta como "terminar el juego": abre Extremo y Nueva Partida +.
const ULTIMO_NIVEL := "1-8"

var RAREZAS := CatalogoProgreso.rarezas()
var NAVES := CatalogoProgreso.naves()
var PINTURAS := CatalogoProgreso.pinturas()
var ITEMS := CatalogoProgreso.items()
var MASCOTAS := CatalogoProgreso.mascotas()
var DIFICULTADES := CatalogoProgreso.dificultades()
var DESAFIOS := CatalogoProgreso.desafios()
var BASE_POR_MUNDO := CatalogoProgreso.base_por_mundo()
var ARMAS := CatalogoArmas.armas()
var HABILIDADES := CatalogoArmas.habilidades()
var ENEMIGOS := CatalogoNiveles.enemigos()
var RUTAS := CatalogoNiveles.rutas()
var MUNDOS := CatalogoNiveles.mundos()
var NIVELES := CatalogoNiveles.niveles()
var DIALOGOS := CatalogoDialogos.dialogos()
var TEXTOS_CALYPSO := CatalogoDialogos.textos_calypso()


func _ready() -> void:
	# Letra limpia y sin pixeles: el arte sigue siendo pixel, pero el texto tiene que leerse.
	fuente = _cargar_fuente("res://arte/fuente/BarlowSemiCondensed-SemiBold.ttf")
	fuente_negrita = _cargar_fuente("res://arte/fuente/BarlowSemiCondensed-Bold.ttf")
	# El logo y nada más conserva la letra pixel.
	var logo: FontFile = load("res://arte/fuente/Jersey10-Regular.ttf")
	logo.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	logo.hinting = TextServer.HINTING_NONE
	logo.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	logo.generate_mipmaps = false
	fuente_logo = logo


## Variantes de letra para comparar en capturas reales (M05). Solo se usan con --letra= en las pruebas:
## el juego normal sigue con la actual hasta que las personas elijan.
## - "actual": Barlow suavizada, a la resolución de la ventana (v0.3).
## - "sin_suavizado": la misma, con bordes duros.
## - "pixel": la misma, dibujada a la resolución lógica (640×360) y agrandada como el arte.
## - "mixta": "pixel" en el texto y Jersey 10 (la del logo) en los títulos grandes.
const LETRAS := ["actual", "sin_suavizado", "pixel", "mixta"]


func usar_letra(op: String) -> void:
	match op:
		"sin_suavizado":
			_bordes_duros(fuente, false)
			_bordes_duros(fuente_negrita, false)
		"pixel":
			_bordes_duros(fuente, true)
			_bordes_duros(fuente_negrita, true)
		"mixta":
			_bordes_duros(fuente, true)
			var j: FontFile = load("res://arte/fuente/Jersey10-Regular.ttf").duplicate()
			_bordes_duros(j, true)
			fuente_negrita = j


func _bordes_duros(f: FontFile, a_resolucion_logica: bool) -> void:
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	# a la resolución lógica, el hinting fuerte abre huecos dentro de las palabras ("rui do")
	f.hinting = TextServer.HINTING_NONE if a_resolucion_logica else TextServer.HINTING_NORMAL
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	if a_resolucion_logica:
		f.oversampling = 1.0


func _cargar_fuente(ruta: String) -> Font:
	var f: FontFile = load(ruta)
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.hinting = TextServer.HINTING_LIGHT
	# de a medio pixel: cada letra cae en su lugar y el espacio entre letras queda parejo
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_ONE_HALF
	f.generate_mipmaps = false
	return f


## Las texturas quedan guardadas aqui: si se liberan despues de dibujar, salen en blanco.
## Si falta un dibujo, sale un cuadro magenta: se nota al probar y el juego no se cae.
func tex(nombre: String) -> Texture2D:
	if not _tex.has(nombre):
		var ruta := "res://arte/sprites/%s.png" % nombre
		if ResourceLoader.exists(ruta):
			_tex[nombre] = load(ruta)
		else:
			var im := Image.create(32, 32, false, Image.FORMAT_RGBA8)
			im.fill(Color(1, 0, 1, 1))
			_tex[nombre] = ImageTexture.create_from_image(im)
	return _tex[nombre]


func existe_tex(nombre: String) -> bool:
	return ResourceLoader.exists("res://arte/sprites/%s.png" % nombre)


## Hoja de una mascota en una forma (0, 1 o 2).
func tex_mascota(id: String, forma: int) -> Texture2D:
	return tex("%s_%d" % [MASCOTAS[id].sprite, forma])


func mundo_de(nivel: String) -> int:
	return int(nivel.get_slice("-", 0)) - 1


func icono_arma(id: String) -> Texture2D:
	return tex("icono_" + id)


func max_hab(id: String) -> int:
	return HABILIDADES[id].get("max", NIVEL_MAX_CARTA)


func nombre_hab(id: String) -> String:
	return HABILIDADES[id].nombre if HABILIDADES.has(id) else id


func arma_con_sinergia(hab: String) -> String:
	for id in ARMAS:
		if ARMAS[id].sinergia == hab:
			return id
	return ""


func rampa_pintura(i: int) -> PackedColorArray:
	var r := PackedColorArray()
	for h in PINTURAS[clampi(i, 0, PINTURAS.size() - 1)].rampa:
		r.append(Color(h))
	return r


func rampa_rareza(rareza: int) -> PackedColorArray:
	var base: Color = RAREZAS[rareza].color
	return PackedColorArray([base.darkened(0.7), base.darkened(0.45), base.darkened(0.2), base, base.lightened(0.5)])


func rampa_llama(rareza: int) -> PackedColorArray:
	if rareza <= 0:
		return PackedColorArray([Color("b02a00"), Color("ff7a1a"), Color("ffd24a"), Color("fff8d0")])
	var base: Color = RAREZAS[rareza].color
	return PackedColorArray([base.darkened(0.45), base, base.lightened(0.45), Color("fffaf0")])


## Prepara el material de una nave segun su pintura y el equipo puesto.
func pintar(mat: ShaderMaterial, pintura: int, rareza_alas: int, rareza_motor: int) -> void:
	mat.set_shader_parameter("casco", rampa_pintura(pintura))
	mat.set_shader_parameter("franja", rampa_rareza(rareza_alas))
	mat.set_shader_parameter("llama", rampa_llama(rareza_motor))


func texto_azar(clave: String) -> String:
	var l: Array = TEXTOS_CALYPSO.get(clave, [""])
	return l[randi() % l.size()]


## Reemplaza {esquivar}, {desync}, {foco} y {mover} por las teclas reales.
func con_teclas(s: String) -> String:
	var r := s.replace("{mover}", "%s %s %s %s" % [Controles.texto("mover_arriba"), Controles.texto("mover_izquierda"), Controles.texto("mover_abajo"), Controles.texto("mover_derecha")])
	for a in ["esquivar", "desync", "foco", "pausa", "disparar"]:
		r = r.replace("{%s}" % a, Controles.texto(a))
	return r
