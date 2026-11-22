extends Control
## Menú de pausa dentro de una partida.

var combate: Node
var botones: Array[Button] = []
var aviso_salir := ""


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 360)
	theme = UI.tema()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.02, 0.07, 0.8)
	fondo.size = size
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var y := 112
	var es_infinito: bool = Datos.NIVELES[Partida.nivel_sel].get("modo", "") == "infinito"
	var b1 := UI.boton("Continuar", Vector2(230, y), Vector2(180, 22), self, _continuar)
	var b2 := UI.boton("Opciones", Vector2(230, y + 26), Vector2(180, 22), self, _opciones)
	var b3 := UI.boton("Reiniciar el nivel", Vector2(230, y + 52), Vector2(180, 22), self, _reiniciar)
	var b4 := UI.boton("Terminar aquí" if es_infinito else "Retirarse al mapa", Vector2(230, y + 78), Vector2(180, 22), self, _salir)
	botones = [b1, b2, b3, b4]
	UI.lista_foco(botones)
	aviso_salir = "Si terminas aquí, solo te llevas la mitad de la chatarra." if es_infinito else "Si te retiras no hay piezas, y solo la mitad de la chatarra."
	b1.grab_focus()
	UI.pie(self, "Flechas o WASD: moverse  ·  Enter o Espacio: elegir  ·  Esc: seguir jugando", "Cruceta: moverse  ·  A: elegir  ·  B: seguir jugando")
	# se dibuja encima del fondo oscuro
	var capa := Control.new()
	capa.size = size
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.draw.connect(_dibujar_textos.bind(capa))
	add_child(capa)


func _dibujar_textos(c: Control) -> void:
	UI.tc(c, 320, 76, "PAUSA", UI.C_ORO, 2, true)
	if aviso_salir != "":
		UI.tc(c, 320, 216, aviso_salir, UI.C_GRIS)


func _unhandled_input(ev: InputEvent) -> void:
	# con las opciones abiertas, las teclas son de ellas
	if has_node("Opciones"):
		return
	# la misma tecla de pausa cierra el menu
	if ev.is_action_pressed("pausa") or ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_continuar()


func _continuar() -> void:
	combate.cerrar_pausa()
	queue_free()


func _opciones() -> void:
	var o := preload("res://pantallas/opciones.gd").new()
	o.name = "Opciones"
	o.al_cerrar = func(): botones[1].grab_focus()
	add_child(o)


func _salir() -> void:
	queue_free()
	combate.abandonar()


func _reiniciar() -> void:
	queue_free()
	combate.volver_a_empezar()
