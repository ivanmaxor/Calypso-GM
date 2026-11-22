extends Control
## Don Tuerca y Calypso hablan. Clic, Enter o Espacio avanza, Esc se salta todo.

signal terminado

const VEL := 0.9  # letras por cuadro
const R_SALTAR := Rect2(140, 334, 190, 18)  # donde dice "saltar todo": para quien solo usa el mouse

var lineas: Array = []
var i := 0
var quien := "tuerca"
var partes := PackedStringArray()
var total := 0
var visibles := 0.0
var t := 0
var ultimo_blip := 0
var cerrado := false


## Muestra un dialogo una sola vez. Si no existe o ya se vio, sigue de inmediato.
static func mostrar(padre: Node, clave: String, luego: Callable) -> void:
	if not Datos.DIALOGOS.has(clave) or Partida.visto(clave):
		luego.call()
		return
	var d = load("res://pantallas/dialogo.gd").new()
	d.lineas = Datos.DIALOGOS[clave]
	d.terminado.connect(func():
		Partida.marcar_visto(clave)
		luego.call())
	padre.add_child(d)


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 360)
	theme = UI.tema()
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_poner(0)


func _poner(n: int) -> void:
	i = n
	quien = lineas[n][0]
	var txt: String = Datos.con_teclas(lineas[n][1])
	partes = UI.partir(txt, 470.0)
	total = 0
	for p in partes:
		total += p.length()
	visibles = 0.0
	ultimo_blip = 0


var _t_acum := 0.0


func _process(d: float) -> void:
	_t_acum += d * 60.0
	t = int(_t_acum)
	if visibles < total:
		visibles = minf(visibles + VEL * d * 60.0, total)
		# Sonido.voz se limita sola por tiempo real: aquí solo se le avisa que siguen saliendo letras
		if int(visibles) - ultimo_blip >= 2:
			ultimo_blip = int(visibles)
			Sonido.voz(quien)
	queue_redraw()


## Se comen las teclas: lo que esta detras no debe enterarse.
func _input(ev: InputEvent) -> void:
	if cerrado or ev is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	if t < 8:
		return
	if ev.is_action_pressed("ui_cancel"):
		_cerrar()
	elif ev.is_action_pressed("ui_accept") or ev.is_action_pressed("disparar"):
		avanzar()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if R_SALTAR.has_point(ev.position):
			_cerrar()
		else:
			avanzar()


func avanzar() -> void:
	if visibles < total:
		visibles = total
		return
	if i + 1 < lineas.size():
		Sonido.tocar("ui_mover")
		_poner(i + 1)
	else:
		Sonido.tocar("ui_ok")
		_cerrar()


func _cerrar() -> void:
	if cerrado:
		return
	cerrado = true
	terminado.emit()
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.05, 0.55))
	var escribiendo := visibles < total
	var boca := escribiendo and (t / 5) % 2 == 0
	var col_nombre := UI.C_ORO
	var nombre := "DON TUERCA"
	if quien == "tuerca":
		var exclama: bool = "!" in lineas[i][1]
		var f := 0
		if boca:
			f = 2 if exclama else 1
		elif not escribiendo and exclama and (t / 40) % 3 == 0:
			f = 3
		var salto := 2 if boca and exclama else 0
		draw_texture_rect_region(Datos.tex("retrato_tuerca"), Rect2(4, 222 - salto, 128, 128), Rect2(f * 128, 0, 128, 128))
	else:
		col_nombre = UI.C_CIAN
		nombre = "CALYPSO"
		var f := 1 if boca else 0
		draw_texture_rect_region(Datos.tex("retrato_calypso"), Rect2(20, 254, 96, 96), Rect2(f * 96, 0, 96, 96))
	var caja := Rect2(136, 262, 496, 90)
	UI.marco(self, caja, UI.C_PANEL, col_nombre)
	draw_rect(Rect2(caja.position.x, caja.position.y - 16, UI.ancho(nombre) + 14, 16), col_nombre.darkened(0.6))
	draw_rect(Rect2(caja.position.x, caja.position.y - 16, UI.ancho(nombre) + 14, 16), col_nombre, false, 1.0)
	UI.t(self, caja.position.x + 7, caja.position.y - 17, nombre, Color.WHITE)
	var y := caja.position.y + 5
	var quedan := int(visibles)
	for p in partes:
		if quedan <= 0:
			break
		UI.t(self, caja.position.x + 10, y, p.substr(0, quedan), UI.C_TEXTO)
		quedan -= p.length()
		y += UI.ALTO_LINEA
	var con_mando: bool = Controles.ultimo_mando
	if not escribiendo:
		var que := "seguir" if i + 1 < lineas.size() else "cerrar"
		var txt: String = ("A: " if con_mando else "Enter o clic: ") + que
		var col := UI.C_ORO if (t / 20) % 2 == 0 else UI.C_GRIS
		UI.t(self, caja.end.x - UI.ancho(txt) - 8, caja.end.y - 16, txt, col)
	UI.t(self, caja.position.x + 10, caja.end.y - 16, "B: saltar todo" if con_mando else "Esc o clic aquí: saltar todo", UI.C_GRIS)
