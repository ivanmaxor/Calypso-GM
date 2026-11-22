extends Control
## Estación EQUIPO: una ranura, sus piezas, y qué hace la que tienes seleccionada.
## Con el foco o el mouse encima se ve la pieza; con Enter o clic se la pones a la nave.

signal cambio

var ranura := "mira"
var sel_uid := -1
var botones_ranura := {}
var scroll: ScrollContainer
var grid: GridContainer
var b_equipar: Button
var b_mejorar: Button
var info: Control
var tab_arriba: Control = null
const COLUMNAS := 6


class Ranura extends Button:
	var id := ""
	var e
	var ancho := 78.0

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(ancho, 66)
		size = Vector2(ancho, 66)
		var vacio := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, vacio)
		focus_entered.connect(e.elegir_ranura.bind(id))
		focus_exited.connect(queue_redraw)
		pressed.connect(e.pulsar_ranura.bind(id))

	func _draw() -> void:
		var marcada: bool = e.ranura == id
		var cx := ancho / 2.0
		UI.marco(self, Rect2(0, 0, ancho, 66), UI.C_PANEL2 if marcada else UI.C_PANEL, UI.C_ORO if marcada else UI.C_LINEA)
		if has_focus():
			draw_rect(Rect2(1, 1, ancho - 2, 64), UI.C_ORO, false, 1.0)
		UI.tc(self, cx, -1, Datos.NOMBRE_RANURA[id], UI.C_ORO if marcada else UI.C_TEXTO)
		var it := Partida.equipado(id)
		if not it.is_empty():
			UI.pieza(self, Vector2(cx - 18, 14), 36, it)
		else:
			UI.marco(self, Rect2(cx - 18, 14, 36, 36), Color("15112a"), Color("2a2448"))
			UI.tc(self, cx, 24, "vacía", UI.C_GRIS)
		UI.tc(self, cx, 50, Datos.QUE_DA_RANURA[id].split(" ")[0], UI.C_GRIS)


func _ready() -> void:
	size = Vector2(490, 334)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var lista: Array = Partida.ranuras_visibles()
	var ancho: float = floorf((482.0 - 3.0 * (lista.size() - 1)) / lista.size())
	var i := 0
	for r in lista:
		var b := Ranura.new()
		b.id = r
		b.e = self
		b.ancho = ancho
		b.position = Vector2(4 + i * (ancho + 3.0), 18)
		add_child(b)
		botones_ranura[r] = b
		i += 1
	scroll = ScrollContainer.new()
	scroll.position = Vector2(4, 106)
	scroll.size = Vector2(246, 208)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	PiezaBoton.barra_visible(scroll)
	grid = GridContainer.new()
	grid.columns = COLUMNAS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(grid)
	info = Control.new()
	info.position = Vector2(254, 88)
	info.size = Vector2(236, 246)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.draw.connect(_dibujar_info)
	add_child(info)
	b_equipar = UI.boton("EQUIPAR", Vector2(258, 282), Vector2(226, 22), self, _equipar)
	b_mejorar = UI.boton("MEJORAR", Vector2(258, 308), Vector2(226, 22), self, _mejorar)
	_enlazar_ranuras()
	elegir_ranura(ranura)


func enfocar() -> void:
	botones_ranura[ranura].grab_focus()


## Lo de más arriba sube a la pestaña. Devuelve a dónde se llega bajando desde ella.
func conectar_tab(tab: Control) -> Control:
	tab_arriba = tab
	_enlazar_ranuras()
	return botones_ranura[ranura]


func _enlazar_ranuras() -> void:
	var lista: Array = Partida.ranuras_visibles()
	for i in lista.size():
		var b: Control = botones_ranura[lista[i]]
		b.focus_neighbor_left = b.get_path_to(botones_ranura[lista[i - 1]] if i > 0 else b)
		b.focus_neighbor_right = b.get_path_to(botones_ranura[lista[i + 1]] if i + 1 < lista.size() else b)
		b.focus_neighbor_top = b.get_path_to(tab_arriba if tab_arriba else b)


## Las flechas no se escapan: de la lista se sube a su ranura y se sigue a la derecha hasta los botones.
func _enlazar_lista() -> void:
	var filas := []
	var fila := []
	for b in grid.get_children():
		fila.append(b)
		if fila.size() == COLUMNAS:
			filas.append(fila)
			fila = []
	if not fila.is_empty():
		filas.append(fila)
	var ran: Control = botones_ranura[ranura]
	PiezaBoton.enlazar(filas, ran, b_equipar, null)
	var marcada := _boton_de(sel_uid)
	var hacia_lista: Control = marcada if marcada else b_equipar
	for r in botones_ranura:
		var b: Control = botones_ranura[r]
		b.focus_neighbor_bottom = b.get_path_to(hacia_lista)
	var izq: Control = marcada if marcada else ran
	b_equipar.focus_neighbor_left = b_equipar.get_path_to(izq)
	b_equipar.focus_neighbor_right = b_equipar.get_path_to(b_equipar)
	b_equipar.focus_neighbor_top = b_equipar.get_path_to(ran)
	b_equipar.focus_neighbor_bottom = b_equipar.get_path_to(b_mejorar)
	b_mejorar.focus_neighbor_left = b_mejorar.get_path_to(izq)
	b_mejorar.focus_neighbor_right = b_mejorar.get_path_to(b_mejorar)
	b_mejorar.focus_neighbor_top = b_mejorar.get_path_to(b_equipar)
	b_mejorar.focus_neighbor_bottom = b_mejorar.get_path_to(b_mejorar)


func _boton_de(uid: int) -> Control:
	for b in grid.get_children():
		if b.item.uid == uid:
			return b
	return null


func elegir_ranura(r: String) -> void:
	if ranura != r:
		Sonido.tocar("ui_mover")
	ranura = r
	var eq := Partida.equipado(r)
	sel_uid = eq.uid if not eq.is_empty() else -1
	_lista()
	refrescar()


## Enter o clic en una ranura: entra a su lista de piezas.
func pulsar_ranura(r: String) -> void:
	elegir_ranura(r)
	var marcada := _boton_de(sel_uid)
	if marcada:
		marcada.grab_focus()


func _lista() -> void:
	for h in grid.get_children():
		grid.remove_child(h)
		h.queue_free()
	for it in Partida.piezas_de(ranura):
		var b := PiezaBoton.new()
		b.item = it
		b.marcado = it.uid == sel_uid
		b.pressed.connect(_pulsar_pieza.bind(it.uid))
		b.focus_entered.connect(_elegir_pieza.bind(it.uid))
		grid.add_child(b)
		b.mouse_entered.connect(b.grab_focus)
	_enlazar_lista()


## Enter o clic en una pieza: se la pone.
func _pulsar_pieza(uid: int) -> void:
	_elegir_pieza(uid)
	if Partida.esta_equipado(uid):
		Sonido.tocar("ui_ok")
	else:
		_equipar()


func _elegir_pieza(uid: int) -> void:
	if sel_uid != uid:
		Sonido.tocar("ui_mover")
	sel_uid = uid
	for b in grid.get_children():
		b.marcado = b.item.uid == uid
		b.queue_redraw()
	_enlazar_lista()
	refrescar()


func refrescar() -> void:
	var it := Partida.item(sel_uid)
	var hay := not it.is_empty()
	var equipada := hay and Partida.esta_equipado(sel_uid)
	b_equipar.disabled = not hay or equipada
	b_equipar.text = "YA LA LLEVAS PUESTA" if equipada else "EQUIPAR"
	b_mejorar.disabled = true
	b_mejorar.text = "MEJORAR"
	if hay:
		if it.nivel >= Partida.nivel_max(it):
			b_mejorar.text = "NIVEL MÁXIMO"
		else:
			var c := Partida.costo_mejora(it)
			b_mejorar.text = "MEJORAR A NIVEL %d: %d CHATARRA" % [it.nivel + 1, c]
			b_mejorar.disabled = Partida.d.chatarra < c
	for r in botones_ranura:
		botones_ranura[r].queue_redraw()
	for b in grid.get_children():
		b.queue_redraw()
	info.queue_redraw()
	queue_redraw()


func _equipar() -> void:
	Partida.equipar(sel_uid)
	Sonido.tocar("mejora", 0.85)
	refrescar()
	cambio.emit()


func _mejorar() -> void:
	if Partida.mejorar(sel_uid):
		Sonido.tocar("mejora")
	else:
		Sonido.tocar("ui_no")
	refrescar()
	cambio.emit()
	if b_mejorar.disabled:
		b_equipar.grab_focus.call_deferred()


func _draw() -> void:
	UI.t(self, 4, 0, "Las piezas mejoran tu nave en todas las partidas. Elige una ranura y ponle la mejor.", UI.C_GRIS)
	var n: int = Partida.piezas_de(ranura).size()
	var que_da: String = Datos.QUE_DA_RANURA[ranura]
	var nombre: String = Datos.NOMBRE_RANURA[ranura]
	if n == 1:
		UI.t(self, 4, 87, "%s (da %s): solo tienes esta" % [nombre, que_da], UI.C_TEXTO)
	else:
		UI.t(self, 4, 87, "%s (da %s): tienes %d piezas" % [nombre, que_da, n], UI.C_TEXTO)
	if n <= COLUMNAS:
		UI.parrafo(self, 4, 150, "Las piezas caen al ganar niveles. Las mejores son más raras: mira el color del marco.", 240, UI.C_GRIS)
	UI.t(self, 4, 316, "E: la llevas puesta", UI.C_GRIS)


func _dibujar_info() -> void:
	var c := info
	UI.marco(c, Rect2(0, 0, 236, 246), UI.C_PANEL, UI.C_LINEA)
	var it := Partida.item(sel_uid)
	if it.is_empty():
		UI.t(c, 6, 4, "Elige una pieza de la lista.", UI.C_GRIS)
		return
	var d := Partida.def_de(it)
	var rar: Dictionary = Datos.RAREZAS[it.rareza]
	UI.t(c, 6, 0, d.nombre, rar.color)
	UI.t(c, 6, 13, "%s, nivel %d de %d" % [rar.nombre, it.nivel, Partida.nivel_max(it)], UI.C_GRIS)
	var y := UI.parrafo(c, 6, 27, PiezaBoton.sin_spoiler(d.desc), 224, UI.C_TEXTO) + 2
	# numeros y comparacion con lo que llevas puesto
	var st := Partida.stats_item(it)
	var eq := Partida.equipado(ranura)
	var st_eq := Partida.stats_item(eq) if not eq.is_empty() else {}
	for k in st:
		var nom: String = Datos.NOMBRE_STAT.get(k, k)
		UI.t(c, 6, y, PiezaBoton.sin_spoiler(nom), UI.C_GRIS)
		UI.t(c, 112, y, PiezaBoton.valor_stat(k, st[k]), UI.C_VERDE)
		if it.uid != eq.get("uid", -1) and st_eq.has(k):
			var dif: float = st[k] - st_eq[k]
			if k == "dash_cd":
				dif = -dif
			if absf(dif) > 0.0001:
				var txt := "(%s)" % _dif(k, dif)
				UI.t(c, 158, y, txt, UI.C_VERDE if dif > 0 else UI.C_ROJO)
		y += 13
	y += 3
	UI.t(c, 6, y, "Al fusionarla, va ganando:" if Partida.tiene("fusion") else "Con más rareza, va ganando:", UI.C_GRIS)
	y += 13
	for p in d.pasivas:
		var activa: bool = it.rareza >= p.r
		var rp: Dictionary = Datos.RAREZAS[p.r]
		c.draw_rect(Rect2(7, y + 4, 7, 7), rp.color if activa else rp.color.darkened(0.6))
		UI.t(c, 18, y, PiezaBoton.sin_spoiler(p.txt), UI.C_TEXTO if activa else Color("6a6488"))
		y += 13
	y = maxi(y + 2, 150)
	c.draw_texture(Datos.tex("obj_tuerca"), Vector2(6, y + 3))
	UI.t(c, 20, y, "Tienes %d de chatarra." % int(Partida.d.chatarra), UI.C_TEXTO)
	UI.parrafo(c, 6, y + 13, "Son las tuercas que sueltan los enemigos: suben el nivel de una pieza.", 224, UI.C_GRIS)


func _dif(k: String, v: float) -> String:
	var s := "+" if v > 0 else "-"
	var a := absf(v)
	if k in PiezaBoton.PORCENTAJES:
		return "%s%d %%" % [s, int(round(a * 100.0))]
	return "%s%d" % [s, int(round(a))]
