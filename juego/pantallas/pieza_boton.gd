class_name PiezaBoton
extends Button
## Un cuadrito con una pieza del inventario. También guarda las ayudas que comparten las estaciones del Hangar.

## Lo que se muestra como porcentaje en la ficha de una pieza.
const PORCENTAJES := ["vel", "desync_carga", "cascada", "suerte", "chatarra", "crit", "crit_dmg", "armadura", "cadencia", "area", "xp", "dano", "thorns", "mov_dano", "dash_cd"]

var item := {}
var marcado := false
var apagado := false
var tam := 36


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(tam, tam)
	size = Vector2(tam, tam)
	var vacio := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(s, vacio)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _draw() -> void:
	var r := Rect2(0, 0, tam, tam)
	if item.is_empty():
		UI.marco(self, r, Color("15112a"), Color("2a2448"))
		return
	UI.pieza(self, Vector2.ZERO, tam, item)
	if item.nivel > 1:
		draw_rect(Rect2(1, tam - 13, UI.ancho(str(item.nivel)) + 3, 12), Color(0, 0, 0, 0.7))
		UI.t(self, 2, tam - 15, str(item.nivel), Color.WHITE)
	if Partida.esta_equipado(item.uid):
		draw_rect(Rect2(tam - 11, 1, 10, 10), UI.C_VERDE)
		UI.t(self, tam - 9, -3, "E", Color("0d0a18"))
	if apagado:
		draw_rect(r, Color(0.05, 0.04, 0.1, 0.72))
	if marcado:
		draw_rect(r.grow(-1), Color.WHITE, false, 1.0)
		draw_rect(r.grow(-2), UI.C_ORO, false, 1.0)
	elif has_focus() or is_hovered():
		draw_rect(r.grow(-1), Color.WHITE, false, 1.0)


# =================================================================================================
# AYUDAS DE LAS ESTACIONES
# =================================================================================================
## Une una cuadrícula con vecinos de foco explícitos, para que las flechas no se escapen.
## filas: una lista de filas con sus botones, alineadas por columna.
## arriba, derecha y abajo: a dónde se sale por ese borde. Si es null, el foco se queda donde está.
static func enlazar(filas: Array, arriba: Control = null, derecha: Control = null, abajo: Control = null) -> void:
	for f in filas.size():
		var fila: Array = filas[f]
		for c in fila.size():
			var b: Control = fila[c]
			var izq: Control = fila[c - 1] if c > 0 else b
			var der: Control = fila[c + 1] if c + 1 < fila.size() else (derecha if derecha else b)
			var sube: Control = filas[f - 1][mini(c, filas[f - 1].size() - 1)] if f > 0 else (arriba if arriba else b)
			var baja: Control = filas[f + 1][mini(c, filas[f + 1].size() - 1)] if f + 1 < filas.size() else (abajo if abajo else b)
			b.focus_neighbor_left = b.get_path_to(izq)
			b.focus_neighbor_right = b.get_path_to(der)
			b.focus_neighbor_top = b.get_path_to(sube)
			b.focus_neighbor_bottom = b.get_path_to(baja)


## La barra de una lista larga: sin ancho propio no se ve, y con mouse hay que poder arrastrarla.
static func barra_visible(scroll: ScrollContainer) -> void:
	scroll.get_v_scroll_bar().custom_minimum_size.x = 6.0


## Lo que habla del Desync no se muestra hasta tenerlo: no hay que adelantarlo (punto 6).
static func sin_spoiler(txt: String) -> String:
	if Partida.tiene("desync"):
		return txt
	var m := txt.to_lower()
	if "desync" in m or "cascada" in m or "reconect" in m:
		return "???"
	return txt


## El valor de un stat como se lee en una ficha: "+3 %" o "+12".
static func valor_stat(k: String, v: float) -> String:
	var signo := "+" if v >= 0.0 else "-"
	# con un decimal: redondear a entero escondía las mejoras chicas (M13)
	if k in PORCENTAJES:
		return "%s%s %%" % [signo, decimal(absf(v) * 100.0)]
	return "%s%s" % [signo, decimal(absf(v))]


## "4,3": los decimales en Chile van con coma, y sin un ",0" que no aporta.
static func decimal(v: float) -> String:
	return String.num(snappedf(v, 0.1), 1).trim_suffix(".0").replace(".", ",")


static func segundos(cuadros: float) -> String:
	return "%s s" % decimal(cuadros / 60.0)
