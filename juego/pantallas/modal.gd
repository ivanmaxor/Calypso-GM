extends Control
## Una pregunta o un aviso encima de cualquier pantalla. Se come la entrada y el foco no se escapa.
## El primer botón siempre es la salida segura: a ese lleva Esc.

var titulo := ""
var texto := ""
var opciones: Array = []  # [["Texto", Callable], ...]
var foco_inicial := 0
var color := UI.C_ORO
var controles: Array[Button] = []
var foco_previo: Control = null
var cerrado := false
var lineas := PackedStringArray()
var caja := Rect2()


## opciones: [["No", callable], ["Sí", callable]]. Un Callable vacío solo cierra.
static func abrir(padre: Node, titulo_: String, texto_: String, opciones_: Array, color_ := UI.C_ORO, foco_ := 0) -> Control:
	var m = load("res://pantallas/modal.gd").new()
	m.titulo = titulo_
	m.texto = texto_
	m.opciones = opciones_
	m.color = color_
	m.foco_inicial = foco_
	padre.add_child(m)
	return m


func _ready() -> void:
	foco_previo = get_viewport().gui_get_focus_owner()
	# encima de todo, sea cual sea el orden de lo que hay detrás: ni se ve ni se puede clicar
	top_level = true
	global_position = Vector2.ZERO
	size = Vector2(640, 360)
	theme = UI.tema()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var n: int = opciones.size()
	var an_boton := 110.0
	for o in opciones:
		an_boton = maxf(an_boton, UI.ancho(o[0]) + 16.0)
	var an: float = maxf(400.0, n * (an_boton + 8.0) + 16.0)
	lineas = UI.partir(texto, an - 28.0)
	var alto: float = 34.0 + lineas.size() * UI.ALTO_LINEA + 42.0
	caja = Rect2(round(320.0 - an / 2.0), round(180.0 - alto / 2.0), an, alto)
	var x0: float = 320.0 - (n * an_boton + (n - 1) * 8.0) / 2.0
	for i in n:
		var b := UI.boton(opciones[i][0], Vector2(x0 + i * (an_boton + 8.0), caja.end.y - 34.0), Vector2(an_boton, 26), self, _elegir.bind(i))
		controles.append(b)
	UI.lista_foco(controles, false)
	controles[foco_inicial].grab_focus()


func _elegir(i: int) -> void:
	if cerrado:
		return
	cerrado = true
	hide()
	# el foco vuelve a donde estaba, salvo que la respuesta lo mueva a otra parte
	if is_instance_valid(foco_previo) and foco_previo.is_inside_tree():
		foco_previo.grab_focus()
	var cb = opciones[i][1]
	queue_free()
	if cb is Callable and cb.is_valid():
		cb.call()


func _unhandled_input(ev: InputEvent) -> void:
	if cerrado:
		return
	if ev is InputEventKey or ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
	if ev.is_action_pressed("ui_cancel"):
		Sonido.tocar("ui_no")
		_elegir(0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.05, 0.75))
	UI.marco(self, caja, UI.C_FONDO, color)
	var x: float = caja.get_center().x
	UI.tc(self, x, caja.position.y + 6, titulo, color)
	var y: float = caja.position.y + 26
	for l in lineas:
		UI.tc(self, x, y, l)
		y += UI.ALTO_LINEA
