extends Control
## La habitación del Hangar: el baño de Don Tuerca hecho taller. Cada objeto es una estación.
## Se cruza con las flechas, WASD o el mouse. Lo que tiene foco brilla y lo demás se oscurece de a poco.
## Enter o clic lo abre. Dónde está cada cosa sale de SalaHangar: aquí no se asume ningún tamaño.

signal abrir(id: String)
signal salir

## La luz que le queda a lo que no tiene foco.
const OSCURO := 0.42
## Cuánto cambia la luz por segundo: el fundido dura un cuarto de segundo.
const VEL_LUZ := 4.0
## Desde qué alfa un píxel cuenta como parte del objeto. Las sombras suaves no se contornean.
const UMBRAL_ALFA := 128
## Ancho del contorno, en píxeles del sprite.
const MARGEN := 2
const COLOR_CONTORNO := Color("ffd24a")
const ESC_NAVE := 2.0

## Contornos ya generados, por textura: se hacen una vez y quedan.
static var _contornos := {}

var h  # el Hangar: dice qué está abierto y cómo se abre lo cerrado
var foco := ""
var orden: Array = []
var orden_z: Array = []
var botones := {}
var luz := {}
var texs := {}
## Lo del fondo que va delante de las estaciones (SalaHangar.DELANTE), por id.
var texs_delante := {}
var datos := {}
var sombra := 0.0
var t := 0.0
var temblor := 0.0
var cartel_a := 0.0
var callado := false
var fondo: Texture2D
var nave: Sprite2D
var nave_sombra: Sprite2D
var mat_nave: ShaderMaterial
var frente: Control
var cartel: Control


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	fondo = Datos.tex("hangar_fondo")
	for id in SalaHangar.ORDEN:
		texs[id] = Datos.tex("hangar_obj_" + id)
		datos[id] = contorno_de(texs[id])
		luz[id] = 0.0
	for id in SalaHangar.DELANTE:
		texs_delante[id] = Datos.tex("hangar_delante_" + id)
	orden = SalaHangar.ORDEN.duplicate()
	orden.sort_custom(_mas_a_la_izquierda)
	orden_z = SalaHangar.ORDEN.duplicate()
	orden_z.sort_custom(func(a, b): return _rect(a).end.y < _rect(b).end.y)
	_crear_nave()
	frente = Control.new()
	frente.size = size
	frente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frente.draw.connect(_dibujar_frente)
	add_child(frente)
	cartel = Control.new()
	cartel.size = size
	cartel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartel.draw.connect(_dibujar_cartel)
	add_child(cartel)
	_crear_barra()
	refrescar()


func _rect(id: String) -> Rect2:
	return SalaHangar.OBJETOS[id].r


## La barra va en el mismo orden que la habitación, para que la derecha sea derecha en las dos. La puerta, al final.
func _mas_a_la_izquierda(a: String, b: String) -> bool:
	if a == "salida" or b == "salida":
		return b == "salida" and a != "salida"
	return _rect(a).get_center().x < _rect(b).get_center().x


func _crear_nave() -> void:
	nave = Sprite2D.new()
	nave.region_enabled = true
	nave.scale = Vector2(ESC_NAVE, ESC_NAVE)
	mat_nave = ShaderMaterial.new()
	mat_nave.shader = load("res://arte/nave.gdshader")
	nave.material = mat_nave
	add_child(nave)
	# el material de la nave no respeta el modulate: para oscurecerla se pone encima su misma silueta
	nave_sombra = Sprite2D.new()
	nave_sombra.region_enabled = true
	nave_sombra.scale = nave.scale
	add_child(nave_sombra)


func _crear_barra() -> void:
	var ancho := (640.0 - 8.0 - 3.0 * (orden.size() - 1)) / orden.size()
	for i in orden.size():
		var id: String = orden[i]
		var b := Button.new()
		b.text = SalaHangar.OBJETOS[id].nombre
		b.position = Vector2(4.0 + i * (ancho + 3.0), 2)
		b.custom_minimum_size = Vector2(ancho, 22)
		b.focus_mode = Control.FOCUS_ALL
		if not h.esta_abierta(id):
			b.icon = Datos.tex("ui_candado")
			b.add_theme_color_override("font_color", UI.C_GRIS)
		add_child(b)
		b.size = Vector2(ancho, 22)
		b.focus_entered.connect(_enfocar.bind(id))
		b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(activar.bind(id))
		botones[id] = b
	for i in orden.size():
		var id: String = orden[i]
		var b: Button = botones[id]
		b.focus_neighbor_left = b.get_path_to(botones[orden[i - 1]] if i > 0 else b)
		b.focus_neighbor_right = b.get_path_to(botones[orden[i + 1]] if i + 1 < orden.size() else b)
		b.focus_neighbor_top = b.get_path_to(_vecino_vertical(id, -1.0))
		b.focus_neighbor_bottom = b.get_path_to(_vecino_vertical(id, 1.0))


## Arriba y abajo van al objeto más cercano en esa dirección. Si no hay ninguno, el foco se queda.
func _vecino_vertical(id: String, dir: float) -> Button:
	var c := _rect(id).get_center()
	var mejor: Button = botones[id]
	var puntos := INF
	for o in orden:
		if o == id:
			continue
		var d: Vector2 = _rect(o).get_center() - c
		if d.y * dir < 16.0 or absf(d.x) > absf(d.y) * 2.5:
			continue
		var p := absf(d.x) * 2.0 + absf(d.y)
		if p < puntos:
			puntos = p
			mejor = botones[o]
	return mejor


## La vuelve a mostrar con el foco en ese objeto. La nave y la mascota pueden haber cambiado.
func mostrar(id: String) -> void:
	visible = true
	set_process(true)
	refrescar()
	sombra = 0.0
	for k in luz:
		luz[k] = 0.0
	callado = true
	foco = id
	cartel_a = 1.0
	botones[id].grab_focus()
	callado = false


func refrescar() -> void:
	var id: String = Partida.nave_actual()
	var tex := Datos.tex("nave2_" + id)
	nave.texture = tex
	nave_sombra.texture = tex
	Partida.preparar_material(mat_nave, id)


func _enfocar(id: String) -> void:
	if not callado and id != foco:
		Sonido.tocar("ui_mover")
		cartel_a = 0.0
	foco = id


func activar(id: String) -> void:
	if id == "salida":
		Sonido.tocar("ui_ok")
		salir.emit()
	elif h.esta_abierta(id):
		Sonido.tocar("ui_ok")
		abrir.emit(id)
	else:
		Sonido.tocar("ui_no")
		temblor = 1.0


func _process(delta: float) -> void:
	t += delta
	sombra = move_toward(sombra, 1.0, delta * VEL_LUZ)
	for id in luz:
		luz[id] = move_toward(luz[id], 1.0 if id == foco else 0.0, delta * VEL_LUZ)
	temblor = move_toward(temblor, 0.0, delta * 3.0)
	cartel_a = move_toward(cartel_a, 1.0, delta * 9.0)
	# la nave flota sobre su plataforma
	var fr := int(t * 8.0) % 2
	var region := Rect2((4 + fr) * 48, 0, 48, 48)
	var pos := Vector2(SalaHangar.POS_NAVE.x, roundf(SalaHangar.POS_NAVE.y + sin(t * 1.6) * 2.0))
	nave.region_rect = region
	nave.position = pos
	nave_sombra.region_rect = region
	nave_sombra.position = pos
	nave_sombra.modulate = Color(0.02, 0.02, 0.05, 1.0 - _brillo("naves"))
	cartel.modulate.a = cartel_a
	queue_redraw()
	frente.queue_redraw()
	cartel.queue_redraw()


## Lo que se ve de un objeto: 1 con foco, OSCURO sin foco. Al entrar, todo parte encendido y se va apagando.
func _brillo(id: String) -> float:
	return lerpf(lerpf(1.0, OSCURO, sombra), 1.0, smoothstep(0.0, 1.0, luz[id]))


# =================================================================================================
# DIBUJO
# =================================================================================================
func _draw() -> void:
	var b := lerpf(1.0, OSCURO, sombra)
	draw_texture_rect(fondo, Rect2(0, 0, 640, 360), false, Color(b, b, b))
	for id in orden_z:
		var v := _brillo(id)
		var col := Color(v, v, v)
		if not h.esta_abierta(id):
			# lo cerrado se ve apagado aunque tenga foco
			col = Color(v * 0.5, v * 0.48, v * 0.6)
		draw_texture_rect(texs[id], _rect(id), false, col)
	# lo del fondo que en la habitación está más adelante que una estación: va encima, con la luz del fondo
	for id in texs_delante:
		draw_texture_rect(texs_delante[id], SalaHangar.DELANTE[id], false, Color(b, b, b))
	_dibujar_mascota()
	draw_rect(Rect2(0, 0, 640, 26), Color(0.05, 0.04, 0.09, 0.9))


func _dibujar_mascota() -> void:
	var id := Partida.mascota_activa()
	if id == "" or not h.esta_abierta("mascota"):
		return
	var tam := Partida.tam_mascota(id)
	var f := int(t * 6.0) % 4
	var v := _brillo("mascota")
	var p := Vector2(SalaHangar.POS_MASCOTA.x - tam, roundf(SalaHangar.POS_MASCOTA.y - tam + sin(t * 2.3) * 1.5))
	draw_texture_rect_region(Datos.tex_mascota(id, Partida.forma_mascota(id)), Rect2(p, Vector2(tam, tam) * 2.0), Rect2(f * tam, 0, tam, tam), Color(v, v, v))


func _dibujar_frente() -> void:
	# los contornos y los candados van encima de todo, para que ningún vecino los tape
	var pulso := 0.84 + 0.16 * sin(t * 4.5)
	for id in orden_z:
		var d: Dictionary = datos[id]
		var a: float = smoothstep(0.0, 1.0, luz[id]) * pulso
		if a > 0.01 and d.tex != null:
			var r := _rect(id)
			var esc: Vector2 = r.size / Vector2(d.w, d.h)
			var col := COLOR_CONTORNO if h.esta_abierta(id) else UI.C_GRIS
			col.a = a
			frente.draw_texture_rect(d.tex, Rect2(r.position - esc * MARGEN, r.size + esc * MARGEN * 2.0), false, col)
		if not h.esta_abierta(id):
			var c := _rect(id).get_center()
			var candado := Datos.tex("ui_candado")
			var s := Vector2(candado.get_size()) * 2.0
			frente.draw_texture_rect(candado, Rect2((c - s / 2.0).round(), s), false)


func _dibujar_cartel() -> void:
	if foco == "":
		return
	var c := cartel
	var o: Dictionary = SalaHangar.OBJETOS[foco]
	var abierta: bool = h.esta_abierta(foco)
	var dx := roundf(sin(t * 46.0) * 3.0 * temblor)
	var r := Rect2(8 + dx, 321, 624, 35)
	c.draw_rect(r, Color(0.06, 0.05, 0.11, 0.96))
	c.draw_rect(r, UI.C_ORO if abierta else UI.C_LINEA, false, 1.0)
	UI.t(c, r.position.x + 8, 322, o.nombre, UI.C_ORO if abierta else UI.C_GRIS, 2, true)
	var x := r.position.x + 134
	UI.t(c, x, 323, o.frase, UI.C_TEXTO)
	if abierta:
		var e: Array = _estado(foco)
		UI.t(c, x, 338, e[0], e[1])
	else:
		var candado := Datos.tex("ui_candado")
		c.draw_texture(candado, Vector2(x, 341))
		UI.t(c, x + 16, 338, h.como_se_abre(foco), UI.C_ROJO if temblor > 0.0 else UI.C_ORO)
	var ayuda := "Enter o clic: entrar"
	if foco == "salida":
		ayuda = "Enter o clic: salir"
	elif not abierta:
		ayuda = "Todavía está cerrado"
	var fin := r.end.x - 8
	UI.t(c, fin - UI.ancho(ayuda), 323, ayuda, UI.C_GRIS)
	var esc := "Esc: volver al mapa"
	UI.t(c, fin - UI.ancho(esc), 338, esc, UI.C_GRIS)


## Una línea con cómo va esa estación: así se sabe si vale la pena entrar.
func _estado(id: String) -> Array:
	match id:
		"naves":
			var def: Dictionary = Datos.NAVES[Partida.nave_actual()]
			return ["Usas %s. Tienes %d de %d naves." % [def.nombre, Partida.d.naves.size(), Datos.NAVES.size()], UI.C_GRIS]
		"equipo":
			return ["Tienes %d de chatarra para mejorarlas." % int(Partida.d.chatarra), UI.C_GRIS]
		"fusionar":
			if Partida.hay_fusiones():
				return ["¡Ya tienes piezas para fusionar!", UI.C_VERDE]
			return ["Todavía no tienes 3 piezas iguales.", UI.C_GRIS]
		"mascota":
			var m := Partida.mascota_activa()
			if m != "":
				return ["Sale contigo: %s, nivel %d." % [Partida.nombre_mascota(m), Partida.nivel_mascota(m)], UI.C_GRIS]
			return ["Todavía no tienes ninguna.", UI.C_GRIS]
		"arsenal":
			return ["Encargos cumplidos: %d de %d." % [Partida.d.desafios.size(), Datos.DESAFIOS.size()], UI.C_GRIS]
	return ["", UI.C_GRIS]


# =================================================================================================
# MOUSE
# =================================================================================================
func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var id := objeto_en(ev.position)
		if id != "" and id != foco:
			botones[id].grab_focus()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var id := objeto_en(ev.position)
		if id != "":
			botones[id].grab_focus()
			accept_event()
			activar(id)


## Qué objeto hay en ese punto. Se mira el alfa: lo transparente de un sprite no se puede tocar.
func objeto_en(p: Vector2) -> String:
	for i in range(orden_z.size() - 1, -1, -1):
		var id: String = orden_z[i]
		var r := _rect(id)
		if not r.grow(MARGEN).has_point(p):
			continue
		var d: Dictionary = datos[id]
		var esc: Vector2 = r.size / Vector2(d.w, d.h)
		var ix := int(floor((p.x - r.position.x) / esc.x)) + MARGEN
		var iy := int(floor((p.y - r.position.y) / esc.y)) + MARGEN
		var ancho: int = d.w + MARGEN * 2
		var alto: int = d.h + MARGEN * 2
		if ix >= 0 and iy >= 0 and ix < ancho and iy < alto and d.mascara[iy * ancho + ix] != 0:
			return id
	return ""


# =================================================================================================
# CONTORNO: una textura aparte hecha desde el alfa del sprite
# =================================================================================================
## Devuelve la textura del contorno (más ancha que el sprite en MARGEN por lado) y la máscara para el mouse.
## El contorno es blanco: el color se lo da quien lo dibuja. Queda guardado por textura.
static func contorno_de(tex: Texture2D) -> Dictionary:
	if _contornos.has(tex):
		return _contornos[tex]
	var r := {"tex": null, "mascara": PackedByteArray(), "w": tex.get_width(), "h": tex.get_height()}
	var w: int = r.w
	var h2: int = r.h
	var ancho := w + MARGEN * 2
	var alto := h2 + MARGEN * 2
	# dentro: 1 si el píxel es parte del objeto
	var dentro := PackedByteArray()
	dentro.resize(ancho * alto)
	var img := tex.get_image()
	if img != null and not img.is_empty():
		# una copia: la imagen que entrega la textura puede ser la que ella guarda
		img = img.duplicate() as Image
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		var px := img.get_data()
		for y in h2:
			var fila := (y + MARGEN) * ancho + MARGEN
			var o := y * w * 4 + 3
			for x in w:
				if px[o] >= UMBRAL_ALFA:
					dentro[fila + x] = 1
				o += 4
	else:
		dentro.fill(1)
	# primer anillo, con los cuatro vecinos: así las esquinas quedan limpias y sin escalones gruesos
	var anillo := PackedByteArray()
	anillo.resize(ancho * alto)
	for y in range(1, alto - 1):
		var f := y * ancho
		for x in range(1, ancho - 1):
			var i := f + x
			if dentro[i] == 0 and (dentro[i - 1] != 0 or dentro[i + 1] != 0 or dentro[i - ancho] != 0 or dentro[i + ancho] != 0):
				anillo[i] = 1
	# segundo anillo, más tenue: da el halo sin engordar la línea
	var salida := PackedByteArray()
	salida.resize(ancho * alto * 4)
	var mascara := PackedByteArray()
	mascara.resize(ancho * alto)
	for y in alto:
		var f := y * ancho
		for x in ancho:
			var i := f + x
			var a := 0
			if anillo[i] != 0:
				a = 255
			elif dentro[i] == 0:
				var hay := (x > 0 and anillo[i - 1] != 0) or (x + 1 < ancho and anillo[i + 1] != 0)
				hay = hay or (y > 0 and anillo[i - ancho] != 0) or (y + 1 < alto and anillo[i + ancho] != 0)
				if hay:
					a = 110
			if a > 0:
				var o := i * 4
				salida[o] = 255
				salida[o + 1] = 255
				salida[o + 2] = 255
				salida[o + 3] = a
			if a > 0 or dentro[i] != 0:
				mascara[i] = 1
	r.mascara = mascara
	r.tex = ImageTexture.create_from_image(Image.create_from_data(ancho, alto, false, Image.FORMAT_RGBA8, salida))
	_contornos[tex] = r
	return r
