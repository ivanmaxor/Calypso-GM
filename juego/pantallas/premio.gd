extends Control
## La gran celebración cuando ganas algo: arma, habilidad, nave, mascota, ranura, tablón, chatarra o pieza.
## Si viene de un desafío, dice cuál cumpliste.

signal terminado

const TIPOS_PREMIO := ["pieza", "chatarra", "cambios"]

var premio := {}
var indice := 1  # "2 de 3", cuando hay varios seguidos
var total := 1
var t := 0
var cerrado := false
var cuerpo := PackedStringArray()


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 360)
	theme = UI.tema()
	mouse_filter = Control.MOUSE_FILTER_STOP
	Sonido.tocar("desbloqueo")
	var txt: String = premio.get("detalle", premio.get("desc", ""))
	cuerpo = UI.partir(txt, 480.0)


var _t_acum := 0.0


func _process(delta: float) -> void:
	_t_acum += delta * 60.0
	t = int(_t_acum)
	queue_redraw()


func _input(ev: InputEvent) -> void:
	if cerrado or ev is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	if t <= 50:
		return
	if ev.is_action_pressed("ui_accept") or ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("disparar"):
		_cerrar()
	elif ev is InputEventMouseButton and ev.pressed:
		_cerrar()


func _cerrar() -> void:
	if cerrado:
		return
	cerrado = true
	Sonido.tocar("ui_ok")
	terminado.emit()
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.05, 0.92))
	var c := Vector2(320, 150)
	# rayos que giran
	var col := Color(1, 0.8, 0.3, 0.16)
	for k in 12:
		var a := TAU * k / 12.0 + t * 0.008
		var a2 := a + 0.14
		var largo := 360.0 * minf(t / 22.0, 1.0)
		draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a), sin(a)) * largo, c + Vector2(cos(a2), sin(a2)) * largo]), col)
	var entra := minf(t / 14.0, 1.0)
	var u := 1.0 + (1.0 - entra) * 1.2
	var titulo: String = "¡PREMIO!" if premio.get("tipo", "") in TIPOS_PREMIO else "¡DESBLOQUEASTE!"
	UI.tc(self, 320, 8, titulo, UI.C_ORO, 3, true)
	if total > 1:
		UI.t(self, 632 - UI.ancho("%d de %d" % [indice, total]), 6, "%d de %d" % [indice, total], UI.C_GRIS)
	if premio.has("desafio"):
		UI.tc(self, 320, 60, "Desafío cumplido: " + premio.desafio, UI.C_CIAN, 1, true)
	var tam := 96.0 * u
	var r := Rect2(c - Vector2(tam, tam) / 2.0, Vector2(tam, tam))
	if premio.has("item"):
		_pieza(c)
	else:
		_icono(r)
		_nombre_y_texto()
	if t > 50 and (t / 20) % 2 == 0:
		UI.tc(self, 320, 334, "A: continuar" if Controles.ultimo_mando else "Enter o clic: continuar", UI.C_TEXTO, 1, true)


func _icono(r: Rect2) -> void:
	match premio.get("icono", ""):
		"mascota":
			var id: String = premio.get("id", "mordisco")
			var lado: int = Partida.TAM_MASCOTA[0]
			var f := (t / 8) % 4
			# 4 veces su tamaño: un múltiplo exacto se ve nítido
			var q := Rect2(r.get_center() - r.size * 0.46, r.size * 0.92)
			draw_texture_rect_region(Datos.tex_mascota(id, 0), q, Rect2(f * lado, 0, lado, lado))
		"nave":
			# se dibuja con su pintura, por eso va en un nodo aparte
			_nave(r)
		"":
			pass
		_:
			draw_texture_rect(Datos.tex(premio.icono), r, false)


func _nombre_y_texto() -> void:
	var nombre: String = premio.get("nombre", "")
	# los nombres largos no caben en grande
	var esc := 2 if UI.ancho(nombre, 2) <= 600.0 else 1
	UI.tc(self, 320, 208, nombre, UI.C_TEXTO, esc, true)
	var y := 240.0
	for lin in cuerpo:
		UI.tc(self, 320, y, lin, UI.C_GRIS, 1, true)
		y += 14


func _pieza(c: Vector2) -> void:
	var it: Dictionary = premio.item
	var rar: Dictionary = Datos.RAREZAS[it.rareza]
	var marco := Rect2(c - Vector2(50, 50), Vector2(100, 100))
	draw_rect(marco, rar.color.darkened(0.72))
	draw_rect(marco, rar.color, false, 1.0)
	draw_texture_rect(Datos.tex("icono_" + it.id), Rect2(c - Vector2(32, 32), Vector2(64, 64)), false)
	UI.tc(self, 320, 208, Partida.def_de(it).nombre, rar.color, 2, true)
	UI.tc(self, 320, 240, rar.nombre.to_upper(), rar.color, 1, true)
	UI.tc(self, 320, 258, "Quedó en tu inventario: póntela en el Hangar.", UI.C_GRIS, 1, true)


var _spr: Sprite2D = null


func _nave(r: Rect2) -> void:
	if _spr == null:
		_spr = Sprite2D.new()
		_spr.region_enabled = true
		_spr.texture = Datos.tex("nave2_" + premio.id)
		_spr.region_rect = Rect2(4 * 48, 0, 48, 48)
		var mat := ShaderMaterial.new()
		mat.shader = load("res://arte/nave.gdshader")
		Partida.preparar_material(mat, premio.id)
		_spr.material = mat
		add_child(_spr)
	_spr.position = r.get_center()
	var e: float = r.size.x / 48.0
	_spr.scale = Vector2(e, e)
	_spr.region_rect = Rect2((4 + (t / 7) % 2) * 48, 0, 48, 48)
