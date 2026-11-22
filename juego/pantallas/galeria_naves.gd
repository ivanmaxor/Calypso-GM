class_name GaleriaNaves
extends Control
## Las seis naves en una fila y la ficha de la seleccionada. La usan el Hangar y la pantalla de elegir.

signal cambio(id: String)
signal confirmar(id: String)

const ANCHO := 490.0
var sel := ""
var con_pintura := false
var tarjetas := {}
var pinturas: Array = []
var t := 0.0
var grande: Sprite2D
var mat_grande: ShaderMaterial
var vecino_abajo: Control = null


class Tarjeta extends Button:
	var id := ""
	var g
	var spr: Sprite2D
	var mat: ShaderMaterial

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(78, 82)
		size = Vector2(78, 82)
		var vacio := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(s, vacio)
		spr = Sprite2D.new()
		spr.region_enabled = true
		spr.region_rect = Rect2(4 * 48, 0, 48, 48)
		spr.texture = Datos.tex("nave2_" + id)
		spr.position = Vector2(39, 32)
		if id in Partida.d.naves:
			mat = ShaderMaterial.new()
			mat.shader = load("res://arte/nave.gdshader")
			spr.material = mat
			Partida.preparar_material(mat, id)
		else:
			spr.modulate = Color(0.05, 0.04, 0.09)
		add_child(spr)
		focus_entered.connect(g.seleccionar.bind(id))
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)
		pressed.connect(g.pulsar.bind(id))

	func _draw() -> void:
		var r := Rect2(0, 0, 78, 82)
		var tiene: bool = id in Partida.d.naves
		var es_sel: bool = g.sel == id
		var fondo := UI.C_PANEL2 if tiene else Color("15112a")
		var borde := UI.C_ORO if es_sel else (UI.C_LINEA if tiene else Color("2a2448"))
		UI.marco(self, r, fondo, borde)
		if es_sel:
			draw_rect(r.grow(-1), UI.C_ORO, false, 1.0)
		var nom: String = Datos.NAVES[id].nombre
		if nom.begins_with("Main "):
			nom = nom.substr(5)
		if nom.begins_with("La "):
			nom = nom.substr(3)
		UI.tc(self, 39, 62, nom if tiene else "???", UI.C_TEXTO if tiene else UI.C_GRIS)
		if not tiene:
			draw_texture(Datos.tex("ui_candado"), Vector2(61, 4))
		elif Partida.nave_actual() == id:
			draw_rect(Rect2(3, 3, 7, 7), UI.C_VERDE)


func _ready() -> void:
	size = Vector2(ANCHO, 290)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var i := 0
	for id in Datos.NAVES:
		var b := Tarjeta.new()
		b.id = id
		b.g = self
		b.position = Vector2(i * 82.0, 0)
		add_child(b)
		tarjetas[id] = b
		i += 1
	if sel == "":
		sel = Partida.nave_actual()
	grande = Sprite2D.new()
	grande.region_enabled = true
	grande.scale = Vector2(2, 2)
	grande.position = Vector2(ANCHO - 66, 170)
	mat_grande = ShaderMaterial.new()
	mat_grande.shader = load("res://arte/nave.gdshader")
	add_child(grande)
	_refrescar_grande()
	if con_pintura:
		for k in Datos.PINTURAS.size():
			var p := Button.new()
			p.position = Vector2(ANCHO - 6 * 22 - 4 + k * 22, 256)
			p.size = Vector2(20, 18)
			p.custom_minimum_size = Vector2(20, 18)
			p.focus_mode = Control.FOCUS_ALL
			var st := StyleBoxFlat.new()
			st.bg_color = Color(Datos.PINTURAS[k].rampa[3])
			st.border_color = Color("0d0a18")
			st.set_border_width_all(1)
			for n in ["normal", "hover", "pressed"]:
				p.add_theme_stylebox_override(n, st)
			var fc: StyleBoxFlat = st.duplicate()
			fc.border_color = Color.WHITE
			fc.set_border_width_all(2)
			p.add_theme_stylebox_override("focus", fc)
			p.pressed.connect(_pintar.bind(k))
			p.focus_entered.connect(func(): Sonido.tocar("ui_mover"))
			p.mouse_entered.connect(p.grab_focus)
			add_child(p)
			pinturas.append(p)
	_refrescar_pinturas()


## Vecinos de foco de la fila de naves y de las pinturas. Devuelve a dónde se llega bajando desde "arriba".
func conectar(arriba: Control, abajo: Control) -> Control:
	var ids: Array = tarjetas.keys()
	for i in ids.size():
		var b: Control = tarjetas[ids[i]]
		b.focus_neighbor_left = b.get_path_to(tarjetas[ids[i - 1]] if i > 0 else b)
		b.focus_neighbor_right = b.get_path_to(tarjetas[ids[i + 1]] if i + 1 < ids.size() else b)
		b.focus_neighbor_top = b.get_path_to(arriba if arriba else b)
		b.focus_neighbor_bottom = b.get_path_to(pinturas[0] if not pinturas.is_empty() else (abajo if abajo else b))
	for i in pinturas.size():
		var p: Control = pinturas[i]
		p.focus_neighbor_left = p.get_path_to(pinturas[i - 1] if i > 0 else p)
		p.focus_neighbor_right = p.get_path_to(pinturas[i + 1] if i + 1 < pinturas.size() else p)
		p.focus_neighbor_bottom = p.get_path_to(abajo if abajo else p)
	vecino_abajo = abajo
	_enlazar_arriba()
	return tarjetas[sel]


## Lo de abajo vuelve siempre a la nave elegida.
func _enlazar_arriba() -> void:
	for p in pinturas:
		p.focus_neighbor_top = p.get_path_to(tarjetas[sel])
	if vecino_abajo:
		var v: Control = pinturas[0] if not pinturas.is_empty() else tarjetas[sel]
		vecino_abajo.focus_neighbor_top = vecino_abajo.get_path_to(v)


func _refrescar_grande() -> void:
	grande.texture = Datos.tex("nave2_" + sel)
	if sel in Partida.d.naves:
		grande.material = mat_grande
		Partida.preparar_material(mat_grande, sel)
		grande.modulate = Color.WHITE
	else:
		grande.material = null
		grande.modulate = Color(0.05, 0.04, 0.09)


func _process(d: float) -> void:
	t += d
	grande.region_rect = Rect2((4 + int(t * 8.0) % 2) * 48, 0, 48, 48)
	grande.position.y = roundf(170.0 + sin(t * 1.6) * 3.0)


func enfocar() -> void:
	tarjetas[sel].grab_focus()


func seleccionar(id: String) -> void:
	if sel != id:
		Sonido.tocar("ui_mover")
	sel = id
	_refrescar_pinturas()
	_refrescar_grande()
	_enlazar_arriba()
	for k in tarjetas:
		tarjetas[k].queue_redraw()
	queue_redraw()
	cambio.emit(id)


func pulsar(id: String) -> void:
	if id in Partida.d.naves:
		Sonido.tocar("ui_ok")
		confirmar.emit(id)
	else:
		Sonido.tocar("ui_no")


func _pintar(k: int) -> void:
	Partida.pintar_nave(sel, k)
	Sonido.tocar("ui_ok")
	var m: ShaderMaterial = tarjetas[sel].mat
	if m:
		Partida.preparar_material(m, sel)
	_refrescar_grande()
	cambio.emit(sel)


func _refrescar_pinturas() -> void:
	var v: bool = sel in Partida.d.naves
	for p in pinturas:
		p.visible = v


func _draw() -> void:
	var def: Dictionary = Datos.NAVES[sel]
	var tiene: bool = sel in Partida.d.naves
	var r := Rect2(0, 88, ANCHO, 196)
	UI.marco(self, r, UI.C_PANEL, UI.C_LINEA)
	var x := 10.0
	var y := 92.0
	UI.t(self, x, y, def.nombre.to_upper() if tiene else "NAVE BLOQUEADA", UI.C_ORO, 2, true)
	y += 30
	if not tiene:
		y = _como_se_gana(x, y)
	UI.t(self, x, y, PiezaBoton.sin_spoiler(def.desc), UI.C_TEXTO)
	y += 20
	var arma: Dictionary = Datos.ARMAS[def.arma]
	UI.marco(self, Rect2(x, y, 34, 34), UI.C_PANEL2, UI.C_CIAN)
	draw_texture(Datos.tex("icono_" + def.arma), Vector2(x + 1, y + 1))
	UI.t(self, x + 40, y - 1, "ARMA PRINCIPAL: " + arma.nombre, UI.C_CIAN)
	UI.t(self, x + 40, y + 13, arma.desc, UI.C_GRIS)
	y += 40
	UI.t(self, x, y, "PASIVA", UI.C_VERDE)
	UI.t(self, x + 52, y, PiezaBoton.sin_spoiler(def.pasiva), UI.C_TEXTO)
	y += 15
	UI.t(self, x, y, "BASE", UI.C_GRIS)
	UI.t(self, x + 52, y, "   ".join(PackedStringArray(def.numeros)), UI.C_TEXTO)
	if con_pintura and tiene:
		UI.t(self, ANCHO - 6 * 22 - 56, 257, "PINTURA", UI.C_GRIS)


## Cómo se gana la nave seleccionada, con su progreso. Devuelve la y siguiente.
func _como_se_gana(x: float, y: float) -> float:
	UI.t(self, x, y, "Para desbloquearla:", UI.C_GRIS)
	y += 15
	draw_texture(Datos.tex("ui_candado"), Vector2(x, y + 3))
	var de := Partida.desafio_de("nave", sel)
	if not de.is_empty() and not Partida.desafio_visible(de):
		UI.t(self, x + 16, y, "??? Se revela más adelante.", UI.C_GRIS)
		return y + 20
	UI.t(self, x + 16, y, Partida.progreso_nave(sel), UI.C_ORO)
	y += 15
	if not de.is_empty():
		var v: int = mini(Partida.valor_stat(de.stat), de.meta)
		UI.barra(self, Rect2(x, y + 2, 200, 8), float(v) / float(de.meta), UI.C_ORO)
		y += 12
	return y + 4
