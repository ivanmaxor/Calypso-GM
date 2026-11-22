extends Control
## Animacion de fusion: la mascota se come las piezas y escupe una mejor.

signal terminado

var iconos := []
var resultado := {}
var icono_resultado: Texture2D
var forma_antes := 0
var cuantas := 1
var t := 0
var listo := false
var forma_despues := 0
var tex_antes: Texture2D
var tex_despues: Texture2D
var sono := false
var chispas := []
var pet := ""
const CENTRO := Vector2(320, 190)


func _ready() -> void:
	size = Vector2(640, 360)
	theme = UI.tema()
	mouse_filter = Control.MOUSE_FILTER_STOP
	# sin mascota elegida se la come Mordisco, para no quedarse sin animación
	pet = Partida.mascota_activa() if Partida.mascota_activa() != "" else "mordisco"
	forma_despues = Partida.forma_mascota(pet)
	tex_antes = Datos.tex_mascota(pet, forma_antes)
	tex_despues = Datos.tex_mascota(pet, forma_despues)
	Sonido.tocar("fusion")


var _t_acum := 0.0


func _process(delta: float) -> void:
	var antes := t
	_t_acum += delta * 60.0
	t = int(_t_acum)
	# se mira si se cruzó el momento: a 144 Hz el mismo valor de t dura varios cuadros
	if antes < 34 and t >= 34:
		Sonido.tocar("nam", 0.9)
	if antes < 44 and t >= 44:
		Sonido.tocar("nam", 1.05)
	if antes < 54 and t >= 54:
		Sonido.tocar("nam", 1.2)
	if t >= 74 and not sono:
		sono = true
		Sonido.tocar("botin_%d" % resultado.rareza)
		var col: Color = Datos.RAREZAS[resultado.rareza].color
		for k in 40:
			var a := randf() * TAU
			var v := randf_range(0.6, 3.2)
			chispas.append({"x": CENTRO.x, "y": CENTRO.y - 20, "vx": cos(a) * v, "vy": sin(a) * v, "c": col, "t": randf_range(20.0, 50.0)})
	var paso := delta * 60.0
	for c in chispas:
		c.x += c.vx * paso
		c.y += c.vy * paso
		c.t -= paso
	chispas = chispas.filter(func(c): return c.t > 0.0)
	queue_redraw()


func _input(ev: InputEvent) -> void:
	if listo or ev is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	if t <= 90:
		return
	if ev.is_action_pressed("ui_accept") or ev.is_action_pressed("ui_cancel"):
		_cerrar()
	elif ev is InputEventMouseButton and ev.pressed:
		_cerrar()


func _cerrar() -> void:
	if listo:
		return
	listo = true
	terminado.emit()
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.07, 0.86))
	var forma := forma_despues if t >= 74 else forma_antes
	var tx: Texture2D = tex_despues if t >= 74 else tex_antes
	var tam: int = Partida.TAM_MASCOTA[forma]
	var fr := 0
	if t >= 30 and t < 74:
		fr = 4 + (int(t / 5) % 2)
	else:
		fr = (t / 8) % 4
	var esc := 3
	var p := CENTRO - Vector2(tam, tam) * esc / 2.0
	if t >= 60 and t < 74:
		p += Vector2(randf_range(-2, 2), randf_range(-2, 2))
	draw_texture_rect_region(tx, Rect2(p, Vector2(tam, tam) * esc), Rect2(fr * tam, 0, tam, tam))
	# piezas que vuelan a la boca
	if t < 58:
		for i in iconos.size():
			var u := clampf(float(t - i * 10) / 30.0, 0.0, 1.0)
			var ini := Vector2(220 + i * 100, 90)
			var q := ini.lerp(CENTRO, u * u)
			if u < 1.0:
				draw_texture(iconos[i], q - Vector2(16, 16))
	for c in chispas:
		draw_rect(Rect2(round(c.x), round(c.y), 2, 2), c.c)
	if t >= 74:
		var rar: Dictionary = Datos.RAREZAS[resultado.rareza]
		var col: Color = rar.color
		var sube := clampf((t - 74) / 14.0, 0.0, 1.0)
		var q := CENTRO + Vector2(0, -36 - 34 * sube)
		var r := Rect2(q - Vector2(18, 18), Vector2(36, 36))
		draw_rect(r, col.darkened(0.75))
		draw_rect(r, col, false, 1.0)
		draw_texture(icono_resultado, q - Vector2(16, 16))
		UI.tc(self, 320, 246, Partida.def_de(resultado).nombre, col, 2, true)
		UI.tc(self, 320, 276, rar.nombre, col, 1, true)
		if cuantas > 1:
			UI.tc(self, 320, 290, "%d fusiones" % cuantas, UI.C_GRIS)
		if forma_despues != forma_antes:
			UI.tc(self, 320, 304, "¡%s cambió de forma!" % Partida.nombre_mascota(pet), UI.C_ROSA, 1, true)
		if t > 90 and (t / 20) % 2 == 0:
			UI.tc(self, 320, 334, "Enter o clic: continuar", UI.C_TEXTO)
