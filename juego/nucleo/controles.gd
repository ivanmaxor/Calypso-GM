extends Node
## Une las reglas de Asignaciones con el InputMap del motor.
## Los menus usan las acciones ui_* del motor, que nunca se cambian: nadie queda sin salida.
## El motor las trae solo con flechas, pero aquí el juego se mueve con WASD: esa es la mano que el
## jugador tiene puesta en el teclado. Por eso los menús aceptan las dos cosas (ver _teclas_de_menu).

const ARCHIVO := "user://controles.cfg"
const ACCIONES := ["mover_arriba", "mover_abajo", "mover_izquierda", "mover_derecha", "disparar", "foco", "esquivar", "desync", "pausa"]
const NOMBRES := {
	"mover_arriba": "Arriba", "mover_abajo": "Abajo", "mover_izquierda": "Izquierda", "mover_derecha": "Derecha",
	"disparar": "Disparar", "foco": "Foco (ir lento)", "esquivar": "Esquivar", "desync": "Desync", "pausa": "Pausa",
}
const NOMBRES_BOTON := {0: "A", 1: "B", 2: "X", 3: "Y", 4: "SELECT", 6: "START", 7: "L3", 8: "R3", 9: "LB", 10: "RB", 11: "ARRIBA", 12: "ABAJO", 13: "IZQ", 14: "DER"}
const NOMBRES_MOUSE := {1: "CLIC IZQ", 2: "CLIC DER", 3: "CLIC RUEDA", 8: "MOUSE 4", 9: "MOUSE 5"}

## Se suman a lo que trae el motor, nunca lo reemplazan. No molestan al escribir: lo que escribes en un
## LineEdit se lo queda él antes de que el menú se entere, y la captura de teclas se come todo en _input.
const TECLAS_MENU := {
	"ui_up": [KEY_W, KEY_UP], "ui_down": [KEY_S, KEY_DOWN], "ui_left": [KEY_A, KEY_LEFT], "ui_right": [KEY_D, KEY_RIGHT],
	"ui_accept": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], "ui_cancel": [KEY_ESCAPE],
}

var DEFECTO := {
	"mover_arriba": {"teclado": ["key:W", "key:Up"], "mando": ["axis:1:-1", "btn:11"]},
	"mover_abajo": {"teclado": ["key:S", "key:Down"], "mando": ["axis:1:1", "btn:12"]},
	"mover_izquierda": {"teclado": ["key:A", "key:Left"], "mando": ["axis:0:-1", "btn:13"]},
	"mover_derecha": {"teclado": ["key:D", "key:Right"], "mando": ["axis:0:1", "btn:14"]},
	"disparar": {"teclado": ["key:J", "key:Z"], "mando": ["axis:5:1", ""]},
	"foco": {"teclado": ["key:Shift", "key:K"], "mando": ["axis:4:1", "btn:9"]},
	"esquivar": {"teclado": ["key:Space", "key:L"], "mando": ["btn:0", "btn:10"]},
	"desync": {"teclado": ["key:X", "mouse:2"], "mando": ["btn:3", "btn:2"]},
	"pausa": {"teclado": ["key:Escape", "key:P"], "mando": ["btn:6", ""]},
}

var a: Asignaciones
var ultimo_mando := false


func _ready() -> void:
	_teclas_de_menu()
	a = Asignaciones.new(DEFECTO)
	for accion in ACCIONES:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion, 0.3)
	cargar()
	aplicar()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _teclas_de_menu() -> void:
	for accion in TECLAS_MENU:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		for k in TECLAS_MENU[accion]:
			var ev := InputEventKey.new()
			ev.keycode = k
			if not InputMap.action_has_event(accion, ev):
				InputMap.action_add_event(accion, ev)
	# el motor tampoco trae los botones del mando para aceptar y volver
	for par in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var bo := InputEventJoypadButton.new()
		bo.button_index = par[1]
		if not InputMap.action_has_event(par[0], bo):
			InputMap.action_add_event(par[0], bo)


func aplicar() -> void:
	for accion in ACCIONES:
		InputMap.action_erase_events(accion)
		for grupo in Asignaciones.GRUPOS:
			for r in Asignaciones.RANURAS:
				var ev := a_evento(a.obtener(accion, grupo, r))
				if ev:
					InputMap.action_add_event(accion, ev)


func guardar() -> void:
	var c := ConfigFile.new()
	c.set_value("version", "numero", 1)
	var d := a.exportar()
	for clave in d:
		c.set_value("teclas", clave, d[clave])
	c.save(_ruta())


func cargar() -> void:
	var c := ConfigFile.new()
	if c.load(_ruta()) != OK:
		return
	var d := {}
	if c.has_section("teclas"):
		for clave in c.get_section_keys("teclas"):
			d[clave] = c.get_value("teclas", clave)
	a.cargar_desde(d, DEFECTO)


func restaurar_todo() -> void:
	a = Asignaciones.new(DEFECTO)
	aplicar()
	guardar()


func restaurar(accion: String) -> void:
	a.mapa[accion] = DEFECTO[accion].duplicate(true)
	a._limpiar_duplicados(DEFECTO)
	aplicar()
	guardar()


## Lo que se muestra en pantalla: la primera tecla de la accion, segun el dispositivo en uso.
func texto(accion: String) -> String:
	var grupo := "mando" if ultimo_mando else "teclado"
	for r in Asignaciones.RANURAS:
		var t := a.obtener(accion, grupo, r)
		if t != "":
			return nombre(t)
	return "?"


func _input(ev: InputEvent) -> void:
	if ev is InputEventJoypadButton or (ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.5):
		ultimo_mando = true
	elif ev is InputEventKey or ev is InputEventMouseButton:
		ultimo_mando = false


static func a_evento(t: String) -> InputEvent:
	if t == "":
		return null
	var p := t.split(":")
	match p[0]:
		"key":
			var e := InputEventKey.new()
			e.keycode = OS.find_keycode_from_string(p[1])
			return e
		"mouse":
			var e := InputEventMouseButton.new()
			e.button_index = int(p[1]) as MouseButton
			return e
		"btn":
			var e := InputEventJoypadButton.new()
			e.button_index = int(p[1]) as JoyButton
			return e
		"axis":
			var e := InputEventJoypadMotion.new()
			e.axis = int(p[1]) as JoyAxis
			e.axis_value = float(p[2])
			return e
	return null


## "" si el evento no sirve para asignar.
static func de_evento(ev: InputEvent) -> String:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = ev.keycode
		if k == KEY_NONE:
			k = ev.physical_keycode
		return "key:" + OS.get_keycode_string(k)
	if ev is InputEventMouseButton and ev.pressed:
		return "mouse:%d" % ev.button_index
	if ev is InputEventJoypadButton and ev.pressed:
		return "btn:%d" % ev.button_index
	if ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.6:
		return "axis:%d:%d" % [ev.axis, 1 if ev.axis_value > 0 else -1]
	return ""


static func nombre(t: String) -> String:
	if t == "":
		return "---"
	var p := t.split(":")
	match p[0]:
		"key":
			var traduce := {"Space": "ESPACIO", "Shift": "SHIFT", "Ctrl": "CTRL", "Alt": "ALT", "Escape": "ESC", "Tab": "TAB", "Enter": "ENTER",
				"Up": "FLECHA ARRIBA", "Down": "FLECHA ABAJO", "Left": "FLECHA IZQ", "Right": "FLECHA DER", "BackSpace": "BORRAR", "Backspace": "BORRAR"}
			return traduce.get(p[1], p[1].to_upper())
		"mouse":
			return NOMBRES_MOUSE.get(int(p[1]), "MOUSE " + p[1])
		"btn":
			return NOMBRES_BOTON.get(int(p[1]), "BOTÓN " + p[1])
		"axis":
			var eje := int(p[1])
			if eje == 4:
				return "LT"
			if eje == 5:
				return "RT"
			var lado := "+" if int(p[2]) > 0 else "-"
			return ("STICK X" if eje == 0 else "STICK Y" if eje == 1 else "STICK2 X" if eje == 2 else "STICK2 Y") + lado
	return t


func _ruta() -> String:
	if "--pruebas" in OS.get_cmdline_user_args():
		# cada copia de prueba con el suyo: si no, una prueba le cambia las teclas a la otra
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--guardado="):
				return "user://%s_controles.cfg" % arg.get_slice("=", 1)
		return "user://pruebas_controles.cfg"
	return ARCHIVO
