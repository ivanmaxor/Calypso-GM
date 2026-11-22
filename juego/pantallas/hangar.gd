extends Control
## El Hangar: primero la habitación (hangar_sala.gd) y, al tocar un objeto, su estación con su barra de
## pestañas y la nave siempre a la izquierda. Esc vuelve a la sala, y Esc en la sala vuelve al mapa.

signal volver

const SALA := preload("res://pantallas/hangar_sala.gd")
const PESTANAS := ["naves", "equipo", "fusionar", "mascota", "arsenal"]
const NOMBRES := {"naves": "NAVES", "equipo": "EQUIPO", "fusionar": "FUSIONAR", "mascota": "MASCOTA", "arsenal": "ARSENAL"}
const REQUIERE := {"fusionar": "fusion", "mascota": "mascota", "arsenal": "tablon"}
const X_TABS := 154.0
const ANCHO_TAB := 95.0
const PASO_TAB := 97.0

var inicial := ""
var pestana := "equipo"
var en_sala := true
var sala
var estacion: Control
var panel: PanelNave
var contenido: Control
var tabs := {}
var actual: Control = null
var galeria: GaleriaNaves = null
var b_volver: Button
var b_usar: Button = null
var bloqueado := false
var velo: ColorRect


func _ready() -> void:
	size = Vector2(640, 360)
	theme = UI.tema()
	_crear_estacion()
	sala = SALA.new()
	sala.h = self
	sala.abrir.connect(abrir)
	sala.salir.connect(func(): volver.emit())
	add_child(sala)
	velo = ColorRect.new()
	velo.color = Color(0.02, 0.01, 0.05, 0.0)
	velo.size = size
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	if inicial != "" and PESTANAS.has(inicial) and esta_abierta(inicial):
		abrir(inicial)
	else:
		# lo que se pide cerrado se muestra en la sala, para ver cómo se abre
		pestana = inicial if PESTANAS.has(inicial) else "naves"
		sala.mostrar.call_deferred(pestana)
	Sonido.musica_menu()


func _crear_estacion() -> void:
	estacion = Control.new()
	estacion.size = size
	estacion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estacion.visible = false
	add_child(estacion)
	var fondo := ColorRect.new()
	fondo.color = UI.C_FONDO
	fondo.size = size
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estacion.add_child(fondo)
	panel = PanelNave.new()
	estacion.add_child(panel)
	var ayuda := Control.new()
	ayuda.size = size
	ayuda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ayuda.draw.connect(_dibujar_ayuda.bind(ayuda))
	estacion.add_child(ayuda)
	b_volver = UI.boton("VOLVER A LA SALA", Vector2(6, 328), Vector2(138, 26), estacion, a_la_sala)
	b_volver.focus_mode = Control.FOCUS_NONE
	var i := 0
	for p in PESTANAS:
		var b := Button.new()
		b.text = NOMBRES[p]
		b.position = Vector2(X_TABS + i * PASO_TAB, 2)
		b.custom_minimum_size = Vector2(ANCHO_TAB, 22)
		b.focus_mode = Control.FOCUS_ALL
		estacion.add_child(b)
		b.size = Vector2(ANCHO_TAB, 22)
		tabs[p] = b
		if not esta_abierta(p):
			b.icon = Datos.tex("ui_candado")
		b.focus_entered.connect(elegir.bind(p))
		b.pressed.connect(_pulsar_tab.bind(p))
		i += 1
	_enlazar_tabs()
	contenido = Control.new()
	contenido.position = Vector2(150, 26)
	contenido.size = Vector2(490, 334)
	contenido.mouse_filter = Control.MOUSE_FILTER_PASS
	estacion.add_child(contenido)


func _enlazar_tabs() -> void:
	for i in PESTANAS.size():
		var b: Button = tabs[PESTANAS[i]]
		b.focus_neighbor_left = b.get_path_to(tabs[PESTANAS[i - 1]] if i > 0 else b)
		b.focus_neighbor_right = b.get_path_to(tabs[PESTANAS[i + 1]] if i + 1 < PESTANAS.size() else b)
		b.focus_neighbor_top = b.get_path_to(b)


func _dibujar_ayuda(c: Control) -> void:
	var y := 256.0
	for lin in ["Flechas/WASD: mover", "Enter: elegir", "Q / E: otra estación", "Esc: volver a la sala"]:
		UI.t(c, 8, y, lin, UI.C_GRIS)
		y += 14


func esta_abierta(p: String) -> bool:
	return not REQUIERE.has(p) or Partida.tiene(REQUIERE[p])


## Cómo se abre una estación cerrada: se busca el nivel que la entrega, para no repetir el dato aquí.
func como_se_abre(p: String) -> String:
	var cosa: String = REQUIERE.get(p, "")
	for id in Datos.ORDEN_NIVELES:
		var pr: Dictionary = Datos.NIVELES[id].premio
		var da: bool = pr.tipo == "tablon" if cosa == "tablon" else pr.tipo == "mascota" and pr.get("id", "mordisco") == "mordisco"
		if da:
			return "Se abre al completar el nivel %s." % id
	return "Se abre más adelante."


# =================================================================================================
# ENTRAR Y SALIR DE UNA ESTACIÓN
# =================================================================================================
func abrir(p: String) -> void:
	en_sala = false
	pestana = p
	sala.visible = false
	sala.set_process(false)
	estacion.visible = true
	_fundir()
	_construir()
	_enfocar_contenido.call_deferred()


func a_la_sala() -> void:
	if en_sala:
		return
	en_sala = true
	if actual:
		contenido.remove_child(actual)
		actual.queue_free()
		actual = null
	galeria = null
	b_usar = null
	estacion.visible = false
	_fundir()
	sala.mostrar(pestana)


func _fundir() -> void:
	velo.color.a = 0.8


func _process(delta: float) -> void:
	if velo and velo.color.a > 0.0:
		velo.color.a = maxf(velo.color.a - delta * 6.0, 0.0)


func elegir(p: String) -> void:
	if p == pestana and actual != null:
		# lo elegido dentro de la estación pudo cambiar: abajo tiene que llegar ahí
		_conectar_contenido()
		return
	Sonido.tocar("ui_mover")
	pestana = p
	_construir()


func _pulsar_tab(p: String) -> void:
	elegir(p)
	_enfocar_contenido()


## Q y E: otra estación, desde donde sea.
func _cambiar(paso: int) -> void:
	Sonido.tocar("ui_mover")
	pestana = PESTANAS[posmod(PESTANAS.find(pestana) + paso, PESTANAS.size())]
	_construir()
	_enfocar_contenido()


func _enfocar_contenido() -> void:
	if en_sala:
		return
	if galeria:
		galeria.enfocar()
	elif actual and actual.has_method("enfocar"):
		actual.enfocar()
	else:
		tabs[pestana].grab_focus()


func _construir() -> void:
	if actual:
		contenido.remove_child(actual)
		actual.queue_free()
		actual = null
	galeria = null
	b_usar = null
	for p in tabs:
		var b: Button = tabs[p]
		var marcada: bool = p == pestana
		var abierta := esta_abierta(p)
		b.add_theme_color_override("font_color", UI.C_ORO if marcada else (UI.C_GRIS if abierta else Color("6a6488")))
		var st := StyleBoxFlat.new()
		st.bg_color = UI.C_PANEL2 if marcada else Color("15112a")
		st.border_color = UI.C_ORO if marcada else (UI.C_LINEA if abierta else Color("2a2448"))
		st.set_border_width_all(1)
		st.content_margin_bottom = 2
		b.add_theme_stylebox_override("normal", st)
	if not esta_abierta(pestana):
		_cerrada(pestana)
	else:
		match pestana:
			"naves":
				_naves()
			"equipo":
				var e := preload("res://pantallas/hangar_equipo.gd").new()
				e.cambio.connect(panel.refrescar)
				actual = e
				contenido.add_child(e)
			"fusionar":
				var f := preload("res://pantallas/hangar_fusion.gd").new()
				f.fusionada.connect(_animar_fusion)
				actual = f
				contenido.add_child(f)
			"mascota":
				var m := preload("res://pantallas/hangar_mascota.gd").new()
				m.cambio.connect(panel.refrescar)
				actual = m
				contenido.add_child(m)
			"arsenal":
				var a := preload("res://pantallas/arsenal.gd").new()
				actual = a
				contenido.add_child(a)
	_conectar_contenido()


## Las pestañas bajan al contenido, y lo de más arriba del contenido sube a la pestaña marcada.
func _conectar_contenido() -> void:
	var tab: Button = tabs[pestana]
	var destino: Control = tab
	if galeria:
		destino = galeria.conectar(tab, b_usar)
		b_usar.focus_neighbor_left = b_usar.get_path_to(b_usar)
		b_usar.focus_neighbor_right = b_usar.get_path_to(b_usar)
		b_usar.focus_neighbor_bottom = b_usar.get_path_to(b_usar)
	elif actual and actual.has_method("conectar_tab"):
		destino = actual.conectar_tab(tab)
	for p in tabs:
		var b: Button = tabs[p]
		b.focus_neighbor_bottom = b.get_path_to(destino if destino != tab else b)


## Lo que todavía no se abre también se puede ver: dice cómo se gana.
func _cerrada(p: String) -> void:
	var c := Control.new()
	c.size = Vector2(490, 334)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.draw.connect(func():
		var candado := Datos.tex("ui_candado")
		c.draw_texture_rect(candado, Rect2(245 - 24, 96, 48, 40), false)
		UI.tc(c, 245, 146, NOMBRES[p], UI.C_GRIS, 2, true)
		UI.tc(c, 245, 180, como_se_abre(p), UI.C_ORO)
		UI.tc(c, 245, 196, SalaHangar.OBJETOS[p].frase, UI.C_GRIS))
	actual = c
	contenido.add_child(c)


func _naves() -> void:
	var c := Control.new()
	c.size = Vector2(490, 334)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	UI.etiqueta("Cada nave trae su arma y su pasiva. Enter o clic en una: sales con esa.", Vector2(4, 0), c, UI.C_GRIS)
	var g := GaleriaNaves.new()
	g.position = Vector2(0, 18)
	g.con_pintura = true
	c.add_child(g)
	b_usar = UI.boton("USAR ESTA NAVE", Vector2(4, 306), Vector2(482, 24), c, func(): _usar(g))
	var act := func(id: String):
		_marcar_usar(id)
		panel.refrescar()
	g.cambio.connect(act)
	g.confirmar.connect(func(id: String): _usar(g))
	galeria = g
	actual = c
	contenido.add_child(c)
	_marcar_usar(g.sel)


func _marcar_usar(id: String) -> void:
	if b_usar == null:
		return
	var tiene: bool = id in Partida.d.naves
	var en_uso: bool = Partida.nave_actual() == id
	b_usar.disabled = not tiene or en_uso
	b_usar.text = "LA ESTÁS USANDO" if en_uso else ("USAR ESTA NAVE" if tiene else "BLOQUEADA")


func _usar(g: GaleriaNaves) -> void:
	if g.sel in Partida.d.naves:
		Partida.elegir_nave(g.sel)
		panel.refrescar()
		_marcar_usar(g.sel)
		Sonido.tocar("mejora", 0.85)
		for k in g.tarjetas:
			g.tarjetas[k].queue_redraw()


func _animar_fusion(iconos: Array, resultado: Dictionary, forma_antes: int, cuantas: int) -> void:
	bloqueado = true
	var a := preload("res://pantallas/fusion.gd").new()
	a.iconos = iconos
	a.resultado = resultado
	a.icono_resultado = Datos.tex("icono_" + resultado.id)
	a.forma_antes = forma_antes
	a.cuantas = cuantas
	a.terminado.connect(func():
		bloqueado = false
		panel.refrescar()
		if actual and actual.has_method("refrescar"):
			actual.refrescar()
		if actual and actual.has_method("enfocar"):
			actual.enfocar())
	add_child(a)


func _unhandled_input(ev: InputEvent) -> void:
	if bloqueado or (actual and actual.get("ocupado") == true):
		return
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if en_sala:
			volver.emit()
		else:
			a_la_sala()
		return
	if not en_sala:
		if ev is InputEventKey and ev.pressed and not ev.echo:
			if ev.physical_keycode == KEY_Q:
				get_viewport().set_input_as_handled()
				_cambiar(-1)
				return
			if ev.physical_keycode == KEY_E:
				get_viewport().set_input_as_handled()
				_cambiar(1)
				return
		elif ev is InputEventJoypadButton and ev.pressed:
			if ev.button_index == JOY_BUTTON_LEFT_SHOULDER or ev.button_index == JOY_BUTTON_RIGHT_SHOULDER:
				get_viewport().set_input_as_handled()
				_cambiar(-1 if ev.button_index == JOY_BUTTON_LEFT_SHOULDER else 1)
				return
	# si un clic en el vacío se llevó el foco, el teclado lo recupera con cualquier tecla de menú
	if get_viewport().gui_get_focus_owner() == null:
		for accion in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept"]:
			if ev.is_action_pressed(accion):
				get_viewport().set_input_as_handled()
				if en_sala:
					sala.botones[sala.foco].grab_focus()
				else:
					_enfocar_contenido()
				return
