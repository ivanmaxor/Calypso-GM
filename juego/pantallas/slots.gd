extends Control
## Las tres ranuras de partida: cargar, borrar, empezar una nueva o traer una de otro computador.

signal listo  # quedó una partida abierta: toca ir al mapa
signal cerrado

const DIFICULTAD := preload("res://pantallas/elegir_dificultad.gd")
const MODAL := preload("res://pantallas/modal.gd")
const ANCHO_F := 196.0
const ALTO_F := 206.0
const Y_F := 48.0

var modo := "cargar"  # cargar, nueva o importar
var modo_antes := "cargar"
var fichas: Array = []
var b_borrar: Array = []
var b_volver: Button
var b_importar: Button = null
var mensaje := ""
var mensaje_col := UI.C_GRIS
var mensaje_t := 0.0
var pie: Label


class Ficha extends Button:
	var i := 1
	var pantalla
	var info := {}
	var nave: Sprite2D = null
	var t := 0.0

	func _ready() -> void:
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(ANCHO_F, ALTO_F)
		size = custom_minimum_size
		var vacio := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, vacio)
		focus_entered.connect(func():
			Sonido.tocar("ui_mover")
			queue_redraw())
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)
		pressed.connect(pantalla.pulsar.bind(i))
		if info.existe and Datos.NAVES.has(info.nave):
			nave = Sprite2D.new()
			nave.region_enabled = true
			nave.texture = Datos.tex("nave2_" + info.nave)
			nave.region_rect = Rect2(4 * 48, 0, 48, 48)
			var mat := ShaderMaterial.new()
			mat.shader = load("res://arte/nave.gdshader")
			Datos.pintar(mat, Datos.NAVES[info.nave].pintura, 0, 0)
			nave.material = mat
			nave.position = Vector2(38, 54)
			add_child(nave)

	func _process(d: float) -> void:
		if nave and has_focus():
			t += d
			nave.region_rect = Rect2((4 + int(t * 8.0) % 2) * 48, 0, 48, 48)

	func _draw() -> void:
		pantalla.dibujar_ficha(self)


func _ready() -> void:
	global_position = Vector2.ZERO
	size = Vector2(640, 360)
	theme = UI.tema()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construir()
	pie = UI.pie(self)
	_poner_pie()


func _poner_pie() -> void:
	pie.teclado = "Flechas o WASD: moverse  ·  Enter o Espacio: elegir  ·  Supr: borrar  ·  Esc: volver" if modo == "cargar" else UI.PIE_MENU


func _construir(foco_en := 0) -> void:
	for h in get_children():
		if not h is UI.Pie:
			remove_child(h)
			h.queue_free()
	fichas.clear()
	b_borrar.clear()
	var x0: float = (640.0 - 3.0 * ANCHO_F - 2.0 * 8.0) / 2.0
	for i in range(1, Partida.NUM_SLOTS + 1):
		var f := Ficha.new()
		f.i = i
		f.pantalla = self
		f.info = Partida.info_slot(i)
		f.position = Vector2(round(x0 + (i - 1) * (ANCHO_F + 8.0)), Y_F)
		add_child(f)
		fichas.append(f)
		var b: Button = null
		if f.info.existe and modo == "cargar":
			b = UI.boton("BORRAR", Vector2(f.position.x, Y_F + ALTO_F + 4.0), Vector2(ANCHO_F, 22), self, _borrar.bind(i))
			b.add_theme_color_override("font_color", UI.C_ROJO)
			b.add_theme_color_override("font_focus_color", UI.C_ROJO)
			b.add_theme_color_override("font_hover_color", UI.C_ROJO)
		b_borrar.append(b)
	var hay_import: bool = Partida.archivo_importable() != "" and modo != "importar"
	var y_b := 286.0
	if hay_import:
		b_importar = UI.boton("IMPORTAR PARTIDA", Vector2(165, y_b), Vector2(150, 24), self, _pedir_importar)
		b_importar.add_theme_color_override("font_color", UI.C_CIAN)
		b_volver = UI.boton("VOLVER", Vector2(325, y_b), Vector2(150, 24), self, _salir)
	else:
		b_importar = null
		b_volver = UI.boton("VOLVER", Vector2(245, y_b), Vector2(150, 24), self, _salir)
	_enlazar()
	var cual: int = foco_en if foco_en > 0 else _ficha_inicial()
	fichas[cual - 1].grab_focus()


## Donde parte el foco: la última que usaste al cargar, y la primera libre si vas a crear una.
func _ficha_inicial() -> int:
	if modo == "cargar":
		var u: int = int(Partida.g.ultimo_slot)
		if u >= 1 and Partida.existe_slot(u):
			return u
		for f in fichas:
			if f.info.existe:
				return f.i
		return 1
	var libre: int = Partida.slot_libre()
	return libre if libre > 0 else 1


func _enlazar() -> void:
	var abajo: Array = [b_volver] if b_importar == null else [b_importar, b_volver]
	for k in fichas.size():
		var f: Control = fichas[k]
		var iz: Control = fichas[posmod(k - 1, fichas.size())]
		var de: Control = fichas[posmod(k + 1, fichas.size())]
		f.focus_neighbor_left = f.get_path_to(iz)
		f.focus_neighbor_right = f.get_path_to(de)
		f.focus_previous = f.get_path_to(iz)
		f.focus_next = f.get_path_to(de)
		f.focus_neighbor_top = f.get_path_to(f)
		f.focus_neighbor_bottom = f.get_path_to(b_borrar[k] if b_borrar[k] != null else abajo[abajo.size() - 1])
		var b: Button = b_borrar[k]
		if b != null:
			b.focus_neighbor_top = b.get_path_to(f)
			b.focus_neighbor_bottom = b.get_path_to(abajo[abajo.size() - 1])
			b.focus_neighbor_left = b.get_path_to(_borrar_vecino(k, -1))
			b.focus_neighbor_right = b.get_path_to(_borrar_vecino(k, 1))
			b.focus_next = b.get_path_to(de)
			b.focus_previous = b.get_path_to(iz)
	UI.lista_foco(abajo, false)
	for c in abajo:
		var ctrl: Control = c
		ctrl.focus_neighbor_top = ctrl.get_path_to(fichas[1])
		ctrl.focus_neighbor_bottom = ctrl.get_path_to(ctrl)
		ctrl.focus_next = ctrl.get_path_to(fichas[0])
		ctrl.focus_previous = ctrl.get_path_to(fichas[fichas.size() - 1])


func _borrar_vecino(k: int, paso: int) -> Control:
	var j := k + paso
	while j >= 0 and j < b_borrar.size():
		if b_borrar[j] != null:
			return b_borrar[j]
		j += paso
	return b_borrar[k]


func pulsar(i: int) -> void:
	var info: Dictionary = fichas[i - 1].info
	Sonido.tocar("ui_ok")
	match modo:
		"cargar":
			if info.existe:
				_cargar(i)
			else:
				_elegir_dificultad(i)
		"nueva":
			if info.existe:
				MODAL.abrir(self, "La Ranura %d ya tiene una partida" % i, _resumen(info) + " Se borra cuando elijas la dificultad.", [["VOLVER", Callable()], ["SOBRESCRIBIR", _elegir_dificultad.bind(i)]], UI.C_ROJO)
			else:
				_elegir_dificultad(i)
		"importar":
			if info.existe:
				MODAL.abrir(self, "La Ranura %d ya tiene una partida" % i, _resumen(info) + " Si importas aquí, se pierde.", [["VOLVER", Callable()], ["SOBRESCRIBIR", _importar.bind(i)]], UI.C_ROJO)
			else:
				_importar(i)


func _resumen(info: Dictionary) -> String:
	var dif: String = Datos.DIFICULTADES[info.dificultad].nombre
	if info.terminado:
		return "%s, juego terminado, %d estrellas." % [dif, info.estrellas]
	return "%s, nivel %s, %d estrellas." % [dif, info.nivel_actual, info.estrellas]


func _cargar(i: int) -> void:
	if Partida.abrir_slot(i):
		listo.emit()
		queue_free()
	else:
		_avisar("No se pudo abrir esa partida: el archivo está dañado.", UI.C_ROJO)


func _elegir_dificultad(i: int) -> void:
	var dlg := DIFICULTAD.new()
	dlg.subtitulo = "Ranura %d. Partida nueva." % i
	dlg.elegida.connect(func(id: String):
		Partida.crear_slot(i, id)
		listo.emit()
		queue_free())
	dlg.cancelado.connect(func(): fichas[i - 1].grab_focus())
	add_child(dlg)


func _borrar(i: int) -> void:
	var info: Dictionary = fichas[i - 1].info
	if not info.existe:
		return
	MODAL.abrir(self, "¿Borrar la Ranura %d?" % i, _resumen(info), [["NO", Callable()], ["SÍ, BORRAR", _borrar_seguro.bind(i)]], UI.C_ROJO)


func _borrar_seguro(i: int) -> void:
	MODAL.abrir(self, "¿Segurísimo?", "Se pierde para siempre: no se puede deshacer.", [["NO, DÉJALA", Callable()], ["BORRAR PARA SIEMPRE", _borrar_ya.bind(i)]], UI.C_ROJO)


func _borrar_ya(i: int) -> void:
	Partida.borrar_slot(i)
	# si era la que estaba abierta, no puede quedar dando vueltas en memoria
	if Partida.slot == i:
		Partida.nuevo()
	_construir(i)
	_avisar("Ranura %d borrada." % i, UI.C_GRIS)


func _pedir_importar() -> void:
	modo_antes = modo
	modo = "importar"
	_poner_pie()
	_construir()
	_avisar("Encontré un archivo para importar. ¿En qué ranura lo dejo?", UI.C_CIAN)


func _importar(i: int) -> void:
	if Partida.importar_a_slot(i):
		listo.emit()
		queue_free()
		return
	Sonido.tocar("ui_no")
	modo = modo_antes
	_poner_pie()
	_construir()
	_avisar("Ese archivo no sirve: está dañado o es de otra versión.", UI.C_ROJO)


func _avisar(t: String, c: Color) -> void:
	mensaje = t
	mensaje_col = c
	mensaje_t = 5.0
	queue_redraw()


func _salir() -> void:
	if modo == "importar":
		modo = modo_antes
		_poner_pie()
		_construir()
		return
	cerrado.emit()
	queue_free()


func _hay_modal() -> bool:
	return get_child(get_child_count() - 1) is MODAL or get_child(get_child_count() - 1) is DIFICULTAD


func _unhandled_input(ev: InputEvent) -> void:
	if _hay_modal():
		return
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Sonido.tocar("ui_no")
		_salir()
	elif ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_DELETE and modo == "cargar":
		get_viewport().set_input_as_handled()
		var f := get_viewport().gui_get_focus_owner()
		if f is Ficha and f.info.existe:
			_borrar(f.i)
		else:
			Sonido.tocar("ui_no")


func _process(d: float) -> void:
	if mensaje_t > 0.0:
		mensaje_t -= d
		if mensaje_t <= 0.0:
			mensaje = ""
			queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), UI.C_FONDO)
	var tit := "CARGAR PARTIDA"
	var sub := "Elige con cuál seguir. Una ranura vacía parte una partida nueva."
	if modo == "nueva":
		tit = "NUEVA PARTIDA"
		sub = "Elige en qué ranura guardarla. Tienes tres, y cada una lleva su propio avance."
	elif modo == "importar":
		tit = "IMPORTAR PARTIDA"
		sub = "Elige en qué ranura dejarla."
	UI.tc(self, 320, 2, tit, UI.C_ORO, 2, true)
	UI.tc(self, 320, 30, sub, UI.C_GRIS)
	if mensaje != "":
		UI.tc(self, 320, 320, mensaje, mensaje_col)


func dibujar_ficha(f: Ficha) -> void:
	var foco := f.has_focus()
	var info: Dictionary = f.info
	var r := Rect2(Vector2.ZERO, f.size)
	UI.marco(f, r, UI.C_PANEL2 if foco else UI.C_PANEL, UI.C_ORO if foco else UI.C_LINEA)
	if foco:
		f.draw_rect(r.grow(-1), UI.C_ORO, false, 1.0)
	var cx: float = f.size.x / 2.0
	UI.tc(f, cx, 5, "RANURA %d" % f.i, UI.C_ORO if foco else UI.C_TEXTO)
	f.draw_line(Vector2(8, 23), Vector2(f.size.x - 8.0, 23), UI.C_LINEA, 1.0)
	if not info.existe:
		UI.tc(f, cx, 70, "Vacía", UI.C_GRIS, 2, true)
		if foco:
			UI.tc(f, cx, ALTO_F - 22.0, _accion("guardar aquí" if modo == "importar" else "partida nueva"), UI.C_ORO)
		return
	# dificultad y ciclo, al lado de la nave
	var def: Dictionary = Datos.DIFICULTADES[info.dificultad]
	f.draw_texture_rect(Datos.tex(def.icono), Rect2(72, 30, 32, 32), false)
	UI.t(f, 108, 30, def.nombre, def.color)
	if info.ciclo > 0:
		UI.t(f, 108, 45, "Ciclo %d" % info.ciclo, UI.C_ROSA)
	f.draw_line(Vector2(8, 82), Vector2(f.size.x - 8.0, 82), UI.C_LINEA, 1.0)
	# hasta dónde llegó
	var y := 86.0
	if info.terminado:
		UI.t(f, 10, y, "¡Juego terminado!", UI.C_VERDE)
		y += UI.ALTO_LINEA
		UI.t(f, 10, y, "Puedes seguir en el mapa.", UI.C_GRIS)
	else:
		UI.t(f, 10, y, "Vas en el nivel %s" % info.nivel_actual, UI.C_TEXTO)
		y += UI.ALTO_LINEA
		UI.t(f, 10, y, Datos.NIVELES[info.nivel_actual].nombre, UI.C_GRIS)
	# números
	var yn := 120.0
	f.draw_texture(Datos.tex("ui_estrella"), Vector2(9, yn + 2))
	UI.t(f, 26, yn, "Estrellas", UI.C_GRIS)
	_derecha(f, yn, "%d/%d" % [info.estrellas, Datos.ORDEN_NIVELES.size() * 3])
	yn += 15.0
	f.draw_texture(Datos.tex("obj_tuerca"), Vector2(10, yn + 3))
	UI.t(f, 26, yn, "Chatarra", UI.C_GRIS)
	_derecha(f, yn, str(info.chatarra))
	yn += 15.0
	UI.t(f, 26, yn, "Tiempo", UI.C_GRIS)
	_derecha(f, yn, UI.duracion(info.tiempo))
	# lo que pasa si aprietas
	if foco:
		match modo:
			"cargar":
				UI.tc(f, cx, ALTO_F - 22.0, _accion("cargar"), UI.C_ORO)
			_:
				UI.tc(f, cx, ALTO_F - 22.0, "Ocupada: se sobrescribe", UI.C_ROJO)


func _accion(que: String) -> String:
	return ("A: " if Controles.ultimo_mando else "Enter o clic: ") + que


func _derecha(f: Control, y: float, s: String) -> void:
	UI.t(f, f.size.x - 10.0 - UI.ancho(s), y, s, UI.C_TEXTO)
