extends Control
## Antes de cada nivel: con que nave sales, como los personajes de Megabonk.

signal despegar
signal volver

var g: GaleriaNaves
var b_ok: Button
var b_volver: Button
var abierto_en := 0
var t := 0
var fondo: Texture2D


func _ready() -> void:
	size = Vector2(640, 360)
	theme = UI.tema()
	var f := ColorRect.new()
	f.color = UI.C_FONDO
	f.size = size
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(f)
	UI.etiqueta("ELIGE TU NAVE", Vector2(75, 4), self, UI.C_ORO)
	UI.etiqueta("Nivel %s: %s. Enter o clic en una nave para salir con ella." % [Partida.nivel_sel, Datos.NIVELES[Partida.nivel_sel].nombre], Vector2(75, 18), self, UI.C_GRIS)
	g = GaleriaNaves.new()
	g.position = Vector2(75, 36)
	g.cambio.connect(_al_cambiar)
	g.confirmar.connect(_elegir)
	add_child(g)
	b_volver = UI.boton("VOLVER", Vector2(75, 326), Vector2(120, 26), self, func(): volver.emit())
	b_ok = UI.boton("¡DESPEGAR!", Vector2(385, 326), Vector2(180, 26), self, _ok)
	b_ok.add_theme_color_override("font_color", UI.C_ORO)
	# las flechas no se escapan: las naves bajan a despegar, y los botones vuelven a las naves
	g.conectar(null, b_ok)
	b_volver.focus_neighbor_right = b_volver.get_path_to(b_ok)
	b_volver.focus_neighbor_left = b_volver.get_path_to(b_volver)
	b_volver.focus_neighbor_bottom = b_volver.get_path_to(b_volver)
	b_ok.focus_neighbor_left = b_ok.get_path_to(b_volver)
	b_ok.focus_neighbor_right = b_ok.get_path_to(b_ok)
	b_ok.focus_neighbor_bottom = b_ok.get_path_to(b_ok)
	g.enfocar()
	abierto_en = Engine.get_process_frames()
	_al_cambiar(g.sel)


func _al_cambiar(id: String) -> void:
	var tiene: bool = id in Partida.d.naves
	b_ok.disabled = not tiene
	b_ok.text = "¡DESPEGAR!" if tiene else "BLOQUEADA"
	b_volver.focus_neighbor_top = b_volver.get_path_to(g.tarjetas[id])


func _elegir(id: String) -> void:
	Partida.elegir_nave(id)
	despegar.emit()


func _ok() -> void:
	_elegir(g.sel)


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		volver.emit()
