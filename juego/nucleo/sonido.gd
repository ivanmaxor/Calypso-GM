extends Node
## Efectos, voces y música.
## La música pasa por un bus con filtro, que se cierra durante el Desync. Rota sola con fundido y no
## se reinicia al cambiar de pantalla. Todos los tiempos de aquí son reales, no cuadros: el juego
## tiene que sonar igual a 60 que a 240 Hz.

const CANALES := 20
const MIN_TEMA := 180.0  # un tema se repite hasta sonar al menos estos segundos
const FUNDIDO := 3.0  # entre temas de la rotación
const FUNDIDO_JEFE := 1.2  # al entrar y salir de un jefe
const FUNDIDO_CORTO := 0.6  # al elegir un tema en Opciones
const ANTICIPO := 10.0  # segundos antes del fundido: ahí se empieza a cargar el tema siguiente
const ESPERA_ELEGIR := 250  # ms: si se pasan temas seguidos, solo suena donde se detuvieron
const DUCK_VOZ := 0.63  # la música baja unos 4 dB mientras alguien habla

## Crédito a la vista: Scott Buckley lo pide (CC-BY 4.0). El detalle está en audio/musica/LICENCIAS_MUSICA.txt.
const CREDITO_MUSICA := "Música: HoliznaCC0, Komiku y Loyalty Freak Music (CC0); Scott Buckley (CC-BY 4.0)."

## Nombre, archivo, ganancia en dB y tipo. La ganancia iguala el volumen entre temas: lleva cada uno a
## -16 LUFS, medido con ebur128 (herramientas/audio/preparar_musica.py). El índice 0 es "Aleatorio".
const TEMAS := [
	["Aleatorio", "", 0.0, ""],
	["Ruby 1", "ruby_1", -2.6, "calma"], ["Ruby 2", "ruby_2", -1.9, "calma"], ["Ruby 3", "ruby_3", -0.4, "calma"],
	["Ruby 4", "ruby_4", -0.9, "calma"], ["Ruby 5", "ruby_5", -1.2, "calma"],
	["Amethyst 1", "amethyst_1", -1.1, "calma"], ["Amethyst 2", "amethyst_2", 0.6, "calma"], ["Amethyst 3", "amethyst_3", 3.9, "calma"],
	["Amethyst 4", "amethyst_4", 2.2, "calma"], ["Amethyst 5", "amethyst_5", 0.6, "calma"],
	["Jump and Shoot Stuff", "up_jump_and_shoot", -4.9, "accion"], ["Coming to the City", "up_coming_to_the_city", -4.4, "accion"],
	["Run on the Expressway", "up_run_on_the_expressway", -4.8, "accion"], ["First Infiltration", "up_first_infiltration", -2.6, "accion"],
	["Time for Retribution", "up_time_for_retribution", -3.4, "accion"], ["Second Strike", "up_second_strike", -3.5, "accion"],
	["Finally Together", "up_finally_together", -4.5, "accion"], ["High Risk Infiltration", "up_high_risk", -4.7, "accion"],
	["Punk Rock Circuit", "kart_punk_rock", -4.5, "accion"], ["Metal Circuit", "kart_metal", -3.7, "accion"],
	["200 Seconds to Escape", "adv_200_segundos", -4.6, "accion"], ["MEGA METAL", "lfm_mega_metal", -3.3, "accion"],
]
## Temas de jefe: recortados para partir ya en lo intenso, y llevados a -15 LUFS.
const JEFES := [
	["Goliath", "jefe_goliath", -1.1, "jefe"], ["Simulacra", "jefe_simulacra", -1.6, "jefe"], ["Legionnaire", "jefe_legionnaire", -5.9, "jefe"],
	["Song of the Forge", "jefe_forja", -1.8, "jefe"], ["Let's See What We Got", "jefe_last_boss", -4.5, "jefe"], ["Swoop Attack", "jefe_swoop", -4.1, "jefe"],
]
const SFX := ["disparo", "disparo_grueso", "disparo_riel", "disparo_cohete", "impacto", "kill", "kill_grande", "kill_jefe", "roce", "bit", "pizza", "nam",
	"nivel", "carta", "racha", "dash", "dano", "corazon_roto", "muerte", "desync_entra", "desync_tick", "reconectar", "cascada", "ace", "aviso_jefe",
	"fase_jefe", "aviso", "ui_mover", "ui_ok", "ui_no", "botin_0", "botin_1", "botin_2", "botin_3", "botin_4", "botin_5", "fusion", "mejora",
	"latido", "voz_0", "voz_1", "voz_2", "voz_3", "voz_4", "voz_5", "voz_6", "voz_7", "voz_8", "voz_9", "voz_10", "voz_11", "voz_12", "voz_13", "voz_14", "voz_15",
	"voz_ia_0", "voz_ia_1", "voz_ia_2", "voz_ia_3", "voz_ia_4", "voz_ia_5", "voz_ia_6", "voz_ia_7", "estrella", "desbloqueo", "nodo"]
const SILABAS_TUERCA := 16
const SILABAS_CALYPSO := 8


## Bolsa barajada: nada se repite hasta agotarla, y la siguiente no parte con lo último que sonó.
## Es lógica pura, sin audio, para poder simularla sin esperar los minutos reales.
class Bolsa:
	var indices: Array = []
	var bolsa: Array = []
	var ultimo := -1
	var rng: RandomNumberGenerator

	func _init(lista: Array, generador: RandomNumberGenerator) -> void:
		indices = lista
		rng = generador

	## Saca uno. Si hay preferidos en la bolsa, sale primero uno de esos. Nunca sale el que se pide evitar.
	func sacar(preferidos: Array = [], evitar := -1) -> int:
		if bolsa.is_empty():
			_rellenar()
		var pos := -1
		for k in range(bolsa.size() - 1, -1, -1):
			if bolsa[k] == evitar:
				continue
			if pos < 0:
				pos = k
			if bolsa[k] in preferidos:
				pos = k
				break
		if pos < 0:
			# solo quedaba el que acaba de sonar: ya se oyó, así que se empieza otra bolsa
			if indices.size() < 2:
				return evitar
			bolsa.clear()
			return sacar(preferidos, evitar)
		ultimo = bolsa[pos]
		bolsa.remove_at(pos)
		return ultimo

	func _rellenar() -> void:
		bolsa = indices.duplicate()
		for i in range(bolsa.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = bolsa[i]
			bolsa[i] = bolsa[j]
			bolsa[j] = t
		# se saca desde el final: lo que sonó recién se va al principio
		if bolsa.size() > 1 and bolsa[-1] == ultimo:
			bolsa[-1] = bolsa[0]
			bolsa[0] = ultimo


## Un reproductor de música con su fundido propio.
class Pista:
	var jugador: AudioStreamPlayer
	var vol := 0.0
	var objetivo := 0.0
	var velocidad := 1.0
	var ganancia := 0.0
	var largo := 0.0
	var pausar := false  # al apagarse queda en pausa, sin perder dónde iba

	func aplicar() -> void:
		# fundido de igual potencia: no se nota un bajón en la mitad
		var v := sin(vol * PI * 0.5)
		jugador.volume_db = ganancia + linear_to_db(v) if v > 0.001 else -80.0


var streams := {}
var canales: Array[AudioStreamPlayer] = []
var bus_musica: int
var bus_sfx: int
var filtro: AudioEffectLowPassFilter
var corte_objetivo := 20500.0
var corte := 20500.0
var ultimo := {}
var volumen_duck := 1.0
var duck_objetivo := 1.0
var duck_voz := 1.0
var rng := RandomNumberGenerator.new()  # propio: el audio no debe alterar el azar de la partida

# música
var pistas: Array[Pista] = []
var actual: Pista
var otra: Pista
var musica: AudioStreamPlayer  # el reproductor que suena ahora
var bolsa_temas: Bolsa
var bolsa_jefes: Bolsa
var tema_actual := 0  # índice en TEMAS; 0 = todavía ninguno
var segundos_tema := 0.0  # lo que ya sonó este tema, en pasadas completas
var en_jefe := false
var jefe_actual := -1
var pitch_musica := 1.0
var contexto := "calma"  # qué tipo se prefiere al sacar el siguiente tema
var tema_pendiente := -1
var pendiente_en := 0
var proximo_tema := -1  # ya salió de la bolsa y se está cargando
var proximo_jefe := -1
var pedidos := {}  # lo que se está cargando en segundo plano
var ultimo_fundido := 0

# voz
var voz_canal: AudioStreamPlayer
var voz_libre := 0  # antes de este instante (ms) no parte otra sílaba
var voz_activa_hasta := 0
var voz_ultima := -1
var voz_tono := 1.0
var voces_tocadas := 0
var sfx_tocados := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_crear_buses()
	for n in SFX:
		streams[n] = load("res://audio/sfx/%s.wav" % n)
	for i in CANALES:
		var p := AudioStreamPlayer.new()
		p.bus = "Efectos"
		add_child(p)
		canales.append(p)
	voz_canal = AudioStreamPlayer.new()
	voz_canal.bus = "Efectos"
	add_child(voz_canal)
	for i in 2:
		var pista := Pista.new()
		pista.jugador = AudioStreamPlayer.new()
		pista.jugador.bus = "Musica"
		add_child(pista.jugador)
		pista.jugador.finished.connect(_al_terminar.bind(pista))
		pistas.append(pista)
	actual = pistas[0]
	otra = pistas[1]
	musica = actual.jugador
	bolsa_temas = Bolsa.new(range(1, TEMAS.size()), rng)
	bolsa_jefes = Bolsa.new(range(JEFES.size()), rng)
	if Ajustes.tema_musica < 0 or Ajustes.tema_musica >= TEMAS.size():
		Ajustes.tema_musica = 0
	aplicar_volumen()


func _crear_buses() -> void:
	AudioServer.add_bus()
	bus_musica = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_musica, "Musica")
	AudioServer.set_bus_send(bus_musica, "Master")
	filtro = AudioEffectLowPassFilter.new()
	filtro.cutoff_hz = 20500.0
	AudioServer.add_bus_effect(bus_musica, filtro)
	AudioServer.add_bus()
	bus_sfx = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_sfx, "Efectos")
	AudioServer.set_bus_send(bus_sfx, "Master")


func aplicar_volumen() -> void:
	var db_musica := _db(Ajustes.musica)
	if db_musica > -80.0:
		db_musica += linear_to_db(maxf(volumen_duck * duck_voz, 0.001))
	AudioServer.set_bus_volume_db(bus_musica, db_musica)
	AudioServer.set_bus_volume_db(bus_sfx, _db(Ajustes.efectos))


## Curva de los deslizadores: cada mitad son 8 dB. 100 % = -5 dB, 50 % = -13 dB, 25 % = -21 dB.
func _db(v: float) -> float:
	if v <= 0.5:
		return -80.0
	return -5.0 + 8.0 * log(v / 100.0) / log(2.0)


## separacion: lo mínimo entre dos veces del mismo sonido, en sesentavos de segundo de tiempo real.
func tocar(nombre: String, pitch := 1.0, vol_db := 0.0, separacion := 2) -> void:
	# Un mismo sonido no se repite tan seguido: evita saturar, y no depende de los Hz del monitor
	var ahora := Time.get_ticks_usec()
	if ultimo.has(nombre) and ahora - ultimo[nombre] < separacion * 16667:
		return
	ultimo[nombre] = ahora
	if not streams.has(nombre):
		return
	for p in canales:
		if not p.playing:
			p.stream = streams[nombre]
			p.pitch_scale = pitch
			p.volume_db = vol_db
			p.play()
			sfx_tocados += 1
			return


# --- música -----------------------------------------------------------------------------------

## Sin argumento: asegura que suene algo, sin reiniciar nada. Con índice de TEMAS: elige ese tema.
func tocar_musica(indice := -1) -> void:
	if indice >= 0:
		_elegir_tema(indice % TEMAS.size())
		return
	musica_menu()


func nombre_tema() -> String:
	return TEMAS[clampi(Ajustes.tema_musica, 0, TEMAS.size() - 1)][0]


## Lo que suena en este momento, aunque la opción sea Aleatorio.
func tema_sonando() -> String:
	if en_jefe and jefe_actual >= 0:
		return JEFES[jefe_actual][0]
	return TEMAS[tema_actual][0] if tema_actual > 0 else ""


## Recorre "Aleatorio" y cada tema.
func cambiar_tema(paso: int) -> void:
	_elegir_tema(posmod(Ajustes.tema_musica + paso, TEMAS.size()))


## Las pantallas avisan dónde están. Nada se reinicia: solo cambia qué se prefiere para el próximo tema.
func musica_menu() -> void:
	contexto = "calma"
	_volver_a_normal()


func musica_juego() -> void:
	contexto = "accion"
	_volver_a_normal()
	_preparar_jefe()


## Si se sale de un combate con el jefe vivo, su música no puede quedar pegada.
func _volver_a_normal() -> void:
	musica_jefe(false)
	_asegurar_musica()


## Al aparecer un jefe entra su música con fundido, y el tema queda en pausa. Al morir, ese tema sigue
## donde iba: sin buscar la posición otra vez, que en un MP3 traba un par de cuadros.
func musica_jefe(activo: bool) -> void:
	if activo == en_jefe:
		return
	en_jefe = activo
	if activo:
		var normal := actual
		_preparar_jefe()
		jefe_actual = proximo_jefe
		proximo_jefe = -1
		if _poner(JEFES[jefe_actual][1], JEFES[jefe_actual][2], FUNDIDO_JEFE):
			normal.pausar = true
		return
	_preparar_jefe()
	var fijo: int = Ajustes.tema_musica
	if fijo > 0 and fijo != tema_actual:
		_tocar_tema(fijo, FUNDIDO_JEFE)
	elif otra.pausar:
		_reanudar(otra, FUNDIDO_JEFE)
	else:
		_tema_siguiente(FUNDIDO_JEFE)


func _elegir_tema(i: int) -> void:
	Ajustes.tema_musica = i
	tema_pendiente = i
	pendiente_en = Time.get_ticks_msec() + ESPERA_ELEGIR


func _asegurar_musica() -> void:
	if musica.playing or tema_pendiente >= 0:
		return
	if Ajustes.tema_musica > 0:
		_tocar_tema(Ajustes.tema_musica, FUNDIDO_CORTO)
	else:
		_tema_siguiente(FUNDIDO_CORTO)


func _rotando() -> bool:
	return Ajustes.tema_musica == 0


## ¿Con esta pasada ya se cumple el mínimo? Si es así, se cambia de tema al terminarla.
func ultima_pasada(segundos: float, largo: float) -> bool:
	return segundos + largo >= MIN_TEMA


func _sacar_tema() -> int:
	var preferidos := []
	for i in range(1, TEMAS.size()):
		if TEMAS[i][3] == contexto:
			preferidos.append(i)
	return bolsa_temas.sacar(preferidos, tema_actual)


func _tema_siguiente(fundido := FUNDIDO) -> void:
	var i := proximo_tema if proximo_tema > 0 else _sacar_tema()
	proximo_tema = -1
	_tocar_tema(i, fundido)


## El próximo jefe queda cargado desde antes: abrir un MP3 de golpe traba varios cuadros.
func _preparar_jefe() -> void:
	if proximo_jefe < 0:
		proximo_jefe = bolsa_jefes.sacar()
		_pedir(JEFES[proximo_jefe][1])


func _pedir(archivo: String) -> void:
	var ruta := "res://audio/musica/%s.mp3" % archivo
	if not pedidos.has(ruta) and ResourceLoader.load_threaded_request(ruta) == OK:
		pedidos[ruta] = true


func _recurso(archivo: String) -> AudioStream:
	var ruta := "res://audio/musica/%s.mp3" % archivo
	if pedidos.erase(ruta):
		return ResourceLoader.load_threaded_get(ruta)  # si ya terminó, no frena nada
	return load(ruta)


func _tocar_tema(i: int, fundido: float) -> void:
	if _poner(TEMAS[i][1], TEMAS[i][2], fundido):
		tema_actual = i
		segundos_tema = 0.0


## Prepara el tema en la pista libre y funde: la que sonaba se apaga sola.
func _poner(archivo: String, ganancia: float, fundido: float) -> bool:
	var s := _recurso(archivo)
	if s == null:
		return false
	var entra := otra
	entra.jugador.stop()
	entra.pausar = false
	entra.jugador.stream_paused = false
	entra.jugador.stream = s
	entra.jugador.pitch_scale = pitch_musica
	entra.ganancia = ganancia
	entra.largo = s.get_length()
	entra.vol = 0.0
	entra.aplicar()
	entra.jugador.play()
	_cruzar(entra, fundido)
	return true


## La pista que estaba en pausa vuelve a sonar donde iba.
func _reanudar(p: Pista, fundido: float) -> void:
	p.pausar = false
	p.jugador.stream_paused = false
	_cruzar(p, fundido)


func _cruzar(entra: Pista, fundido: float) -> void:
	var sale := actual
	entra.objetivo = 1.0
	entra.velocidad = 1.0 / fundido
	sale.objetivo = 0.0
	sale.velocidad = 1.0 / fundido
	otra = sale
	actual = entra
	musica = entra.jugador


## Terminó una pasada completa de una pista.
func _al_terminar(p: Pista) -> void:
	if p != actual:
		return  # iba saliendo: su fundido ya terminó o le falta poco
	if en_jefe:
		p.jugador.play()
		return
	segundos_tema += p.largo
	if _rotando() and segundos_tema >= MIN_TEMA:
		_tema_siguiente()
	else:
		p.jugador.play()


## Cuenta las pasadas y arranca el fundido justo antes de que termine la última.
func _vigilar_musica() -> void:
	if tema_pendiente >= 0 and Time.get_ticks_msec() >= pendiente_en:
		var i := tema_pendiente
		tema_pendiente = -1
		if not en_jefe and i > 0 and i != tema_actual:
			_tocar_tema(i, FUNDIDO_CORTO)
		elif not en_jefe:
			_asegurar_musica()
	if en_jefe or not _rotando() or not musica.playing or not ultima_pasada(segundos_tema, actual.largo):
		return
	var queda := actual.largo - musica.get_playback_position()
	if proximo_tema < 0 and queda <= FUNDIDO + ANTICIPO:
		proximo_tema = _sacar_tema()
		_pedir(TEMAS[proximo_tema][1])
	if queda <= FUNDIDO:
		_tema_siguiente()


## Con reloj real: si el juego se atrasa, el delta se recorta y el fundido no debe alargarse.
func _fundir() -> void:
	var ahora := Time.get_ticks_usec()
	var dt := (ahora - ultimo_fundido) / 1000000.0
	ultimo_fundido = ahora
	for p in pistas:
		if p.vol != p.objetivo:
			p.vol = move_toward(p.vol, p.objetivo, dt * p.velocidad)
			p.aplicar()
		if p.vol <= 0.0 and p.objetivo <= 0.0 and p.jugador.playing:
			if p.pausar:
				p.jugador.stream_paused = true
			else:
				p.jugador.stop()


# --- voz --------------------------------------------------------------------------------------

## Una sílaba de quien habla. Se puede llamar todo lo seguido que se quiera: se limita sola por
## tiempo real, encadena sílabas distintas y les mueve el tono para que suene a frase.
func voz(quien: String) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora < voz_libre:
		return
	var tuerca := quien == "tuerca"
	var cuantas := SILABAS_TUERCA if tuerca else SILABAS_CALYPSO
	var n := rng.randi_range(0, cuantas - 1)
	if n == voz_ultima:
		n = (n + rng.randi_range(1, cuantas - 1)) % cuantas
	voz_ultima = n
	var s = streams.get(("voz_%d" if tuerca else "voz_ia_%d") % n)
	if s == null:
		return
	var pausa_ms := 0
	if tuerca:
		# el tono camina y a veces pega un salto: el viejo se indigna
		voz_tono = clampf(voz_tono + rng.randf_range(-0.09, 0.09), 0.88, 1.16)
		if rng.randf() < 0.14:
			voz_tono = rng.randf_range(1.02, 1.26)
		if rng.randf() < 0.18:
			pausa_ms = rng.randi_range(70, 150)
	else:
		# Calypso no se emociona: solo tres escalones
		voz_tono = [0.97, 1.0, 1.03][rng.randi_range(0, 2)]
		if rng.randf() < 0.22:
			pausa_ms = rng.randi_range(90, 170)
	voz_canal.stream = s
	voz_canal.pitch_scale = voz_tono
	voz_canal.volume_db = 0.0
	voz_canal.play()
	voces_tocadas += 1
	var dura_ms := int(s.get_length() / voz_tono * 1000.0)
	voz_libre = ahora + int(dura_ms * 0.94) + pausa_ms
	voz_activa_hasta = ahora + dura_ms + 150


# --- efectos sobre la música ------------------------------------------------------------------

## Lag spike: se cierran los agudos y baja un poco el tono.
func desync(activo: bool) -> void:
	corte_objetivo = 420.0 if activo else 20500.0
	pitch_musica = 0.84 if activo else 1.0
	for p in pistas:
		p.jugador.pitch_scale = pitch_musica


## Silencio antes de la cascada.
func silencio(activo: bool) -> void:
	duck_objetivo = 0.06 if activo else 1.0


func pausa(activo: bool) -> void:
	corte_objetivo = 900.0 if activo else 20500.0


func _process(delta: float) -> void:
	if not is_equal_approx(corte, corte_objetivo):
		corte = lerpf(corte, corte_objetivo, minf(delta * 7.0, 1.0))
		if absf(corte - corte_objetivo) < 10.0:
			corte = corte_objetivo
		filtro.cutoff_hz = corte
	var cambio := false
	if not is_equal_approx(volumen_duck, duck_objetivo):
		volumen_duck = move_toward(volumen_duck, duck_objetivo, delta * 8.0)
		cambio = true
	# la música se hace a un lado mientras alguien habla: entra rápido y vuelve lento
	var hablando := Time.get_ticks_msec() < voz_activa_hasta
	var obj_voz := DUCK_VOZ if hablando else 1.0
	if not is_equal_approx(duck_voz, obj_voz):
		duck_voz = move_toward(duck_voz, obj_voz, delta * (5.0 if hablando else 0.9))
		cambio = true
	if cambio:
		aplicar_volumen()
	_fundir()
	_vigilar_musica()
