extends Control
## Opciones por pestañas: Pantalla, Sonido, Teclas y General.
##
## Con teclado (flechas o WASD) o mando:
## - En la barra de pestañas, izquierda y derecha cambian de pestaña. Enter o abajo entran a la primera fila.
## - En una fila, arriba y abajo se mueven; izquierda y derecha cambian el valor (mantener apretado repite
##   en lo que tiene barra). Enter cambia lo que se pueda cambiar.
## - Q y E (o los hombros del mando) cambian de pestaña desde cualquier parte.
## - Esc en una fila vuelve a la pestaña; Esc en la pestaña cierra.
## Con mouse: clic en las pestañas, en las flechas de cada fila y en las barras (también arrastrando).

const PESTANAS := ["Pantalla", "Sonido", "Teclas", "General"]
const CONTROLES_UI := preload("res://pantallas/controles_ui.gd")
const PIE_FILAS := "Flechas o WASD: moverse y cambiar  ·  Enter: cambiar  ·  Q / E: otra pestaña  ·  Esc: volver"
const PIE_FILAS_MANDO := "Cruceta: moverse y cambiar  ·  A: cambiar  ·  LB / RB: otra pestaña  ·  B: volver"

var al_cerrar: Callable
var botones_pestana: Array[Button] = []
var contenido: Control
var pestana := 0
var filas: Array = []
var controles_ui = null
var b_volver: Button
var cerrado := false
var aviso_general := ""
var l_q: Label
var l_e: Label


class Fila extends Button:
	const X_MENOS := 200.0
	const X_MAS := 416.0
	const X_BARRA := 224.0
	const AN_BARRA := 146.0
	const AN_FLECHA := 20.0

	var titulo := ""
	var ayuda := ""
	var obtener: Callable
	var cambiar: Callable  # recibe +1 o -1
	var barra: Callable  # opcional: devuelve de 0 a 1
	var fijar: Callable  # opcional, con barra: recibe de 0 a 1. Es lo que hace el mouse en la barra
	var solo_pulsar := false  # no cambia con las flechas: es una acción, y se hace con Enter o clic
	var repite := false  # mantener apretado repite: en lo que tiene barra, no en lo que se prende y apaga
	var arrastrando := false
	var mouse_x := -1.0
	var eco := 0.0
	var mantenido := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(440, 24)
		size = Vector2(440, 24)
		focus_mode = Control.FOCUS_ALL
		focus_entered.connect(func():
			Sonido.tocar("ui_mover")
			queue_redraw())
		focus_exited.connect(queue_redraw)
		mouse_exited.connect(func():
			mouse_x = -1.0
			queue_redraw())
		# el mouse se atiende en _gui_input: esto solo llega por teclado o mando
		pressed.connect(func(): _paso(1))

	func _process(d: float) -> void:
		eco = maxf(eco - d, 0.0)
		# el teclado repite solo, gracias al sistema. El mando no: se cuenta aquí
		if not (repite and has_focus() and Controles.ultimo_mando):
			mantenido = 0.0
			return
		var s := 0
		if Input.is_action_pressed("ui_left"):
			s = -1
		elif Input.is_action_pressed("ui_right"):
			s = 1
		if s == 0:
			mantenido = 0.0
			return
		mantenido += d
		if mantenido > 0.35 and eco <= 0.0:
			eco = 0.09
			_paso(s)

	func _paso(s: int) -> void:
		var antes: String = obtener.call()
		cambiar.call(s)
		queue_redraw()
		if solo_pulsar:
			Sonido.tocar("ui_ok")
		elif obtener.call() == antes:
			Sonido.tocar("ui_no")
		else:
			Sonido.tocar("ui_mover")

	func _fijar_desde(x: float) -> void:
		fijar.call(clampf((x - X_BARRA) / AN_BARRA, 0.0, 1.0))
		queue_redraw()

	func _clic(x: float) -> void:
		if solo_pulsar:
			_paso(1)
		elif x >= X_MENOS and x < X_MENOS + AN_FLECHA:
			_paso(-1)
		elif x >= X_MAS:
			_paso(1)
		elif barra.is_valid():
			if fijar.is_valid() and x >= X_BARRA and x <= X_BARRA + AN_BARRA:
				arrastrando = true
				_fijar_desde(x)
				Sonido.tocar("ui_mover")
		else:
			_paso(1)

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				if ev.pressed:
					_clic(ev.position.x)
				else:
					arrastrando = false
				accept_event()
			return
		if ev is InputEventMouseMotion:
			mouse_x = ev.position.x
			if arrastrando:
				_fijar_desde(ev.position.x)
			queue_redraw()
			return
		if solo_pulsar:
			return
		var izq: bool = ev.is_action_pressed("ui_left", true)
		var der: bool = ev.is_action_pressed("ui_right", true)
		if not (izq or der):
			return
		accept_event()
		# lo que se prende y apaga no repite: a 30 veces por segundo sería una lotería
		if ev.is_echo() and (not repite or eco > 0.0):
			return
		eco = 0.09
		_paso(-1 if izq else 1)

	func _flecha(x: float, s: String, col: Color) -> void:
		var sobre: bool = mouse_x >= x and mouse_x < x + AN_FLECHA
		UI.marco(self, Rect2(x, 3, AN_FLECHA, 18), Color("332a60") if sobre else Color("15112a"), col if sobre or has_focus() else UI.C_LINEA)
		UI.tc(self, x + AN_FLECHA / 2.0, 3, s, col)

	func _draw() -> void:
		var col := UI.C_ORO if has_focus() else UI.C_TEXTO
		UI.t(self, 8, 3, titulo, col)
		var val: String = obtener.call()
		if solo_pulsar:
			UI.marco(self, Rect2(X_MENOS, 3, X_MAS + AN_FLECHA - X_MENOS, 18), Color("15112a"), col if has_focus() else UI.C_LINEA)
			UI.tc(self, (X_MENOS + X_MAS + AN_FLECHA) / 2.0, 3, val, col)
			return
		_flecha(X_MENOS, "<", col)
		_flecha(X_MAS, ">", col)
		if barra.is_valid():
			UI.barra(self, Rect2(X_BARRA, 7, AN_BARRA, 10), barra.call(), UI.C_ORO if has_focus() else UI.C_GRIS)
			UI.t(self, X_MAS - 4.0 - UI.ancho(val), 3, val, col)
		else:
			UI.tc(self, (X_MENOS + X_MAS + AN_FLECHA) / 2.0, 3, val, col)


func _ready() -> void:
	global_position = Vector2.ZERO
	size = Vector2(640, 360)
	theme = UI.tema()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := ColorRect.new()
	fondo.color = UI.C_FONDO
	fondo.size = size
	add_child(fondo)
	UI.etiqueta("OPCIONES", Vector2(12, 3), self, UI.C_ORO)
	var x := 104
	for i in PESTANAS.size():
		var b := Button.new()
		b.text = PESTANAS[i]
		b.position = Vector2(x + i * 104, 2)
		b.custom_minimum_size = Vector2(100, 22)
		b.focus_mode = Control.FOCUS_ALL
		add_child(b)
		# el tamaño va después de entrar al árbol: antes no conoce el tema y queda más alto
		b.size = Vector2(100, 22)
		b.focus_entered.connect(_elegir_pestana.bind(i))
		b.gui_input.connect(_pestana_input)
		botones_pestana.append(b)
	# recuerdan qué tecla cambia de pestaña, a cada lado de la barra
	l_q = UI.etiqueta("Q", Vector2(84, 3), self, UI.C_GRIS)
	l_e = UI.etiqueta("E", Vector2(x + PESTANAS.size() * 104, 3), self, UI.C_GRIS)
	contenido = Control.new()
	contenido.position = Vector2(0, 28)
	contenido.size = Vector2(640, 290)
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(contenido)
	b_volver = UI.boton("VOLVER", Vector2(250, 318), Vector2(140, 22), self, _cerrar)
	UI.pie(self, PIE_FILAS, PIE_FILAS_MANDO)
	_construir()
	botones_pestana[pestana].grab_focus()


func _elegir_pestana(i: int) -> void:
	if i == pestana and contenido.get_child_count() > 0:
		return
	Sonido.tocar("ui_mover")
	pestana = i
	_construir()


## Enter en una pestaña: entrar a lo que tiene adentro. Con el mouse no hace falta: basta el clic en la fila.
func _pestana_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_entrar()


func _entrar() -> void:
	var primero := _primero()
	if primero:
		primero.grab_focus()


func _primero() -> Control:
	if controles_ui:
		return controles_ui.primer_boton()
	return filas[0] if not filas.is_empty() else null


## Q o E desde cualquier parte. Si estabas en una fila, sigues en las filas de la pestaña nueva.
func _otra_pestana(s: int) -> void:
	var f := get_viewport().gui_get_focus_owner()
	var adentro: bool = f != null and contenido.is_ancestor_of(f)
	Sonido.tocar("ui_mover")
	pestana = posmod(pestana + s, PESTANAS.size())
	_construir()
	if adentro:
		_entrar()
	else:
		botones_pestana[pestana].grab_focus()


func _construir() -> void:
	for h in contenido.get_children():
		contenido.remove_child(h)
		h.queue_free()
	filas.clear()
	controles_ui = null
	aviso_general = ""
	for i in botones_pestana.size():
		var marcada := i == pestana
		botones_pestana[i].add_theme_color_override("font_color", UI.C_ORO if marcada else UI.C_GRIS)
		var st := StyleBoxFlat.new()
		st.bg_color = UI.C_PANEL2 if marcada else Color("15112a")
		st.border_color = UI.C_ORO if marcada else UI.C_LINEA
		st.set_border_width_all(1)
		st.content_margin_bottom = 2
		botones_pestana[i].add_theme_stylebox_override("normal", st)
	match PESTANAS[pestana]:
		"Pantalla":
			_pantalla()
		"Sonido":
			_sonido()
		"Teclas":
			_teclas()
		"General":
			_general()
	_enlazar()


func _si_no(v: bool) -> String:
	return "Sí" if v else "No"


func _fila(titulo: String, obtener: Callable, cambiar: Callable, ayuda := "", barra := Callable()) -> Fila:
	var f := Fila.new()
	f.titulo = titulo
	f.obtener = obtener
	f.cambiar = cambiar
	f.ayuda = ayuda
	f.barra = barra
	f.position = Vector2(100, 8 + filas.size() * 42)
	contenido.add_child(f)
	if ayuda != "":
		UI.etiqueta(ayuda, Vector2(108, 8 + filas.size() * 42 + 23), contenido, UI.C_GRIS)
	filas.append(f)
	return f


## Una fila con barra: flechas de a un paso, y el mouse la fija donde hagas clic.
func _fila_barra(titulo: String, leer: Callable, poner: Callable, maximo: int, paso: int, ayuda := "") -> Fila:
	var f := _fila(titulo, func(): return "%d %%" % leer.call(), func(s): poner.call(clampi(leer.call() + paso * s, 0, maximo)), ayuda, func(): return float(leer.call()) / maximo)
	f.fijar = func(v: float): poner.call(clampi(roundi(v * maximo / paso) * paso, 0, maximo))
	f.repite = true
	return f


func _pantalla() -> void:
	_fila("Pantalla completa", func(): return _si_no(Ajustes.pantalla_completa), func(_s):
		Ajustes.pantalla_completa = not Ajustes.pantalla_completa
		Ajustes.aplicar_video(), "También con F11.")
	_fila_barra("Sacudida de pantalla", func(): return Ajustes.sacudida, func(v): Ajustes.sacudida = v, 150, 25, "Cuánto tiembla al recibir golpes y explosiones.")
	_fila("Reducir destellos", func(): return _si_no(Ajustes.reducir_destellos), func(_s): Ajustes.reducir_destellos = not Ajustes.reducir_destellos, "Menos flashes de luz y sin borde rojo.")
	_fila_barra("Oscurecer el fondo", func(): return Ajustes.atenuar_fondo, func(v): Ajustes.atenuar_fondo = v, 80, 20, "Las balas se ven mejor con el fondo más oscuro.")


func _sonido() -> void:
	_fila_barra("Música", func(): return Ajustes.musica, func(v):
		Ajustes.musica = v
		Sonido.aplicar_volumen(), 100, 10)
	_fila_barra("Efectos", func(): return Ajustes.efectos, func(v):
		Ajustes.efectos = v
		Sonido.aplicar_volumen()
		Sonido.tocar("kill"), 100, 10)
	_fila("Tema de música", func(): return Sonido.nombre_tema(), func(s): Sonido.cambiar_tema(s), Sonido.CREDITO_MUSICA)


func _teclas() -> void:
	controles_ui = CONTROLES_UI.new()
	controles_ui.name = "Controles"
	contenido.add_child(controles_ui)


func _general() -> void:
	_fila("Disparo automático", func(): return _si_no(Ajustes.disparo_auto), func(_s): Ajustes.disparo_auto = not Ajustes.disparo_auto, "Si lo apagas, disparas manteniendo la tecla.")
	_fila("Foco", func(): return "Alternar" if Ajustes.foco_alternar else "Mantener", func(_s): Ajustes.foco_alternar = not Ajustes.foco_alternar, "Mantener: lento mientras aprietas. Alternar: un toque y otro toque.")
	_fila("Números de daño", func(): return _si_no(Ajustes.ver_numeros), func(_s): Ajustes.ver_numeros = not Ajustes.ver_numeros, "Los números que saltan al pegarle a un enemigo.")
	var repetir := _fila("Textos de Don Tuerca", func(): return aviso_general if aviso_general != "" else "Volver a verlos", _repetir_textos, "Los vuelve a contar desde el principio, en esta partida.")
	repetir.solo_pulsar = true


func _hay_partida_abierta() -> bool:
	return Partida.slot == 0 or Partida.existe_slot(Partida.slot)


func _repetir_textos(_s: int) -> void:
	if not _hay_partida_abierta():
		aviso_general = "Primero abre una partida"
		return
	Partida.d.vistos = []
	Partida.guardar()
	aviso_general = "Listo: los va a repetir"


func _enlazar() -> void:
	var primero: Control = _primero()
	var ultimo: Control = null
	if controles_ui:
		ultimo = controles_ui.ultimo_boton()
	elif not filas.is_empty():
		ultimo = filas[filas.size() - 1]
	# las pestañas: un anillo arriba, y abajo se entra a la primera fila
	var n: int = botones_pestana.size()
	for i in n:
		var b := botones_pestana[i]
		b.focus_neighbor_left = b.get_path_to(botones_pestana[posmod(i - 1, n)])
		b.focus_neighbor_right = b.get_path_to(botones_pestana[posmod(i + 1, n)])
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(primero)
		b.focus_next = b.get_path_to(primero)
		b.focus_previous = b.get_path_to(b_volver)
	# las filas: de arriba abajo, y a los lados solo cambian el valor
	var tab := botones_pestana[pestana]
	for i in filas.size():
		var f: Fila = filas[i]
		var yo := f.get_path_to(f)
		var arriba: Control = filas[i - 1] if i > 0 else tab
		var abajo: Control = filas[i + 1] if i + 1 < filas.size() else b_volver
		f.focus_neighbor_left = yo
		f.focus_neighbor_right = yo
		f.focus_neighbor_top = f.get_path_to(arriba)
		f.focus_neighbor_bottom = f.get_path_to(abajo)
		f.focus_previous = f.get_path_to(arriba)
		f.focus_next = f.get_path_to(abajo)
	var volver_yo := b_volver.get_path_to(b_volver)
	b_volver.focus_neighbor_left = volver_yo
	b_volver.focus_neighbor_right = volver_yo
	b_volver.focus_neighbor_bottom = volver_yo
	b_volver.focus_neighbor_top = b_volver.get_path_to(ultimo)
	b_volver.focus_previous = b_volver.get_path_to(ultimo)
	b_volver.focus_next = b_volver.get_path_to(tab)
	if controles_ui:
		controles_ui.limitar_foco(b_volver, tab)


func _unhandled_input(ev: InputEvent) -> void:
	if cerrado:
		return
	if controles_ui and controles_ui.ocupado():
		return
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Sonido.tocar("ui_no")
		var f := get_viewport().gui_get_focus_owner()
		if f != null and contenido.is_ancestor_of(f):
			botones_pestana[pestana].grab_focus()
		else:
			_cerrar()
		return
	var s := 0
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_Q:
			s = -1
		elif ev.keycode == KEY_E:
			s = 1
	elif ev is InputEventJoypadButton and ev.pressed:
		if ev.button_index == JOY_BUTTON_LEFT_SHOULDER:
			s = -1
		elif ev.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			s = 1
	if s != 0:
		get_viewport().set_input_as_handled()
		_otra_pestana(s)


func _process(_d: float) -> void:
	# los hombros del mando se llaman distinto que las teclas
	l_q.text = "LB" if Controles.ultimo_mando else "Q"
	l_e.text = "RB" if Controles.ultimo_mando else "E"


func _cerrar() -> void:
	if cerrado:
		return
	cerrado = true
	Ajustes.guardar()
	if al_cerrar.is_valid():
		al_cerrar.call()
	queue_free()
