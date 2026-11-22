extends Control
## Pantalla de título: seguir, empezar, cargar, opciones y salir.

signal jugar

const SLOTS := preload("res://pantallas/slots.gd")
const OPCIONES := preload("res://pantallas/opciones.gd")
const MODAL := preload("res://pantallas/modal.gd")
const FONDO := "fondo_chatarra_lejos"

var tiempo := 0.0
var nave: Sprite2D
var mat_nave: ShaderMaterial
var b_jugar: Button  # el botón principal: Continuar si hay partida, Nueva Partida si no
var b_continuar: Button = null
var b_nueva: Button
var b_cargar: Button
var b_opciones: Button
var b_salir: Button
var ranura_continuar := 0
var resumen := ""


func _ready() -> void:
	size = Vector2(640, 360)
	theme = UI.tema()
	nave = Sprite2D.new()
	nave.region_enabled = true
	nave.scale = Vector2(2, 2)
	mat_nave = ShaderMaterial.new()
	mat_nave.shader = load("res://arte/nave.gdshader")
	nave.material = mat_nave
	add_child(nave)
	_refrescar_nave()
	_crear_botones()
	UI.pie(self, "Flechas o WASD: moverse  ·  Enter o Espacio: elegir", "Cruceta: moverse  ·  A: elegir")
	Sonido.musica_menu()
	if Partida.g.aviso != "":
		_mostrar_aviso.call_deferred()


func _refrescar_nave() -> void:
	nave.texture = Datos.tex("nave2_" + Partida.nave_actual())
	Partida.preparar_material(mat_nave, Partida.nave_actual())


## La ranura con la que se sigue: la última usada y, si ya no está, la primera que haya.
func _buscar_continuar() -> int:
	var u: int = int(Partida.g.ultimo_slot)
	if u >= 1 and Partida.existe_slot(u):
		return u
	for i in range(1, Partida.NUM_SLOTS + 1):
		if Partida.existe_slot(i):
			return i
	return 0


func _crear_botones() -> void:
	for b in [b_continuar, b_nueva, b_cargar, b_opciones, b_salir]:
		if b != null:
			remove_child(b)
			b.queue_free()
	b_continuar = null
	ranura_continuar = _buscar_continuar()
	resumen = ""
	var y := 152.0
	var lista := []
	if ranura_continuar > 0:
		b_continuar = UI.boton("CONTINUAR", Vector2(240, y), Vector2(160, 26), self, _continuar)
		lista.append(b_continuar)
		y += 30.0
		var info := Partida.info_slot(ranura_continuar)
		if info.existe:
			var dif: String = Datos.DIFICULTADES[info.dificultad].nombre
			resumen = "Ranura %d · %s · %s" % [ranura_continuar, dif, "terminado" if info.terminado else "nivel " + info.nivel_actual]
	b_nueva = UI.boton("NUEVA PARTIDA", Vector2(240, y), Vector2(160, 22), self, _ir_slots.bind("nueva"))
	lista.append(b_nueva)
	y += 26.0
	b_cargar = UI.boton("CARGAR", Vector2(240, y), Vector2(160, 22), self, _ir_slots.bind("cargar"))
	if Partida.hay_partidas() or Partida.archivo_importable() != "":
		lista.append(b_cargar)
	else:
		# sin partidas no hay nada que cargar: se ve apagado y las flechas se lo saltan
		b_cargar.disabled = true
		b_cargar.focus_mode = Control.FOCUS_NONE
	y += 26.0
	b_opciones = UI.boton("OPCIONES", Vector2(240, y), Vector2(160, 22), self, _opciones)
	lista.append(b_opciones)
	y += 26.0
	b_salir = UI.boton("SALIR", Vector2(240, y), Vector2(160, 22), self, func(): get_tree().quit())
	lista.append(b_salir)
	UI.lista_foco(lista)
	b_jugar = lista[0]
	b_jugar.add_theme_color_override("font_color", UI.C_ORO)
	b_jugar.grab_focus()


func _continuar() -> void:
	if Partida.abrir_slot(ranura_continuar):
		jugar.emit()
		return
	Sonido.tocar("ui_no")
	MODAL.abrir(self, "No se pudo abrir", "El archivo de la Ranura %d está dañado o es de otra versión. Bórrala o elige otra en CARGAR." % ranura_continuar, [["ENTENDIDO", Callable()]], UI.C_ROJO)


func _ir_slots(modo: String) -> void:
	var s := SLOTS.new()
	s.modo = modo
	s.listo.connect(func(): jugar.emit())
	s.cerrado.connect(func():
		# pudo haber borrado partidas: los botones cambian
		_refrescar_nave()
		_crear_botones()
		var b: Button = b_nueva if modo == "nueva" else b_cargar
		if b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus())
	add_child(s)


func _opciones() -> void:
	var o := OPCIONES.new()
	o.al_cerrar = func(): b_opciones.grab_focus()
	add_child(o)


## Una sola vez: te trajimos tu partida de la versión anterior.
func _mostrar_aviso() -> void:
	var txt: String = Partida.g.aviso
	Partida.g.aviso = ""
	Partida.guardar_global()
	MODAL.abrir(self, "Tu partida sigue aquí", txt, [["ENTENDIDO", Callable()]], UI.C_VERDE)


func _process(d: float) -> void:
	tiempo += d
	var fr := int(tiempo * 8.0) % 2
	nave.region_rect = Rect2((4 + fr) * 48, 0, 48, 48)
	nave.position = Vector2(round(320 + sin(tiempo * 0.7) * 150), round(312 + sin(tiempo * 1.3) * 4))
	queue_redraw()


func _draw() -> void:
	var fondo: Texture2D = Datos.tex(FONDO)
	var h := float(fondo.get_height())
	var y := fposmod(tiempo * 14.0, h)
	for ox in [-280, 120, 520]:
		draw_texture(fondo, Vector2(ox, y - h))
		draw_texture(fondo, Vector2(ox, y))
	draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.07, 0.5))
	var f := int(tiempo * 5.0) % 4
	var a := 1 + int(tiempo * 1.2) % 3
	draw_texture_rect_region(Datos.tex("compactador"), Rect2(14, 46, 128, 128), Rect2(a * 128, 0, 128, 128), Color(0.75, 0.75, 0.85, 1))
	draw_texture_rect_region(Datos.tex("spammer"), Rect2(500, 64, 96, 96), Rect2(f * 48, 0, 48, 48), Color(0.85, 0.85, 0.95, 1))
	var logo: Font = Datos.fuente_logo
	var ta := logo.get_string_size("CALYPSO", HORIZONTAL_ALIGNMENT_LEFT, -1, 128).x
	draw_string(logo, Vector2(320 - ta / 2.0 + 6, 118 + 6), "CALYPSO", HORIZONTAL_ALIGNMENT_LEFT, -1, 128, Color("0d0a18"))
	draw_string(logo, Vector2(320 - ta / 2.0, 118), "CALYPSO", HORIZONTAL_ALIGNMENT_LEFT, -1, 128, UI.C_ORO)
	UI.t(self, 6, 342, "v0.3", UI.C_GRIS, 1, true)
	if resumen != "" and b_continuar != null:
		UI.t(self, b_continuar.position.x + b_continuar.size.x + 8.0, b_continuar.position.y + 5.0, resumen, UI.C_TEXTO, 1, true)
	var pet: String = Partida.mascota_activa()
	if pet != "":
		var tam := Partida.tam_mascota(pet)
		var fm := Partida.forma_mascota(pet)
		var r := Rect2(nave.position.x + 50, nave.position.y + 6, tam, tam)
		draw_texture_rect_region(Datos.tex_mascota(pet, fm), r, Rect2(f * tam, 0, tam, tam))
