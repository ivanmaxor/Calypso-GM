extends Control
## Estación MASCOTA: todas en una fila. Las que tienes, las que faltan en silueta y cómo se ganan, y las de
## otros mundos como "?". La demo muestra lo que hace cada una, con sus números de verdad.

signal cambio

const DEMO := Rect2(4, 70, 172, 158)
const TAM_CELDA := 46
const DURA_CICLO := 2.4

var sel := ""
var celdas := {}
var b_elegir: Button
var b_nombre: Button
var ocupado := false
var t := 0.0
var demo: Control
var nave: Sprite2D
var modal: Control = null
var campo: LineEdit = null
var tab_arriba: Control = null


class Celda extends Button:
	var id := ""
	var m

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(TAM_CELDA, TAM_CELDA)
		size = Vector2(TAM_CELDA, TAM_CELDA)
		var vacio := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, vacio)
		focus_entered.connect(m.seleccionar.bind(id))
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)
		pressed.connect(m.elegir.bind(id))

	func _draw() -> void:
		var r := Rect2(0, 0, TAM_CELDA, TAM_CELDA)
		var def: Dictionary = Datos.MASCOTAS[id]
		var es_sel: bool = m.sel == id
		var tiene := Partida.tiene_mascota(id)
		var otro_mundo: bool = def.sprite == ""
		UI.marco(self, r, UI.C_PANEL2 if not otro_mundo else Color("15112a"), UI.C_ORO if es_sel else (UI.C_LINEA if tiene else Color("2a2448")))
		if otro_mundo:
			UI.tc(self, TAM_CELDA / 2.0, 6, "?", UI.C_GRIS)
			# más chico que el resto: si no, "Mundo 2" no cabe en el cuadro
			var txt := "Mundo %d" % def.mundo
			var w: float = Datos.fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(Datos.fuente, Vector2(round((TAM_CELDA - w) / 2.0), 36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.C_GRIS)
		else:
			var tam := Partida.tam_mascota(id)
			var f: int = int(m.t * 6.0) % 4 if es_sel and tiene else 0
			var o := float(TAM_CELDA - tam) / 2.0
			draw_texture_rect_region(Datos.tex_mascota(id, Partida.forma_mascota(id)), Rect2(o, o, tam, tam), Rect2(f * tam, 0, tam, tam), Color.WHITE if tiene else Color(0, 0, 0, 1))
			if not tiene:
				draw_texture(Datos.tex("ui_candado"), Vector2(TAM_CELDA - 14, TAM_CELDA - 12))
		if Partida.mascota_activa() == id:
			draw_rect(Rect2(3, 3, 7, 7), UI.C_VERDE)
		if es_sel:
			draw_rect(r.grow(-1), UI.C_ORO, false, 1.0)


func _ready() -> void:
	size = Vector2(490, 334)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var i := 0
	for id in Datos.MASCOTAS:
		var c := Celda.new()
		c.id = id
		c.m = self
		c.position = Vector2(4 + i * (TAM_CELDA + 2), 18)
		add_child(c)
		celdas[id] = c
		i += 1
	sel = Partida.mascota_activa()
	if sel == "":
		sel = Datos.MASCOTAS.keys()[0]
	demo = Control.new()
	demo.position = DEMO.position
	demo.size = DEMO.size
	demo.clip_contents = true
	demo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	demo.draw.connect(_dibujar_demo)
	add_child(demo)
	nave = Sprite2D.new()
	nave.region_enabled = true
	var mat := ShaderMaterial.new()
	mat.shader = load("res://arte/nave.gdshader")
	nave.material = mat
	nave.texture = Datos.tex("nave2_" + Partida.nave_actual())
	Partida.preparar_material(mat, Partida.nave_actual())
	demo.add_child(nave)
	b_elegir = UI.boton("SALIR CON ELLA", Vector2(4, 232), Vector2(172, 22), self, func(): elegir(sel))
	b_nombre = UI.boton("CAMBIAR NOMBRE", Vector2(4, 258), Vector2(172, 22), self, _renombrar)
	_enlazar()
	seleccionar(sel)


func enfocar() -> void:
	celdas[sel].grab_focus()


func conectar_tab(tab: Control) -> Control:
	tab_arriba = tab
	_enlazar()
	return celdas[sel]


func _enlazar() -> void:
	var fila: Array = celdas.values()
	PiezaBoton.enlazar([fila], tab_arriba, null, b_elegir)
	b_elegir.focus_neighbor_left = b_elegir.get_path_to(b_elegir)
	b_elegir.focus_neighbor_right = b_elegir.get_path_to(b_elegir)
	b_elegir.focus_neighbor_bottom = b_elegir.get_path_to(b_nombre)
	b_nombre.focus_neighbor_left = b_nombre.get_path_to(b_nombre)
	b_nombre.focus_neighbor_right = b_nombre.get_path_to(b_nombre)
	b_nombre.focus_neighbor_top = b_nombre.get_path_to(b_elegir)
	b_nombre.focus_neighbor_bottom = b_nombre.get_path_to(b_nombre)
	b_elegir.focus_neighbor_top = b_elegir.get_path_to(celdas[sel])


func seleccionar(id: String) -> void:
	if sel != id:
		Sonido.tocar("ui_mover")
	sel = id
	t = 0.0
	_enlazar()
	_refrescar()


func _refrescar() -> void:
	var tiene := Partida.tiene_mascota(sel)
	var activa := Partida.mascota_activa() == sel
	b_elegir.disabled = not tiene or activa
	b_elegir.text = "YA SALES CON ELLA" if activa else ("SALIR CON ELLA" if tiene else "BLOQUEADA")
	b_nombre.disabled = not tiene
	for k in celdas:
		celdas[k].queue_redraw()
	nave.visible = Datos.MASCOTAS[sel].sprite != ""
	queue_redraw()


## Enter o clic: sales con esa, si la tienes.
func elegir(id: String) -> void:
	seleccionar(id)
	if not Partida.tiene_mascota(id):
		Sonido.tocar("ui_no")
		return
	if Partida.mascota_activa() != id:
		Partida.elegir_mascota(id)
		Sonido.tocar("mejora", 1.1)
		cambio.emit()
	else:
		Sonido.tocar("ui_ok")
	_refrescar()


func _process(delta: float) -> void:
	t += delta
	nave.region_rect = Rect2((4 + int(t * 8.0) % 2) * 48, 0, 48, 48)
	nave.position = _pos_nave() + Vector2(0, roundf(sin(t * 1.6) * 1.5))
	if celdas.has(sel):
		celdas[sel].queue_redraw()
	demo.queue_redraw()


func _pos_nave() -> Vector2:
	return Vector2(DEMO.size.x / 2.0 - 26.0, DEMO.size.y - 34.0)


func _pos_pet() -> Vector2:
	return Vector2(DEMO.size.x / 2.0 + 32.0, DEMO.size.y - 66.0 + roundf(sin(t * 2.3) * 2.0))


# =================================================================================================
# LA DEMO: lo que hace, según su "ia"
# =================================================================================================
func _dibujar_demo() -> void:
	var c := demo
	UI.marco(c, Rect2(Vector2.ZERO, DEMO.size), Color("1b1633"), UI.C_LINEA)
	var def: Dictionary = Datos.MASCOTAS[sel]
	if def.sprite == "":
		UI.tc(c, DEMO.size.x / 2.0, DEMO.size.y / 2.0 - 24.0, "?", UI.C_GRIS, 3, true)
		return
	var ciclo := fmod(t, DURA_CICLO)
	var accion := false
	match def.ia:
		"come":
			accion = _demo_come(c, ciclo)
		"chispa":
			accion = _demo_chispa(c, ciclo)
		"iman":
			accion = _demo_iman(c, ciclo)
		"escudo":
			accion = _demo_escudo(c, ciclo)
	var tam := Partida.tam_mascota(sel)
	var f: int = 4 + int(t * 10.0) % 2 if accion else int(t * 6.0) % 4
	var lado := float(tam * 2)
	var col := Color.WHITE if Partida.tiene_mascota(sel) else Color(0, 0, 0, 1)
	c.draw_texture_rect_region(Datos.tex_mascota(sel, Partida.forma_mascota(sel)), Rect2(_pos_pet() - Vector2(lado, lado) / 2.0, Vector2(lado, lado)), Rect2(f * tam, 0, tam, tam), col)


func _bala(c: Control, p: Vector2) -> void:
	var fb := int(t * 8.0) % 2
	c.draw_texture_rect_region(Datos.tex("bala_orbe"), Rect2(p.round() - Vector2(5, 5), Vector2(11, 11)), Rect2(fb * 11, 0, 11, 11))


func _demo_come(c: Control, ciclo: float) -> bool:
	var pet := _pos_pet()
	c.draw_arc(pet, Partida.pet_radio(sel), 0.0, TAU, 40, Color(1.0, 0.75, 0.9, 0.22), 1.0)
	if ciclo < 1.2:
		_bala(c, Vector2(14, 16).lerp(pet, ciclo / 1.2))
	elif ciclo < 1.9:
		UI.tc(c, pet.x, pet.y - 40.0, "¡ÑAM!", Color("ffd0f0"), 1, true)
	return ciclo > 1.0 and ciclo < 1.5


func _demo_chispa(c: Control, ciclo: float) -> bool:
	var pet := _pos_pet()
	var e := Vector2(46, 34)
	var dio := ciclo > 1.0 and ciclo < 1.3
	var fr := int(t * 6.0) % 4
	c.draw_texture_rect_region(Datos.tex("bot"), Rect2(e - Vector2(16, 16), Vector2(32, 32)), Rect2(fr * 32, 0, 32, 32), Color(2.5, 2.5, 2.5) if dio else Color.WHITE)
	if dio:
		# el chispazo: una línea quebrada, nueva cada vez
		var puntos := PackedVector2Array([pet])
		for k in range(1, 6):
			var u := float(k) / 6.0
			var salto := sin(t * 90.0 + k * 2.3) * 6.0
			puntos.append(pet.lerp(e, u) + Vector2(salto, -salto))
		puntos.append(e)
		c.draw_polyline(puntos, UI.C_CIAN, 1.0)
	if ciclo > 1.0 and ciclo < 1.8:
		var st := Partida.stats_nave()
		var dano := int(Partida.pet_dano(sel) * st.atk * st.dano)
		UI.tc(c, e.x, e.y - 30.0 - (ciclo - 1.0) * 10.0, "-%d" % dano, UI.C_ORO, 1, true)
	return dio


func _demo_iman(c: Control, ciclo: float) -> bool:
	var destino := _pos_nave()
	var u := clampf((ciclo - 0.7) / 0.6, 0.0, 1.0)
	u *= u
	if u < 1.0:
		for k in 8:
			var ini := Vector2(18 + (k * 53) % 136, 18 + (k * 37) % 74)
			var p := ini.lerp(destino, u).round()
			var tx := Datos.tex("obj_tuerca" if k % 3 == 0 else "bit2")
			c.draw_texture(tx, p - Vector2(tx.get_size()) / 2.0)
	elif ciclo < 1.9:
		UI.tc(c, destino.x, destino.y - 34.0, "¡Todo tuyo!", UI.C_ORO, 1, true)
	return ciclo > 0.5 and ciclo < 1.3


func _demo_escudo(c: Control, ciclo: float) -> bool:
	var centro := _pos_nave()
	if ciclo < 1.4:
		c.draw_circle(centro, 22.0, Color(0.45, 0.9, 1.0, 0.16))
		c.draw_arc(centro, 22.0, 0.0, TAU, 32, UI.C_CIAN, 1.0)
		_bala(c, Vector2(centro.x, 8.0).lerp(centro - Vector2(0, 22), ciclo / 1.4))
	elif ciclo < 1.9:
		var u := (ciclo - 1.4) / 0.5
		c.draw_arc(centro, 22.0 + u * 14.0, 0.0, TAU, 32, Color(0.45, 0.9, 1.0, 1.0 - u), 1.0)
		UI.tc(c, centro.x, 10.0, "¡Frenada!", UI.C_CIAN, 1, true)
	return ciclo > 2.0


# =================================================================================================
# TEXTOS
# =================================================================================================
func _que_hace(id: String) -> PackedStringArray:
	var def: Dictionary = Datos.MASCOTAS[id]
	var cada := PiezaBoton.segundos(Partida.pet_recarga(id))
	var r := PackedStringArray()
	match def.ia:
		"come":
			r.append("Se come una bala que pase cerca (alcance: %d)." % int(Partida.pet_radio(id)))
			r.append("Vuelve a comer cada %s." % cada)
			if Partida.tiene("desync"):
				r.append("Cada bala que se come carga tu Desync.")
		"chispa":
			r.append("Le da un chispazo al enemigo más cercano (alcance: %d)." % int(Partida.pet_radio(id)))
			r.append("Pega %d %% de tu Ataque, cada %s." % [int(round(Partida.pet_dano(id) * 100.0)), cada])
		"iman":
			r.append("Te trae todos los Bits y la chatarra del campo.")
			r.append("Lo hace cada %s." % cada)
		"escudo":
			r.append("Te da un escudo que frena un golpe.")
			r.append("Te da otro cada %s." % cada)
	var mods: Dictionary = def.get("mods_nivel", {})
	if not mods.is_empty():
		var partes := PackedStringArray()
		for k in mods:
			partes.append(_gana_por_nivel(k, mods[k]))
		r.append("Cada nivel le da a tu nave %s." % " y ".join(partes))
	return r


func _gana_por_nivel(k: String, v: float) -> String:
	const NOMBRES := {"dano": "de daño", "cadencia": "de cadencia", "iman": "de imán", "chatarra": "de chatarra", "hp": "de vida"}
	var en_pct: bool = k in PiezaBoton.PORCENTAJES
	return "+%s%s %s" % [PiezaBoton.decimal(v * 100.0 if en_pct else v), " %" if en_pct else "", NOMBRES.get(k, k)]


func _draw() -> void:
	UI.t(self, 4, 0, "Una mascota vuela contigo y te ayuda sola. Sales con una a la vez: elígela aquí.", UI.C_GRIS)
	var def: Dictionary = Datos.MASCOTAS[sel]
	var x := 186.0
	var y := 66.0
	var ancho := 300.0
	if def.sprite == "":
		UI.t(self, x, y, "???", UI.C_GRIS, 2, true)
		y += 32
		draw_texture(Datos.tex("ui_candado"), Vector2(x, y + 3))
		UI.t(self, x + 16, y, "Llega con el " + def.desbloqueo.txt, UI.C_ORO)
		return
	var tiene := Partida.tiene_mascota(sel)
	var activa := Partida.mascota_activa() == sel
	var nombre: String = Partida.nombre_mascota(sel) if tiene else def.nombre
	UI.t(self, x, y, nombre, UI.C_ORO if tiene else UI.C_GRIS, 2, true)
	var nx: float = x + UI.ancho(nombre, 2) + 10.0
	if activa:
		UI.t(self, nx, y + 10, "Sale contigo", UI.C_VERDE)
	elif not tiene:
		draw_texture(Datos.tex("ui_candado"), Vector2(nx, y + 13))
	y += 30
	y = UI.parrafo(self, x, y, def.desc, ancho, UI.C_TEXTO) + 4
	UI.t(self, x, y, "QUÉ HACE", UI.C_ROSA)
	y += 14
	for l in _que_hace(sel):
		draw_rect(Rect2(x + 1, y + 5, 4, 4), UI.C_ORO)
		y = UI.parrafo(self, x + 10, y, l, ancho - 10.0, UI.C_TEXTO)
	y += 4
	if tiene:
		_como_crece(x, y, ancho)
	else:
		_como_se_gana(x, y, ancho, def)


func _como_crece(x: float, y: float, ancho: float) -> void:
	var n := Partida.nivel_mascota(sel)
	UI.t(self, x, y, "CÓMO CRECE", UI.C_ROSA)
	y += 14
	UI.t(self, x, y, "Nivel %d" % n, UI.C_ORO)
	if n < Partida.NIVEL_MAX_MASCOTA:
		var xp0 := Partida.xp_de_nivel(n)
		var xp1 := Partida.xp_de_nivel(n + 1)
		var v := float(Partida.xp_mascota(sel) - xp0) / float(maxi(xp1 - xp0, 1))
		UI.barra(self, Rect2(x + 52, y + 3, 170, 10), v, UI.C_ORO)
		UI.t(self, x + 228, y, "%d/%d" % [Partida.xp_mascota(sel) - xp0, xp1 - xp0], UI.C_GRIS)
	else:
		UI.t(self, x + 52, y, "Nivel máximo", UI.C_VERDE)
	y += 15
	y = UI.parrafo(self, x, y, "Solo crece la que sale contigo: al fusionar piezas y al ganar niveles.", ancho, UI.C_TEXTO) + 3
	# sus tres formas, con el nivel en que llegan
	var forma := Partida.forma_mascota(sel)
	var px := x
	for i in Partida.FORMAS_MASCOTA.size():
		var tam: int = Partida.TAM_MASCOTA[i]
		var col := Color.WHITE if i <= forma else Color(0, 0, 0, 1)
		draw_texture_rect_region(Datos.tex_mascota(sel, i), Rect2(px, y, tam, tam), Rect2(0, 0, tam, tam), col)
		UI.t(self, px + tam + 3, y + 7, "Nivel %d" % Partida.FORMAS_MASCOTA[i], UI.C_TEXTO if i <= forma else UI.C_GRIS)
		px += 92.0


func _como_se_gana(x: float, y: float, ancho: float, def: Dictionary) -> void:
	UI.t(self, x, y, "CÓMO SE GANA", UI.C_ROSA)
	y += 14
	var de := Partida.desafio_de("mascota", sel)
	if not de.is_empty() and not Partida.desafio_visible(de):
		UI.t(self, x, y, "??? Se revela más adelante.", UI.C_GRIS)
		return
	y = UI.parrafo(self, x, y, def.desbloqueo.txt, ancho, UI.C_ORO)
	if not de.is_empty():
		var v: int = mini(Partida.valor_stat(de.stat), de.meta)
		UI.barra(self, Rect2(x, y + 3, 170, 10), float(v) / float(de.meta), UI.C_ORO)
		UI.t(self, x + 176, y, "%d/%d" % [v, de.meta], UI.C_GRIS)


# =================================================================================================
# CAMBIAR NOMBRE
# =================================================================================================
func _renombrar() -> void:
	if not Partida.tiene_mascota(sel):
		return
	ocupado = true
	modal = Control.new()
	modal.position = Vector2(-150, -26)
	modal.size = Vector2(640, 360)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var velo := ColorRect.new()
	velo.color = Color(0.03, 0.02, 0.07, 0.6)
	velo.size = modal.size
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(velo)
	var p := Panel.new()
	p.position = Vector2(170, 120)
	p.size = Vector2(300, 100)
	modal.add_child(p)
	UI.etiqueta("¿Cómo se llama tu mascota?", Vector2(12, 6), p, UI.C_ORO)
	campo = LineEdit.new()
	campo.position = Vector2(12, 26)
	campo.custom_minimum_size = Vector2(276, 0)
	campo.text = Partida.nombre_mascota(sel)
	campo.max_length = 14
	p.add_child(campo)
	campo.text_submitted.connect(func(_txt: String): _cerrar_nombre(true))
	var listo := UI.boton("LISTO", Vector2(12, 66), Vector2(134, 24), p, func(): _cerrar_nombre(true))
	var cancelar := UI.boton("CANCELAR", Vector2(154, 66), Vector2(134, 24), p, func(): _cerrar_nombre(false))
	# el foco no sale de este panel
	campo.focus_neighbor_top = campo.get_path_to(campo)
	campo.focus_neighbor_bottom = campo.get_path_to(listo)
	listo.focus_neighbor_top = listo.get_path_to(campo)
	listo.focus_neighbor_bottom = listo.get_path_to(listo)
	listo.focus_neighbor_left = listo.get_path_to(listo)
	listo.focus_neighbor_right = listo.get_path_to(cancelar)
	cancelar.focus_neighbor_top = cancelar.get_path_to(campo)
	cancelar.focus_neighbor_bottom = cancelar.get_path_to(cancelar)
	cancelar.focus_neighbor_left = cancelar.get_path_to(listo)
	cancelar.focus_neighbor_right = cancelar.get_path_to(cancelar)
	campo.focus_next = campo.get_path_to(listo)
	campo.focus_previous = campo.get_path_to(cancelar)
	listo.focus_next = listo.get_path_to(cancelar)
	listo.focus_previous = listo.get_path_to(campo)
	cancelar.focus_next = cancelar.get_path_to(campo)
	cancelar.focus_previous = cancelar.get_path_to(listo)
	campo.grab_focus()
	campo.caret_column = campo.text.length()


func _cerrar_nombre(guardar: bool) -> void:
	if not ocupado:
		return
	if guardar:
		var n: String = campo.text.strip_edges()
		if n != "":
			Partida.renombrar_mascota(n, sel)
	ocupado = false
	modal.queue_free()
	modal = null
	campo = null
	cambio.emit()
	queue_redraw()
	b_nombre.grab_focus()


func _input(ev: InputEvent) -> void:
	# Esc cierra de una: sin esto, el LineEdit se lo come para dejar de escribir
	if ocupado and ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cerrar_nombre(false)
