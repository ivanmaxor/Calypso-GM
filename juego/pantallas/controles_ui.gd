extends Control
## Pantalla de teclas: principal, secundaria y mando, con detección de conflictos.
## Con teclado: flechas o WASD para moverse, Enter para cambiar, Supr para borrar.
## Con mouse: clic para cambiar, clic derecho para borrar.

const MODAL := preload("res://pantallas/modal.gd")
const AYUDA := "Enter o clic: cambiar  ·  Supr o clic derecho: borrar"
const COLUMNAS := ["teclado0", "teclado1", "mando0"]

var b_rest1: Button
var b_rest2: Button
var b_cancelar: Button
var botones := {}
var capturando := {}
var panel_conflicto: Control = null
var aviso: Label
var ignorar_hasta := 0
var ultima_celda := {}  # la última tecla de la tabla que tuvo el foco: la que restaura "Restaurar esta"


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 290)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var x := [30, 170, 310, 450]
	UI.etiqueta("Acción", Vector2(x[0], -3), self, UI.C_GRIS)
	UI.etiqueta("Principal", Vector2(x[1], -3), self, UI.C_GRIS)
	UI.etiqueta("Secundaria", Vector2(x[2], -3), self, UI.C_GRIS)
	UI.etiqueta("Mando", Vector2(x[3], -3), self, UI.C_GRIS)
	var y := 15
	for accion in Controles.ACCIONES:
		UI.etiqueta(Controles.NOMBRES[accion], Vector2(x[0], y + 1), self)
		botones[accion] = {}
		var definiciones := [["teclado", 0, x[1]], ["teclado", 1, x[2]], ["mando", 0, x[3]]]
		for d in definiciones:
			var b := Button.new()
			b.position = Vector2(d[2], y)
			b.size = Vector2(134, 20)
			b.custom_minimum_size = Vector2(134, 20)
			b.focus_mode = Control.FOCUS_ALL
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
			add_child(b)
			var grupo: String = d[0]
			var ranura: int = d[1]
			b.pressed.connect(func(): _empezar_captura(accion, grupo, ranura))
			b.focus_entered.connect(func():
				ultima_celda = {"accion": accion, "grupo": grupo, "ranura": ranura}
				Sonido.tocar("ui_mover"))
			b.gui_input.connect(_celda_input.bind(accion, grupo, ranura))
			botones[accion][grupo + str(ranura)] = b
		y += 23
	b_rest1 = UI.boton("Restaurar esta", Vector2(310, y + 2), Vector2(134, 20), self, _restaurar_actual)
	b_rest2 = UI.boton("Restaurar todas", Vector2(450, y + 2), Vector2(134, 20), self, _restaurar_todas)
	aviso = UI.etiqueta(AYUDA, Vector2(x[0], y + 25), self, UI.C_GRIS)
	# para quien solo usa el mouse: mientras se espera una tecla, cualquier clic contaría como tecla
	b_cancelar = UI.boton("Cancelar", Vector2(450, y + 2), Vector2(134, 20), self, _cancelar_captura)
	b_cancelar.focus_mode = Control.FOCUS_NONE
	b_cancelar.visible = false
	_refrescar()


func primer_boton() -> Control:
	return botones[Controles.ACCIONES[0]]["teclado0"]


func ultimo_boton() -> Control:
	return b_rest1


## Todos los vecinos explícitos: el foco nunca se escapa a lo que hay detrás.
func limitar_foco(b_volver: Button, tab: Button) -> void:
	var filas: int = Controles.ACCIONES.size()
	for r in filas:
		var accion: String = Controles.ACCIONES[r]
		for c in COLUMNAS.size():
			var b: Button = botones[accion][COLUMNAS[c]]
			var yo := b.get_path_to(b)
			b.focus_neighbor_left = b.get_path_to(botones[accion][COLUMNAS[c - 1]]) if c > 0 else yo
			b.focus_neighbor_right = b.get_path_to(botones[accion][COLUMNAS[c + 1]]) if c + 1 < COLUMNAS.size() else yo
			if r > 0:
				b.focus_neighbor_top = b.get_path_to(botones[Controles.ACCIONES[r - 1]][COLUMNAS[c]])
			else:
				b.focus_neighbor_top = b.get_path_to(tab)
			if r + 1 < filas:
				b.focus_neighbor_bottom = b.get_path_to(botones[Controles.ACCIONES[r + 1]][COLUMNAS[c]])
			else:
				b.focus_neighbor_bottom = b.get_path_to(b_rest2 if c == 2 else b_rest1)
			b.focus_next = b.get_path_to(b_rest1) if r + 1 == filas and c == 2 else b.get_path_to(botones[accion][COLUMNAS[c + 1]] if c + 1 < COLUMNAS.size() else botones[Controles.ACCIONES[r + 1]][COLUMNAS[0]])
			b.focus_previous = b.get_path_to(tab) if r == 0 and c == 0 else b.get_path_to(botones[accion][COLUMNAS[c - 1]] if c > 0 else botones[Controles.ACCIONES[r - 1]][COLUMNAS[2]])
	var abajo: String = Controles.ACCIONES[filas - 1]
	b_rest1.focus_neighbor_top = b_rest1.get_path_to(botones[abajo]["teclado1"])
	b_rest2.focus_neighbor_top = b_rest2.get_path_to(botones[abajo]["mando0"])
	b_rest1.focus_neighbor_left = b_rest1.get_path_to(b_rest1)
	b_rest1.focus_neighbor_right = b_rest1.get_path_to(b_rest2)
	b_rest2.focus_neighbor_left = b_rest2.get_path_to(b_rest1)
	b_rest2.focus_neighbor_right = b_rest2.get_path_to(b_rest2)
	b_rest1.focus_neighbor_bottom = b_rest1.get_path_to(b_volver)
	b_rest2.focus_neighbor_bottom = b_rest2.get_path_to(b_volver)
	b_rest1.focus_next = b_rest1.get_path_to(b_rest2)
	b_rest1.focus_previous = b_rest1.get_path_to(botones[abajo]["mando0"])
	b_rest2.focus_next = b_rest2.get_path_to(b_volver)
	b_rest2.focus_previous = b_rest2.get_path_to(b_rest1)


func ocupado() -> bool:
	return not capturando.is_empty() or panel_conflicto != null


func _refrescar() -> void:
	for accion in botones:
		for clave in botones[accion]:
			var grupo: String = clave.substr(0, clave.length() - 1)
			var ranura := int(clave.substr(clave.length() - 1))
			botones[accion][clave].text = Controles.nombre(Controles.a.obtener(accion, grupo, ranura))


func _accion_con_foco() -> Dictionary:
	var f := get_viewport().gui_get_focus_owner()
	for accion in botones:
		for clave in botones[accion]:
			if botones[accion][clave] == f:
				return {"accion": accion, "grupo": clave.substr(0, clave.length() - 1), "ranura": int(clave.substr(clave.length() - 1))}
	return {}


func _empezar_captura(accion: String, grupo: String, ranura: int) -> void:
	capturando = {"accion": accion, "grupo": grupo, "ranura": ranura}
	var txt := "Pulsa una tecla o botón del mouse" if grupo == "teclado" else "Pulsa un botón del mando"
	_mensaje("%s para %s. Esc cancela." % [txt, Controles.NOMBRES[accion]], UI.C_ORO)
	botones[accion][grupo + str(ranura)].text = "..."
	b_cancelar.visible = true
	b_rest2.visible = false
	ignorar_hasta = Engine.get_process_frames() + 8


## Clic derecho en una tecla de la tabla: borrarla, igual que Supr.
func _celda_input(ev: InputEvent, accion: String, grupo: String, ranura: int) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT and not ocupado():
		get_viewport().set_input_as_handled()
		botones[accion][grupo + str(ranura)].grab_focus()
		_borrar(accion, grupo, ranura)


func _borrar(accion: String, grupo: String, ranura: int) -> void:
	if Controles.a.borrar(accion, grupo, ranura):
		Sonido.tocar("ui_ok")
		_guardar()
	else:
		Sonido.tocar("ui_no")
		_mensaje("%s no puede quedar sin ninguna tecla." % Controles.NOMBRES[accion], UI.C_ROJO)


func _input(ev: InputEvent) -> void:
	if panel_conflicto != null:
		return
	if capturando.is_empty():
		if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_DELETE:
			var f := _accion_con_foco()
			if not f.is_empty():
				_borrar(f.accion, f.grupo, f.ranura)
				get_viewport().set_input_as_handled()
		return
	if ev is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	if Engine.get_process_frames() < ignorar_hasta:
		return
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_cancelar_captura()
		return
	if ev is InputEventMouseButton and ev.pressed and b_cancelar.get_global_rect().has_point(ev.position):
		_cancelar_captura()
		return
	var grupo: String = capturando.grupo
	var tecla := Controles.de_evento(ev)
	if tecla == "" or not Asignaciones.es_valida(tecla, grupo):
		return
	var r := Controles.a.asignar(capturando.accion, grupo, capturando.ranura, tecla)
	if r.has("conflicto"):
		_mostrar_conflicto(tecla, r.conflicto)
		return
	Sonido.tocar("ui_ok")
	_terminar_captura()
	_guardar()


func _cancelar_captura() -> void:
	Sonido.tocar("ui_no")
	_terminar_captura()
	_refrescar()


func _terminar_captura() -> void:
	capturando = {}
	b_cancelar.visible = false
	b_rest2.visible = true
	_mensaje(AYUDA, UI.C_GRIS)


func _mensaje(t: String, c: Color) -> void:
	aviso.text = t
	aviso.add_theme_color_override("font_color", c)


func _mostrar_conflicto(tecla: String, otro: Dictionary) -> void:
	var cap := capturando.duplicate()
	_terminar_captura()
	var cerrar := func():
		panel_conflicto = null
		_refrescar()
	var resolver := func(modo: String):
		panel_conflicto = null
		var r := Controles.a.asignar(cap.accion, cap.grupo, cap.ranura, tecla, modo)
		_refrescar()
		if r.has("error"):
			Sonido.tocar("ui_no")
			_mensaje("%s quedaría sin teclas. Usa Intercambiar." % Controles.NOMBRES[r.accion], UI.C_ROJO)
		else:
			_guardar()
	var txt := "Si la intercambias, %s queda con la tecla que tenía %s." % [Controles.NOMBRES[otro.accion], Controles.NOMBRES[cap.accion]]
	panel_conflicto = MODAL.abrir(self, "%s ya está en %s" % [Controles.nombre(tecla), Controles.NOMBRES[otro.accion]], txt,
		[["Cancelar", cerrar], ["Intercambiar", resolver.bind("intercambiar")], ["Quitar de allá", resolver.bind("quitar")]], UI.C_ORO, 1)


func _guardar() -> void:
	Controles.aplicar()
	Controles.guardar()
	_refrescar()


func _restaurar_actual() -> void:
	if ultima_celda.is_empty():
		_mensaje("Primero elige una tecla de la tabla.", UI.C_GRIS)
		return
	Controles.restaurar(ultima_celda.accion)
	_refrescar()
	_mensaje("%s volvió a sus teclas de fábrica." % Controles.NOMBRES[ultima_celda.accion], UI.C_VERDE)


func _restaurar_todas() -> void:
	Controles.restaurar_todo()
	_refrescar()
	_mensaje("Todas las teclas volvieron a las de fábrica.", UI.C_VERDE)
