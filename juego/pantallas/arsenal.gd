extends Control
## El Arsenal: el inventario de desbloqueos, como el de Megabonk. Aquí se ve qué existe, qué falta por ganar
## y cómo, y qué se puede prender o apagar. Lo base siempre sale; lo ganado se prende o se apaga.

const PESTANAS := ["armas", "habs", "piezas", "desafios"]
const NOMBRES := {"armas": "ARMAS", "habs": "HABILIDADES", "piezas": "PIEZAS", "desafios": "DESAFÍOS"}
const COLUMNAS := 7
const TAM := 36
const PASO := 38
const Y_CUERPO := 42.0
const ALTO_CUERPO := 290.0
const X_FICHA := 278.0
const ANCHO_FICHA := 210.0
const ANCHO_LISTA := 274.0
const ANCHO_FILA := 470.0
const ALTO_FILA := 36.0
## Dónde empieza el bloque de abajo de la ficha: cómo ganarlo o prenderlo.
const Y_BLOQUE := 228.0

var pestana := "armas"
var tabs := {}
var scroll: ScrollContainer
var lienzo: Control
var celdas := {}
var filas := []
var titulos := []
var sel := ""
var sel_de := {}
var ficha: Control
var b_alternar: Button
var tab_arriba: Control = null
var parpadeo := 0.0
var y_fin := 0.0


## Un cuadrito de arma, habilidad o pieza. Su aspecto dice en qué estado está.
class Celda extends Button:
	var id := ""
	var a

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(TAM, TAM)
		size = Vector2(TAM, TAM)
		var vacio := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, vacio)
		focus_entered.connect(a.seleccionar.bind(id))
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)
		pressed.connect(a.pulsar.bind(id))

	func _draw() -> void:
		var r := Rect2(0, 0, TAM, TAM)
		var st: String = a.estado(id)
		var tx: Texture2D = Datos.tex("icono_" + id)
		var o := (Vector2(TAM, TAM) - Vector2(tx.get_size())) / 2.0
		match st:
			"base", "cae":
				UI.marco(self, r, UI.C_PANEL2, UI.C_LINEA)
				draw_texture(tx, o)
			"on":
				UI.marco(self, r, Color("17331f"), UI.C_VERDE)
				draw_texture(tx, o)
				_tilde()
			"off":
				UI.marco(self, r, Color("15112a"), Color("4a4560"))
				draw_texture(tx, o, Color(0.4, 0.4, 0.45, 0.7))
				draw_line(Vector2(3, 3), Vector2(TAM - 3, TAM - 3), UI.C_ROJO, 1.0)
				draw_line(Vector2(TAM - 3, 3), Vector2(3, TAM - 3), UI.C_ROJO, 1.0)
			"bloqueado", "no_cae":
				UI.marco(self, r, UI.C_PANEL2, Color("2a2448"))
				draw_texture(tx, o, Color(0, 0, 0, 1))
				draw_texture(Datos.tex("ui_candado"), Vector2(TAM - 14, TAM - 12))
			_:
				UI.marco(self, r, Color("15112a"), Color("2a2448"))
				UI.tc(self, TAM / 2.0, 10, "?", UI.C_GRIS)
		if has_focus():
			draw_rect(r.grow(-1), Color.WHITE, false, 1.0)
			draw_rect(r.grow(-2), UI.C_ORO, false, 1.0)

	func _tilde() -> void:
		draw_rect(Rect2(TAM - 11, 1, 10, 10), UI.C_VERDE)
		draw_polyline(PackedVector2Array([Vector2(TAM - 9, 6), Vector2(TAM - 7, 8), Vector2(TAM - 3, 3)]), Color("0d0a18"), 1.0)


## Una fila de la lista de desafíos.
class Fila extends Button:
	var de := {}
	var a
	var spr: Sprite2D = null

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(ANCHO_FILA, ALTO_FILA - 2.0)
		size = custom_minimum_size
		var vacio := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, vacio)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)
		if de.premio.tipo == "nave" and Partida.desafio_visible(de):
			spr = Sprite2D.new()
			spr.region_enabled = true
			spr.region_rect = Rect2(4 * 48, 0, 48, 48)
			spr.texture = Datos.tex("nave2_" + de.premio.id)
			if a.premio_en_silueta(de):
				# sin el shader de pintura, para que la silueta quede negra entera
				spr.modulate = Color(0, 0, 0, 1)
			else:
				var mat := ShaderMaterial.new()
				mat.shader = load("res://arte/nave.gdshader")
				Partida.preparar_material(mat, de.premio.id)
				spr.material = mat
			spr.position = Vector2(18, 17)
			add_child(spr)

	func _draw() -> void:
		var alto := ALTO_FILA - 2.0
		var r := Rect2(0, 0, ANCHO_FILA, alto)
		var ve := Partida.desafio_visible(de)
		var hecho := Partida.desafio_hecho(de.id)
		UI.marco(self, r, Color("17331f") if hecho else UI.C_PANEL, UI.C_VERDE if hecho else UI.C_LINEA)
		if has_focus():
			draw_rect(r, UI.C_ORO, false, 1.0)
			draw_rect(r.grow(-1), UI.C_ORO, false, 1.0)
		if not ve:
			UI.tc(self, 18, 9, "?", UI.C_GRIS)
			UI.t(self, 38, 1, "???", UI.C_GRIS)
			UI.t(self, 38, 16, "Se revela más adelante.", Color("6a6488"))
			return
		var silueta: bool = a.premio_en_silueta(de)
		a.dibujar_premio(self, de, Vector2(2, 1), silueta)
		if silueta:
			draw_texture(Datos.tex("ui_candado"), Vector2(24, 21))
		UI.t(self, 38, 1, de.txt, UI.C_VERDE if hecho else UI.C_TEXTO)
		UI.t(self, 38, 16, "Premio: " + a.nombre_premio(de), UI.C_GRIS)
		var v: int = mini(Partida.valor_stat(de.stat), de.meta)
		var x := ANCHO_FILA - 126.0
		if hecho:
			UI.t(self, ANCHO_FILA - 8.0 - UI.ancho("¡Hecho!"), 9, "¡Hecho!", UI.C_VERDE)
		else:
			UI.barra(self, Rect2(x, 5, 118, 9), float(v) / float(de.meta), UI.C_ORO)
			var txt: String = a.progreso(de)
			UI.t(self, ANCHO_FILA - 8.0 - UI.ancho(txt), 15, txt, UI.C_GRIS)


func _ready() -> void:
	size = Vector2(490, 334)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var i := 0
	for p in PESTANAS:
		var b := Button.new()
		b.position = Vector2(4 + i * 121.0, 17)
		b.custom_minimum_size = Vector2(118, 22)
		b.focus_mode = Control.FOCUS_ALL
		add_child(b)
		b.size = Vector2(118, 22)
		b.focus_entered.connect(elegir_pestana.bind(p))
		b.pressed.connect(_pulsar_tab.bind(p))
		tabs[p] = b
		i += 1
	scroll = ScrollContainer.new()
	scroll.position = Vector2(2, Y_CUERPO)
	scroll.size = Vector2(ANCHO_LISTA, ALTO_CUERPO)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	PiezaBoton.barra_visible(scroll)
	lienzo = Control.new()
	lienzo.mouse_filter = Control.MOUSE_FILTER_PASS
	lienzo.draw.connect(_dibujar_titulos)
	scroll.add_child(lienzo)
	ficha = Control.new()
	ficha.position = Vector2(X_FICHA, Y_CUERPO)
	ficha.size = Vector2(ANCHO_FICHA, ALTO_CUERPO)
	ficha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ficha.draw.connect(_dibujar_ficha)
	add_child(ficha)
	b_alternar = UI.boton("APAGAR", Vector2(X_FICHA + 8.0, Y_CUERPO + ALTO_CUERPO - 30.0), Vector2(ANCHO_FICHA - 16.0, 24), self, func(): pulsar(sel))
	b_alternar.focus_mode = Control.FOCUS_NONE
	_armar()


func enfocar() -> void:
	if celdas.has(sel):
		celdas[sel].grab_focus()
	elif not filas.is_empty():
		filas[0][0].grab_focus()
	else:
		tabs[pestana].grab_focus()


func conectar_tab(tab: Control) -> Control:
	tab_arriba = tab
	_enlazar_tabs()
	return tabs[pestana]


func _enlazar_tabs() -> void:
	var destino: Control = filas[0][0] if not filas.is_empty() else null
	for i in PESTANAS.size():
		var b: Button = tabs[PESTANAS[i]]
		b.focus_neighbor_left = b.get_path_to(tabs[PESTANAS[i - 1]] if i > 0 else b)
		b.focus_neighbor_right = b.get_path_to(tabs[PESTANAS[i + 1]] if i + 1 < PESTANAS.size() else b)
		b.focus_neighbor_top = b.get_path_to(tab_arriba if tab_arriba else b)
		b.focus_neighbor_bottom = b.get_path_to(destino if destino else b)


func elegir_pestana(p: String) -> void:
	if p == pestana:
		return
	Sonido.tocar("ui_mover")
	pestana = p
	sel = ""
	_armar()


func _pulsar_tab(p: String) -> void:
	elegir_pestana(p)
	enfocar()


# =================================================================================================
# ARMAR LA LISTA DE CADA PESTAÑA
# =================================================================================================
func _armar() -> void:
	for h in lienzo.get_children():
		lienzo.remove_child(h)
		h.queue_free()
	celdas.clear()
	filas.clear()
	titulos.clear()
	var lista: bool = pestana == "desafios"
	ficha.visible = not lista
	scroll.size.x = 486.0 if lista else ANCHO_LISTA
	var y := 1.0
	match pestana:
		"armas":
			y = _armar_cosas(Datos.ARMAS.keys(), y)
		"habs":
			y = _armar_cosas(Datos.HABILIDADES.keys(), y)
		"piezas":
			y = _armar_piezas(y)
		"desafios":
			y = _armar_desafios(y)
	lienzo.custom_minimum_size = Vector2(ANCHO_FILA + 2.0 if lista else COLUMNAS * PASO + 2.0, y)
	lienzo.queue_redraw()
	_enlazar_celdas()
	_enlazar_tabs()
	scroll.scroll_vertical = 0
	if not lista:
		var primero: String = filas[0][0].id if not filas.is_empty() else ""
		seleccionar(primero)
	_textos_tabs()
	_refrescar()


## Armas y habilidades: base, ganadas y por ganar, cada grupo con su título.
func _armar_cosas(ids: Array, y: float) -> float:
	var base := []
	var ganadas := []
	var faltan := []
	var ocultas := []
	for id in ids:
		match estado(id):
			"base":
				base.append(id)
			"on", "off":
				ganadas.append(id)
			"oculto":
				ocultas.append(id)
			_:
				faltan.append(id)
	y = _grupo("BASE: SIEMPRE PUEDEN SALIR", UI.C_GRIS, base, y)
	if ganadas.is_empty():
		titulos.append([y, "GANADAS: todavía ninguna. Cumple un desafío.", UI.C_GRIS])
		y += 20.0
	else:
		y = _grupo("GANADAS: ENTER O CLIC PRENDE O APAGA", UI.C_VERDE, ganadas, y)
	faltan.append_array(ocultas)
	return _grupo("POR GANAR", UI.C_ORO, faltan, y)


## Piezas: las que ya caen y, después, las que vienen, agrupadas por cuándo empiezan a caer.
func _armar_piezas(y: float) -> float:
	var ya := []
	var por_nivel := {}
	var por_mundo := {}
	var ocultas := []
	for id in Datos.ITEMS:
		var it: Dictionary = Datos.ITEMS[id]
		match estado(id):
			"cae":
				ya.append(id)
			"oculto":
				ocultas.append(id)
			_:
				if it.get("mundo", 1) - 1 > Partida.mundo_alcanzado():
					var m: int = it.mundo
					if not por_mundo.has(m):
						por_mundo[m] = []
					por_mundo[m].append(id)
				else:
					var n: String = it.desde
					if not por_nivel.has(n):
						por_nivel[n] = []
					por_nivel[n].append(id)
	y = _grupo("YA ESTÁN CAYENDO", UI.C_VERDE, ya, y)
	for n in Datos.ORDEN_NIVELES:
		if por_nivel.has(n):
			y = _grupo("CAEN DESDE EL NIVEL %s" % n, UI.C_ORO, por_nivel[n], y)
	var mundos: Array = por_mundo.keys()
	mundos.sort()
	for m in mundos:
		y = _grupo("LLEGAN CON EL MUNDO %d" % m, UI.C_GRIS, por_mundo[m], y)
	return _grupo("MÁS ADELANTE", UI.C_GRIS, ocultas, y)


func _grupo(titulo: String, color: Color, ids: Array, y: float) -> float:
	if ids.is_empty():
		return y
	titulos.append([y, "%s (%d)" % [titulo, ids.size()], color])
	y += 15.0
	var fila := []
	for i in ids.size():
		var c := Celda.new()
		c.id = ids[i]
		c.a = self
		c.position = Vector2(2.0 + (i % COLUMNAS) * PASO, y + (i / COLUMNAS) * PASO)
		lienzo.add_child(c)
		celdas[ids[i]] = c
		fila.append(c)
		if fila.size() == COLUMNAS:
			filas.append(fila)
			fila = []
	if not fila.is_empty():
		filas.append(fila)
	return y + ceilf(float(ids.size()) / COLUMNAS) * PASO + 4.0


## Los desafíos, los más cerca de cumplirse primero. Al final, los que no se ven y los ya hechos.
func _armar_desafios(y: float) -> float:
	var lista: Array = Datos.DESAFIOS.duplicate()
	lista.sort_custom(func(a, b):
		var ga := _grupo_desafio(a)
		var gb := _grupo_desafio(b)
		if ga != gb:
			return ga < gb
		var pa := _cercania(a)
		var pb := _cercania(b)
		if not is_equal_approx(pa, pb):
			return pa > pb
		return a.meta < b.meta)
	for de in lista:
		var f := Fila.new()
		f.de = de
		f.a = self
		f.position = Vector2(2, y)
		lienzo.add_child(f)
		filas.append([f])
		y += ALTO_FILA
	return y


func _grupo_desafio(de: Dictionary) -> int:
	if Partida.desafio_hecho(de.id):
		return 2
	return 0 if Partida.desafio_visible(de) else 1


func _cercania(de: Dictionary) -> float:
	return float(mini(Partida.valor_stat(de.stat), de.meta)) / float(de.meta)


func _enlazar_celdas() -> void:
	PiezaBoton.enlazar(filas, tabs[pestana])


func _textos_tabs() -> void:
	for p in PESTANAS:
		var b: Button = tabs[p]
		b.text = "%s %s" % [NOMBRES[p], _cuenta(p)]
		var marcada: bool = p == pestana
		b.add_theme_color_override("font_color", UI.C_ORO if marcada else UI.C_GRIS)
		var st := StyleBoxFlat.new()
		st.bg_color = UI.C_PANEL2 if marcada else Color("15112a")
		st.border_color = UI.C_ORO if marcada else UI.C_LINEA
		st.set_border_width_all(1)
		st.content_margin_bottom = 2
		b.add_theme_stylebox_override("normal", st)


## Cuánto de cada cosa tienes: se ve de un vistazo lo que falta.
func _cuenta(p: String) -> String:
	var n := 0
	match p:
		"armas":
			for id in Datos.ARMAS:
				if Partida.arma_desbloqueada(id):
					n += 1
			return "%d/%d" % [n, Datos.ARMAS.size()]
		"habs":
			for id in Datos.HABILIDADES:
				if Partida.hab_desbloqueada(id):
					n += 1
			return "%d/%d" % [n, Datos.HABILIDADES.size()]
		"piezas":
			for id in Datos.ITEMS:
				if Partida.pieza_abierta(id):
					n += 1
			return "%d/%d" % [n, Datos.ITEMS.size()]
	return "%d/%d" % [Partida.d.desafios.size(), Datos.DESAFIOS.size()]


func _dibujar_titulos() -> void:
	for ti in titulos:
		UI.t(lienzo, 2, ti[0], ti[1], ti[2])


# =================================================================================================
# ESTADO DE CADA COSA
# =================================================================================================
## base: siempre sale. on/off: ganada, prendida o apagada. bloqueado: se ve en silueta. oculto: no se muestra aún.
## Piezas: cae, no_cae, oculto.
func estado(id: String) -> String:
	match pestana:
		"armas":
			if Partida.es_base_arma(id):
				return "base"
			if id in Partida.d.armas:
				return "off" if Partida.esta_apagado(id) else "on"
			return _bloqueo("arma", id)
		"habs":
			if Partida.es_base_hab(id):
				return "base"
			if id in Partida.d.habs:
				return "off" if Partida.esta_apagado(id) else "on"
			var h: Dictionary = Datos.HABILIDADES[id]
			if h.get("requiere", "") != "" and not Partida.tiene(h.requiere):
				return "oculto"
			return _bloqueo("hab", id)
		"piezas":
			var it: Dictionary = Datos.ITEMS[id]
			if it.ranura == "reactor" and not Partida.tiene("desync"):
				return "oculto"
			return "cae" if Partida.pieza_abierta(id) else "no_cae"
	return "oculto"


func _bloqueo(tipo: String, id: String) -> String:
	var de := Partida.desafio_de(tipo, id)
	if not de.is_empty() and not Partida.desafio_visible(de):
		return "oculto"
	return "bloqueado"


func seleccionar(id: String) -> void:
	if sel != id and sel != "":
		Sonido.tocar("ui_mover")
	sel = id
	_refrescar()


## Enter o clic: prende o apaga lo ganado. Lo demás avisa por qué no se puede.
func pulsar(id: String) -> void:
	seleccionar(id)
	match estado(id):
		"on":
			Partida.alternar(id)
			Sonido.tocar("ui_ok", 0.8)
		"off":
			Partida.alternar(id)
			Sonido.tocar("mejora", 1.1)
		_:
			Sonido.tocar("ui_no")
			parpadeo = 1.0
	_refrescar()


func _refrescar() -> void:
	var st: String = estado(sel) if sel != "" else ""
	b_alternar.visible = st == "on" or st == "off"
	b_alternar.text = "APAGAR" if st == "on" else "PRENDER"
	for k in celdas:
		celdas[k].queue_redraw()
	ficha.queue_redraw()
	queue_redraw()


func _process(delta: float) -> void:
	if parpadeo > 0.0:
		parpadeo = maxf(parpadeo - delta * 2.5, 0.0)
		ficha.queue_redraw()


# =================================================================================================
# LA FICHA DE LA DERECHA
# =================================================================================================
func _dibujar_ficha() -> void:
	var c := ficha
	UI.marco(c, Rect2(0, 0, ANCHO_FICHA, ALTO_CUERPO), UI.C_PANEL, UI.C_LINEA)
	y_fin = 0.0
	if sel == "":
		return
	var st := estado(sel)
	if st == "oculto":
		_ficha_oculta(c)
		return
	match pestana:
		"armas":
			_ficha_arma(c, st)
		"habs":
			_ficha_hab(c, st)
		"piezas":
			_ficha_pieza(c, st)


func _ficha_oculta(c: Control) -> void:
	UI.marco(c, Rect2(6, 6, TAM, TAM), Color("15112a"), Color("2a2448"))
	UI.tc(c, 6 + TAM / 2.0, 16, "?", UI.C_GRIS)
	UI.t(c, 48, 6, "???", UI.C_GRIS, 2, true)
	UI.parrafo(c, 8, 52, "Todavía no te lo podemos contar. Se revela más adelante.", ANCHO_FICHA - 16.0, UI.C_GRIS)


## El encabezado: icono, nombre y qué es. Devuelve la y siguiente.
func _cabeza(c: Control, st: String, nombre: String, que_es: String) -> float:
	var tx: Texture2D = Datos.tex("icono_" + sel)
	var bloqueado := st == "bloqueado" or st == "no_cae"
	UI.marco(c, Rect2(6, 6, TAM, TAM), UI.C_PANEL2, UI.C_LINEA)
	c.draw_texture(tx, Vector2(6, 6) + (Vector2(TAM, TAM) - Vector2(tx.get_size())) / 2.0, Color(0, 0, 0, 1) if bloqueado else Color.WHITE)
	var col: Color = UI.C_GRIS if bloqueado else UI.C_ORO
	var y := 4.0
	for lin in UI.partir(nombre, ANCHO_FICHA - 54.0):
		UI.t(c, 48, y, lin, col)
		y += 14.0
	UI.t(c, 48, y, que_es, UI.C_GRIS)
	return maxf(y + 16.0, 46.0)


func _ficha_arma(c: Control, st: String) -> void:
	var def: Dictionary = Datos.ARMAS[sel]
	var y := _cabeza(c, st, def.nombre, "Arma")
	y = UI.parrafo(c, 8, y, PiezaBoton.sin_spoiler(def.desc), ANCHO_FICHA - 16.0, UI.C_TEXTO) + 4.0
	UI.t(c, 8, y, "CÓMO EVOLUCIONA", UI.C_ROSA)
	y += 14.0
	var hab := _nombre_visible_hab(def.sinergia)
	y = UI.parrafo(c, 8, y, "Con el arma a nivel %d y la habilidad %s, se vuelve:" % [Datos.NIVEL_MAX_CARTA, hab], ANCHO_FICHA - 16.0, UI.C_TEXTO)
	UI.t(c, 8, y, def.evo.nombre, UI.C_CIAN)
	y += 14.0
	y = UI.parrafo(c, 8, y, PiezaBoton.sin_spoiler(def.evo.desc), ANCHO_FICHA - 16.0, UI.C_GRIS)
	_bloque_estado(c, st, "arma", y, "Puede salir en las cartas.", "No saldrá en las cartas.")


func _ficha_hab(c: Control, st: String) -> void:
	var def: Dictionary = Datos.HABILIDADES[sel]
	var maximo: int = Datos.max_hab(sel)
	var y := _cabeza(c, st, def.nombre, "Habilidad, hasta nivel %d" % maximo)
	y = UI.parrafo(c, 8, y, PiezaBoton.sin_spoiler(def.desc), ANCHO_FICHA - 16.0, UI.C_TEXTO) + 4.0
	UI.t(c, 8, y, "CADA NIVEL", UI.C_ROSA)
	y += 14.0
	y = UI.parrafo(c, 8, y, PiezaBoton.sin_spoiler(def.por_nivel), ANCHO_FICHA - 16.0, UI.C_TEXTO) + 4.0
	var arma := Datos.arma_con_sinergia(sel)
	if arma != "":
		UI.t(c, 8, y, "HACE EVOLUCIONAR", UI.C_ROSA)
		y += 14.0
		var nom: String = Datos.ARMAS[arma].nombre if Partida.arma_desbloqueada(arma) or _bloqueo("arma", arma) != "oculto" else "???"
		y = UI.parrafo(c, 8, y, "%s, que se vuelve %s. Si llevas esa arma, puede salir aunque no la hayas ganado." % [nom, Datos.ARMAS[arma].evo.nombre], ANCHO_FICHA - 16.0, UI.C_GRIS)
	_bloque_estado(c, st, "hab", y, "Puede salir en las cartas.", "Solo saldrá si llevas su arma." if arma != "" else "No saldrá en las cartas.")


func _ficha_pieza(c: Control, st: String) -> void:
	var def: Dictionary = Datos.ITEMS[sel]
	var y := _cabeza(c, st, def.nombre, "%s: da %s" % [Datos.NOMBRE_RANURA[def.ranura], Datos.QUE_DA_RANURA[def.ranura]])
	y = UI.parrafo(c, 8, y, PiezaBoton.sin_spoiler(def.desc), ANCHO_FICHA - 16.0, UI.C_TEXTO) + 4.0
	UI.t(c, 8, y, "AL FUSIONARLA, VA GANANDO", UI.C_ROSA)
	y += 14.0
	for p in def.pasivas:
		var rp: Dictionary = Datos.RAREZAS[p.r]
		c.draw_rect(Rect2(9, y + 4, 7, 7), rp.color)
		UI.t(c, 20, y, PiezaBoton.sin_spoiler(p.txt), UI.C_TEXTO)
		y += 13.0
	y_fin = y
	var yb := Y_BLOQUE + 14.0
	if st == "cae":
		UI.t(c, 8, yb, "YA ESTÁ CAYENDO", UI.C_VERDE)
		var n := 0
		for it in Partida.d.inventario:
			if it.id == sel:
				n += 1
		UI.t(c, 8, yb + 14.0, "Tienes %d." % n if n > 0 else "Todavía no te sale ninguna.", UI.C_GRIS)
	else:
		UI.t(c, 8, yb, "CUÁNDO EMPIEZA A CAER", UI.C_ORO)
		var cuando: String = "Con el Mundo %d." % def.mundo if def.mundo - 1 > Partida.mundo_alcanzado() else "Desde el nivel %s." % def.desde
		UI.t(c, 8, yb + 14.0, cuando, UI.C_TEXTO)
	_marco_parpadeo(c)


## El nombre de una habilidad, salvo que todavía sea secreta.
func _nombre_visible_hab(id: String) -> String:
	var h: Dictionary = Datos.HABILIDADES[id]
	if h.get("requiere", "") != "" and not Partida.tiene(h.requiere):
		return "???"
	return h.nombre


## Lo de abajo de la ficha: si siempre sale, si está prendida, o cómo se gana.
func _bloque_estado(c: Control, st: String, tipo: String, y: float, txt_on: String, txt_off: String) -> void:
	y_fin = y
	var yb := Y_BLOQUE
	match st:
		"base":
			UI.t(c, 8, yb, "BASE: SIEMPRE SALE", UI.C_ORO)
			UI.t(c, 8, yb + 14.0, "No se puede apagar.", UI.C_GRIS)
		"on":
			c.draw_rect(Rect2(8, yb + 4, 8, 8), UI.C_VERDE)
			UI.t(c, 20, yb, "PRENDIDA", UI.C_VERDE)
			UI.t(c, 8, yb + 14.0, txt_on, UI.C_GRIS)
		"off":
			c.draw_rect(Rect2(8, yb + 4, 8, 8), UI.C_ROJO)
			UI.t(c, 20, yb, "APAGADA", UI.C_ROJO)
			UI.t(c, 8, yb + 14.0, txt_off, UI.C_GRIS)
		"bloqueado":
			var de := Partida.desafio_de(tipo, sel)
			UI.t(c, 8, yb, "CÓMO SE GANA", UI.C_ORO)
			if de.is_empty():
				UI.t(c, 8, yb + 14.0, "Llega con un mundo nuevo.", UI.C_TEXTO)
			else:
				var ya: float = UI.parrafo(c, 8, yb + 14.0, de.txt, ANCHO_FICHA - 16.0, UI.C_TEXTO)
				UI.barra(c, Rect2(8, ya + 4.0, 110, 9), _cercania(de), UI.C_ORO)
				UI.t(c, 124, ya, progreso(de), UI.C_GRIS)
	_marco_parpadeo(c)


## Si aprietas lo que no se puede, parpadea donde dice por qué.
func _marco_parpadeo(c: Control) -> void:
	if parpadeo > 0.0:
		var col := UI.C_ORO
		col.a = parpadeo
		c.draw_rect(Rect2(3, Y_BLOQUE - 2.0, ANCHO_FICHA - 6.0, ALTO_CUERPO - Y_BLOQUE - 1.0), col, false, 1.0)


# =================================================================================================
# LO QUE SE DIBUJA ARRIBA Y AYUDAS DE LOS DESAFÍOS
# =================================================================================================
func _draw() -> void:
	match pestana:
		"armas":
			_ranuras("Armas por partida", Partida.max_armas(), Datos.TOPE_ARMAS, "ranura_arma")
		"habs":
			_ranuras("Habilidades por partida", Partida.max_habs(), Datos.TOPE_HABS, "ranura_hab")
		"piezas":
			UI.t(self, 4, 0, "Las piezas caen al ganar niveles. Mientras más avanzas, más tipos caen.", UI.C_GRIS)
		"desafios":
			UI.t(self, 4, 0, "Cada desafío cumplido da un premio para siempre. Primero, los que tienes más cerca.", UI.C_GRIS)


## Cuántas ranuras tienes, y qué falta para la que sigue.
func _ranuras(nombre: String, n: int, tope: int, tipo: String) -> void:
	for i in tope:
		var r := Rect2(4 + i * 12, 3, 10, 10)
		if i < n:
			draw_rect(r, UI.C_ORO)
		else:
			draw_rect(r, Color("15112a"))
			draw_rect(r, UI.C_LINEA, false, 1.0)
	var x := 8.0 + tope * 12.0
	var txt := "%s: %d de %d." % [nombre, n, tope]
	UI.t(self, x, 0, txt, UI.C_TEXTO)
	x += UI.ancho(txt) + 6.0
	for de in Datos.DESAFIOS:
		if de.premio.tipo == tipo and not Partida.desafio_hecho(de.id):
			UI.t(self, x, 0, "La siguiente: %s (%s)" % [de.txt.to_lower(), progreso(de)], UI.C_GRIS)
			return
	UI.t(self, x, 0, "Ya tienes todas.", UI.C_VERDE)


func progreso(de: Dictionary) -> String:
	var v: int = mini(Partida.valor_stat(de.stat), de.meta)
	if de.stat == "inf_seg":
		return "%d:%02d/%d:%02d" % [v / 60, v % 60, de.meta / 60, de.meta % 60]
	return "%s/%s" % [_miles(v), _miles(de.meta)]


func _miles(n: int) -> String:
	var s := str(n)
	return s.substr(0, s.length() - 3) + "." + s.substr(s.length() - 3) if n >= 1000 else s


func nombre_premio(de: Dictionary) -> String:
	var p: Dictionary = de.premio
	match p.tipo:
		"arma":
			return "arma, " + Datos.ARMAS[p.id].nombre
		"hab":
			return "habilidad, " + Datos.HABILIDADES[p.id].nombre
		"nave":
			return "nave, " + Datos.NAVES[p.id].nombre
		"mascota":
			return "mascota, " + Datos.MASCOTAS[p.id].nombre
		"ranura_arma":
			return "una ranura de arma más"
		"ranura_hab":
			return "una ranura de habilidad más"
	return ""


## Lo que todavía no ganas se ve como silueta, igual que en Armas y Habilidades: el desafío se lee,
## pero el premio guarda el misterio (M18). Las ranuras no esconden nada, así que se ven siempre.
func premio_en_silueta(de: Dictionary) -> bool:
	return not Partida.desafio_hecho(de.id) and not String(de.premio.tipo).begins_with("ranura")


func dibujar_premio(c: Control, de: Dictionary, pos: Vector2, silueta := false) -> void:
	var p: Dictionary = de.premio
	var col := Color(0, 0, 0, 1) if silueta else Color.WHITE
	match p.tipo:
		"arma", "hab":
			c.draw_texture(Datos.tex("icono_" + p.id), pos, col)
		"mascota":
			var tam: int = Partida.TAM_MASCOTA[0]
			c.draw_texture_rect_region(Datos.tex_mascota(p.id, 0), Rect2(pos + Vector2(5, 5), Vector2(tam, tam)), Rect2(0, 0, tam, tam), col)
		"ranura_arma":
			c.draw_texture(Datos.tex("icono_ranura_arma"), pos)
		"ranura_hab":
			c.draw_texture(Datos.tex("icono_ranura_hab"), pos)
		# la nave se dibuja con su pintura, en un Sprite2D de la fila
