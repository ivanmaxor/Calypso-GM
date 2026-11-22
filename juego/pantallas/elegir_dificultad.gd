extends Control
## Las cuatro dificultades en tarjetas. La usan la partida nueva y la Nueva Partida +.

signal elegida(id: String)
signal cancelado

const ORDEN := ["facil", "normal", "dificil", "extremo"]
const ANCHO_T := 148.0
const ALTO_T := 214.0

var titulo := "¿QUÉ TAN DURO LO QUIERES?"
var subtitulo := ""
var preseleccion := "normal"
var tarjetas := {}
var b_volver: Button
var aviso := ""
var aviso_t := 0.0


class Tarjeta extends Button:
	var id := ""
	var pantalla

	func _ready() -> void:
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(ANCHO_T, ALTO_T)
		size = custom_minimum_size
		var vacio := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, vacio)
		focus_entered.connect(func():
			Sonido.tocar("ui_mover")
			queue_redraw())
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)
		pressed.connect(pantalla.pulsar.bind(id))

	func _draw() -> void:
		pantalla.dibujar_tarjeta(self)


func _ready() -> void:
	global_position = Vector2.ZERO
	size = Vector2(640, 360)
	theme = UI.tema()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var x0: float = (640.0 - ORDEN.size() * ANCHO_T - (ORDEN.size() - 1) * 6.0) / 2.0
	var lista := []
	for i in ORDEN.size():
		var t := Tarjeta.new()
		t.id = ORDEN[i]
		t.pantalla = self
		t.position = Vector2(round(x0 + i * (ANCHO_T + 6.0)), 54)
		add_child(t)
		tarjetas[t.id] = t
		lista.append(t)
	UI.lista_foco(lista, false)
	b_volver = UI.boton("VOLVER", Vector2(250, 312), Vector2(140, 24), self, _cancelar)
	for t in lista:
		t.focus_neighbor_bottom = t.get_path_to(b_volver)
		t.focus_neighbor_top = t.get_path_to(t)
	var ini: String = preseleccion if tarjetas.has(preseleccion) and _abierta(preseleccion) else "normal"
	var yo := b_volver.get_path_to(b_volver)
	b_volver.focus_neighbor_left = yo
	b_volver.focus_neighbor_right = yo
	b_volver.focus_neighbor_bottom = yo
	b_volver.focus_neighbor_top = b_volver.get_path_to(tarjetas[ini])
	b_volver.focus_next = b_volver.get_path_to(lista[0])
	b_volver.focus_previous = b_volver.get_path_to(lista[lista.size() - 1])
	tarjetas[ini].grab_focus()
	UI.pie(self, "Flechas o WASD: moverse  ·  Enter o Espacio: elegir  ·  Esc: volver")


func _abierta(id: String) -> bool:
	return Datos.DIFICULTADES[id].get("requiere", "") == "" or Partida.extremo_abierto()


func pulsar(id: String) -> void:
	if not _abierta(id):
		Sonido.tocar("ui_no")
		aviso = "%s se abre al terminar el juego." % Datos.DIFICULTADES[id].nombre
		aviso_t = 3.0
		queue_redraw()
		return
	Sonido.tocar("ui_ok")
	elegida.emit(id)


func _cancelar() -> void:
	cancelado.emit()
	queue_free()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Sonido.tocar("ui_no")
		_cancelar()


func _process(d: float) -> void:
	if aviso_t > 0.0:
		aviso_t -= d
		if aviso_t <= 0.0:
			aviso = ""
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), UI.C_FONDO)
	UI.tc(self, 320, 2, titulo, UI.C_ORO, 2, true)
	UI.tc(self, 320, 32, subtitulo, UI.C_GRIS)
	if aviso != "":
		UI.tc(self, 320, 291, aviso, UI.C_ROJO)
	else:
		UI.tc(self, 320, 291, "No se cambia a mitad de partida: solo al empezar una Nueva Partida +.", UI.C_GRIS)


func dibujar_tarjeta(t: Tarjeta) -> void:
	var def: Dictionary = Datos.DIFICULTADES[t.id]
	var abierta := _abierta(t.id)
	var foco := t.has_focus()
	var col: Color = def.color if abierta else UI.C_GRIS
	var r := Rect2(Vector2.ZERO, t.size)
	UI.marco(t, r, UI.C_PANEL2 if foco else UI.C_PANEL, col if foco else UI.C_LINEA)
	if foco:
		t.draw_rect(r.grow(-1), col, false, 1.0)
	var cx: float = t.size.x / 2.0
	var ic := Rect2(cx - 32.0, 8, 64, 64)
	t.draw_texture_rect(Datos.tex(def.icono), ic, false, Color.WHITE if abierta else Color(0.35, 0.33, 0.45))
	if not abierta:
		t.draw_texture_rect(Datos.tex("ui_candado"), Rect2(cx - 14.0, 26, 28, 28), false)
	UI.tc(t, cx, 72, def.nombre, col, 2, true)
	var y := 100.0
	var desc: String = def.desc.replace("Se abre al terminar el juego. ", "")
	if not abierta:
		for l in UI.partir("Termina el juego para abrirlo.", ANCHO_T - 12.0):
			UI.tc(t, cx, y, l, UI.C_ORO)
			y += UI.ALTO_LINEA
	for l in UI.partir(desc, ANCHO_T - 12.0):
		UI.tc(t, cx, y, l, UI.C_TEXTO if abierta else UI.C_GRIS)
		y += UI.ALTO_LINEA
	# los números, para comparar de un vistazo
	y = ALTO_T - 46.0
	t.draw_line(Vector2(8, y - 1), Vector2(ANCHO_T - 8.0, y - 1), UI.C_LINEA, 1.0)
	_dato(t, y, "Vida enemiga", def.hp, abierta)
	_dato(t, y + 14.0, "Daño enemigo", def.dano, abierta)
	_dato(t, y + 28.0, "Botín", def.botin, abierta)


func _dato(t: Control, y: float, nombre: String, v: float, abierta: bool) -> void:
	var txt := "%d %%" % roundi(v * 100.0)
	UI.t(t, 8, y, nombre, UI.C_GRIS)
	UI.t(t, ANCHO_T - 8.0 - UI.ancho(txt), y, txt, UI.C_TEXTO if abierta else UI.C_GRIS)
