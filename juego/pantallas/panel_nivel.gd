extends Control
## Lo que se abre al pulsar un nivel: qué trae, qué premio da y cómo ganar las estrellas.
## La Ruleta explica cómo funciona, y el Modo Infinito muestra tu récord en vez de estrellas.

signal jugar
signal cerrado

const CAJA := Rect2(40, 14, 560, 332)
const ANCHO_IZQ := 344.0
## Lo que puede salir en los rodillos de la Ruleta: de lo peligroso a lo bueno.
const RODILLOS := [["rueda_jefe", "Jefe"], ["rueda_compacto", "Compacto"], ["rueda_horda", "Horda"], ["rueda_pizza", "Pizza"],
	["rueda_moneda", "Moneda"], ["rueda_bolsa", "Bolsa"], ["rueda_diamante", "Diamante"], ["rueda_cofre", "Cofre"]]

var id := "1-1"
var def: Dictionary
var modo := "normal"
var nuevos: Array = []
var b_jugar: Button
var b_volver: Button


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 360)
	theme = UI.tema()
	mouse_filter = Control.MOUSE_FILTER_STOP
	def = Datos.NIVELES[id]
	modo = def.get("modo", "normal")
	var i: int = Datos.ORDEN_NIVELES.find(id)
	if i >= 0:
		var antes: Array = Datos.NIVELES[Datos.ORDEN_NIVELES[i - 1]].enemigos if i > 0 else []
		for e in def.enemigos:
			if not e in antes:
				nuevos.append(e)
	var y_b := CAJA.end.y - 34
	b_volver = UI.boton("VOLVER", Vector2(CAJA.position.x + 12, y_b), Vector2(120, 26), self, _cerrar)
	b_jugar = UI.boton("¡JUGAR!", Vector2(CAJA.end.x - 192, y_b), Vector2(180, 26), self, _jugar)
	b_jugar.add_theme_color_override("font_color", UI.C_ORO)
	UI.lista_foco([b_volver, b_jugar], false, false)
	b_jugar.grab_focus.call_deferred()


func _jugar() -> void:
	jugar.emit()


func _cerrar() -> void:
	cerrado.emit()
	queue_free()


func _process(_d: float) -> void:
	queue_redraw()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cerrar()


## Para quien usa el mouse: un clic fuera de la caja es volver.
func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and not CAJA.has_point(ev.position):
		accept_event()
		_cerrar()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.05, 0.7))
	UI.marco(self, CAJA, UI.C_FONDO, UI.C_ORO)
	var x := CAJA.position.x + 12
	var y := CAJA.position.y + 4
	var titulo: String = "NIVEL " + id if modo == "normal" else def.nombre.to_upper()
	UI.t(self, x, y, titulo, UI.C_ORO, 2, true)
	if modo == "normal":
		UI.t(self, x + UI.ancho(titulo, 2) + 12, y + 8, def.nombre, UI.C_TEXTO)
	y += 32
	# la Ruleta se explica entera en "cómo funciona"
	if modo != "ruleta":
		y = UI.parrafo(self, x, y, def.desc, ANCHO_IZQ, UI.C_GRIS) + 4
	match modo:
		"infinito":
			_cuerpo_infinito(x, y)
		"ruleta":
			_cuerpo_ruleta(x, y)
		_:
			_cuerpo_normal(x, y)
	_caja_premio()
	_dificultad(CAJA.end.x - 196.0, CAJA.position.y + 190.0)


func _cuerpo_normal(x: float, y0: float) -> void:
	var y := y0
	UI.t(self, x, y, "ENEMIGOS", UI.C_ROSA)
	y += 16
	var ex := x
	for e in def.enemigos:
		_enemigo(e, ex, y, true)
		ex += 60
	y += 52
	for e in nuevos:
		var txt: String = "%s: %s" % [Datos.ENEMIGOS[e].nombre, Datos.ENEMIGOS[e].ayuda]
		UI.marco(self, Rect2(x, y + 1, 40, 14), UI.C_ROSA.darkened(0.5), UI.C_ROSA.darkened(0.2))
		UI.tc(self, x + 20, y, "NUEVO", Color.WHITE)
		y = UI.parrafo(self, x + 46, y, txt, ANCHO_IZQ - 46.0, UI.C_TEXTO)
		if y > 196:
			break
	_estrellas(x, 214)


func _cuerpo_ruleta(x: float, y0: float) -> void:
	var y := y0
	UI.t(self, x, y, "CÓMO FUNCIONA", UI.C_ROSA)
	y += 15
	y = UI.parrafo(self, x, y, "Dos veces en el nivel se limpia el campo y gira la tragamonedas de Don Tuerca: 3 rodillos, y cada uno suma lo suyo.", ANCHO_IZQ)
	y += 3
	# dos filas de cuatro, con el nombre al lado del dibujo
	var paso := 90.0
	for k in RODILLOS.size():
		var rx: float = x + (k % 4) * paso
		var ry: float = y + (k / 4) * 33.0
		draw_texture_rect(Datos.tex(RODILLOS[k][0]), Rect2(rx, ry, 32, 32), false)
		UI.t(self, rx + 34, ry + 8, RODILLOS[k][1], UI.C_GRIS)
	y += 68
	UI.parrafo(self, x, y, "Tres iguales lo cambian todo: súper jefe, mega horda, jackpot, cura total o tres cartas.", ANCHO_IZQ, UI.C_ORO)
	_estrellas(x, 214)


func _cuerpo_infinito(x: float, y0: float) -> void:
	var y := y0
	UI.t(self, x, y, "CÓMO FUNCIONA", UI.C_CIAN)
	y += 15
	y = UI.parrafo(self, x, y, "No se gana: se aguanta. Cada minuto llegan más y más fuertes, y cada tanto cae un jefe.", ANCHO_IZQ)
	y = UI.parrafo(self, x, y, "Cuando caigas, te llevas chatarra y piezas según cuánto duraste.", ANCHO_IZQ)
	y += 8
	UI.t(self, x, y, "ENEMIGOS", UI.C_ROSA)
	y += 16
	var lista: Array = def.enemigos
	var paso: float = minf(57.0, ANCHO_IZQ / lista.size())
	for k in lista.size():
		_enemigo(lista[k], x + k * paso, y, false)
	y += 44
	# lo que se gana por aguantar
	UI.t(self, x, y, "PREMIOS POR AGUANTAR", UI.C_ORO)
	y += 16
	for de in Datos.DESAFIOS:
		if de.stat != "inf_seg":
			continue
		var hecho: bool = Partida.desafio_hecho(de.id)
		draw_texture(Datos.tex("ui_estrella" if hecho else "ui_estrella_vacia"), Vector2(x, y + 2))
		UI.t(self, x + 18, y, "%s: %s" % [de.txt, _nombre_premio(de.premio)], UI.C_TEXTO if hecho else UI.C_GRIS)
		y += 15


func _nombre_premio(p: Dictionary) -> String:
	if p.tipo == "arma":
		return Datos.ARMAS[p.id].nombre
	if p.tipo == "hab":
		return Datos.HABILIDADES[p.id].nombre
	return ""


func _estrellas(x: float, y0: float) -> void:
	var yy := y0
	UI.t(self, x, yy, "ESTRELLAS", UI.C_ORO)
	yy += 16
	var est: int = Partida.estrellas(id)
	var cond := ["Termina el nivel", "Recibe %d golpes o menos" % def.golpes, "Haz una cadena de %d kills" % def.cadena]
	for k in 3:
		draw_texture(Datos.tex("ui_estrella" if k < est else "ui_estrella_vacia"), Vector2(x, yy + 2))
		UI.t(self, x + 18, yy, cond[k], UI.C_TEXTO if k < est else UI.C_GRIS)
		yy += 15


## El premio, o el récord en el Modo Infinito.
func _caja_premio() -> void:
	var rp := Rect2(CAJA.end.x - 196, CAJA.position.y + 36, 184, 142)
	var cx: float = rp.position.x + rp.size.x / 2.0
	if modo == "infinito":
		var rec: Dictionary = Partida.d.records.get(id, {})
		UI.marco(self, rp, Color("10222a"), UI.C_CIAN)
		UI.tc(self, cx, rp.position.y + 4, "TU RÉCORD", UI.C_CIAN)
		draw_texture_rect(Datos.tex("icono_infinito"), Rect2(cx - 24.0, rp.position.y + 22, 48, 48), false)
		if rec.is_empty():
			UI.tc(self, cx, rp.position.y + 78, "Todavía no hay", UI.C_GRIS)
			UI.tc(self, cx, rp.position.y + 92, "¿Cuánto aguantas?", UI.C_GRIS)
		else:
			UI.tc(self, cx, rp.position.y + 70, UI.reloj(int(rec.seg)), UI.C_TEXTO, 2, true)
			UI.tc(self, cx, rp.position.y + 102, "%d kills" % int(rec.kills), UI.C_GRIS)
		return
	var ganado: bool = Partida.nivel_completado(id)
	UI.marco(self, rp, Color("2a1e10") if not ganado else UI.C_PANEL, UI.C_ORO if not ganado else UI.C_LINEA)
	var p: Dictionary = def.premio
	UI.tc(self, cx, rp.position.y + 2, "PREMIO" if not ganado else "YA LO GANASTE", UI.C_ORO if not ganado else UI.C_VERDE)
	var ic := Rect2(cx - 32, rp.position.y + 18, 64, 64)
	_premio(p, ic, ganado)
	var ty := rp.position.y + 86
	for lin in UI.partir(p.nombre, rp.size.x - 10):
		UI.tc(self, cx, ty, lin, UI.C_TEXTO)
		ty += 13
	for lin in UI.partir(p.desc, rp.size.x - 10):
		UI.tc(self, cx, ty, lin, UI.C_GRIS)
		ty += 13


## Con qué dificultad vas a jugar. Se ve justo antes de empezar para que nada sorprenda.
func _dificultad(x: float, y: float) -> void:
	var di: Dictionary = Partida.dif()
	draw_texture_rect(Datos.tex(di.icono), Rect2(x, y + 1, 24, 24), false)
	UI.t(self, x + 28, y, "Dificultad: " + di.nombre, di.color)
	if Partida.ciclo() > 0:
		UI.t(self, x + 28, y + 14, "Ciclo %d: enemigos más fuertes" % Partida.ciclo(), UI.C_ROSA)


func _enemigo(e: String, x: float, y: float, con_nombre: bool) -> void:
	var d: Dictionary = Datos.ENEMIGOS[e]
	var r := Rect2(x, y, 34, 34)
	var es_nuevo: bool = e in nuevos
	UI.marco(self, r, UI.C_PANEL, UI.C_ROSA if es_nuevo else UI.C_LINEA)
	var w: float = d.w
	var esc := 32.0 / w if w > 32.0 else 1.0
	var tam := w * esc
	draw_texture_rect_region(Datos.tex(d.sprite), Rect2(x + 17 - tam / 2.0, y + 17 - tam / 2.0, tam, tam), Rect2(0, 0, w, d.h))
	if not con_nombre:
		return
	if d.get("jefe", false):
		UI.tc(self, x + 17, y + 34, "JEFE", UI.C_ROJO)
	else:
		UI.tc(self, x + 17, y + 34, d.nombre, UI.C_GRIS)


func _premio(p: Dictionary, r: Rect2, ganado: bool) -> void:
	match p.icono:
		"mascota":
			# 22 x 3: múltiplo exacto, para que el dibujo no se deforme
			var lado: int = Partida.TAM_MASCOTA[0]
			var q := Rect2(r.get_center() - Vector2(lado * 3, lado * 3) / 2.0, Vector2(lado * 3, lado * 3))
			draw_texture_rect_region(Datos.tex_mascota(p.get("id", "mordisco"), 0), q, Rect2(0, 0, lado, lado))
		"nave":
			var color := Color.WHITE if ganado else Color(0.2, 0.2, 0.32)
			draw_texture_rect_region(Datos.tex("nave2_" + p.id), r, Rect2(4 * 48, 0, 48, 48), color)
			if not ganado:
				draw_texture(Datos.tex("ui_candado"), r.get_center() - Vector2(7, 7))
		_:
			draw_texture_rect(Datos.tex(p.icono), r, false)
