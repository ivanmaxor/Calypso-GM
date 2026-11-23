extends Control
## Menú de pausa dentro de una partida. A los lados, lo que llevas equipado (M16); al centro, cómo
## vas con las estrellas del nivel (M17), porque el fondo oscuro tapa el HUD.

## Columnas de armas (izquierda) y habilidades (derecha).
const COL_X := [8.0, 424.0]
const COL_ANCHO := 208.0
const COL_Y := 30.0
const COL_FIN := 334.0
const ESTRELLAS_Y := 238.0
const CENTRO_ANCHO := 196.0

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
		var ya := 216.0
		for lin in UI.partir(aviso_salir, CENTRO_ANCHO):
			UI.tc(c, 320, ya, lin, UI.C_GRIS)
			ya += 13
	if combate == null:
		return
	_columna(c, 0, "ARMAS", UI.C_CIAN, entradas("armas"))
	_columna(c, 1, "HABILIDADES", UI.C_VERDE, entradas("habs"))
	var y := ESTRELLAS_Y + 13.0 * maxf(UI.partir(aviso_salir, CENTRO_ANCHO).size() - 1, 0)
	for e in estrellas():
		var lineas := UI.partir(e.txt, CENTRO_ANCHO - 18.0)
		var x0 := 320.0 - CENTRO_ANCHO / 2.0
		if e.has("ok"):
			c.draw_texture(Datos.tex("ui_estrella" if e.ok else "ui_estrella_vacia"), Vector2(x0, y + 2))
			for lin in lineas:
				UI.t(c, x0 + 18, y, lin, UI.C_TEXTO if e.ok else UI.C_GRIS)
				y += 13
		else:
			UI.tc(c, 320, y, e.txt, UI.C_ORO)
			y += 13
		y += 1


func _columna(c: Control, lado: int, titulo: String, col: Color, lista: Array) -> void:
	var x: float = COL_X[lado]
	var y := COL_Y
	# panel opaco: el HUD de abajo no se transparenta entre las letras
	UI.marco(c, Rect2(x - 5, y - 3, COL_ANCHO + 10, COL_FIN - y + 6), UI.C_FONDO, UI.C_LINEA)
	UI.t(c, x, y, titulo, col)
	y += 16
	if lista.is_empty():
		UI.t(c, x, y, "Nada todavía.", UI.C_GRIS)
		return
	for e in lista:
		var r := Rect2(x, y, 34, 34)
		UI.marco(c, r, UI.C_PANEL2, UI.C_ORO if e.evo else UI.C_LINEA)
		c.draw_texture(Datos.tex(e.icono), Vector2(x + 1, y + 1))
		UI.t(c, x + 38, y - 1, e.nombre, UI.C_ORO if e.evo else UI.C_TEXTO)
		var niv: String = e.nivel
		UI.t(c, x + COL_ANCHO - UI.ancho(niv), y - 1, niv, UI.C_ORO)
		var yy := y + 12.0
		for lin in e.desc:
			UI.t(c, x + 38, yy, lin, UI.C_GRIS)
			yy += 13
		y = maxf(yy, y + 34.0) + 6.0


## Lo que llevas: [{icono, nombre, nivel, desc (líneas), evo}]. Las armas evolucionadas muestran su evolución.
func entradas(tipo: String) -> Array:
	var r := []
	var ancho_txt := COL_ANCHO - 38.0
	if tipo == "armas":
		for a in combate.arsenal.armas:
			var d: Dictionary = Datos.ARMAS[a.id]
			var nombre: String = d.evo.nombre if a.evo else d.nombre
			var desc: String = d.evo.desc if a.evo else d.desc
			var niv := "EVO" if a.evo else "Nv %d/%d" % [a.nivel, Datos.NIVEL_MAX_CARTA]
			r.append(_entrada("icono_" + a.id, nombre, niv, desc, a.evo, ancho_txt))
	else:
		for id in combate.habs:
			var h: Dictionary = Datos.HABILIDADES[id]
			var niv := "Nv %d/%d" % [combate.habs[id], Datos.max_hab(id)]
			r.append(_entrada("icono_" + id, h.nombre, niv, h.desc, false, ancho_txt))
	return r


func _entrada(icono: String, nombre: String, niv: String, desc: String, evo: bool, ancho_txt: float) -> Dictionary:
	# el nombre comparte línea con el nivel: si no caben, el nombre se acorta
	var max_nombre := ancho_txt - UI.ancho(niv) - 6.0
	while UI.ancho(nombre) > max_nombre and nombre.length() > 3:
		nombre = nombre.substr(0, nombre.length() - 2).strip_edges() + "."
	return {"icono": icono, "nombre": nombre, "nivel": niv, "desc": UI.partir(desc, ancho_txt), "evo": evo}


## Las estrellas del nivel y cómo vas, como en el panel del mapa. En Infinito y Ruleta no hay.
func estrellas() -> Array:
	var nv: Dictionary = combate.nivel
	if combate.modo_nivel != "normal" or not nv.has("golpes"):
		return []
	var meta_cadena := Partida.meta_cadena(combate.nivel_id)
	return [
		{"txt": "ESTRELLAS DEL NIVEL " + str(combate.nivel_id)},
		{"txt": "Termina el nivel", "ok": false},
		{"txt": "Máximo %d golpes (llevas %d)" % [nv.golpes, combate.golpes], "ok": combate.golpes <= nv.golpes},
		{"txt": "Cadena de %d (mejor: %d)" % [meta_cadena, combate.max_cadena], "ok": combate.max_cadena >= meta_cadena},
	]


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
