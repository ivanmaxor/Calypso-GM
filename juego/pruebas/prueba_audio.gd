extends Node
## Pruebas del audio. La parte rápida corre con --tests. La parte real (--audio) suena con el driver
## Dummy: adelanta cada tema hasta casi el final para no esperar los minutos de verdad.

const SALTO := 0.25  # cuánto se deja sonar de cada pasada


# --- parte rápida: reglas sin audio ------------------------------------------------------------

static func correr(ok: Callable) -> void:
	# curva de volumen
	ok.call(absf(Sonido._db(100) - (-5.0)) < 0.01, "volumen 100 % = -5 dB")
	ok.call(absf(Sonido._db(50) - (-13.0)) < 0.01, "volumen 50 % = -13 dB")
	ok.call(absf(Sonido._db(25) - (-21.0)) < 0.01, "volumen 25 % = -21 dB")
	ok.call(Sonido._db(0) <= -80.0, "volumen 0 % es silencio")
	# todos los temas existen
	ok.call(Sonido.TEMAS[0][0] == "Aleatorio", "el primer tema es Aleatorio")
	ok.call(Sonido.JEFES.size() >= 3, "al menos 3 temas de jefe")
	for lista in [Sonido.TEMAS.slice(1), Sonido.JEFES]:
		for t in lista:
			var s = load("res://audio/musica/%s.mp3" % t[1])
			ok.call(s != null, "existe " + t[1])
			ok.call(s != null and s.get_length() > 60.0, "dura más de un minuto " + t[1])
			ok.call(absf(t[2]) < 8.0, "ganancia razonable " + t[1])
	for n in Sonido.SFX:
		ok.call(Sonido.streams.get(n) != null, "existe el sonido " + n)
	# Opciones recorre Aleatorio y cada tema, sin salirse
	var guardado: int = Ajustes.tema_musica
	Ajustes.tema_musica = 0
	var vistos := {}
	for i in Sonido.TEMAS.size():
		vistos[Sonido.nombre_tema()] = true
		Sonido.cambiar_tema(1)
	ok.call(vistos.size() == Sonido.TEMAS.size(), "cambiar_tema pasa por todos")
	ok.call(Ajustes.tema_musica == 0, "cambiar_tema da la vuelta a Aleatorio")
	Sonido.cambiar_tema(-1)
	ok.call(Ajustes.tema_musica == Sonido.TEMAS.size() - 1, "cambiar_tema hacia atrás da la vuelta")
	Ajustes.tema_musica = guardado
	Sonido.tema_pendiente = -1
	_bolsa(ok)
	_minimo(ok)
	_voz_y_separacion(ok)
	_ajustes(ok)


## La bolsa no repite hasta agotarse y no parte con lo último que sonó.
static func _bolsa(ok: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var cuantos: int = Sonido.TEMAS.size() - 1
	var b = Sonido.Bolsa.new(range(1, cuantos + 1), rng)
	var ultimo := -1
	var sin_repetir := true
	var sin_pegar := true
	var acciones := []
	for i in Sonido.TEMAS.size():
		if Sonido.TEMAS[i][3] == "accion":
			acciones.append(i)
	var primero_accion := true
	for vuelta in 200:
		var vistos := {}
		for k in cuantos:
			var t: int = b.sacar(acciones)
			if vistos.has(t):
				sin_repetir = false
			vistos[t] = true
			if t == ultimo:
				sin_pegar = false
			ultimo = t
			# con preferencia: primero salen todos los de acción, y recién después los otros
			if k < acciones.size() and not t in acciones:
				primero_accion = false
		if vistos.size() != cuantos:
			sin_repetir = false
	ok.call(sin_repetir, "la bolsa no repite hasta agotarse")
	ok.call(sin_pegar, "ningún tema suena dos veces seguidas al rellenar")
	ok.call(primero_accion, "en combate salen primero los temas movidos")
	# después de un tema fijo no puede salir ese mismo, ni aunque sea lo único que queda en la bolsa
	var d = Sonido.Bolsa.new(range(1, 5), rng)
	var nunca := true
	for i in 300:
		var evitar := (i % 4) + 1
		if d.sacar([], evitar) == evitar:
			nunca = false
	ok.call(nunca, "la bolsa respeta el tema que se pide evitar")
	var unica = Sonido.Bolsa.new([7], rng)
	ok.call(unica.sacar([], 7) == 7, "una bolsa de uno no se queda pegada")
	# el azar del audio es propio: no mueve el de la partida
	seed(1234)
	var a := randi()
	seed(1234)
	var c = Sonido.Bolsa.new(range(1, 5), Sonido.rng)
	c.sacar()
	Sonido.voz_libre = 0
	Sonido.voz("tuerca")
	Sonido.voz_canal.stop()
	ok.call(randi() == a, "el audio no altera el azar de la partida")


## Simula el reloj con el largo real de cada tema: nunca cambia antes de los 3 minutos ni con una pasada de más.
static func _minimo(ok: Callable) -> void:
	var cumple := true
	var sin_sobra := true
	var mas_largo := 0.0
	for t in Sonido.TEMAS.slice(1):
		var largo: float = load("res://audio/musica/%s.mp3" % t[1]).get_length()
		var segundos := 0.0
		while true:
			var ultima: bool = Sonido.ultima_pasada(segundos, largo)
			segundos += largo
			if ultima:
				break
		if segundos < Sonido.MIN_TEMA:
			cumple = false
		if segundos - largo >= Sonido.MIN_TEMA:
			sin_sobra = false
		mas_largo = maxf(mas_largo, segundos)
	ok.call(cumple, "cada tema suena al menos 3 minutos")
	ok.call(sin_sobra, "cambia al terminar la pasada que cumple los 3 minutos")
	ok.call(mas_largo < 7.0 * 60.0, "ningún tema se queda más de 7 minutos")


## La voz y los efectos se limitan por tiempo, sin importar cuántas veces se llamen.
static func _voz_y_separacion(ok: Callable) -> void:
	Sonido.voz_libre = 0
	var antes: int = Sonido.voces_tocadas
	for i in 500:
		Sonido.voz("tuerca")
	ok.call(Sonido.voces_tocadas - antes == 1, "la voz no se dispara si se llama muchas veces seguidas")
	var espera: int = Sonido.voz_libre - Time.get_ticks_msec()
	ok.call(espera > 60 and espera < 400, "la siguiente sílaba espera lo que dura esta")
	Sonido.voz_canal.stop()
	Sonido.voz_libre = 0
	Sonido.voz_activa_hasta = 0
	antes = Sonido.sfx_tocados
	Sonido.ultimo.erase("ui_mover")
	for i in 500:
		Sonido.tocar("ui_mover")
	ok.call(Sonido.sfx_tocados - antes == 1, "un efecto no se repite dentro de su separación")
	for c in Sonido.canales:
		c.stop()


## El que venía con un archivo de antes parte en 50 % y Aleatorio, una sola vez.
static func _ajustes(ok: Callable) -> void:
	var ruta := "user://prueba_audio_%d.cfg" % OS.get_process_id()
	Ajustes.ruta_prueba = ruta
	var m: int = Ajustes.musica
	var e: int = Ajustes.efectos
	var tm: int = Ajustes.tema_musica
	var viejo := ConfigFile.new()
	viejo.set_value("audio", "musica", 10)
	viejo.set_value("audio", "efectos", 60)
	viejo.set_value("audio", "tema_musica", 4)
	viejo.save(ruta)
	Ajustes.cargar()
	ok.call(Ajustes.musica == 50, "archivo viejo: música a 50 %")
	ok.call(Ajustes.tema_musica == 0, "archivo viejo: tema en Aleatorio")
	ok.call(Ajustes.efectos == 60, "archivo viejo: conserva sus efectos")
	Ajustes.musica = 30
	Ajustes.tema_musica = 3
	Ajustes.guardar()
	Ajustes.cargar()
	ok.call(Ajustes.musica == 30 and Ajustes.tema_musica == 3, "la migración ocurre una sola vez")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	Ajustes.ruta_prueba = ""
	Ajustes.musica = m
	Ajustes.efectos = e
	Ajustes.tema_musica = tm


# --- parte real: reproductores de verdad, con el reloj adelantado --------------------------------

var pasadas := 0
var fallos := 0


func _ok(cond: bool, nombre: String) -> void:
	if cond:
		pasadas += 1
	else:
		fallos += 1
		print("  FALLA: ", nombre)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await _real()
	print("[audio] pasadas=%d fallos=%d" % [pasadas, fallos])
	get_tree().quit()


func _esperar(seg: float) -> void:
	var fin := Time.get_ticks_msec() + int(seg * 1000.0)
	while Time.get_ticks_msec() < fin:
		await get_tree().process_frame


## Salta hasta casi el final de la pasada actual y espera a que termine o a que cambie el tema.
func _adelantar() -> void:
	Sonido.musica.seek(maxf(Sonido.actual.largo - SALTO, 0.0))
	await _esperar(SALTO + 0.25)


func _real() -> void:
	Ajustes.tema_musica = 0
	Ajustes.musica = 50
	Sonido.aplicar_volumen()
	# 1) arranca y no se reinicia al cambiar de pantalla
	Sonido.musica_menu()
	await _esperar(0.6)
	var t0: int = Sonido.tema_actual
	_ok(Sonido.musica.playing and t0 > 0, "empieza a sonar")
	print("  primer tema: ", Sonido.tema_sonando(), " (tipo ", Sonido.TEMAS[t0][3], ")")
	_ok(Sonido.TEMAS[t0][3] == "calma", "en menús prefiere un tema calmado")
	var pos0: float = Sonido.musica.get_playback_position()
	Sonido.musica_juego()
	Sonido.tocar_musica()
	Sonido.musica_juego()
	await _esperar(0.3)
	_ok(Sonido.tema_actual == t0 and Sonido.musica.get_playback_position() > pos0, "no se reinicia al cambiar de pantalla")
	# 2) rotación real: varias pasadas con el reloj adelantado
	var sonados := []
	var mal_minimo := 0
	var repetidos := 0
	for n in 14:
		var tema: int = Sonido.tema_actual
		var largo: float = Sonido.actual.largo
		if tema in sonados:
			repetidos += 1
		sonados.append(tema)
		var veces := 0
		while Sonido.tema_actual == tema and veces < 12:
			veces += 1
			var antes: float = Sonido.segundos_tema
			await _adelantar()
			if Sonido.tema_actual != tema and antes + largo < Sonido.MIN_TEMA:
				mal_minimo += 1
		print("  tema %d: %s (%s), %d pasadas de %.0f s = %.0f s" % [n + 1, Sonido.TEMAS[tema][0], Sonido.TEMAS[tema][3], veces, largo, veces * largo])
		_ok(veces * largo >= Sonido.MIN_TEMA, "%s suena al menos 3 minutos" % Sonido.TEMAS[tema][0])
		_ok((veces - 1) * largo < Sonido.MIN_TEMA, "%s cambia al terminar la pasada que los cumple" % Sonido.TEMAS[tema][0])
	_ok(mal_minimo == 0, "ningún tema cambió antes de los 3 minutos")
	_ok(repetidos == 0, "14 temas seguidos sin repetir")
	var movidos := 0
	for t in sonados:
		if Sonido.TEMAS[t][3] == "accion":
			movidos += 1
	_ok(movidos >= 12, "en combate salen temas movidos (%d de 14)" % movidos)
	# 3) el fundido apaga la otra pista
	await _esperar(float(Sonido.FUNDIDO) + 0.3)
	_ok(not Sonido.otra.jugador.playing, "el tema anterior se apaga con el fundido")
	_ok(absf(Sonido.actual.vol - 1.0) < 0.01, "el tema nuevo queda a volumen completo")
	# 4) jefe: entra con fundido, se repite y al terminar vuelve al mismo tema donde iba
	var tema_antes: int = Sonido.tema_actual
	var seg_antes: float = Sonido.segundos_tema
	Sonido.musica.seek(30.0)
	await _esperar(0.2)
	var pos_antes: float = Sonido.musica.get_playback_position()
	var stream_antes = Sonido.musica.stream
	await _esperar(0.4)
	var u_jefe := Time.get_ticks_usec()
	Sonido.musica_jefe(true)
	print("  entrar al jefe, ya cargado en segundo plano: %.1f ms" % ((Time.get_ticks_usec() - u_jefe) / 1000.0))
	_ok(Sonido.en_jefe and Sonido.musica.stream != stream_antes, "entra el tema de jefe")
	print("  jefe: ", Sonido.tema_sonando())
	var de_jefe := false
	for j in Sonido.JEFES:
		if Sonido.musica.stream.resource_path.ends_with(j[1] + ".mp3"):
			de_jefe = true
	_ok(de_jefe, "el tema es de la lista de jefes")
	await _esperar(float(Sonido.FUNDIDO_JEFE) + 0.3)
	_ok(Sonido.otra.jugador.stream_paused, "el tema normal queda en pausa")
	await _adelantar()
	_ok(Sonido.en_jefe and Sonido.musica.playing and Sonido.musica.get_playback_position() < 5.0, "el tema de jefe se repite si la pelea sigue")
	Sonido.musica_jefe(true)
	_ok(Sonido.en_jefe, "pedir jefe dos veces no hace nada raro")
	var u_salida := Time.get_ticks_usec()
	Sonido.musica_jefe(false)
	print("  volver del jefe al tema anterior: %.1f ms" % ((Time.get_ticks_usec() - u_salida) / 1000.0))
	await _esperar(0.3)
	_ok(not Sonido.en_jefe and Sonido.tema_actual == tema_antes and Sonido.musica.stream == stream_antes, "vuelve al tema que sonaba")
	var pos_vuelta: float = Sonido.musica.get_playback_position()
	_ok(pos_vuelta >= pos_antes and pos_vuelta < pos_antes + 3.0, "y sigue donde iba (%.1f s, se había ido en %.1f s)" % [pos_vuelta, pos_antes])
	_ok(not Sonido.musica.stream_paused, "ya no está en pausa")
	_ok(is_equal_approx(Sonido.segundos_tema, seg_antes), "los minutos del tema no se pierden")
	await _esperar(float(Sonido.FUNDIDO_JEFE) + 0.3)
	# salir del combate con el jefe vivo no deja su música pegada
	Sonido.musica_jefe(true)
	await _esperar(0.2)
	Sonido.musica_menu()
	_ok(not Sonido.en_jefe, "salir al menú termina la música de jefe")
	await _esperar(float(Sonido.FUNDIDO_JEFE) + 0.3)
	_ok(Sonido.tema_actual == tema_antes and Sonido.musica.stream == stream_antes and Sonido.musica.playing, "y sigue el tema de antes")
	_ok(not Sonido.otra.jugador.playing, "y el de jefe se apaga")
	# elegir otro tema durante un jefe: suena recién al terminar el jefe
	Sonido.musica_jefe(true)
	await _esperar(float(Sonido.FUNDIDO_JEFE) + 0.3)
	var elegido: int = 2 if tema_antes != 2 else 3
	Sonido.tocar_musica(elegido)
	await _esperar(0.5)
	_ok(Sonido.en_jefe and Sonido.tema_actual == tema_antes, "elegir un tema no corta al jefe")
	Sonido.musica_jefe(false)
	await _esperar(0.2)
	_ok(Sonido.tema_actual == elegido and Sonido.musica.playing, "al terminar el jefe suena el elegido")
	_ok(not Sonido.musica.stream_paused, "y no queda en pausa")
	await _esperar(float(Sonido.FUNDIDO_JEFE) + 0.3)
	# 5) tema fijo: se queda aunque pasen los 3 minutos
	Ajustes.tema_musica = 0
	Sonido.cambiar_tema(1)
	Sonido.cambiar_tema(1)
	Sonido.cambiar_tema(1)
	_ok(Sonido.nombre_tema() == Sonido.TEMAS[3][0], "la opción cambia al tiro")
	await _esperar(0.5)
	_ok(Sonido.tema_actual == 3, "suena donde se detuvo, sin pasar por los otros")
	for v in 6:
		await _adelantar()
	_ok(Sonido.tema_actual == 3 and Sonido.musica.playing, "un tema fijo no rota")
	_ok(Sonido.segundos_tema >= Sonido.MIN_TEMA, "ya sonó más de 3 minutos")
	# vuelve a Aleatorio: sigue el que sonaba y luego rota
	Ajustes.tema_musica = 1
	Sonido.cambiar_tema(-1)
	_ok(Sonido.nombre_tema() == "Aleatorio", "vuelve a Aleatorio")
	await _esperar(0.5)
	_ok(Sonido.tema_actual == 3, "no corta el tema al volver a Aleatorio")
	await _adelantar()
	await _esperar(0.3)
	_ok(Sonido.tema_actual != 3, "y con los 3 minutos cumplidos rota")
	# 6) Desync: el tono baja en la pista que suena y vuelve
	Sonido.desync(true)
	_ok(is_equal_approx(Sonido.musica.pitch_scale, 0.84), "el Desync baja el tono")
	await _esperar(0.2)
	Sonido.musica_jefe(true)
	_ok(is_equal_approx(Sonido.musica.pitch_scale, 0.84), "un tema que entra durante el Desync respeta el tono")
	Sonido.musica_jefe(false)
	Sonido.desync(false)
	_ok(is_equal_approx(Sonido.musica.pitch_scale, 1.0), "y vuelve al salir")
	# 7) voz: ritmo por tiempo real, sin importar los cuadros
	await _esperar(0.3)
	var v0: int = Sonido.voces_tocadas
	var cuadros := 0
	var ini := Time.get_ticks_msec()
	while Time.get_ticks_msec() - ini < 4000:
		Sonido.voz("tuerca")
		cuadros += 1
		await get_tree().process_frame
	var por_seg := (Sonido.voces_tocadas - v0) / 4.0
	print("  voz Tuerca: %.1f sílabas por segundo, con %d cuadros por segundo" % [por_seg, cuadros / 4])
	_ok(por_seg > 3.5 and por_seg < 9.0, "la voz va a ritmo de habla")
	_ok(Sonido.duck_voz < 0.8, "la música baja mientras alguien habla")
	await _esperar(1.5)
	_ok(is_equal_approx(Sonido.duck_voz, 1.0), "y vuelve al callarse")
	v0 = Sonido.voces_tocadas
	ini = Time.get_ticks_msec()
	while Time.get_ticks_msec() - ini < 3000:
		Sonido.voz("calypso")
		await get_tree().process_frame
	print("  voz Calypso: %.1f sílabas por segundo" % ((Sonido.voces_tocadas - v0) / 3.0))
	_ok((Sonido.voces_tocadas - v0) >= 9, "Calypso también habla")
	# 8) la misma voz cuando el juego va a menos cuadros por segundo
	await _esperar(0.3)
	var f0 := Engine.max_fps
	Engine.max_fps = 30
	v0 = Sonido.voces_tocadas
	ini = Time.get_ticks_msec()
	while Time.get_ticks_msec() - ini < 3000:
		Sonido.voz("tuerca")
		await get_tree().process_frame
	var a_30 := (Sonido.voces_tocadas - v0) / 3.0
	Engine.max_fps = f0
	print("  voz a 30 cuadros por segundo: %.1f sílabas por segundo" % a_30)
	_ok(absf(a_30 - por_seg) < 2.0, "el ritmo no depende de los cuadros")
	# 9) cargar un tema al vuelo no debe trabar el combate
	var peor := 0
	for t in Sonido.TEMAS.slice(1) + Sonido.JEFES:
		var u0 := Time.get_ticks_usec()
		ResourceLoader.load("res://audio/musica/%s.mp3" % t[1], "", ResourceLoader.CACHE_MODE_IGNORE)
		peor = maxi(peor, Time.get_ticks_usec() - u0)
	print("  cargar un tema de golpe tarda como máximo %.1f ms (por eso se carga antes, en segundo plano)" % (peor / 1000.0))
	var u0 := 0
	var peor_cambio := 0
	for n in 5:
		Ajustes.tema_musica = 0
		await _esperar(0.2)
		Sonido.proximo_tema = Sonido._sacar_tema()
		Sonido._pedir(Sonido.TEMAS[Sonido.proximo_tema][1])
		await _esperar(float(Sonido.ANTICIPO) * 0.1)
		u0 = Time.get_ticks_usec()
		Sonido._tema_siguiente()
		peor_cambio = maxi(peor_cambio, Time.get_ticks_usec() - u0)
	print("  cambio de tema con carga anticipada: como máximo %.1f ms" % (peor_cambio / 1000.0))
	_ok(peor_cambio < 16000, "el cambio de tema no traba un cuadro (%.1f ms)" % (peor_cambio / 1000.0))
