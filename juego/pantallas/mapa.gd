extends Control
## El mundo: un camino de niveles que se abren en orden, como en Plantas vs Zombies 2.
## Fuera del camino cuelgan los niveles extra: la Ruleta y el Modo Infinito.

signal jugar_nivel(id: String)
signal ir_hangar(pestana: String)
signal ir_titulo
signal ng_plus_hecho

const CAMPO_X := PanelNave.ANCHO
const CAMPO_W := 640 - PanelNave.ANCHO
const MAPA_W := 1040.0
const ICONO_EXTRA := {"ruleta": "icono_ruleta", "infinito": "icono_infinito"}
const COLOR_EXTRA := {"ruleta": Color("ff6fb5"), "infinito": Color("6fe8ff")}

var panel: PanelNave
var campo: Control
var capa_nodos: Control
var capa_info: Control
var capa_arriba: Control
var ficha: Sprite2D
var mat_ficha: ShaderMaterial
var nodos := {}
var cam := 0.0
var cam_obj := 0.0
var t := 0
var ficha_pos := Vector2.ZERO
var ficha_obj := Vector2.ZERO
var curva := []
var modal: Control = null
var recien := ""  # nivel recien abierto, para celebrarlo
var recien_extra := ""  # el nivel extra que se abre junto con él
var foco_en := ""  # el nivel donde queda el foco al entrar. Vacío: el que toca jugar
var recien_t := 0
var b_hangar: Button
var b_naves: Button
var b_opciones: Button
var b_menu: Button
var b_ngplus: Button = null
var columna: Array = []
var info_mundo := ""
var arrastrando := false
var arrastre_x := 0.0
var arrastre_cam := 0.0
var ultimo_foco: Control = null
var bloqueado := false
var planetas: Array = []
var puntos_extra := {}
var pie: Label


class Nodo extends Button:
	var id := ""
	var mapa

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(44, 44)
		size = Vector2(44, 44)
		var vacio := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, vacio)
		focus_entered.connect(mapa.al_enfocar.bind(self))
		mouse_entered.connect(grab_focus)
		pressed.connect(mapa.pulsar_nodo.bind(id))

	func _draw() -> void:
		mapa.dibujar_nodo(self)


class Planeta extends Button:
	var i := 0
	var mapa

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(50, 50)
		size = Vector2(50, 50)
		var vacio := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, vacio)
		focus_entered.connect(mapa.al_enfocar_mundo.bind(i))
		focus_exited.connect(mapa.al_salir_mundo)
		mouse_entered.connect(grab_focus)
		pressed.connect(mapa.pulsar_mundo.bind(i))

	func _draw() -> void:
		mapa.dibujar_planeta(self)


func _ready() -> void:
	size = Vector2(640, 360)
	theme = UI.tema()
	curva = _catmull()
	campo = Control.new()
	campo.position = Vector2(CAMPO_X, 0)
	campo.size = Vector2(CAMPO_W, 360)
	campo.clip_contents = true
	campo.mouse_filter = Control.MOUSE_FILTER_PASS
	campo.draw.connect(_dibujar_campo)
	campo.gui_input.connect(_campo_input)
	add_child(campo)
	capa_nodos = Control.new()
	capa_nodos.size = Vector2(MAPA_W, 360)
	capa_nodos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	campo.add_child(capa_nodos)
	ficha = Sprite2D.new()
	ficha.region_enabled = true
	mat_ficha = ShaderMaterial.new()
	mat_ficha.shader = load("res://arte/nave.gdshader")
	ficha.material = mat_ficha
	ficha.texture = Datos.tex("nave2_" + Partida.nave_actual())
	Partida.preparar_material(mat_ficha, Partida.nave_actual())
	capa_nodos.add_child(ficha)
	for id in Datos.ORDEN_NIVELES:
		_crear_nodo(id, Datos.NODOS[id])
	_crear_nodo("portal", Datos.PORTAL)
	for id in Datos.EXTRAS:
		_crear_nodo(id, Datos.NODOS[id])
		puntos_extra[id] = _punteado(id)
	# los carteles van en su propia capa, para que ningún nodo los tape
	capa_info = Control.new()
	capa_info.size = Vector2(CAMPO_W, 360)
	capa_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_info.draw.connect(_dibujar_info)
	campo.add_child(capa_info)
	_crear_planetas()
	_flechas()
	panel = PanelNave.new()
	add_child(panel)
	_crear_botones()
	_enlazar_foco()
	pie = UI.pie(self, "Flechas o WASD: moverse  ·  Enter: entrar  ·  Esc: menú", "Cruceta: moverse  ·  A: entrar  ·  B: menú", 344.0, CAMPO_X + CAMPO_W / 2.0, true)
	var actual: String = Partida.nivel_actual()
	if recien != "":
		actual = recien
		recien_t = 110
		Sonido.tocar("desbloqueo", 1.0, -3.0)
	elif foco_en != "" and nodos.has(foco_en):
		actual = foco_en
	ficha_pos = Datos.NODOS[actual] + Vector2(0, -34)
	ficha_obj = ficha_pos
	cam = clampf(Datos.NODOS[actual].x - CAMPO_W / 2.0, 0.0, MAPA_W - CAMPO_W)
	cam_obj = cam
	nodos[actual].grab_focus.call_deferred()
	Sonido.musica_menu()


func _crear_nodo(id: String, pos: Vector2) -> void:
	var n := Nodo.new()
	n.id = id
	n.mapa = self
	n.position = pos - Vector2(22, 22)
	capa_nodos.add_child(n)
	nodos[id] = n


func _catmull() -> Array:
	var pts := []
	for id in Datos.ORDEN_NIVELES:
		pts.append(Datos.NODOS[id])
	pts.append(Datos.PORTAL)
	var r := []
	for i in pts.size() - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
		var tramo := []
		for k in 22:
			var u := k / 22.0
			var u2 := u * u
			var u3 := u2 * u
			tramo.append(0.5 * (2.0 * p1 + (p2 - p0) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (3.0 * p1 - p0 - 3.0 * p2 + p3) * u3))
		r.append(tramo)
	return r


## La línea punteada que une un nivel extra con el camino: sale del tramo que sigue al nivel que lo abre.
func _punteado(id: String) -> Array:
	var i: int = Datos.ORDEN_NIVELES.find(Datos.EXTRAS[id].requiere)
	var desde: Vector2 = curva[i][11]
	var hasta: Vector2 = Datos.NODOS[id]
	var r := []
	var largo: float = desde.distance_to(hasta)
	var d := 8.0
	while d < largo - 16.0:
		r.append(desde.lerp(hasta, d / largo))
		d += 8.0
	return r


func _crear_planetas() -> void:
	capa_arriba = Control.new()
	capa_arriba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_arriba.position = Vector2(CAMPO_X, 0)
	capa_arriba.size = Vector2(CAMPO_W, 80)
	capa_arriba.draw.connect(_dibujar_arriba)
	add_child(capa_arriba)
	for i in Datos.MUNDOS.size():
		var p := Planeta.new()
		p.i = i
		p.mapa = self
		p.position = Vector2(122 + i * 52, 3)
		capa_arriba.add_child(p)
		planetas.append(p)


func _flechas() -> void:
	var izq := UI.boton("<", Vector2(CAMPO_X + 3, 322), Vector2(24, 24), self, func(): _mover_cam(-220.0))
	var der := UI.boton(">", Vector2(640 - 27, 322), Vector2(24, 24), self, func(): _mover_cam(220.0))
	izq.focus_mode = Control.FOCUS_NONE
	der.focus_mode = Control.FOCUS_NONE


func _mover_cam(d: float) -> void:
	cam_obj = clampf(cam_obj + d, 0.0, MAPA_W - CAMPO_W)


func _crear_botones() -> void:
	var y := 214
	b_hangar = UI.boton("HANGAR", Vector2(6, y), Vector2(138, 24), self, func():
		if Partida.tiene("hangar"):
			ir_hangar.emit("")
		else:
			Sonido.tocar("ui_no"))
	b_naves = UI.boton("NAVES", Vector2(6, y + 28), Vector2(138, 24), self, func():
		if Partida.tiene("hangar"):
			ir_hangar.emit("naves")
		else:
			Sonido.tocar("ui_no"))
	b_opciones = UI.boton("OPCIONES", Vector2(6, y + 56), Vector2(138, 24), self, _opciones)
	b_menu = UI.boton("MENÚ", Vector2(6, y + 84), Vector2(138, 24), self, func(): ir_titulo.emit())
	if not Partida.tiene("hangar"):
		for b in [b_hangar, b_naves]:
			b.disabled = true
			b.focus_mode = Control.FOCUS_NONE
		b_hangar.text = "HANGAR (gana 1-1)"
		b_naves.text = "NAVES (gana 1-1)"
	if Partida.puede_ng_plus():
		b_ngplus = UI.boton("NUEVA PARTIDA +", Vector2(6, y + 112), Vector2(138, 24), self, _nueva_plus)
		b_ngplus.add_theme_color_override("font_color", UI.C_ORO)
	columna = []
	for b in [b_hangar, b_naves, b_opciones, b_menu, b_ngplus]:
		if b != null and b.focus_mode != Control.FOCUS_NONE:
			columna.append(b)


func _enlazar_foco() -> void:
	# el orden del camino es el orden de las flechas
	var orden: Array = Datos.ORDEN_NIVELES.duplicate()
	orden.append("portal")
	for i in orden.size():
		var n: Nodo = nodos[orden[i]]
		var ant: Control = nodos[orden[i - 1]] if i > 0 else b_opciones
		var sig: Control = nodos[orden[i + 1]] if i + 1 < orden.size() else n
		n.focus_neighbor_left = n.get_path_to(ant)
		n.focus_neighbor_right = n.get_path_to(sig)
		n.focus_neighbor_top = n.get_path_to(planetas[0])
		n.focus_neighbor_bottom = n.get_path_to(n)
		n.focus_next = n.get_path_to(sig)
		n.focus_previous = n.get_path_to(ant)
	# los extras cuelgan del camino: abajo o arriba, según dónde estén dibujados
	_extra_abajo("1-R", "1-4", "1-5")
	_extra_arriba("1-INF", "1-8", "portal")
	var actual: Nodo = nodos[Partida.nivel_actual()]
	UI.lista_foco(columna)
	for b in columna:
		b.focus_neighbor_right = b.get_path_to(actual)
		b.focus_neighbor_left = b.get_path_to(b)
		b.focus_next = b.get_path_to(actual)
	for i in planetas.size():
		var p: Planeta = planetas[i]
		var yo := p.get_path_to(p)
		p.focus_neighbor_bottom = p.get_path_to(actual)
		p.focus_neighbor_top = yo
		p.focus_neighbor_left = p.get_path_to(planetas[i - 1]) if i > 0 else p.get_path_to(b_opciones)
		p.focus_neighbor_right = p.get_path_to(planetas[i + 1]) if i + 1 < planetas.size() else yo
		p.focus_next = p.focus_neighbor_right
		p.focus_previous = p.focus_neighbor_left


func _extra_abajo(id: String, a: String, b: String) -> void:
	var x: Nodo = nodos[id]
	for vecino in [a, b]:
		nodos[vecino].focus_neighbor_bottom = nodos[vecino].get_path_to(x)
	x.focus_neighbor_top = x.get_path_to(nodos[a])
	x.focus_neighbor_left = x.get_path_to(nodos[a])
	x.focus_neighbor_right = x.get_path_to(nodos[b])
	x.focus_neighbor_bottom = x.get_path_to(x)
	x.focus_next = x.get_path_to(nodos[b])
	x.focus_previous = x.get_path_to(nodos[a])


func _extra_arriba(id: String, a: String, b: String) -> void:
	var x: Nodo = nodos[id]
	for vecino in [a, b]:
		nodos[vecino].focus_neighbor_top = nodos[vecino].get_path_to(x)
	x.focus_neighbor_bottom = x.get_path_to(nodos[a])
	x.focus_neighbor_left = x.get_path_to(nodos[a])
	x.focus_neighbor_right = x.get_path_to(nodos[b])
	x.focus_neighbor_top = x.get_path_to(planetas[planetas.size() - 1])
	x.focus_next = x.get_path_to(nodos[b])
	x.focus_previous = x.get_path_to(nodos[a])


func al_enfocar(n: Nodo) -> void:
	Sonido.tocar("nodo", 1.0, -6.0)
	ultimo_foco = n
	var p: Vector2 = n.position + Vector2(22, 22)
	if n.id != "portal" and Partida.nivel_abierto(n.id):
		ficha_obj = p + Vector2(0, -34)
	if p.x - cam < 60.0 or p.x - cam > CAMPO_W - 60.0:
		cam_obj = clampf(p.x - CAMPO_W / 2.0, 0.0, MAPA_W - CAMPO_W)


func al_enfocar_mundo(i: int) -> void:
	Sonido.tocar("nodo", 1.0, -6.0)
	var m: Dictionary = Datos.MUNDOS[i]
	info_mundo = "%s. %s %s" % [m.nombre, m.desc, "" if m.abierto else "Próximamente."]


func al_salir_mundo() -> void:
	info_mundo = ""


## El mundo en que estás lleva a su nivel. A los otros todavía no se puede ir.
func pulsar_mundo(i: int) -> void:
	if Datos.MUNDOS[i].abierto:
		Sonido.tocar("ui_ok")
		nodos[Partida.nivel_actual()].grab_focus()
	else:
		Sonido.tocar("ui_no")


func pulsar_nodo(id: String) -> void:
	if modal != null or bloqueado:
		return
	if id == "portal":
		Sonido.tocar("ui_no")
		return
	if not Partida.nivel_abierto(id):
		Sonido.tocar("ui_no")
		return
	Sonido.tocar("ui_ok")
	_abrir_panel(id)


func _abrir_panel(id: String) -> void:
	var p := preload("res://pantallas/panel_nivel.gd").new()
	p.id = id
	p.jugar.connect(func():
		jugar_nivel.emit(id))
	p.cerrado.connect(func():
		modal = null
		nodos[id].grab_focus())
	modal = p
	add_child(p)


func _opciones() -> void:
	var o := preload("res://pantallas/opciones.gd").new()
	o.al_cerrar = func(): b_opciones.grab_focus()
	modal = o
	o.tree_exited.connect(func(): modal = null)
	add_child(o)


func _nueva_plus() -> void:
	var np := preload("res://pantallas/nueva_plus.gd").new()
	np.cerrado.connect(func():
		modal = null
		b_ngplus.grab_focus())
	np.hecho.connect(func(): ng_plus_hecho.emit())
	modal = np
	add_child(np)


## Esc: del camino al menú de la izquierda, y de ahí al título.
func _unhandled_input(ev: InputEvent) -> void:
	if modal != null or bloqueado or not ev.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if get_viewport().gui_get_focus_owner() == b_menu:
		ir_titulo.emit()
	else:
		Sonido.tocar("ui_no")
		b_menu.grab_focus()


func _campo_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			_mover_cam(-50.0)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			_mover_cam(50.0)
		elif ev.button_index == MOUSE_BUTTON_LEFT:
			arrastrando = ev.pressed
			arrastre_x = ev.position.x
			arrastre_cam = cam_obj
	elif ev is InputEventMouseMotion and arrastrando:
		cam_obj = clampf(arrastre_cam - (ev.position.x - arrastre_x), 0.0, MAPA_W - CAMPO_W)


var _t_acum := 0.0
var _recien_acum := -1.0


func _process(d: float) -> void:
	_t_acum += d * 60.0
	t = int(_t_acum)
	if recien_t > 0:
		if _recien_acum < 0.0:
			_recien_acum = float(recien_t)
		_recien_acum -= d * 60.0
		recien_t = maxi(int(_recien_acum), 0)
	# suavizado que no depende de los Hz de la pantalla
	cam = lerpf(cam, cam_obj, 1.0 - pow(1.0 - 0.16, d * 60.0))
	capa_nodos.position.x = -round(cam)
	ficha_pos = ficha_pos.lerp(ficha_obj, 1.0 - pow(1.0 - 0.1, d * 60.0))
	ficha.position = Vector2(round(ficha_pos.x), round(ficha_pos.y + sin(t * 0.08) * 2.0))
	ficha.region_rect = Rect2((4 + (t / 7) % 2) * 48, 0, 48, 48)
	# el recordatorio es del mapa: con un diálogo o un panel encima, se esconde
	pie.visible = get_child(get_child_count() - 1) == pie
	campo.queue_redraw()
	capa_nodos.queue_redraw()
	capa_info.queue_redraw()
	capa_arriba.queue_redraw()
	for id in nodos:
		nodos[id].queue_redraw()
	for p in planetas:
		p.queue_redraw()


func _dibujar_campo() -> void:
	var cx := roundf(cam)
	campo.draw_texture_rect_region(Datos.tex("mapa_chatarra"), Rect2(0, 0, CAMPO_W, 360), Rect2(cx, 0, CAMPO_W, 360))
	# el camino se va pintando a medida que avanzas
	for i in curva.size():
		var abierto: bool = i < Datos.ORDEN_NIVELES.size() and Partida.nivel_completado(Datos.ORDEN_NIVELES[i])
		var col := UI.C_ORO if abierto else Color(0.05, 0.04, 0.1, 0.7)
		for q: Vector2 in curva[i]:
			var x: float = q.x - cx
			if x > -3 and x < CAMPO_W + 3:
				campo.draw_rect(Rect2(round(x) - 1, round(q.y) - 1, 3, 3), col)
	# los niveles extra: punteado en su color cuando se abren
	for id in puntos_extra:
		var col: Color = COLOR_EXTRA[Datos.NIVELES[id].modo] if Partida.nivel_abierto(id) else Color(0.05, 0.04, 0.1, 0.8)
		for q: Vector2 in puntos_extra[id]:
			var x: float = q.x - cx
			if x > -3 and x < CAMPO_W + 3:
				campo.draw_rect(Rect2(round(x) - 1, round(q.y) - 1, 3, 3), col)


## Arriba a la izquierda: con qué dificultad juegas y en qué vuelta vas.
func _dibujar_arriba() -> void:
	var def: Dictionary = Partida.dif()
	var alto := 48.0
	UI.marco(capa_arriba, Rect2(3, 4, 114, alto), Color(0.05, 0.03, 0.12, 0.85), UI.C_LINEA)
	capa_arriba.draw_texture_rect(Datos.tex(def.icono), Rect2(5, 12, 32, 32), false)
	UI.t(capa_arriba, 40, 5, def.nombre, def.color)
	var y := 19.0
	if Partida.slot > 0:
		UI.t(capa_arriba, 40, y, "Ranura %d" % Partida.slot, UI.C_GRIS)
		y += 14.0
	if Partida.ciclo() > 0:
		UI.t(capa_arriba, 40, y, "Ciclo %d" % Partida.ciclo(), UI.C_ROSA)
	if info_mundo != "":
		UI.cartel(capa_arriba, CAMPO_W / 2.0, 56, info_mundo, UI.C_TEXTO, Rect2(0, 0, CAMPO_W, 80))


func dibujar_planeta(p: Planeta) -> void:
	var m: Dictionary = Datos.MUNDOS[p.i]
	var tx: Texture2D = Datos.tex("mundo_%d" % p.i)
	var mod := Color.WHITE if m.abierto else Color(0.42, 0.40, 0.55)
	p.draw_texture(tx, Vector2(1, 1), mod)
	if p.has_focus():
		p.draw_rect(Rect2(0, 0, 50, 50), Color.WHITE, false, 1.0)
	elif p.i == 0:
		p.draw_rect(Rect2(0, 0, 50, 50), UI.C_ORO, false, 1.0)
	if not m.abierto:
		p.draw_texture(Datos.tex("ui_candado"), Vector2(18, 18))


func dibujar_nodo(n: Nodo) -> void:
	var c := Vector2(22, 22)
	var foco := n.has_focus()
	if n.id == "portal":
		if foco:
			_anillo(n, c, 21.0, UI.C_GRIS)
		n.draw_texture(Datos.tex("ui_candado"), c - Vector2(7, 7))
		return
	if Datos.EXTRAS.has(n.id):
		_dibujar_extra(n, c, foco)
		return
	var abierto: bool = Partida.nivel_abierto(n.id)
	var hecho: bool = Partida.nivel_completado(n.id)
	var def: Dictionary = Datos.NIVELES[n.id]
	var fondo := Color("3a3458")
	var borde := Color("0d0a18")
	if hecho:
		fondo = Color("2f6a3a")
		borde = UI.C_VERDE
	elif abierto:
		fondo = Color("c07a10")
		borde = UI.C_ORO
	# base del nodo
	var r := 15.0
	var es_jefe: bool = def.has("jefe")
	if es_jefe:
		r = 18.0
	n.draw_circle(c, r + 2, Color("0d0a18"))
	n.draw_circle(c, r, fondo)
	n.draw_arc(c, r, 0, TAU, 32, borde, 2.0, false)
	if abierto and not hecho:
		var pulso := 2.0 + 2.0 * (0.5 + 0.5 * sin(t * 0.13))
		n.draw_arc(c, r + pulso + 1, 0, TAU, 32, Color(1, 0.85, 0.3, 0.7), 1.0, false)
	if foco:
		_anillo(n, c, r + 5.0, Color.WHITE)
	if not abierto:
		n.draw_texture(Datos.tex("ui_candado"), c - Vector2(7, 7))
	elif es_jefe:
		n.draw_texture(Datos.tex("ui_calavera"), c - Vector2(7, 12))
		UI.tc(n, 22, 23, n.id, Color.WHITE, 1, true)
	else:
		UI.tc(n, 22, 15, n.id, Color.WHITE, 1, true)
	if hecho:
		_estrellas(n)
	# el premio se ve arriba, en un recuadro, hasta que lo ganas
	if not hecho:
		_caja_premio(n, def.premio, abierto)
	_celebrar(n, c, r)


func _dibujar_extra(n: Nodo, c: Vector2, foco: bool) -> void:
	var def: Dictionary = Datos.NIVELES[n.id]
	var modo: String = def.modo
	var abierto: bool = Partida.nivel_abierto(n.id)
	var hecho: bool = Partida.nivel_completado(n.id)
	var col: Color = COLOR_EXTRA[modo]
	var r := 17.0
	n.draw_circle(c, r + 2, Color("0d0a18"))
	n.draw_circle(c, r, col.darkened(0.6) if abierto else Color("3a3458"))
	n.draw_arc(c, r, 0, TAU, 32, col if abierto else Color("0d0a18"), 2.0, false)
	if abierto and not hecho:
		var pulso := 2.0 + 2.0 * (0.5 + 0.5 * sin(t * 0.13))
		n.draw_arc(c, r + pulso + 1, 0, TAU, 32, Color(col, 0.7), 1.0, false)
	if foco:
		_anillo(n, c, r + 5.0, Color.WHITE)
	n.draw_texture_rect(Datos.tex(ICONO_EXTRA[modo]), Rect2(c - Vector2(14, 14), Vector2(28, 28)), false, Color.WHITE if abierto else Color(0.3, 0.3, 0.4))
	if not abierto:
		n.draw_texture(Datos.tex("ui_candado"), c - Vector2(7, 7))
	if modo == "ruleta":
		if hecho:
			_estrellas(n)
		else:
			_caja_premio(n, def.premio, abierto)
	_celebrar(n, c, r)


func _estrellas(n: Nodo) -> void:
	var est: int = Partida.estrellas(n.id)
	for k in 3:
		var tx: Texture2D = Datos.tex("ui_estrella" if k < est else "ui_estrella_vacia")
		n.draw_texture(tx, Vector2(22 - 21 + k * 14, 36))


func _caja_premio(n: Nodo, premio: Dictionary, abierto: bool) -> void:
	var y := -24.0 + roundf(sin(t * 0.07 + n.position.x) * 1.5)
	var box := Rect2(11, y, 22, 22)
	n.draw_rect(box, Color("1d1736"))
	n.draw_rect(box, UI.C_ORO if abierto else Color("6a6488"), false, 1.0)
	_icono_premio(n, premio, box.grow(-1), abierto)


func _celebrar(n: Nodo, c: Vector2, r: float) -> void:
	if (recien == n.id or recien_extra == n.id) and recien_t > 0 and (recien_t / 8) % 2 == 0:
		_anillo(n, c, r + 9.0, UI.C_ORO)
		UI.tc(n, 22, -40, "¡NUEVO!", UI.C_ORO, 1, true)


func _anillo(n: Control, c: Vector2, r: float, col: Color) -> void:
	n.draw_arc(c, r, 0, TAU, 40, col, 1.0, false)


func _icono_premio(n: Control, premio: Dictionary, r: Rect2, abierto: bool) -> void:
	var mod := Color.WHITE if abierto else Color(0.7, 0.7, 0.8)
	match premio.icono:
		"mascota":
			n.draw_texture_rect_region(Datos.tex_mascota(premio.get("id", "mordisco"), 0), r, Rect2(0, 0, Partida.TAM_MASCOTA[0], Partida.TAM_MASCOTA[0]), mod)
		"nave":
			# la silueta de la nave: se ve lo que viene, no se revela el color
			n.draw_texture_rect_region(Datos.tex("nave2_" + premio.id), r, Rect2(4 * 48, 0, 48, 48), Color(0.08, 0.08, 0.14) if not abierto else Color(0.3, 0.3, 0.45))
		_:
			n.draw_texture_rect(Datos.tex(premio.icono), r, false, mod)


## El cartel del nivel que tiene el foco: cómo se llama y, si está cerrado, cómo se abre.
func _dibujar_info() -> void:
	var f := get_viewport().gui_get_focus_owner()
	if not f is Nodo or not f.is_inside_tree():
		return
	var txt := ""
	var col := UI.C_TEXTO
	var abajo := 42.0
	if f.id == "portal":
		txt = "Portal a Verdor: próximamente"
		col = UI.C_GRIS
	else:
		var def: Dictionary = Datos.NIVELES[f.id]
		if Partida.nivel_abierto(f.id):
			txt = def.nombre
			if def.get("modo", "") == "infinito":
				var rec: int = int(Partida.d.records.get(f.id, {}).get("seg", 0))
				if rec > 0:
					txt += ". Récord: " + UI.reloj(rec)
		else:
			col = UI.C_GRIS
			if Datos.EXTRAS.has(f.id):
				txt = "%s: gana %s para abrirlo" % [def.nombre, Datos.EXTRAS[f.id].requiere]
			else:
				txt = "Cerrado: primero gana %s" % Datos.ORDEN_NIVELES[Datos.ORDEN_NIVELES.find(f.id) - 1]
		if Partida.nivel_completado(f.id):
			abajo = 54.0
	var cx: float = f.position.x + 22.0 - round(cam)
	var y: float = f.position.y + abajo
	# abajo no hay espacio: se muestra encima, sobre el recuadro del premio
	if y > 326.0:
		y = f.position.y - 46.0
	UI.cartel(capa_info, cx, y, txt, col, Rect2(0, 0, CAMPO_W, 360))
