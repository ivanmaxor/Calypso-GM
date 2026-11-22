class_name UI
extends RefCounted
## Tema visual y ayudas para interfaz y texto.

const C_FONDO := Color("120e22")
const C_PANEL := Color("1d1736")
const C_PANEL2 := Color("262044")
const C_LINEA := Color("4a3f7a")
const C_TEXTO := Color("f4f0ff")
const C_GRIS := Color("a8a2c8")
const C_ORO := Color("f5c84c")
const C_ROSA := Color("ff6fb5")
const C_CIAN := Color("6fe8ff")
const C_VERDE := Color("7ee07a")
const C_ROJO := Color("ff4a4a")
const TAM := 14
const ALTO_LINEA := 14
## Linea base fija, para que el texto no se mueva de donde estaba en la interfaz.
const BASE := 13.0
## Lo que se recuerda al pie de los menús.
const PIE_MENU := "Flechas o WASD: moverse  ·  Enter o Espacio: elegir  ·  Esc: volver"
const PIE_MENU_MANDO := "Cruceta: moverse  ·  A: elegir  ·  B: volver"


static var _tema: Theme = null


## Recordatorio de teclas al pie de una pantalla. Cambia solo si estás jugando con mando.
class Pie extends Label:
	var teclado := ""
	var mando := ""
	var centro_x := 320.0

	func _ready() -> void:
		horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_color_override("font_color", UI.C_GRIS)
		_poner()

	func _poner() -> void:
		var txt: String = mando if Controles.ultimo_mando and mando != "" else teclado
		if txt == text:
			return
		text = txt
		var an: float = UI.ancho(txt) + 12.0
		size = Vector2(an, 16)
		position.x = round(centro_x - an / 2.0)

	func _process(_d: float) -> void:
		_poner()


static func tema() -> Theme:
	if _tema == null:
		_tema = crear_tema()
	return _tema


static func crear_tema() -> Theme:
	var t := Theme.new()
	t.default_font = Datos.fuente
	t.default_font_size = TAM
	var normal := _caja(C_PANEL2, C_LINEA)
	var hover := _caja(Color("332a60"), C_GRIS)
	var foco := _caja(Color("332a60"), C_ORO)
	var pres := _caja(Color("453a80"), C_ORO)
	var apag := _caja(Color("15112a"), Color("2a2448"))
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pres)
	t.set_stylebox("focus", "Button", foco)
	t.set_stylebox("disabled", "Button", apag)
	t.set_color("font_color", "Button", C_TEXTO)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", C_ORO)
	t.set_color("font_pressed_color", "Button", C_ORO)
	t.set_color("font_hover_pressed_color", "Button", C_ORO)
	t.set_color("font_disabled_color", "Button", Color("6a6488"))
	t.set_color("font_color", "Label", C_TEXTO)
	t.set_constant("line_spacing", "Label", -2)
	t.set_stylebox("panel", "PanelContainer", _caja(C_FONDO, C_LINEA))
	t.set_stylebox("panel", "Panel", _caja(C_FONDO, C_LINEA))
	var barra := StyleBoxFlat.new()
	barra.bg_color = Color("262040")
	var agarre := StyleBoxFlat.new()
	agarre.bg_color = C_GRIS
	t.set_stylebox("scroll", "VScrollBar", barra)
	t.set_stylebox("grabber", "VScrollBar", agarre)
	t.set_stylebox("grabber_highlight", "VScrollBar", agarre)
	t.set_stylebox("grabber_pressed", "VScrollBar", agarre)
	t.set_stylebox("normal", "LineEdit", _caja(C_PANEL, C_LINEA))
	t.set_stylebox("focus", "LineEdit", _caja(C_PANEL, C_ORO))
	t.set_color("font_color", "LineEdit", C_TEXTO)
	t.set_color("caret_color", "LineEdit", C_ORO)
	return t


static func _caja(fondo: Color, borde: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(1)
	s.anti_aliasing = false
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 0
	s.content_margin_bottom = 2
	return s


static func boton(texto: String, pos: Vector2, tam: Vector2, padre: Node, al_pulsar: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.position = pos
	b.custom_minimum_size = tam
	b.focus_mode = Control.FOCUS_ALL
	padre.add_child(b)
	b.size = tam
	b.pressed.connect(func():
		Sonido.tocar("ui_ok")
		al_pulsar.call())
	b.focus_entered.connect(func(): Sonido.tocar("ui_mover"))
	return b


static func etiqueta(texto: String, pos: Vector2, padre: Node, color := C_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.add_theme_color_override("font_color", color)
	padre.add_child(l)
	return l


## Pone el recordatorio de teclas. "fondo": para que se lea sobre un dibujo.
static func pie(padre: Node, teclado := PIE_MENU, mando := PIE_MENU_MANDO, y := 343.0, cx := 320.0, fondo := false) -> Label:
	var p := Pie.new()
	p.teclado = teclado
	p.mando = mando
	p.centro_x = cx
	p.position.y = y
	if fondo:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.05, 0.03, 0.12, 0.82)
		p.add_theme_stylebox_override("normal", st)
	padre.add_child(p)
	return p


## Encadena controles en una lista: las flechas y Tab se mueven entre ellos y nunca se escapan a lo de atrás.
## "ciclica": del último se pasa al primero.
static func lista_foco(lista: Array, vertical := true, ciclica := true) -> void:
	var n := lista.size()
	for i in n:
		var c: Control = lista[i]
		var ant: Control = lista[posmod(i - 1, n)] if ciclica or i > 0 else c
		var sig: Control = lista[posmod(i + 1, n)] if ciclica or i < n - 1 else c
		var yo := c.get_path_to(c)
		c.focus_neighbor_top = c.get_path_to(ant) if vertical else yo
		c.focus_neighbor_bottom = c.get_path_to(sig) if vertical else yo
		c.focus_neighbor_left = yo if vertical else c.get_path_to(ant)
		c.focus_neighbor_right = yo if vertical else c.get_path_to(sig)
		c.focus_next = c.get_path_to(sig)
		c.focus_previous = c.get_path_to(ant)


## Un tiempo corto para leerlo de un vistazo: 3:07
static func reloj(seg: int) -> String:
	return "%d:%02d" % [seg / 60, seg % 60]


## Un tiempo largo, en palabras: "1 h 23 min", "12 min", "menos de 1 min".
static func duracion(seg: int) -> String:
	if seg < 60:
		return "menos de 1 min"
	if seg < 3600:
		return "%d min" % (seg / 60)
	return "%d h %d min" % [seg / 3600, (seg % 3600) / 60]


## Un cartelito con fondo para explicar algo encima de un dibujo. Lo mantiene dentro de "limite".
static func cartel(c: CanvasItem, cx: float, y: float, s: String, col := C_TEXTO, limite := Rect2(0, 0, 640, 360)) -> void:
	var an: float = ancho(s) + 10.0
	var x: float = clampf(round(cx - an / 2.0), limite.position.x + 1.0, maxf(limite.end.x - an - 1.0, limite.position.x + 1.0))
	marco(c, Rect2(x, y, an, 16), Color(0.05, 0.03, 0.12, 0.92), C_LINEA)
	t(c, x + 5, y - 1, s, col)


## Texto en cualquier CanvasItem durante su _draw. y es la parte de arriba de la letra.
static func t(c: CanvasItem, x: float, y: float, s: String, col := C_TEXTO, esc := 1, sombra := false) -> void:
	# el texto grande se pide a su tamaño real: asi nunca se ve borroso ni con pixeles
	var f: Font = _fuente_de(esc)
	var tam: int = TAM * esc
	var base: float = BASE * esc
	if sombra:
		var o: float = maxf(1.0, esc * 0.75)
		c.draw_string(f, Vector2(x + o, y + base + o), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color("0d0a18"))
	c.draw_string(f, Vector2(x, y + base), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)


static func _fuente_de(esc: int) -> Font:
	return Datos.fuente_negrita if esc >= 2 else Datos.fuente


static func ancho(s: String, esc := 1) -> float:
	return _fuente_de(esc).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM * esc).x


static func tc(c: CanvasItem, cx: float, y: float, s: String, col := C_TEXTO, esc := 1, sombra := false) -> void:
	t(c, round(cx - ancho(s, esc) / 2.0), y, s, col, esc, sombra)


## Parte un texto en lineas de hasta "max_px" de ancho.
static func partir(s: String, max_px: float) -> PackedStringArray:
	var r := PackedStringArray()
	var linea := ""
	for p in s.split(" "):
		var prueba := p if linea == "" else linea + " " + p
		if ancho(prueba) > max_px and linea != "":
			r.append(linea)
			linea = p
		else:
			linea = prueba
	if linea != "":
		r.append(linea)
	return r


## Dibuja un parrafo. Devuelve la y siguiente.
static func parrafo(c: CanvasItem, x: float, y: float, s: String, max_px: float, col := C_TEXTO) -> float:
	for lin in partir(s, max_px):
		t(c, x, y, lin, col)
		y += ALTO_LINEA
	return y


static func marco(c: CanvasItem, r: Rect2, fondo := C_PANEL, borde := C_LINEA) -> void:
	c.draw_rect(r, fondo)
	c.draw_rect(r, borde, false, 1.0)


static func barra(c: CanvasItem, r: Rect2, v: float, col: Color, fondo := Color("0d0a18")) -> void:
	c.draw_rect(r, fondo)
	c.draw_rect(Rect2(r.position + Vector2.ONE, Vector2(maxf((r.size.x - 2) * clampf(v, 0.0, 1.0), 0.0), r.size.y - 2)), col)


## Icono de una pieza dentro de su marco de rareza.
static func pieza(c: CanvasItem, pos: Vector2, tam: float, it: Dictionary, resaltar := false) -> void:
	var r := Rect2(pos, Vector2(tam, tam))
	var col: Color = Datos.RAREZAS[it.rareza].color
	c.draw_rect(r, col.darkened(0.72))
	c.draw_rect(r, col, false, 1.0)
	if it.rareza >= 3:
		c.draw_rect(r.grow(-1), col, false, 1.0)
	if resaltar:
		c.draw_rect(r.grow(1), Color.WHITE, false, 1.0)
	var tx: Texture2D = Datos.tex("icono_" + it.id)
	c.draw_texture(tx, pos + Vector2((tam - tx.get_width()) / 2.0, (tam - tx.get_height()) / 2.0))
