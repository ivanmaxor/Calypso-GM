extends Control
## Nueva Partida +: qué se conserva, qué cambia, y con qué dificultad se parte de nuevo.

signal hecho
signal cerrado

const DIFICULTAD := preload("res://pantallas/elegir_dificultad.gd")
const SE_CONSERVA := ["Tus piezas y su nivel", "Tus naves y mascotas", "Tu chatarra", "Armas y habilidades ganadas", "Desafíos y ranuras"]

var b_seguir: Button
var b_volver: Button
var b_repetir: Button
var repetir := true
var cambia := PackedStringArray()


func _ready() -> void:
	global_position = Vector2.ZERO
	size = Vector2(640, 360)
	theme = UI.tema()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var c: int = Partida.ciclo() + 1
	# lo que suben los enemigos en esta vuelta, sin contar la dificultad que elijas
	Partida.d.ciclo = c
	var m: Dictionary = Partida.mods_enemigos()
	Partida.d.ciclo = c - 1
	var di: Dictionary = Partida.dif()
	cambia = PackedStringArray([
		"Los niveles parten de cero, y las estrellas también.",
		"Enemigos con %d %% de vida y %d %% de daño." % [roundi(m.hp / di.hp * 100.0), roundi(m.dano / di.dano * 100.0)],
		"Disparan más seguido y sus balas van más rápido.",
		"Sueltan mejor botín y más chatarra.",
		"Lo que ya ganaste no se repite: da chatarra.",
	])
	b_repetir = UI.boton("", Vector2(150, 236), Vector2(340, 22), self, _alternar_repetir)
	_texto_repetir()
	b_volver = UI.boton("VOLVER", Vector2(150, 266), Vector2(120, 26), self, _cerrar)
	b_seguir = UI.boton("ELEGIR DIFICULTAD", Vector2(290, 266), Vector2(200, 26), self, _elegir)
	b_seguir.add_theme_color_override("font_color", UI.C_ORO)
	# de arriba abajo, y a los lados entre los dos de abajo
	b_repetir.focus_neighbor_bottom = b_repetir.get_path_to(b_seguir)
	b_repetir.focus_neighbor_top = b_repetir.get_path_to(b_repetir)
	b_repetir.focus_neighbor_left = b_repetir.get_path_to(b_repetir)
	b_repetir.focus_neighbor_right = b_repetir.get_path_to(b_repetir)
	b_repetir.focus_next = b_repetir.get_path_to(b_volver)
	b_repetir.focus_previous = b_repetir.get_path_to(b_seguir)
	for b in [b_volver, b_seguir]:
		b.focus_neighbor_top = b.get_path_to(b_repetir)
		b.focus_neighbor_bottom = b.get_path_to(b)
	b_volver.focus_neighbor_left = b_volver.get_path_to(b_volver)
	b_volver.focus_neighbor_right = b_volver.get_path_to(b_seguir)
	b_seguir.focus_neighbor_left = b_seguir.get_path_to(b_volver)
	b_seguir.focus_neighbor_right = b_seguir.get_path_to(b_seguir)
	b_volver.focus_next = b_volver.get_path_to(b_seguir)
	b_volver.focus_previous = b_volver.get_path_to(b_repetir)
	b_seguir.focus_next = b_seguir.get_path_to(b_repetir)
	b_seguir.focus_previous = b_seguir.get_path_to(b_volver)
	b_seguir.grab_focus()
	UI.pie(self)


func _alternar_repetir() -> void:
	repetir = not repetir
	_texto_repetir()


func _texto_repetir() -> void:
	b_repetir.text = "Repetir los textos de Don Tuerca: %s" % ("Sí" if repetir else "No")


func _elegir() -> void:
	var dlg := DIFICULTAD.new()
	dlg.titulo = "¿CON QUÉ DIFICULTAD VUELVES?"
	dlg.subtitulo = "Ciclo %d de %d. Los enemigos ya vienen más fuertes por el ciclo." % [Partida.ciclo() + 1, Partida.CICLO_MAX]
	dlg.preseleccion = Partida.dificultad()
	dlg.elegida.connect(_partir)
	dlg.cancelado.connect(func(): b_seguir.grab_focus())
	add_child(dlg)


func _partir(id: String) -> void:
	Partida.iniciar_ng_plus(id, repetir)
	# Don Tuerca ya se presentó: esta vuelta parte con su diálogo propio
	Partida.marcar_visto("inicio")
	hecho.emit()


func _cerrar() -> void:
	cerrado.emit()
	queue_free()


func _unhandled_input(ev: InputEvent) -> void:
	if get_child(get_child_count() - 1) is DIFICULTAD:
		return
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Sonido.tocar("ui_no")
		_cerrar()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), UI.C_FONDO)
	UI.tc(self, 320, 6, "NUEVA PARTIDA +", UI.C_ORO, 3, true)
	UI.tc(self, 320, 50, "Otra vuelta desde el principio, ahora en el ciclo %d de %d." % [Partida.ciclo() + 1, Partida.CICLO_MAX], UI.C_GRIS)
	var a := Rect2(20, 72, 250, 154)
	UI.marco(self, a, UI.C_PANEL, UI.C_VERDE)
	UI.t(self, a.position.x + 10, a.position.y + 6, "SE CONSERVA", UI.C_VERDE)
	var y: float = a.position.y + 26
	for l in SE_CONSERVA:
		UI.t(self, a.position.x + 10, y, l)
		y += 22.0
	var b := Rect2(280, 72, 340, 154)
	UI.marco(self, b, UI.C_PANEL, UI.C_ROSA)
	UI.t(self, b.position.x + 10, b.position.y + 6, "CAMBIA", UI.C_ROSA)
	y = b.position.y + 26
	for l in cambia:
		UI.t(self, b.position.x + 10, y, l)
		y += 22.0
