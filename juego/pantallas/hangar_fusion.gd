extends Control
## Estación FUSIONAR: tres piezas iguales entran y sale una mejor. Se ve antes de hacerlo, y siempre dice qué falta.

signal fusionada(iconos: Array, resultado: Dictionary, forma_antes: int, cuantas: int)

var elegidas: Array[int] = []
var scroll: ScrollContainer
var lienzo: Control
var botones: Array = []
var titulos := []
var b_fusionar: Button
var b_auto: Button
var tab_arriba: Control = null
var enfocada := -1
const CAJAS := [Vector2(6, 32), Vector2(66, 32), Vector2(126, 32)]
const CAJA_FINAL := Vector2(198, 32)
const TAM_CAJA := 44
const X_CELDAS := 52.0
const PASO := 38.0
const COLUMNAS := 11


func _ready() -> void:
	size = Vector2(490, 334)
	mouse_filter = Control.MOUSE_FILTER_PASS
	b_fusionar = UI.boton("FUSIONAR", Vector2(6, 80), Vector2(150, 22), self, _fusionar)
	b_fusionar.add_theme_color_override("font_color", UI.C_ORO)
	b_auto = UI.boton("AUTO-FUSIONAR TODO", Vector2(160, 80), Vector2(150, 22), self, _auto)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(2, 136)
	scroll.size = Vector2(486, 196)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	PiezaBoton.barra_visible(scroll)
	lienzo = Control.new()
	lienzo.mouse_filter = Control.MOUSE_FILTER_PASS
	lienzo.draw.connect(_dibujar_titulos)
	scroll.add_child(lienzo)
	_lista()
	refrescar()


func enfocar() -> void:
	if not botones.is_empty():
		botones[0].grab_focus()
	else:
		b_auto.grab_focus()


func conectar_tab(tab: Control) -> Control:
	tab_arriba = tab
	b_fusionar.focus_neighbor_top = b_fusionar.get_path_to(tab)
	b_auto.focus_neighbor_top = b_auto.get_path_to(tab)
	return b_auto if b_fusionar.disabled else b_fusionar


func _lista() -> void:
	for h in lienzo.get_children():
		lienzo.remove_child(h)
		h.queue_free()
	botones.clear()
	titulos.clear()
	var filas := []
	var y := 2.0
	for r in Partida.ranuras_visibles():
		var piezas: Array = Partida.piezas_de(r)
		if piezas.is_empty():
			continue
		titulos.append([y, Datos.NOMBRE_RANURA[r]])
		var fila := []
		for i in piezas.size():
			var b := PiezaBoton.new()
			b.item = piezas[i]
			b.position = Vector2(X_CELDAS + (i % COLUMNAS) * PASO, y + (i / COLUMNAS) * PASO)
			b.pressed.connect(_pulsar.bind(piezas[i].uid))
			b.focus_entered.connect(_enfocada.bind(piezas[i].uid))
			lienzo.add_child(b)
			b.mouse_entered.connect(b.grab_focus)
			botones.append(b)
			fila.append(b)
			if fila.size() == COLUMNAS:
				filas.append(fila)
				fila = []
		if not fila.is_empty():
			filas.append(fila)
		y += ceilf(float(piezas.size()) / COLUMNAS) * PASO + 2.0
	lienzo.custom_minimum_size = Vector2(X_CELDAS + COLUMNAS * PASO, y)
	lienzo.queue_redraw()
	# de la lista se sube a los botones, y de los botones se baja a la lista
	PiezaBoton.enlazar(filas, b_fusionar)
	if not botones.is_empty():
		for b in [b_fusionar, b_auto]:
			b.focus_neighbor_bottom = b.get_path_to(botones[0])
	else:
		for b in [b_fusionar, b_auto]:
			b.focus_neighbor_bottom = b.get_path_to(b)
	b_fusionar.focus_neighbor_left = b_fusionar.get_path_to(b_fusionar)
	b_fusionar.focus_neighbor_right = b_fusionar.get_path_to(b_auto)
	b_auto.focus_neighbor_left = b_auto.get_path_to(b_fusionar)
	b_auto.focus_neighbor_right = b_auto.get_path_to(b_auto)


func _dibujar_titulos() -> void:
	for ti in titulos:
		UI.t(lienzo, 2, ti[0] + 10, ti[1], UI.C_GRIS)


func _enfocada(uid: int) -> void:
	enfocada = uid
	queue_redraw()


func _grupo(it: Dictionary) -> int:
	var n := 0
	for o in Partida.d.inventario:
		if o.rareza == it.rareza and Partida.ranura_de(o) == Partida.ranura_de(it):
			n += 1
	return n


func _compatible(it: Dictionary) -> bool:
	if it.rareza >= Datos.RAREZAS.size() - 1 or _grupo(it) < Datos.FUSION_PIEZAS:
		return false
	if elegidas.is_empty():
		return true
	var base := Partida.item(elegidas[0])
	return Partida.ranura_de(it) == Partida.ranura_de(base) and it.rareza == base.rareza


func _pulsar(uid: int) -> void:
	var it := Partida.item(uid)
	if uid in elegidas:
		elegidas.erase(uid)
		Sonido.tocar("ui_mover")
	elif elegidas.size() < Datos.FUSION_PIEZAS and _compatible(it):
		# si eliges la que llevas puesta, ella es la base: nunca se pierde
		if Partida.esta_equipado(uid):
			elegidas.push_front(uid)
		else:
			elegidas.append(uid)
		Sonido.tocar("ui_ok")
	else:
		Sonido.tocar("ui_no")
	refrescar()
	if elegidas.size() == Datos.FUSION_PIEZAS:
		b_fusionar.grab_focus()


func refrescar() -> void:
	b_fusionar.disabled = elegidas.size() < Datos.FUSION_PIEZAS
	b_auto.disabled = not Partida.hay_fusiones()
	for b in botones:
		b.marcado = b.item.uid in elegidas
		b.apagado = not _compatible(b.item) and not b.marcado
		b.queue_redraw()
	queue_redraw()


func _fusionar() -> void:
	if elegidas.size() < Datos.FUSION_PIEZAS:
		return
	var base := elegidas[0]
	var otros: Array = elegidas.slice(1)
	var iconos := []
	for u in elegidas:
		iconos.append(Datos.tex("icono_" + Partida.item(u).id))
	var antes := Partida.forma_mascota()
	var r := Partida.fusionar_con(base, otros)
	elegidas.clear()
	if r.is_empty():
		Sonido.tocar("ui_no")
	else:
		fusionada.emit(iconos, r, antes, 1)
	_lista()
	refrescar()


func _auto() -> void:
	var antes := Partida.forma_mascota()
	var hechos := Partida.fusionar_todo()
	elegidas.clear()
	if hechos.is_empty():
		return
	var mejor: Dictionary = hechos[0]
	for h in hechos:
		if h.rareza > mejor.rareza:
			mejor = h
	var ic := Datos.tex("icono_" + mejor.id)
	fusionada.emit([ic, ic, ic], mejor, antes, hechos.size())
	_lista()
	refrescar()


## El grupo más cercano a juntar 3, para decirle al jugador cuánto le falta.
func _mas_cerca() -> Dictionary:
	var mejor := {}
	for r in Partida.ranuras_visibles():
		for k in Datos.RAREZAS.size() - 1:
			var n := 0
			for it in Partida.piezas_de(r):
				if it.rareza == k:
					n += 1
			if n > 0 and (mejor.is_empty() or n > mejor.n):
				mejor = {"n": n, "ranura": r, "rareza": k}
	return mejor


## Lo que hay que hacer ahora, según lo que llevas elegido.
func _instruccion() -> String:
	if not elegidas.is_empty():
		var base := Partida.item(elegidas[0])
		var nom := "%s, %s" % [Datos.NOMBRE_RANURA[Partida.ranura_de(base)], Datos.RAREZAS[base.rareza].nombre]
		match elegidas.size():
			1:
				return "Bien. Elige 2 más iguales: %s." % nom
			2:
				return "Elige 1 más: %s." % nom
		return "¡Listas! Aprieta FUSIONAR."
	if Partida.hay_fusiones():
		return "Elige una pieza que brille. Las oscuras todavía no tienen con quién juntarse."
	var c := _mas_cerca()
	if c.is_empty():
		return "Aún no tienes piezas. Caen al ganar niveles."
	return "Te faltan piezas. Lo más cerca: %s, %s, tienes %d de 3." % [Datos.NOMBRE_RANURA[c.ranura], Datos.RAREZAS[c.rareza].nombre, c.n]


func _draw() -> void:
	UI.t(self, 4, 0, "Junta 3 piezas del mismo tipo y el mismo color: sale una del color siguiente.", UI.C_GRIS)
	_dibujar_escalera()
	for i in 3:
		var q: Vector2 = CAJAS[i]
		var r := Rect2(q, Vector2(TAM_CAJA, TAM_CAJA))
		if i < elegidas.size():
			var it := Partida.item(elegidas[i])
			if not it.is_empty():
				UI.pieza(self, q, TAM_CAJA, it)
		else:
			UI.marco(self, r, Color("15112a"), UI.C_LINEA)
			UI.tc(self, q.x + TAM_CAJA / 2.0, q.y + 14, "?", Color("3a3458"))
		if i < 2:
			UI.tc(self, q.x + TAM_CAJA + 8, q.y + 14, "+", UI.C_TEXTO)
	UI.tc(self, CAJA_FINAL.x - 14, CAJA_FINAL.y + 14, "=", UI.C_TEXTO)
	_dibujar_resultado()
	UI.t(self, 4, 104, _instruccion(), UI.C_TEXTO)
	var it2 := Partida.item(enfocada)
	if not it2.is_empty():
		var rar: Dictionary = Datos.RAREZAS[it2.rareza]
		var txt := "%s: %s, nivel %d" % [Partida.def_de(it2).nombre, rar.nombre, it2.nivel]
		if Partida.esta_equipado(it2.uid):
			txt += ". La llevas puesta."
		UI.t(self, 4, 118, txt, rar.color)


## Los colores, de peor a mejor: así se entiende a qué sube cada pieza.
func _dibujar_escalera() -> void:
	var x := 4.0
	for i in Datos.RAREZAS.size():
		var rar: Dictionary = Datos.RAREZAS[i]
		draw_rect(Rect2(x, 19, 8, 8), rar.color)
		UI.t(self, x + 10, 14, rar.nombre, UI.C_GRIS)
		x += 10.0 + UI.ancho(rar.nombre) + 4.0
		if i + 1 < Datos.RAREZAS.size():
			UI.t(self, x, 14, ">", Color("6a6488"))
			x += UI.ancho(">") + 4.0


func _dibujar_resultado() -> void:
	var r := Rect2(CAJA_FINAL, Vector2(TAM_CAJA, TAM_CAJA))
	var x := CAJA_FINAL.x + TAM_CAJA + 8
	if elegidas.is_empty():
		UI.marco(self, r, Color("15112a"), UI.C_ORO)
		UI.tc(self, r.position.x + TAM_CAJA / 2.0, r.position.y + 14, "?", UI.C_ORO)
		var quien := Partida.nombre_mascota()
		var txt := "%s se las come y escupe la nueva. Cada fusión le da experiencia." % quien if quien != "" else "Entran tres piezas y sale una mejor."
		UI.parrafo(self, x, 32, txt, 236, UI.C_GRIS)
		return
	var base := Partida.item(elegidas[0])
	var nueva_rareza: int = base.rareza + 1
	var futura: Dictionary = base.duplicate()
	futura.rareza = nueva_rareza
	UI.pieza(self, CAJA_FINAL, TAM_CAJA, futura)
	var rar: Dictionary = Datos.RAREZAS[nueva_rareza]
	UI.t(self, x, 30, Partida.def_de(base).nombre, rar.color)
	UI.t(self, x, 43, "Pasa a " + rar.nombre, rar.color)
	var y := 56
	for p in Partida.def_de(base).pasivas:
		if p.r == nueva_rareza:
			UI.t(self, x, y, "Nuevo: " + PiezaBoton.sin_spoiler(p.txt), UI.C_VERDE)
			y += 13
	var inv := 0
	for u in elegidas.slice(1):
		inv += int(Partida.item(u).invertido)
	if inv > 0:
		UI.t(self, x, y, "Te devuelve %d de chatarra" % inv, UI.C_GRIS)
