extends Node
## Lo común a todas las pruebas: el estado compartido y las herramientas para apretar teclas, hacer clic,
## esperar cuadros, sacar fotos y anotar lo que pasa o falla. Lo heredan los demás módulos de pruebas.

var activo := false


var args := {}


var principal: Node


var cuadro := 0


var capturas := {}


var carpeta := ""


var salir := -1


var bot := false


var torpe := false


var reaccion := 4


var ruido := 0.0


var dir_actual := Vector2.ZERO


var bot_espera := 0


var dash_pendiente := false


var ultimo_log := 0


var estres := 0


var tiempos := []


var peor := 0.0


var veces := 0


var repetir := 1


var ganadas := 0


var intentos := {}


var suma := {}


const ACCIONES := ["mover_arriba", "mover_abajo", "mover_izquierda", "mover_derecha"]


## Parte de cero de verdad: solo toca los archivos de esta prueba, nunca los del jugador.
## Las opciones y las teclas también: Ajustes y Controles ya las cargaron, así que se vuelven a las de fábrica.
func _limpiar_guardados() -> void:
	var nombres: Array = [Partida.prueba + ".json", Partida.prueba + "_global.json", Partida.prueba + "_v2.json", Partida.prueba + "_importar.json"]
	nombres.append(Partida.prueba + "_ajustes.cfg")
	nombres.append(Partida.prueba + "_controles.cfg")
	for i in range(1, Partida.NUM_SLOTS + 1):
		nombres.append("%s_%d.json" % [Partida.prueba, i])
	for n in nombres:
		var ruta: String = "user://" + n
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	Partida._cargar_global()
	Partida.nuevo()
	Ajustes.restablecer()
	Controles.restablecer()
	Sonido.aplicar_volumen()


func _res_demo(tipo := "") -> Dictionary:
	var r := {"ganado": true, "kills": 182, "jefes": 0, "jefe": false, "tiempo": 96, "nivel": 11, "max_cadena": 44, "desyncs": 3, "aces": 1, "roces": 80, "nams": 12, "golpes": 2, "chatarra": 64, "evoluciones": 0, "nivel_id": Partida.nivel_sel, "abandono": false, "modo": "normal", "kills_tipo": {}, "esquivas": 0, "cambios": 0, "giros": 0, "jackpots": 0, "nave": Partida.nave_actual(), "hp": 40, "hp_max": 70, "build": ""}
	match tipo if tipo != "" else args.get("res", "ganado"):
		"derrota":
			r.ganado = false
			r.tiempo = 73
		"retiro":
			r.ganado = false
			r.abandono = true
			r.tiempo = 73
		"retiro_rapido":
			r.ganado = false
			r.abandono = true
			r.tiempo = 4
			r.kills = 2
		"infinito":
			r.ganado = false
			r.modo = "infinito"
			r.nivel_id = "1-INF"
			r.tiempo = 214
			r.kills = 612
		"ruleta":
			r.modo = "ruleta"
			r.nivel_id = "1-R"
			r.giros = 2
			r.jackpots = 1
	return r


func _premio_demo() -> Dictionary:
	if args.has("premio"):
		for de in Datos.DESAFIOS:
			if de.id == args.premio:
				return Partida._premio_desafio(de)
	var id: String = args.get("nivel", "1-3")
	return Partida._aplicar_premio(Datos.NIVELES[id].premio.duplicate(), id)


func _preparar_combate(c) -> void:
	if args.has("armas"):
		for id in args.armas.split(","):
			var a = c.arsenal.buscar(id)
			if a == null:
				a = c.arsenal.agregar(id)
			if args.has("evo"):
				while a.nivel < Datos.NIVEL_MAX_CARTA:
					c.arsenal.subir(a)
				c.arsenal.evolucionar(a)
	if args.has("habs"):
		for id in args.habs.split(","):
			c.habs[id] = 1
			var h: Dictionary = Datos.HABILIDADES[id]
			if h.has("mods"):
				Partida._sumar(c.stats, h.mods)
			if h.get("especial", "") == "escudo":
				c.escudo = true
	if args.has("cartas"):
		c.niveles_pendientes = 1
	if args.has("barra"):
		c.barra = float(args.barra)
	if args.has("ruleta"):
		c.ruleta_forzada = Array(args.ruleta.split(","))
	# --hitbox=tenue|cercana|foco: cómo se ve la hitbox jugando normal (#58)
	if args.has("hitbox"):
		if args.hitbox in c.ESTILOS_HITBOX:
			c.estilo_hitbox = args.hitbox
		else:
			push_error("--hitbox=%s no existe; usa %s" % [args.hitbox, ", ".join(c.ESTILOS_HITBOX)])
	# --pausa: abre el menú de pausa al partir, para capturarlo
	if args.has("pausa"):
		c.abrir_pausa.call_deferred()


func _marcar_vistos() -> void:
	for k in Datos.DIALOGOS:
		if not k in Partida.d.vistos:
			Partida.d.vistos.append(k)


## Deja la partida como si ya hubieras jugado hasta ese nivel (solo para probar).
func _avanzar_hasta(id: String) -> void:
	for n in Datos.ORDEN_NIVELES:
		if n == id:
			break
		Partida.completar_nivel(n, {"golpes": 2, "max_cadena": 999 if randf() < 0.5 else 0})
	_marcar_vistos()


func _capturar(n: int) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(carpeta)
	img.save_png("%s/c_%05d.png" % [carpeta, n])
	print("[captura] ", n)


# --- recorrido por los menus con entradas reales ---------------------------------------------
var paso := 0


var espera_f := 0


var f_ok := 0


var f_mal := 0


var f_guardado := 0


var f_txt := ""


var f_ctrl = null


var f_en_curso := false  # una etapa escrita de corrido, con esperas adentro


func _pulsar(accion: String) -> void:
	var ev := InputEventAction.new()
	ev.action = accion
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventAction.new()
	ev2.action = accion
	ev2.pressed = false
	Input.parse_input_event.call_deferred(ev2)


func _tecla(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventKey.new()
	ev2.keycode = k
	ev2.physical_keycode = k
	ev2.pressed = false
	Input.parse_input_event.call_deferred(ev2)


func _check(c: bool, n: String) -> void:
	if c:
		f_ok += 1
		if args.has("verboso"):
			print("  ok: ", n)
	else:
		f_mal += 1
		print("  FALLA: ", n)


func _foco() -> Control:
	return get_viewport().gui_get_focus_owner()


func _foto(nombre := "") -> void:
	if carpeta == "":
		return
	if nombre == "":
		_capturar(cuadro)
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(carpeta)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [carpeta, nombre])


func _hijo_de_tipo(n: Node, ruta: String) -> Node:
	for h in n.get_children():
		if h.get_script() and h.get_script().resource_path == ruta:
			return h
	return null


# --- etapas escritas de corrido: cada una usa teclas reales, y las dos manos: WASD y flechas ----
const NOMBRE_TECLA := {KEY_W: "W", KEY_A: "A", KEY_S: "S", KEY_D: "D", KEY_UP: "Arriba", KEY_DOWN: "Abajo", KEY_LEFT: "Izquierda", KEY_RIGHT: "Derecha",
	KEY_ENTER: "Enter", KEY_SPACE: "Espacio", KEY_ESCAPE: "Esc", KEY_Q: "Q", KEY_E: "E", KEY_DELETE: "Supr"}


const P_OPCIONES := "res://pantallas/opciones.gd"


const P_SLOTS := "res://pantallas/slots.gd"


const P_DIFICULTAD := "res://pantallas/elegir_dificultad.gd"


const P_MODAL := "res://pantallas/modal.gd"


const P_DIALOGO := "res://pantallas/dialogo.gd"


const P_PANEL := "res://pantallas/panel_nivel.gd"


const P_PREMIO := "res://pantallas/premio.gd"


const P_NUEVA_PLUS := "res://pantallas/nueva_plus.gd"


func _cuadros(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Una tecla real, y unos cuadros para que haga efecto.
func _t(k: Key, espera := 6) -> void:
	_tecla(k)
	await _cuadros(espera)


## Lo que manda el teclado cuando una tecla se queda apretada.
func _eco(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	ev.echo = true
	Input.parse_input_event(ev)
	await _cuadros(8)


func _nt(k: Key) -> String:
	return NOMBRE_TECLA.get(k, str(k))


## Aprieta las teclas de "pares" [tecla, control esperado] y revisa que el foco quede ahí.
func _ruta_foco(pares: Array, que: String) -> void:
	for par in pares:
		await _t(par[0])
		_check(_foco() == par[1], "%s: %s lleva el foco a donde debe" % [que, _nt(par[0])])


## Clic real en el centro de un control.
func _clic(c: Control, boton := MOUSE_BUTTON_LEFT) -> void:
	await _clic_en(c.get_global_rect().get_center(), boton)


## Todo con el mouse, sin tocar el teclado: en coordenadas de la pantalla de 640x360.
func _clic_en(pos: Vector2, boton := MOUSE_BUTTON_LEFT) -> void:
	_mover_mouse(pos)
	await _cuadros(2)
	var ev := InputEventMouseButton.new()
	ev.position = _raton(pos)
	ev.global_position = ev.position
	ev.button_index = boton
	ev.pressed = true
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if boton == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
	Input.parse_input_event(ev)
	await _cuadros(2)
	var ev2 := InputEventMouseButton.new()
	ev2.position = ev.position
	ev2.global_position = ev.position
	ev2.button_index = boton
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _cuadros(6)


func _mover_mouse(pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _raton(pos)
	ev.global_position = ev.position
	Input.parse_input_event(ev)


func _esperar(cuadros: int) -> void:
	for i in cuadros:
		await get_tree().physics_frame


## Aprieta una tecla de verdad y espera a que haga efecto.
func _apretar(k: Key, cuadros := 5) -> void:
	_tecla(k)
	await _esperar(cuadros)


## Una letra para escribir en un LineEdit: necesita su carácter.
func _letra(k: Key, c: String) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.unicode = c.unicode_at(0)
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2: InputEventKey = ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event.call_deferred(ev2)
	await _esperar(3)


## Pasa un punto de la pantalla lógica de 640x360 a coordenadas de la ventana, que es lo que traen los
## eventos del mouse. Usa la transformación del estiramiento y no el ancho de la ventana: sin ventana
## (--headless) la ventana mide 64x64 y el juego queda centrado con franjas, así que multiplicar por el
## ancho mandaba los clics a otro lado.
func _raton(p: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * p


func _raton_mover(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _raton(p)
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	await _esperar(4)


func _raton_clic(p: Vector2) -> void:
	await _raton_mover(p)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = _raton(p)
	ev.global_position = ev.position
	ev.pressed = true
	Input.parse_input_event(ev)
	await _esperar(2)
	var ev2: InputEventMouseButton = ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _esperar(5)


func _raton_rueda(p: Vector2) -> void:
	await _raton_mover(p)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_WHEEL_DOWN
	ev.position = _raton(p)
	ev.global_position = ev.position
	ev.factor = 1.0
	ev.pressed = true
	Input.parse_input_event(ev)
	await _esperar(2)
	var ev2: InputEventMouseButton = ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _esperar(6)


func _foto_h(nombre: String) -> void:
	if carpeta == "":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(carpeta)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [carpeta, nombre])


## El centro de un control, en la pantalla lógica.
func _centro(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


## Lo definitivo lo hace UI_A en controles.gd. Aquí se garantiza para poder probar WASD en esta copia.
func _asegurar_wasd() -> void:
	for par in [["ui_up", KEY_W], ["ui_down", KEY_S], ["ui_left", KEY_A], ["ui_right", KEY_D], ["ui_accept", KEY_SPACE]]:
		var ev := InputEventKey.new()
		ev.keycode = par[1]
		if not InputMap.action_has_event(par[0], ev):
			InputMap.action_add_event(par[0], ev)


# --- pruebas automaticas de reglas ------------------------------------------------------------
var fallos := 0


var pasadas := 0


func _ok(cond: bool, nombre: String) -> void:
	if cond:
		pasadas += 1
	else:
		fallos += 1
		print("  FALLA: ", nombre)


func _existe(n: String) -> bool:
	return ResourceLoader.exists("res://arte/sprites/%s.png" % n)
