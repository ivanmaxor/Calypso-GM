extends Node
## Opciones del jugador. Se guardan en user://ajustes.cfg

const ARCHIVO := "user://ajustes.cfg"
const VERSION_AUDIO := 3  # la v0.3 cambió la curva de volumen y agregó la rotación de temas

var ruta_prueba := ""  # si no está vacía, se guarda ahí en vez del archivo de siempre
var musica := 50
var efectos := 80
var pantalla_completa := true
var sacudida := 100
var reducir_destellos := false
var atenuar_fondo := 0
var disparo_auto := true
var foco_alternar := false
var escala_chat_rapida := false
var tema_musica := 0  # índice en Sonido.TEMAS; 0 = Aleatorio
var ver_numeros := true


func _ready() -> void:
	cargar()
	aplicar_video()


func _input(ev: InputEvent) -> void:
	# F11 o Alt+Enter cambian entre ventana y pantalla completa
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_F11 or (ev.keycode == KEY_ENTER and ev.alt_pressed):
			pantalla_completa = not pantalla_completa
			aplicar_video()
			guardar()
			get_viewport().set_input_as_handled()


func cargar() -> void:
	var c := ConfigFile.new()
	if c.load(_ruta()) != OK:
		return
	musica = c.get_value("audio", "musica", musica)
	efectos = c.get_value("audio", "efectos", efectos)
	tema_musica = c.get_value("audio", "tema_musica", tema_musica)
	pantalla_completa = c.get_value("video", "pantalla_completa", pantalla_completa)
	sacudida = c.get_value("video", "sacudida", sacudida)
	reducir_destellos = c.get_value("video", "reducir_destellos", reducir_destellos)
	atenuar_fondo = c.get_value("video", "atenuar_fondo", atenuar_fondo)
	disparo_auto = c.get_value("juego", "disparo_auto", disparo_auto)
	foco_alternar = c.get_value("juego", "foco_alternar", foco_alternar)
	ver_numeros = c.get_value("juego", "ver_numeros", ver_numeros)
	if int(c.get_value("audio", "version", 0)) < VERSION_AUDIO:
		# El 70 % de antes sonaría distinto con la curva nueva. Una sola vez: parte en 50 % y Aleatorio.
		musica = 50
		tema_musica = 0
		guardar()


func guardar() -> void:
	var c := ConfigFile.new()
	c.set_value("audio", "version", VERSION_AUDIO)
	c.set_value("audio", "musica", musica)
	c.set_value("audio", "efectos", efectos)
	c.set_value("audio", "tema_musica", tema_musica)
	c.set_value("video", "pantalla_completa", pantalla_completa)
	c.set_value("video", "sacudida", sacudida)
	c.set_value("video", "reducir_destellos", reducir_destellos)
	c.set_value("video", "atenuar_fondo", atenuar_fondo)
	c.set_value("juego", "disparo_auto", disparo_auto)
	c.set_value("juego", "foco_alternar", foco_alternar)
	c.set_value("juego", "ver_numeros", ver_numeros)
	c.save(_ruta())


func aplicar_video() -> void:
	# Las pruebas automaticas no deben tomar la pantalla
	if "--pruebas" in OS.get_cmdline_user_args():
		return
	if pantalla_completa:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _ruta() -> String:
	if ruta_prueba != "":
		return ruta_prueba
	if "--pruebas" in OS.get_cmdline_user_args():
		return "user://pruebas_ajustes.cfg"
	return ARCHIVO
