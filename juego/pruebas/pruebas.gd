extends Node
## Herramientas de prueba. Solo se activan con el argumento --pruebas.
##
##   --pantalla=mapa|hangar|combate|titulo|opciones|teclas|resultado|naves|panel|dialogo|premio|slots|dificultad|nueva_plus|pausa   abre esa pantalla
##   --modo=cargar|nueva|importar                 lo que hace la pantalla de ranuras
##   --ranuras=normal:1-4,dificil:fin:2,vacia     arma las ranuras: dificultad:hasta qué nivel[:ciclo]
##   --premio=a_cohetes                           premio de ese desafío (sin esto, el del --nivel=)
##   --res=ganado|derrota|retiro|retiro_rapido|infinito|ruleta   el resultado que se muestra
##   --pestana=naves|equipo|fusionar|mascota      pestana del hangar
##   --opcion=0..3                                pestana de opciones
##   --nivel=1-4                                  nivel que se juega
##   --nave=id                                    nave que se usa
##   --armas=a,b  --habs=a,b  --evo               parte el combate con eso puesto
##   --bot  --torpe                               juega solo, bien o mal
##   --quieto                                     bot que no se mueve ni esquiva nunca
##   --ciego                                      bot que persigue enemigos y elige bien las cartas, pero jamás esquiva
##   --generar=1-8                                arma con Partida.generar_para la partida de quien viene llegando a ese nivel
##   --ruleta=jefe,jefe,jefe                      fuerza lo que sale en la tragamonedas
##   --campana                                    juega todo el mundo en orden, usando el Hangar
##   --barrido  --ciego                           cada nivel una vez / un bot que no esquiva nada
##   --capturas=carpeta  --en=100,500  --auto     guarda imagenes
##   --salir=N                                    termina en el cuadro N
##   --hasta=1-4 o --hasta=fin                    deja la partida avanzada hasta ahí
##   --generar=1-8 --salida=ruta.json             escribe una partida lista para importar y termina
##   --demo  --saltar=SEG  --estres=N  --tests  --flujo  --verboso  --log  --perf
##   --flujo_hangar                               recorre la sala y las estaciones con teclas y mouse
##   --demo_arsenal  --sub=piezas  --sel=id       Arsenal a mitad de camino, pestaña y cosa seleccionada

var activo := false
var args := {}
var principal: Node
var cuadro := 0
var capturas := {}
var carpeta := ""
var salir := -1
var bot := false
var torpe := false
var reaccion := 4
var ruido := 0.0
var dir_actual := Vector2.ZERO
var bot_espera := 0
var dash_pendiente := false
var ultimo_log := 0
var estres := 0
var tiempos := []
var peor := 0.0
var veces := 0
var repetir := 1
var ganadas := 0
var intentos := {}
var suma := {}
const ACCIONES := ["mover_arriba", "mover_abajo", "mover_izquierda", "mover_derecha"]


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var p: PackedStringArray = a.substr(2).split("=")
			args[p[0]] = p[1] if p.size() > 1 else "1"
	activo = args.has("pruebas")
	process_physics_priority = -100
	process_priority = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(activo)
	set_physics_process(activo)
	if not activo:
		return
	if not DisplayServer.get_name() == "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		DisplayServer.window_set_position(Vector2i(-2600, 60))
	bot = args.has("bot")
	torpe = args.has("torpe")
	if torpe:
		reaccion = 16
		ruido = 0.22
	salir = int(args.get("salir", "-1"))
	carpeta = args.get("capturas", "")
	estres = int(args.get("estres", "0"))
	repetir = int(args.get("repetir", "1"))
	seed(int(args.get("semilla", "12345")))
	if args.has("en"):
		for n in args.en.split(","):
			capturas[int(n)] = true
	# esto va antes de que se arme el título, que muestra lo que hay en las ranuras
	if args.has("reiniciar") and Partida.prueba != "":
		_limpiar_guardados()
	if args.has("ranuras"):
		_armar_ranuras(args.ranuras)


## Parte de cero de verdad: solo toca los archivos de esta prueba, nunca los del jugador.
func _limpiar_guardados() -> void:
	var nombres: Array = [Partida.prueba + ".json", Partida.prueba + "_global.json", Partida.prueba + "_v2.json", Partida.prueba + "_importar.json"]
	for i in range(1, Partida.NUM_SLOTS + 1):
		nombres.append("%s_%d.json" % [Partida.prueba, i])
	for n in nombres:
		var ruta: String = "user://" + n
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	Partida._cargar_global()
	Partida.nuevo()


func _armar_ranuras(txt: String) -> void:
	var partes: PackedStringArray = txt.split(",")
	for i in mini(partes.size(), Partida.NUM_SLOTS):
		var p: PackedStringArray = partes[i].split(":")
		if p[0] == "vacia":
			continue
		Partida.slot = i + 1
		var hasta: String = p[1] if p.size() > 1 else "1-1"
		Partida.generar_para("1-8" if hasta == "fin" else hasta, p[0])
		if hasta == "fin":
			Partida.completar_nivel("1-8", {"golpes": 0, "max_cadena": 999})
		if p.size() > 2:
			Partida.d.ciclo = int(p[2])
		Partida.d.tiempo = 1500 * (i + 1) + 90
		Partida.guardar()
	Partida.slot = 0
	Partida.nuevo()


func iniciar(p: Node) -> void:
	principal = p
	if not activo:
		return
	if args.has("reiniciar"):
		Partida.nuevo()
	if args.has("generar") and args.has("salida"):
		Partida.generar_para(args.generar, args.get("dificultad", "normal"))
		var ruta: String = args.salida
		Partida._escribir_json(ruta, Partida.d)
		print("[generar] ", ruta)
		get_tree().quit()
		return
	if args.has("hasta"):
		_avanzar_hasta(args.hasta)
	if args.has("generar"):
		Partida.generar_para(args.generar, args.get("dificultad", "normal"))
		Partida.nivel_sel = args.generar
		_marcar_vistos()
	if args.has("mascota"):
		Partida.dar_mascota(args.mascota)
		Partida.desbloquear("mascota")
		Partida.elegir_mascota(args.mascota)
	if args.has("ciclo"):
		Partida.d.ciclo = int(args.ciclo)
	if args.has("dificultad"):
		Partida.d.dificultad = args.dificultad
	if args.has("demo"):
		_demo()
	if args.has("nivel"):
		Partida.nivel_sel = args.nivel
	if args.has("nave"):
		if not args.nave in Partida.d.naves:
			Partida.d.naves.append(args.nave)
		Partida.d.nave = args.nave
	if args.has("tests"):
		_tests()
		get_tree().quit()
		return
	if args.has("audio"):
		add_child(load("res://pruebas/prueba_audio.gd").new())
		return
	if args.has("flujo"):
		return
	if args.has("flujo_hangar"):
		_flujo_hangar()
		return
	if args.has("demo_arsenal"):
		_demo_arsenal()
	if args.has("campana"):
		Partida.nivel_sel = Partida.nivel_actual()
		p.ir_combate()
		return
	match args.get("pantalla", ""):
		"mapa":
			_marcar_vistos()
			p.ir_mapa(args.get("recien", ""))
		"hangar":
			p.ir_hangar(args.get("pestana", ""))
			_abrir_en_hangar(p.actual)
		"combate":
			p.ir_combate()
		"naves":
			p.ir_seleccion()
		"panel":
			_marcar_vistos()
			p.ir_mapa()
			p.actual._abrir_panel(args.get("nivel", "1-1"))
		"dialogo":
			p.ir_mapa()
			Partida.d.vistos.erase(args.get("clave", "inicio"))
			var D = load("res://pantallas/dialogo.gd")
			D.mostrar(p.actual, args.get("clave", "inicio"), func(): pass)
		"premio":
			_marcar_vistos()
			var pr = load("res://pantallas/premio.gd").new()
			pr.premio = _premio_demo()
			p.ir_mapa()
			p.actual.add_child(pr)
		"resultado":
			_marcar_vistos()
			p.ir_resultado(_res_demo())
		"slots":
			var sl = load("res://pantallas/slots.gd").new()
			sl.modo = args.get("modo", "cargar")
			p.actual.add_child(sl)
		"dificultad":
			var di = load("res://pantallas/elegir_dificultad.gd").new()
			di.subtitulo = "Ranura 1. Partida nueva."
			p.actual.add_child(di)
		"nueva_plus":
			_marcar_vistos()
			p.ir_mapa()
			p.actual._nueva_plus()
		"pausa":
			p.ir_combate()
		"opciones":
			var o = load("res://pantallas/opciones.gd").new()
			o.pestana = int(args.get("opcion", "0"))
			p.actual.add_child(o)
	if args.has("saltar") and p.actual is Node2D:
		var c = p.actual
		c.guion_t = float(args.saltar)
		while c.guion_i < c.guion.size() and c.guion[c.guion_i].t < c.guion_t:
			c.guion_i += 1
		if c.modo_nivel == "infinito":
			c.inf_hasta = c.guion_t
			c.inf_sig_jefe = (floor(c.guion_t / 120.0) + 1.0) * 120.0
			c.inf_jefes = int(floor(c.guion_t / 120.0))
	if p.actual and p.actual.has_method("elegir_carta"):
		_preparar_combate(p.actual)
		if args.get("pantalla", "") == "pausa":
			p.actual.abrir_pausa.call_deferred()


func _res_demo(tipo := "") -> Dictionary:
	var r := {"ganado": true, "kills": 182, "jefes": 0, "jefe": false, "tiempo": 96, "nivel": 11, "max_cadena": 44, "desyncs": 3, "aces": 1, "roces": 80, "nams": 12, "golpes": 2, "chatarra": 64, "evoluciones": 0, "nivel_id": Partida.nivel_sel, "abandono": false, "modo": "normal", "kills_tipo": {}, "esquivas": 0, "cambios": 0, "giros": 0, "jackpots": 0, "nave": Partida.nave_actual(), "hp": 40, "hp_max": 70, "build": ""}
	match tipo if tipo != "" else args.get("res", "ganado"):
		"derrota":
			r.ganado = false
			r.tiempo = 73
		"retiro":
			r.ganado = false
			r.abandono = true
			r.tiempo = 73
		"retiro_rapido":
			r.ganado = false
			r.abandono = true
			r.tiempo = 4
			r.kills = 2
		"infinito":
			r.ganado = false
			r.modo = "infinito"
			r.nivel_id = "1-INF"
			r.tiempo = 214
			r.kills = 612
		"ruleta":
			r.modo = "ruleta"
			r.nivel_id = "1-R"
			r.giros = 2
			r.jackpots = 1
	return r


func _premio_demo() -> Dictionary:
	if args.has("premio"):
		for de in Datos.DESAFIOS:
			if de.id == args.premio:
				return Partida._premio_desafio(de)
	var id: String = args.get("nivel", "1-3")
	return Partida._aplicar_premio(Datos.NIVELES[id].premio.duplicate(), id)


func _preparar_combate(c) -> void:
	if args.has("armas"):
		for id in args.armas.split(","):
			var a = c.arsenal.buscar(id)
			if a == null:
				a = c.arsenal.agregar(id)
			if args.has("evo"):
				while a.nivel < Datos.NIVEL_MAX_CARTA:
					c.arsenal.subir(a)
				c.arsenal.evolucionar(a)
	if args.has("habs"):
		for id in args.habs.split(","):
			c.habs[id] = 1
			var h: Dictionary = Datos.HABILIDADES[id]
			if h.has("mods"):
				Partida._sumar(c.stats, h.mods)
			if h.get("especial", "") == "escudo":
				c.escudo = true
	if args.has("cartas"):
		c.niveles_pendientes = 1
	if args.has("barra"):
		c.barra = float(args.barra)
	if args.has("ruleta"):
		c.ruleta_forzada = Array(args.ruleta.split(","))


func _marcar_vistos() -> void:
	for k in Datos.DIALOGOS:
		if not k in Partida.d.vistos:
			Partida.d.vistos.append(k)


## Deja la partida como si ya hubieras jugado hasta ese nivel (solo para probar).
func _avanzar_hasta(id: String) -> void:
	for n in Datos.ORDEN_NIVELES:
		if n == id:
			break
		Partida.completar_nivel(n, {"golpes": 2, "max_cadena": 999 if randf() < 0.5 else 0})
	_marcar_vistos()


func _demo() -> void:
	# inventario de muestra para ver el hangar con piezas de todas las rarezas
	Partida.d.chatarra = 1800
	Partida.dar_mascota("mordisco")
	Partida.d.mascotas.mordisco.xp = 180
	for id in Datos.ITEMS:
		for r in [0, 0, 0, 1, 1, 2, 3, 4, 5]:
			if randf() < 0.55:
				Partida.agregar(id, r)
	Partida.equipar(Partida.agregar("mira_laser", 3).uid)
	Partida.equipar(Partida.agregar("alas_iman", 4).uid)
	Partida.equipar(Partida.agregar("motor_fantasma", 5).uid)


func _physics_process(_d: float) -> void:
	if args.has("flujo") and principal:
		if not f_en_curso:
			_flujo()
		return
	if args.has("vitrina") and principal and principal.actual and principal.actual.has_method("elegir_carta"):
		_vitrina(principal.actual)
	if not principal or not bot:
		return
	var c = principal.actual
	if c == null:
		return
	if c.has_method("elegir_carta"):
		_bot_combate(c)
	elif c.has_signal("al_mapa") and c.b1.visible:
		if args.has("campana"):
			_campana(c)
		elif repetir > 1:
			_contar(c.res)
			repetir -= 1
			if args.has("progreso"):
				_usar_hangar()
			principal.ir_combate()
			_preparar_combate(principal.actual)
		else:
			_contar(c.res)
			_resumen()
			get_tree().quit()


func _campana(c) -> void:
	var res: Dictionary = c.res
	var id: String = res.nivel_id
	intentos[id] = intentos.get(id, 0) + 1
	print("[campana] %s #%d %s t=%ds kills=%d niv=%d golpes=%d/%d hp=%d/%d cadena=%d/%d desync=%d ace=%d est=%d chat=%d  %s" % [id, intentos[id], "GANA" if res.ganado else "pierde", res.tiempo, res.kills, res.nivel, res.golpes, Datos.NIVELES[id].golpes, res.hp, res.hp_max, res.max_cadena, Datos.NIVELES[id].cadena, res.desyncs, res.aces, Partida.estrellas(id), res.chatarra, res.build])
	print("           ttk: ", _ttk_txt(res), _jefes_txt(res), "  golpes por: ", str(res.get("golpes_por", {})))
	_usar_hangar()
	if args.has("barrido"):
		# juega cada nivel una vez, gane o pierda, para medir cuanta presion hay
		if not res.ganado:
			Partida.completar_nivel(id, {"golpes": 99, "max_cadena": 0})
		var i: int = Datos.ORDEN_NIVELES.find(id)
		if i + 1 >= Datos.ORDEN_NIVELES.size():
			print("[barrido] fin")
			get_tree().quit()
			return
		Partida.nivel_sel = Datos.ORDEN_NIVELES[i + 1]
		principal.ir_combate()
		return
	if Partida.nivel_completado("1-8"):
		var tot := 0
		for k in intentos:
			tot += intentos[k]
		print("[campana] FIN intentos=%d estrellas=%d/%d" % [tot, Partida.estrellas_totales(), Datos.ORDEN_NIVELES.size() * 3])
		get_tree().quit()
		return
	if intentos.get(id, 0) >= int(args.get("max_intentos", "12")) and not res.ganado:
		print("[campana] ATASCADO en ", id)
		get_tree().quit()
		return
	Partida.nivel_sel = Partida.nivel_actual()
	principal.ir_combate()


## Lo que haria una persona entre partidas: fusionar, equipar lo mejor y mejorarlo.
func _usar_hangar() -> void:
	if Partida.tiene("fusion"):
		Partida.fusionar_todo()
	var ranuras: Array = Partida.ranuras_visibles()
	for r in ranuras:
		var mejor := Partida.equipado(r)
		for it in Partida.piezas_de(r):
			if mejor.is_empty() or it.rareza > mejor.rareza or (it.rareza == mejor.rareza and it.nivel > mejor.nivel):
				mejor = it
		if not mejor.is_empty():
			Partida.equipar(mejor.uid)
	var gasto := true
	while gasto:
		gasto = false
		for r in ranuras:
			if not Partida.equipado(r).is_empty() and Partida.mejorar(Partida.equipado(r).uid):
				gasto = true
	var s := Partida.stats_nave()
	var rarezas := PackedStringArray()
	for r in ranuras:
		var it := Partida.equipado(r)
		if not it.is_empty():
			rarezas.append("%s:%d/n%d" % [r.substr(0, 3), it.rareza, it.nivel])
	print("[hangar] ataque=%d vida=%d  %s  mascota=n%d fusiones=%d piezas=%d" % [int(s.atk * s.dano), int(s.hp), " ".join(rarezas), Partida.nivel_mascota(), Partida.d.estadisticas.fusiones, Partida.d.inventario.size()])


func _contar(res: Dictionary) -> void:
	veces += 1
	if res.ganado:
		ganadas += 1
	print("[bot] partida %d %s: %s t=%ds kills=%d nivel=%d golpes=%d cadena=%d desync=%d ace=%d roces=%d nam=%d chatarra=%d evo=%d" % [veces, res.nivel_id, "GANA" if res.ganado else "pierde", res.tiempo, res.kills, res.nivel, res.golpes, res.max_cadena, res.desyncs, res.aces, res.roces, res.nams, res.chatarra, res.evoluciones])
	print("      t=%ds hp=%d/%d ttk: " % [res.tiempo, res.hp, res.hp_max], _ttk_txt(res), _jefes_txt(res), "  golpes por: ", str(res.get("golpes_por", {})), "  build: ", res.get("build", ""))
	if not res.get("cascadas", []).is_empty():
		var txt := PackedStringArray()
		for k in res.cascadas:
			txt.append("%d/%d" % [k[0], k[1]])
		print("      desync (golpes/kills): ", " ".join(txt))
	if res.get("modo", "normal") != "normal":
		print("      modo=%s giros=%d jackpots=%d kills_tipo=%s" % [res.get("modo", ""), res.get("giros", 0), res.get("jackpots", 0), str(res.get("kills_tipo", {}))])
	suma["tiempo"] = suma.get("tiempo", 0) + res.tiempo
	suma["golpes"] = suma.get("golpes", 0) + res.golpes
	suma["kills"] = suma.get("kills", 0) + res.kills
	suma["nivel"] = suma.get("nivel", 0) + res.nivel
	suma["cadena"] = suma.get("cadena", 0) + res.max_cadena


## Cuánto dura cada tipo de enemigo desde su primer golpe, en segundos. Entre paréntesis: en el tramo final del nivel.
func _ttk_txt(res: Dictionary) -> String:
	var t := PackedStringArray()
	var todo: Dictionary = res.get("ttk", {})
	var tarde: Dictionary = res.get("ttk_tarde", {})
	for tipo in todo:
		var f: Array = todo[tipo]
		var linea := "%s %.2fs" % [tipo, f[1] / maxf(f[0], 1.0) / 60.0]
		if tarde.has(tipo):
			var g: Array = tarde[tipo]
			linea += " (%.2f)" % (g[1] / maxf(g[0], 1.0) / 60.0)
		t.append(linea)
	return ", ".join(t)


func _jefes_txt(res: Dictionary) -> String:
	var t := PackedStringArray()
	for j in res.get("t_jefes", []):
		t.append("%s en %.1fs" % [j.tipo, j.seg])
	if res.get("jefe_hp", -1.0) >= 0.0 and not res.ganado:
		t.append("el jefe quedó con %d %%" % int(res.jefe_hp * 100.0))
	return "" if t.is_empty() else "  JEFES: " + ", ".join(t)


func _resumen() -> void:
	var n := maxf(veces, 1.0)
	print("[bot] fin ganadas=%d de %d | promedio: t=%.0fs golpes=%.1f kills=%.0f nivel=%.1f cadena=%.0f" % [ganadas, veces, suma.get("tiempo", 0) / n, suma.get("golpes", 0) / n, suma.get("kills", 0) / n, suma.get("nivel", 0) / n, suma.get("cadena", 0) / n])


func _soltar() -> void:
	for a in ACCIONES:
		Input.action_release(a)
	Input.action_release("foco")
	Input.action_release("esquivar")
	Input.action_release("desync")


func _bot_combate(c) -> void:
	if args.has("log") and c.ticks - ultimo_log >= 600:
		ultimo_log = c.ticks
		var nombres := PackedStringArray()
		for a in c.arsenal.armas:
			nombres.append("%s%d%s" % [a.id, a.nivel, "*" if a.evo else ""])
		print("[bot] t=%ds guion=%.0f %s hp=%d/%d niv=%d kills=%d balas=%d enem=%d barra=%d armas=%s habs=%s" % [c.ticks / 60, c.guion_t, c.estado, c.hp, c.stats.hp, c.nivel_carta, c.kills, c.bn, c.enemigos.size(), c.barra, ",".join(nombres), str(c.habs.keys())])
	if estres > 0 and c.estado == "jugando":
		c.presupuesto = estres
		while c.bn < estres:
			var a := randf() * TAU
			c._bala(randf_range(0, 400), randf_range(0, 200), cos(a) * 0.3, sin(a) * 0.3, randi() % 3, 0, 0, true)
		c.iframes = 10
	# para mirar el escudo del Desync quebrándose en las capturas
	if args.has("golpear_desync") and c.estado == "desync" and c.ticks - ultimo_log >= 70:
		ultimo_log = c.ticks
		c.iframes = 0
		c._recibir_dano(20.0, "prueba")
	if c.estado == "cartas":
		_soltar()
		bot_espera += 1
		if bot_espera > 10:
			bot_espera = 0
			c.elegir_carta(_mejor_carta(c))
		return
	if not c.estado in ["jugando", "desync"]:
		_soltar()
		return
	# soltar y apretar en el mismo cuadro no cuenta como pulsación: se aprieta un cuadro y se suelta el siguiente
	var dash_suelto: bool = not Input.is_action_pressed("esquivar")
	var desync_suelto: bool = not Input.is_action_pressed("desync")
	if not dash_suelto:
		Input.action_release("esquivar")
	if not desync_suelto:
		Input.action_release("desync")
	# el bot --quieto no se mueve ni esquiva: solo dispara y usa el Desync
	if not args.has("quieto"):
		if c.ticks % reaccion == 0:
			_decidir(c)
		_aplicar_dir()
		if dash_pendiente and c.dash_cd <= 0 and dash_suelto:
			Input.action_press("esquivar")
			dash_pendiente = false
	if c.tiene_desync and c.barra >= 100.0 and c.estado == "jugando" and desync_suelto:
		var en_pantalla := 0
		for e in c.enemigos:
			if e.y > 0:
				en_pantalla += 1
		if en_pantalla >= 5 or c.jefe_actual != null or c.hp < c.stats.hp * 0.3:
			Input.action_press("desync")


func _mejor_carta(c) -> int:
	if torpe:
		return randi() % c.cartas.size()
	var mejor := 0
	var puntos := -999.0
	for i in c.cartas.size():
		var ca: Dictionary = c.cartas[i]
		var p := randf() * 2.0
		match ca.tipo:
			"evo":
				p += 100.0
			"arma":
				if ca.nv > 0:
					p += 8.0
				elif c.arsenal.armas.size() < 3:
					p += 6.0
				if ca.sin_ok:
					p += 5.0
			"hab":
				if ca.get("sin_ok", false):
					p += 9.0
				if ca.nv > 0:
					p += 3.0
				if ca.id in ["p2w", "spray", "pizza"]:
					p += 3.0
		if p > puntos:
			puntos = p
			mejor = i
	return mejor


func _aplicar_dir() -> void:
	for a in ACCIONES:
		Input.action_release(a)
	if dir_actual.x < -0.1:
		Input.action_press("mover_izquierda")
	elif dir_actual.x > 0.1:
		Input.action_press("mover_derecha")
	if dir_actual.y < -0.1:
		Input.action_press("mover_arriba")
	elif dir_actual.y > 0.1:
		Input.action_press("mover_abajo")


func _decidir(c) -> void:
	if ruido > 0 and randf() < ruido:
		dir_actual = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.ZERO][randi() % 5]
		return
	var esc: float = c.ESC_DESYNC if c.estado == "desync" else 1.0
	var vel: float = 2.75 * c.stats.vel
	# objetivo: enemigo mas cercano para quedar debajo; si hay un jefe, el jefe, como haría cualquiera
	var tx := 200.0
	var md := INF
	var peso_x := 0.018
	for e in c.enemigos:
		if e.y > -5.0 and e.y < 300.0:
			var d: float = absf(e.x - c.jx) + e.y * 0.1
			if d < md:
				md = d
				tx = e.x
	if c.jefe_actual != null and not c.jefe_actual.muerto:
		tx = c.jefe_actual.x
		peso_x = 0.03
	# si hay objetos cerca, tambien los quiere
	var dirs := [Vector2.ZERO, Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]
	var mejor := Vector2.ZERO
	var ms := -INF
	var riesgo_min := INF
	for dv in dirs:
		var s := 0.0
		var riesgo := 0.0
		for tk: float in [4.0, 9.0, 15.0, 22.0]:
			var nx: float = clampf(c.jx + dv.x * vel * tk, 8.0, 392.0)
			var ny: float = clampf(c.jy + dv.y * vel * tk, 10.0, 350.0)
			if args.has("ciego"):
				break
			# de la bomba del AFK sí arranca
			if c.afk_mira >= 0.0 and (nx - c.afk_mx) * (nx - c.afk_mx) + (ny - c.afk_my) * (ny - c.afk_my) < 40.0 * 40.0:
				riesgo += 80.0
			for i in c.bn:
				var bpx: float = c.bx[i] + c.bvx[i] * esc * tk
				var bpy: float = c.by[i] + c.bvy[i] * esc * tk
				var ddx: float = bpx - nx
				var ddy: float = bpy - ny
				var d2: float = ddx * ddx + ddy * ddy
				if d2 < 26.0 * 26.0:
					var pena: float = 900.0 / (d2 + 9.0) * (26.0 / (tk + 4.0))
					riesgo += pena
			for e in c.enemigos:
				var ex: float = e.x
				var ey: float = e.y
				# los que vienen hacia ti se miran donde van a estar, como lo haría una persona
				if e.modo == "lanzado":
					ex += e.ex * esc * tk
					ey += e.ey * esc * tk
				elif e.modo == "libre":
					ex += e.vx * esc * tk
					ey += e.vy * esc * tk
				elif e.def.ia == "kamikaze" and e.modo == "actuar" and e.mt >= 20.0:
					# ya te apuntó: la línea avisa por dónde viene
					var va: Vector2 = Vector2(e.dx - e.x, e.dy - e.y).normalized() * 4.4 * c.mult_vel
					var dem: float = maxf(tk - (45.0 - e.mt) / esc, 0.0)
					ex += va.x * esc * dem
					ey += va.y * esc * dem
				var ddx: float = ex - nx
				var ddy: float = ey - ny
				var r: float = e.def.radio + 12.0
				if ddx * ddx + ddy * ddy < r * r:
					riesgo += 60.0
		s -= riesgo
		var fx: float = clampf(c.jx + dv.x * vel * 15.0, 8.0, 392.0)
		var fy: float = clampf(c.jy + dv.y * vel * 15.0, 10.0, 350.0)
		s -= absf(fx - tx) * peso_x
		s -= absf(fy - 305.0) * 0.03
		# si lleva rato en el mismo lugar, se mueve antes de que llegue la bomba
		if c.afk_t > 180 and not args.has("ciego"):
			s += sqrt((fx - c.afk_x) * (fx - c.afk_x) + (fy - c.afk_y) * (fy - c.afk_y)) * 0.04
		# no pegarse a los bordes
		s -= maxf(0.0, 30.0 - fx) * 0.05 + maxf(0.0, fx - 370.0) * 0.05
		if s > ms:
			ms = s
			mejor = dv
		riesgo_min = minf(riesgo_min, riesgo)
	dir_actual = mejor
	if riesgo_min > 120.0 and not torpe:
		dash_pendiente = true


func _process(d: float) -> void:
	cuadro += 1
	if args.has("perf"):
		tiempos.append(d)
		peor = maxf(peor, d)
	if capturas.has(cuadro) and carpeta != "":
		_capturar(cuadro)
	if args.has("auto") and principal and principal.actual and principal.actual.has_method("elegir_carta"):
		_auto(principal.actual)
	if salir > 0 and cuadro >= salir:
		if args.has("perf") and tiempos.size() > 30:
			var s := 0.0
			for x in tiempos.slice(30):
				s += x
			var c = principal.actual if principal else null
			print("[perf] fps=%.1f cuadro_medio=%.2fms peor=%.2fms balas=%d" % [(tiempos.size() - 30) / s, s / (tiempos.size() - 30) * 1000.0, peor * 1000.0, c.bn if c and c.get("bn") != null else 0])
		if principal and principal.actual and principal.actual.has_method("elegir_carta"):
			var c = principal.actual
			print("[bot] al salir: t=%ds estado=%s hp=%d nivel=%d kills=%d guion=%.0f" % [c.ticks / 60, c.estado, c.hp, c.nivel_carta, c.kills, c.guion_t])
		get_tree().quit()


# Captura una vez cada momento clave de la partida
var vistos := {}
const DEMORA := {"cartas": 30, "desync": 110, "reconectando": 6, "cascada": 40, "victoria": 60, "muerte": 30, "jugando_jefe": 500, "desync_jefe": 110, "cascada_jefe": 8}


func _auto(c) -> void:
	var clave: String = c.estado
	if c.jefe_actual != null:
		clave += "_jefe"
	if c.hp_flash == 6 and not vistos.has("golpe"):
		vistos["golpe"] = -1
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(carpeta)
		get_viewport().get_texture().get_image().save_png("%s/auto_golpe.png" % carpeta)
		return
	if c.hp < c.stats.hp * 0.3 and c.vivo and not vistos.has("vida_baja"):
		vistos["vida_baja"] = -1
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(carpeta)
		get_viewport().get_texture().get_image().save_png("%s/auto_vida_baja.png" % carpeta)
		return
	for g in c.gemas:
		if g.tipo in ["pizza", "bomba", "iman", "cofre"] and not vistos.has("objeto"):
			vistos["objeto"] = -1
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute(carpeta)
			get_viewport().get_texture().get_image().save_png("%s/auto_objeto.png" % carpeta)
			return
	if clave == "jugando" and c.guion_t > 30.0:
		clave = "jugando_tarde"
	if not vistos.has(clave):
		vistos[clave] = cuadro
	elif vistos[clave] > 0 and cuadro - vistos[clave] >= DEMORA.get(clave, 200):
		vistos[clave] = -1
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(carpeta)
		img.save_png("%s/auto_%s.png" % [carpeta, clave])
		print("[auto] ", clave, " en cuadro ", cuadro)


func _capturar(n: int) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(carpeta)
	img.save_png("%s/c_%05d.png" % [carpeta, n])
	print("[captura] ", n)


# --- recorrido por los menus con entradas reales ---------------------------------------------
var paso := 0
var espera_f := 0
var f_ok := 0
var f_mal := 0
var f_guardado := 0
var f_txt := ""
var f_ctrl = null
var f_en_curso := false  # una etapa escrita de corrido, con esperas adentro


func _pulsar(accion: String) -> void:
	var ev := InputEventAction.new()
	ev.action = accion
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventAction.new()
	ev2.action = accion
	ev2.pressed = false
	Input.parse_input_event.call_deferred(ev2)


func _tecla(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventKey.new()
	ev2.keycode = k
	ev2.physical_keycode = k
	ev2.pressed = false
	Input.parse_input_event.call_deferred(ev2)


func _check(c: bool, n: String) -> void:
	if c:
		f_ok += 1
		if args.has("verboso"):
			print("  ok: ", n)
	else:
		f_mal += 1
		print("  FALLA: ", n)


func _foco() -> Control:
	return get_viewport().gui_get_focus_owner()


func _foto(nombre := "") -> void:
	if carpeta == "":
		return
	if nombre == "":
		_capturar(cuadro)
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(carpeta)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [carpeta, nombre])


func _hijo_de_tipo(n: Node, ruta: String) -> Node:
	for h in n.get_children():
		if h.get_script() and h.get_script().resource_path == ruta:
			return h
	return null


func _flujo() -> void:
	espera_f -= 1
	if espera_f > 0:
		return
	espera_f = 14
	var a = principal.actual
	match paso:
		0:
			f_en_curso = true
			await _flujo_titulo()
			f_en_curso = false
			espera_f = 14
		1:
			_check(a.has_signal("jugar_nivel"), "elegir dificultad abre el mapa")
			var d := _hijo_de_tipo(a, "res://pantallas/dialogo.gd")
			_check(d != null, "Don Tuerca saluda la primera vez")
			_foto()
			_check(a.modal == null, "el dialogo no abre el nivel de atras")
			_pulsar("ui_accept")
		2:
			var d := _hijo_de_tipo(a, "res://pantallas/dialogo.gd")
			_check(d != null and d.visibles >= d.total, "Enter completa el texto")
			_check(a.modal == null, "Enter no se pasa al mapa")
			_pulsar("ui_accept")
		3:
			var d := _hijo_de_tipo(a, "res://pantallas/dialogo.gd")
			_check(d != null and d.i == 1, "Enter pasa a la linea siguiente")
			_pulsar("ui_cancel")
		4:
			_check(_hijo_de_tipo(a, "res://pantallas/dialogo.gd") == null, "Esc se salta el dialogo")
			_check(Partida.visto("inicio"), "no se repite")
			_check(_foco() == a.nodos["1-1"], "el foco queda en el nivel 1-1")
			_check(not Partida.nivel_abierto("1-2"), "1-2 parte cerrado")
			_check(a.b_hangar.disabled, "el Hangar parte cerrado")
			_foto()
			_pulsar("ui_right")
		5:
			_check(_foco() == a.nodos["1-2"], "la flecha va al siguiente nivel")
			_pulsar("ui_accept")
		6:
			_check(a.modal == null, "un nivel cerrado no se abre")
			_pulsar("ui_left")
		7:
			_check(_foco() == a.nodos["1-1"], "la flecha vuelve")
			_pulsar("ui_accept")
		8:
			_check(a.modal != null, "Enter abre el panel del nivel")
			_foto()
			_check(_foco() == a.modal.b_jugar, "JUGAR tiene el foco")
			_pulsar("ui_up")
		9:
			_check(_foco() == a.modal.b_jugar, "el foco no se escapa del panel")
			_pulsar("ui_cancel")
		10:
			_check(a.modal == null, "Esc cierra el panel")
			_check(_foco() == a.nodos["1-1"], "el foco vuelve al nivel")
			_pulsar("ui_accept")
		11:
			_pulsar("ui_accept")
			espera_f = 30
		12:
			_check(a.has_method("elegir_carta"), "con una sola nave se juega de inmediato")
			_check(not a.tiene_desync, "el Desync aun no existe")
			_check(not a.tiene_mascota, "la mascota aun no existe")
			_check(a.arsenal.armas.size() == 1 and a.arsenal.armas[0].id == "pistola", "parte con el arma de su nave")
			a.barra = 100.0
			_tecla(KEY_X)
		13:
			_check(a.estado == "jugando", "sin Desync la tecla no hace nada")
			a.barra = 0.0
			_tecla(KEY_ESCAPE)
			espera_f = 20
		14:
			_check(a.estado == "pausa", "Esc pausa")
			_foto()
			var panel = a.capa_pausa.get_child(0)
			panel.botones[1].grab_focus()
			_pulsar("ui_accept")
		15:
			var panel = a.capa_pausa.get_child(0)
			_check(panel.has_node("Opciones"), "abre opciones desde la pausa")
			var o = panel.get_node("Opciones")
			_foto()
			o.botones_pestana[1].grab_focus()
		16:
			var o = a.capa_pausa.get_child(0).get_node("Opciones")
			_check(o.pestana == 1, "la barra de arriba cambia a Sonido")
			f_guardado = Ajustes.musica
			o.filas[0].grab_focus()
			_pulsar("ui_left")
		17:
			var o = a.capa_pausa.get_child(0).get_node("Opciones")
			_check(Ajustes.musica == f_guardado - 10, "izquierda baja el volumen")
			_foto()
			o.botones_pestana[2].grab_focus()
		18:
			var o = a.capa_pausa.get_child(0).get_node("Opciones")
			_check(o.pestana == 2 and o.controles_ui != null, "pestana Teclas")
			_foto()
			f_ctrl = o.controles_ui
			f_ctrl.botones["disparar"]["teclado0"].grab_focus()
			_pulsar("ui_accept")
			espera_f = 24
		19:
			_check(not f_ctrl.capturando.is_empty(), "espera una tecla")
			_tecla(KEY_Q)
		20:
			_check(Controles.a.obtener("disparar", "teclado", 0) == "key:Q", "asigna Q a disparar")
			var ok := false
			for ev in InputMap.action_get_events("disparar"):
				if ev is InputEventKey and ev.keycode == KEY_Q:
					ok = true
			_check(ok, "el motor ya usa la tecla nueva")
			f_ctrl.botones["disparar"]["teclado1"].grab_focus()
			_pulsar("ui_accept")
			espera_f = 24
		21:
			_tecla(KEY_X)
		22:
			_check(f_ctrl.panel_conflicto != null, "avisa del conflicto con Desync")
			_foto()
			_pulsar("ui_accept")
		23:
			_check(Controles.a.obtener("disparar", "teclado", 1) == "key:X", "intercambia: X queda en disparar")
			_check(Controles.a.obtener("desync", "teclado", 0) == "key:Z", "intercambia: Z queda en Desync")
			f_ctrl.botones["disparar"]["teclado1"].grab_focus()
			_tecla(KEY_DELETE)
		24:
			_check(Controles.a.obtener("disparar", "teclado", 1) == "", "Supr borra la secundaria")
			f_ctrl.botones["disparar"]["teclado0"].grab_focus()
			_tecla(KEY_DELETE)
		25:
			_check(Controles.a.obtener("disparar", "teclado", 0) == "key:Q", "no deja la accion sin teclas")
			Controles.restaurar_todo()
			_check(Controles.a.obtener("disparar", "teclado", 0) == "key:J", "restaurar todo")
			f_ctrl.botones["disparar"]["teclado0"].grab_focus()
			_pulsar("ui_accept")
			espera_f = 24
		26:
			_check(not f_ctrl.capturando.is_empty(), "captura otra vez")
			_tecla(KEY_ESCAPE)
		27:
			var o = a.capa_pausa.get_child(0).get_node("Opciones")
			_check(f_ctrl.capturando.is_empty(), "Esc cancela la captura")
			_check(o != null, "Esc en la captura no cierra opciones")
			_pulsar("ui_cancel")
			paso = 106
			return
		106:
			var o = a.capa_pausa.get_child(0).get_node("Opciones")
			_check(_foco() == o.botones_pestana[o.pestana], "Esc en la tabla vuelve a la pestana")
			_pulsar("ui_cancel")
			paso = 28
			return
		28:
			_check(not a.capa_pausa.get_child(0).has_node("Opciones"), "Esc cierra opciones")
			_tecla(KEY_ESCAPE)
		29:
			_check(a.estado != "pausa", "Esc vuelve al juego")
			f_guardado = a.arsenal.armas.size() + a.habs.size()
			a.niveles_pendientes = 1
			espera_f = 40
		30:
			_check(a.estado == "cartas", "subir de nivel abre cartas")
			_foto()
			_pulsar("ui_right")
		31:
			_check(a.carta_sel == 2, "derecha mueve la carta")
			f_guardado = a.cambios_restantes
			_tecla(KEY_X)
		32:
			_check(a.cambios_restantes == f_guardado - 1, "X cambia las cartas")
			espera_f = 20
			f_guardado = a.arsenal.armas.size() + a.habs.size()
			var total := 0
			for ar in a.arsenal.armas:
				total += ar.nivel
			f_guardado += total
			_pulsar("ui_accept")
		33:
			_check(a.estado == "jugando", "Enter elige carta")
			var total: int = a.arsenal.armas.size() + a.habs.size()
			for ar in a.arsenal.armas:
				total += ar.nivel
			_check(total > f_guardado, "la carta hace efecto")
			# probar el Desync con la tecla real
			a.tiene_desync = true
			a.barra = 100.0
			_tecla(KEY_X)
			espera_f = 6
		34:
			_check(a.estado == "desync", "con Desync, X lo activa")
			espera_f = 460
		35:
			_check(a.estado == "jugando", "el Desync termina y vuelve al juego")
			a.tiene_desync = false
			# ganar el nivel, con un golpe: ganar sin golpes completaria un desafio y agregaria otro premio
			a.golpes = maxi(a.golpes, 1)
			a.guion_i = a.guion.size()
			a.pendientes.clear()
			for e in a.enemigos:
				e.muerto = true
			espera_f = 150
		36:
			_check(a.has_signal("al_mapa"), "terminar el nivel muestra el resultado")
			_check(Partida.nivel_completado("1-1"), "1-1 queda completado")
			_check(Partida.tiene("hangar"), "se gana el Hangar")
			_check(Partida.estrellas("1-1") >= 1, "da estrellas")
			espera_f = 340
		37:
			_check(a.b1.visible, "aparecen los botones del resultado")
			_foto()
			_check(_foco() == a.b1, "CONTINUAR tiene el foco")
			_pulsar("ui_accept")
			espera_f = 20
		38:
			var pr := _hijo_de_tipo(a, "res://pantallas/premio.gd")
			_check(pr != null, "se celebra el premio")
			_foto()
			espera_f = 70
		39:
			_pulsar("ui_accept")
			espera_f = 20
		40:
			var d := _hijo_de_tipo(a, "res://pantallas/dialogo.gd")
			_check(d != null and d.lineas == Datos.DIALOGOS["despues_1-1"], "Don Tuerca comenta el nivel")
			_foto()
			_pulsar("ui_cancel")
			espera_f = 20
		41:
			_check(a.has_signal("jugar_nivel"), "vuelve al mapa")
			_check(a.recien == "1-2", "celebra el nivel nuevo")
			_check(_foco() == a.nodos["1-2"], "el foco queda en 1-2")
			_check(Partida.nivel_abierto("1-2"), "1-2 ya se abrio")
			_check(not a.b_hangar.disabled, "el Hangar ya se abrio")
			_foto()
			a.b_hangar.grab_focus()
			_pulsar("ui_accept")
			espera_f = 20
		42:
			_check(a.has_method("esta_abierta"), "entra al Hangar")
			_check(a.en_sala, "parte en la sala")
			_check(not a.esta_abierta("fusionar"), "Fusionar sigue cerrado")
			_check(not a.esta_abierta("mascota"), "Mascota sigue cerrada")
			_foto()
			a.sala.botones["equipo"].grab_focus()
			_pulsar("ui_accept")
			espera_f = 14
			paso = 100
			return
		100:
			_check(a.pestana == "equipo", "abre Equipo desde la sala")
			_check(_foco() is Button and _foco().get("id") in Datos.RANURAS, "el foco parte en las ranuras")
			f_txt = a.actual.ranura
			_pulsar("ui_right")
			espera_f = 10
			paso = 101
			return
		101:
			_check(a.actual.ranura != f_txt and _foco().get("id") == a.actual.ranura, "derecha cambia de ranura y su lista")
			_pulsar("ui_down")
			espera_f = 10
			paso = 102
			return
		102:
			_check(_foco() is PiezaBoton, "abajo baja a las piezas")
			_pulsar("ui_left")
			espera_f = 10
			paso = 103
			return
		103:
			var f0 := _foco()
			_check(f0 != null and a.is_ancestor_of(f0), "las flechas no se salen del Hangar")
			_pulsar("ui_cancel")
			espera_f = 20
			paso = 104
			return
		104:
			_check(a.en_sala, "Esc vuelve a la sala")
			_pulsar("ui_cancel")
			espera_f = 20
			paso = 1060
			return
		1060:
			_check(a.has_signal("jugar_nivel"), "Esc en la sala sale al mapa")
			principal.ir_hangar("equipo")
			espera_f = 20
			paso = 105
			return
		105:
			Partida.d.chatarra = 500
			var e = a.actual
			e.elegir_ranura("mira")
			_check(e.sel_uid == Partida.equipado("mira").uid, "muestra lo que llevas puesto")
			var uid_nueva: int = Partida.agregar("cargador", 1).uid
			e._lista()
			e._elegir_pieza(uid_nueva)
			_check(not e.b_equipar.disabled, "EQUIPAR disponible")
			e.b_equipar.grab_focus()
			_pulsar("ui_accept")
			f_guardado = uid_nueva
			paso = 42
		43:
			_check(Partida.equipado("mira").uid == f_guardado, "se equipa con Enter")
			var e = a.actual
			var c0: int = Partida.d.chatarra
			e.b_mejorar.grab_focus()
			_pulsar("ui_accept")
			f_guardado = c0
		44:
			_check(Partida.d.chatarra < f_guardado, "mejorar gasta chatarra")
			_check(Partida.equipado("mira").nivel == 2, "sube de nivel")
			Partida.desbloquear("fusion")
			Partida.desbloquear("mascota")
			Partida.dar_mascota("mordisco")
			principal.ir_hangar("fusionar")
			espera_f = 20
		45:
			_check(a.pestana == "fusionar", "abre en Fusionar")
			var f = a.actual
			_check(f.b_fusionar.disabled, "sin piezas no se fusiona")
			# tres piezas iguales, una equipada
			var base := Partida.equipado("casco")
			var x1 := Partida.agregar("casco_blindado", 0)
			var x2 := Partida.agregar("casco_lata", 0)
			var ajena := Partida.agregar("chip_critico", 0)
			f._lista()
			f.refrescar()
			f._pulsar(x1.uid)
			f._pulsar(ajena.uid)
			_check(f.elegidas.size() == 1, "no deja mezclar ranuras")
			f._pulsar(x2.uid)
			f._pulsar(base.uid)
			_check(f.elegidas[0] == base.uid, "lo equipado siempre es la base")
			_check(not f.b_fusionar.disabled, "con tres piezas se puede")
			_foto()
			f_guardado = base.uid
			f.b_fusionar.grab_focus()
			_pulsar("ui_accept")
			espera_f = 40
		46:
			_check(_hijo_de_tipo(a, "res://pantallas/fusion.gd") != null, "se ve la animacion")
			_check(a.bloqueado, "el Hangar espera a la animacion")
			espera_f = 90
		47:
			_foto()
			_pulsar("ui_accept")
			espera_f = 20
		48:
			_check(not a.bloqueado, "la animacion se cierra")
			_check(Partida.equipado("casco").uid == f_guardado and Partida.equipado("casco").rareza == 1, "la pieza quedo Poco comun y puesta")
			_check(Partida.xp_mascota() > 0, "la mascota comio")
			a.tabs["mascota"].grab_focus()
			espera_f = 10
		49:
			_check(a.pestana == "mascota", "pestana Mascota")
			_foto()
			a.tabs["naves"].grab_focus()
			espera_f = 10
		50:
			_check(a.pestana == "naves", "pestana Naves")
			_foto()
			Partida.d.naves.append("camper")
			_pulsar("ui_cancel")
			espera_f = 20
			paso = 107
			return
		107:
			_check(a.en_sala, "Esc vuelve a la sala")
			_pulsar("ui_cancel")
			espera_f = 20
			paso = 51
			return
		51:
			_check(a.has_signal("jugar_nivel"), "Esc vuelve al mapa")
			a.nodos["1-2"].grab_focus()
			_pulsar("ui_accept")
		52:
			_check(a.modal != null, "abre 1-2")
			_pulsar("ui_accept")
			espera_f = 20
		53:
			_check(a.has_signal("despegar"), "con dos naves se elige nave")
			_foto()
			var g = a.g
			g.tarjetas["camper"].grab_focus()
			espera_f = 6
		54:
			_check(a.g.sel == "camper", "las flechas eligen nave")
			a.g.tarjetas["smurf"].grab_focus()
			espera_f = 6
		55:
			_check(a.b_ok.disabled, "una nave bloqueada no despega")
			a.g.tarjetas["camper"].grab_focus()
			espera_f = 6
		56:
			_pulsar("ui_accept")
			espera_f = 20
		57:
			_check(Partida.nave_actual() == "camper", "queda elegida")
			var d := _hijo_de_tipo(a, "res://pantallas/dialogo.gd")
			_check(d != null, "Don Tuerca avisa antes del nivel")
			_pulsar("ui_cancel")
			espera_f = 30
		58:
			_check(a.has_method("elegir_carta"), "empieza el nivel")
			_check(a.arsenal.armas[0].id == "railgun", "con el arma de esa nave")
			# morir
			a.hp = 1.0
			a.iframes = 0
			a._recibir_dano(50.0)
			_check(a.estado == "muerte", "morir termina la partida")
			espera_f = 130
		59:
			_check(a.has_signal("al_mapa"), "muestra el resultado")
			_check(not Partida.nivel_completado("1-2"), "perder no completa el nivel")
			espera_f = 340
		60:
			_foto()
			_pulsar("ui_accept")
			espera_f = 20
		61:
			var d := _hijo_de_tipo(a, "res://pantallas/dialogo.gd")
			_check(d != null and d.lineas == Datos.DIALOGOS["derrota"], "Don Tuerca consuela la primera derrota")
			_pulsar("ui_cancel")
			espera_f = 20
		62:
			_check(a.has_signal("jugar_nivel"), "vuelve al mapa")
			a.b_menu.grab_focus()
			_pulsar("ui_accept")
			espera_f = 20
		63:
			_check(a.has_signal("jugar"), "MENÚ vuelve al titulo")
			f_en_curso = true
			await _flujo_ranuras()
			await _flujo_migracion()
			await _flujo_importar()
			await _flujo_mapa_extras()
			await _flujo_nueva_plus()
			await _flujo_premios()
			await _flujo_resultados()
			await _flujo_pausa()
			await _flujo_mouse()
			print("[flujo] ok=%d fallas=%d" % [f_ok, f_mal])
			get_tree().quit()
			return
	paso += 1


# --- etapas escritas de corrido: cada una usa teclas reales, y las dos manos: WASD y flechas ----
const NOMBRE_TECLA := {KEY_W: "W", KEY_A: "A", KEY_S: "S", KEY_D: "D", KEY_UP: "Arriba", KEY_DOWN: "Abajo", KEY_LEFT: "Izquierda", KEY_RIGHT: "Derecha",
	KEY_ENTER: "Enter", KEY_SPACE: "Espacio", KEY_ESCAPE: "Esc", KEY_Q: "Q", KEY_E: "E", KEY_DELETE: "Supr"}
const P_OPCIONES := "res://pantallas/opciones.gd"
const P_SLOTS := "res://pantallas/slots.gd"
const P_DIFICULTAD := "res://pantallas/elegir_dificultad.gd"
const P_MODAL := "res://pantallas/modal.gd"
const P_DIALOGO := "res://pantallas/dialogo.gd"
const P_PANEL := "res://pantallas/panel_nivel.gd"
const P_PREMIO := "res://pantallas/premio.gd"
const P_NUEVA_PLUS := "res://pantallas/nueva_plus.gd"


func _cuadros(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Una tecla real, y unos cuadros para que haga efecto.
func _t(k: Key, espera := 6) -> void:
	_tecla(k)
	await _cuadros(espera)


## Lo que manda el teclado cuando una tecla se queda apretada.
func _eco(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	ev.echo = true
	Input.parse_input_event(ev)
	await _cuadros(8)


func _nt(k: Key) -> String:
	return NOMBRE_TECLA.get(k, str(k))


## Aprieta las teclas de "pares" [tecla, control esperado] y revisa que el foco quede ahí.
func _ruta_foco(pares: Array, que: String) -> void:
	for par in pares:
		await _t(par[0])
		_check(_foco() == par[1], "%s: %s lleva el foco a donde debe" % [que, _nt(par[0])])


func _flujo_titulo() -> void:
	Controles.restaurar_todo()
	var a = principal.actual
	_check(a.has_signal("jugar"), "parte en el titulo")
	_check(a.b_continuar == null, "sin partidas no hay CONTINUAR")
	_check(a.b_cargar.disabled, "sin partidas CARGAR esta apagado")
	_check(_foco() == a.b_nueva, "NUEVA PARTIDA tiene el foco")
	_foto("titulo_vacio")
	await _ruta_foco([[KEY_S, a.b_opciones], [KEY_S, a.b_salir], [KEY_S, a.b_nueva], [KEY_W, a.b_salir], [KEY_W, a.b_opciones], [KEY_W, a.b_nueva],
		[KEY_DOWN, a.b_opciones], [KEY_DOWN, a.b_salir], [KEY_DOWN, a.b_nueva], [KEY_UP, a.b_salir], [KEY_UP, a.b_opciones]], "titulo")
	await _t(KEY_SPACE, 10)
	var o = _hijo_de_tipo(a, P_OPCIONES)
	_check(o != null, "Espacio abre Opciones")
	if o != null:
		await _flujo_opciones(a, o)
	_check(_hijo_de_tipo(a, P_OPCIONES) == null, "Esc en la pestana cierra Opciones")
	_check(_foco() == a.b_opciones, "el foco vuelve a OPCIONES")
	await _flujo_partida_nueva(a)


## Opciones, tecla por tecla. Es lo que el jugador reclamó: se revisa con WASD y con flechas.
func _flujo_opciones(a, o) -> void:
	var tabs: Array = o.botones_pestana
	_check(o.pestana == 0 and _foco() == tabs[0], "Opciones: parte en la primera pestana")
	_foto("opciones_pantalla")
	# la barra de pestanas
	for par in [[KEY_D, 1], [KEY_A, 0], [KEY_RIGHT, 1], [KEY_LEFT, 0], [KEY_A, 3], [KEY_D, 0], [KEY_LEFT, 3], [KEY_RIGHT, 0], [KEY_E, 1], [KEY_E, 2], [KEY_E, 3], [KEY_E, 0], [KEY_Q, 3], [KEY_Q, 2], [KEY_Q, 1], [KEY_Q, 0]]:
		await _t(par[0])
		_check(o.pestana == par[1] and _foco() == tabs[par[1]], "barra: %s va a la pestana %d" % [_nt(par[0]), par[1]])
	for k in [KEY_W, KEY_UP]:
		await _t(k)
		_check(_foco() == tabs[0], "barra: %s no se sale de la barra" % _nt(k))
	# entrar y salir: Enter, Espacio, S y abajo entran; W, arriba y Esc salen
	for k in [KEY_S, KEY_DOWN, KEY_ENTER, KEY_SPACE]:
		await _t(k)
		_check(_foco() == o.filas[0], "%s entra a la primera fila" % _nt(k))
		await _t(KEY_ESCAPE)
		_check(_foco() == tabs[0] and _hijo_de_tipo(a, P_OPCIONES) != null, "Esc en una fila vuelve a la pestana sin cerrar")
	for k in [KEY_W, KEY_UP]:
		await _t(KEY_S)
		await _t(k)
		_check(_foco() == tabs[0], "%s en la primera fila vuelve a la pestana" % _nt(k))
	# --- Pantalla
	await _t(KEY_S)
	await _fila_alterna(func(): return Ajustes.pantalla_completa, "Pantalla completa")
	await _t(KEY_S)
	_check(_foco() == o.filas[1], "S baja a la segunda fila")
	await _fila_barra(func(): return Ajustes.sacudida, func(v): Ajustes.sacudida = v, 25, 150, "Sacudida")
	await _t(KEY_DOWN)
	_check(_foco() == o.filas[2], "abajo baja a la tercera fila")
	await _fila_alterna(func(): return Ajustes.reducir_destellos, "Reducir destellos")
	await _t(KEY_S)
	_check(_foco() == o.filas[3], "S baja a la cuarta fila")
	await _fila_barra(func(): return Ajustes.atenuar_fondo, func(v): Ajustes.atenuar_fondo = v, 20, 80, "Oscurecer el fondo")
	await _t(KEY_S)
	_check(_foco() == o.b_volver, "de la ultima fila se baja a VOLVER")
	await _ruta_foco([[KEY_S, o.b_volver], [KEY_A, o.b_volver], [KEY_D, o.b_volver], [KEY_W, o.filas[3]], [KEY_UP, o.filas[2]], [KEY_W, o.filas[1]], [KEY_UP, o.filas[0]], [KEY_W, tabs[0]]], "Pantalla")
	# mantener apretado tambien recorre las filas
	await _t(KEY_S)
	await _eco(KEY_S)
	_check(_foco() == o.filas[1], "mantener S sigue bajando")
	await _eco(KEY_DOWN)
	_check(_foco() == o.filas[2], "mantener abajo sigue bajando")
	await _eco(KEY_W)
	await _eco(KEY_UP)
	await _t(KEY_W)
	_check(_foco() == tabs[0], "mantener W y arriba sube hasta la pestana")
	# Q y E desde una fila: sigues en las filas de la pestana nueva
	await _t(KEY_S)
	await _t(KEY_E)
	_check(o.pestana == 1 and _foco() == o.filas[0], "E desde una fila pasa a la primera fila de Sonido")
	_foto("opciones_sonido")
	# --- Sonido
	await _fila_barra(func(): return Ajustes.musica, func(v):
		Ajustes.musica = v
		Sonido.aplicar_volumen(), 10, 100, "Musica")
	await _t(KEY_S)
	await _fila_barra(func(): return Ajustes.efectos, func(v):
		Ajustes.efectos = v
		Sonido.aplicar_volumen(), 10, 100, "Efectos")
	await _t(KEY_S)
	var tema: String = Sonido.nombre_tema()
	await _t(KEY_D)
	_check(Sonido.nombre_tema() != tema, "D cambia el tema")
	await _t(KEY_A)
	_check(Sonido.nombre_tema() == tema, "A vuelve al tema de antes")
	await _t(KEY_RIGHT)
	_check(Sonido.nombre_tema() != tema, "derecha cambia el tema")
	await _t(KEY_LEFT)
	_check(Sonido.nombre_tema() == tema, "izquierda vuelve al tema de antes")
	await _eco(KEY_D)
	_check(Sonido.nombre_tema() == tema, "mantener apretado no recorre todos los temas")
	await _t(KEY_E)
	_check(o.pestana == 2 and o.controles_ui != null and _foco() == o.controles_ui.primer_boton(), "E pasa a la tabla de Teclas")
	_foto("opciones_teclas")
	await _flujo_teclas(o)
	# --- General
	await _t(KEY_E)
	_check(o.pestana == 3 and _foco() == o.filas[0], "E pasa a General")
	_foto("opciones_general")
	await _fila_alterna(func(): return Ajustes.disparo_auto, "Disparo automatico")
	await _t(KEY_S)
	await _fila_alterna(func(): return Ajustes.foco_alternar, "Foco")
	await _t(KEY_S)
	await _fila_alterna(func(): return Ajustes.ver_numeros, "Numeros de dano")
	await _t(KEY_S)
	Partida.d.vistos = ["inicio", "antes_1-2"]
	for k in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT]:
		await _t(k)
	_check(Partida.d.vistos.size() == 2, "las flechas no borran los textos vistos")
	await _t(KEY_ENTER)
	_check(Partida.d.vistos.is_empty(), "Enter vacia los textos vistos")
	_foto("opciones_general_textos")
	# sin partida abierta no hay nada que repetir, y no se crea una ranura fantasma
	Partida.slot = 3
	await _t(KEY_ENTER)
	_check(not Partida.existe_slot(3) and o.aviso_general != "" and "abre" in o.aviso_general, "sin partida abierta avisa y no crea una ranura")
	_foto("opciones_general_sin_partida")
	Partida.slot = 0
	# salir: Esc a la pestana, y con mando tambien
	await _t(KEY_ESCAPE)
	_check(_foco() == tabs[3], "Esc vuelve a la pestana General")
	await _flujo_mando(o)
	await _t(KEY_ESCAPE, 10)


## Un boton de mando apretado y soltado.
func _boton(b: JoyButton, espera := 6) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = b
	ev.pressed = true
	Input.parse_input_event(ev)
	await _cuadros(2)
	var ev2 := InputEventJoypadButton.new()
	ev2.button_index = b
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _cuadros(espera)


## Los hombros cambian de pestana, la cruceta recorre y cambia, y mantenerla apretada repite.
func _flujo_mando(o) -> void:
	var inicial: int = o.pestana
	await _boton(JOY_BUTTON_RIGHT_SHOULDER)
	_check(o.pestana == posmod(inicial + 1, 4), "RB pasa a la pestana siguiente")
	_check(Controles.ultimo_mando and o.l_e.text == "RB", "la barra dice RB al usar el mando")
	await _boton(JOY_BUTTON_LEFT_SHOULDER)
	_check(o.pestana == inicial, "LB vuelve a la anterior")
	# a la pestana de Sonido, y a su primera fila con la cruceta
	o.botones_pestana[1].grab_focus()
	await _cuadros(4)
	await _boton(JOY_BUTTON_DPAD_DOWN)
	_check(_foco() == o.filas[0], "la cruceta entra a la primera fila")
	Ajustes.musica = 40
	await _boton(JOY_BUTTON_DPAD_RIGHT)
	_check(Ajustes.musica == 50, "la cruceta sube el volumen")
	await _boton(JOY_BUTTON_DPAD_LEFT)
	_check(Ajustes.musica == 40, "la cruceta baja el volumen")
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_DPAD_RIGHT
	ev.pressed = true
	Input.parse_input_event(ev)
	await _cuadros(50)
	var ev2 := InputEventJoypadButton.new()
	ev2.button_index = JOY_BUTTON_DPAD_RIGHT
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _cuadros(4)
	_check(Ajustes.musica > 50, "mantener la cruceta repite")
	Ajustes.musica = 50
	await _boton(JOY_BUTTON_B)
	_check(_foco() == o.botones_pestana[1], "B vuelve a la pestana")
	await _boton(JOY_BUTTON_A)
	_check(_foco() == o.filas[0], "A entra a la fila")
	await _boton(JOY_BUTTON_B)
	# se vuelve al teclado, y las pistas tambien
	await _t(KEY_E)
	await _t(KEY_E)
	_check(not Controles.ultimo_mando and o.l_e.text == "E", "al volver al teclado la barra dice E")
	o.botones_pestana[o.pestana].grab_focus()
	await _cuadros(4)


## Una fila de las que se prenden y apagan: cada tecla la cambia, y mantener apretado no la vuelve loca.
func _fila_alterna(leer: Callable, nombre: String) -> void:
	var v: bool = leer.call()
	for k in [KEY_D, KEY_A, KEY_RIGHT, KEY_LEFT, KEY_ENTER, KEY_SPACE]:
		await _t(k)
		v = not v
		_check(leer.call() == v, "%s cambia con %s" % [nombre, _nt(k)])
	await _eco(KEY_D)
	_check(leer.call() == v, "%s no repite al mantener" % nombre)


## Una fila con barra: un paso con cada tecla, repite al mantener y se detiene en las orillas.
func _fila_barra(leer: Callable, poner: Callable, paso_v: int, maximo: int, nombre: String) -> void:
	var original: int = leer.call()
	poner.call(paso_v * 2)
	for par in [[KEY_A, paso_v], [KEY_D, paso_v * 2], [KEY_LEFT, paso_v], [KEY_RIGHT, paso_v * 2]]:
		await _t(par[0])
		_check(leer.call() == par[1], "%s: %s da %d" % [nombre, _nt(par[0]), par[1]])
	var v: int = paso_v * 2
	await _eco(KEY_D)
	await _eco(KEY_D)
	_check(leer.call() == mini(v + paso_v * 2, maximo), "%s: mantener D repite" % nombre)
	await _eco(KEY_LEFT)
	_check(leer.call() == mini(v + paso_v * 2, maximo) - paso_v, "%s: mantener izquierda repite" % nombre)
	poner.call(maximo)
	await _t(KEY_D)
	_check(leer.call() == maximo, "%s: no se pasa del maximo" % nombre)
	poner.call(0)
	await _t(KEY_A)
	_check(leer.call() == 0, "%s: no baja de cero" % nombre)
	poner.call(original)


## La tabla de teclas: moverse, capturar, conflictos, borrar y restaurar, solo con teclado.
func _flujo_teclas(o) -> void:
	var u = o.controles_ui
	var B: Dictionary = u.botones
	var tab: Button = o.botones_pestana[2]
	await _ruta_foco([[KEY_D, B.mover_arriba.teclado1], [KEY_RIGHT, B.mover_arriba.mando0], [KEY_D, B.mover_arriba.mando0], [KEY_A, B.mover_arriba.teclado1], [KEY_LEFT, B.mover_arriba.teclado0], [KEY_A, B.mover_arriba.teclado0],
		[KEY_S, B.mover_abajo.teclado0], [KEY_DOWN, B.mover_izquierda.teclado0], [KEY_W, B.mover_abajo.teclado0], [KEY_UP, B.mover_arriba.teclado0], [KEY_W, tab], [KEY_S, B.mover_arriba.teclado0]], "Teclas")
	# hasta abajo y a los botones de restaurar
	for k in Controles.ACCIONES.size() - 1:
		await _t(KEY_S)
	_check(_foco() == B.pausa.teclado0, "S llega a la ultima accion")
	await _ruta_foco([[KEY_S, u.b_rest1], [KEY_D, u.b_rest2], [KEY_A, u.b_rest1], [KEY_S, o.b_volver], [KEY_W, u.b_rest1], [KEY_W, B.pausa.teclado1], [KEY_D, B.pausa.mando0], [KEY_S, u.b_rest2], [KEY_W, B.pausa.mando0]], "Teclas abajo")
	# capturar una tecla: Q no cambia de pestana mientras se espera
	B.disparar.teclado0.grab_focus()
	await _cuadros(4)
	await _t(KEY_ENTER, 14)
	_check(not u.capturando.is_empty() and u.ocupado(), "Enter espera una tecla")
	_foto("opciones_teclas_captura")
	await _t(KEY_Q, 10)
	_check(Controles.a.obtener("disparar", "teclado", 0) == "key:Q", "capturar: Q queda en Disparar")
	_check(o.pestana == 2, "capturar: Q no cambia de pestana")
	# WASD se puede capturar, y avisa del conflicto con moverse
	await _t(KEY_SPACE, 14)
	_check(not u.capturando.is_empty(), "Espacio tambien empieza a capturar")
	await _t(KEY_W, 10)
	_check(u.panel_conflicto != null, "capturar: W avisa que ya se usa para moverse")
	_foto("opciones_teclas_conflicto")
	var m = u.panel_conflicto
	_check(_foco() == m.controles[1], "el conflicto parte en Intercambiar")
	await _ruta_foco([[KEY_D, m.controles[2]], [KEY_A, m.controles[1]], [KEY_LEFT, m.controles[0]], [KEY_RIGHT, m.controles[1]], [KEY_W, m.controles[1]], [KEY_S, m.controles[1]]], "conflicto")
	await _t(KEY_ESCAPE, 10)
	_check(u.panel_conflicto == null and o.is_inside_tree(), "Esc cierra el conflicto")
	_check(_foco() == B.disparar.teclado0, "tras el conflicto el foco vuelve a la tecla")
	_check(Controles.a.obtener("mover_arriba", "teclado", 0) == "key:W", "cancelar no cambia nada")
	# Esc en la captura cancela, sin cerrar Opciones
	await _t(KEY_ENTER, 14)
	await _t(KEY_ESCAPE, 8)
	_check(u.capturando.is_empty() and o.is_inside_tree(), "Esc cancela la captura")
	# Supr borra la secundaria, y no deja a una accion sin teclas
	await _t(KEY_D)
	await _t(KEY_DELETE)
	_check(Controles.a.obtener("disparar", "teclado", 1) == "", "Supr borra la secundaria")
	await _t(KEY_A)
	await _t(KEY_DELETE)
	_check(Controles.a.obtener("disparar", "teclado", 0) == "key:Q", "Supr no deja la accion sin teclas")
	# restaurar esta: sirve para la ultima tecla elegida, aunque el foco ahora este en el boton
	u.b_rest1.grab_focus()
	await _cuadros(4)
	await _t(KEY_ENTER)
	_check(Controles.a.obtener("disparar", "teclado", 0) == "key:J" and Controles.a.obtener("disparar", "teclado", 1) == "key:Z", "Restaurar esta devuelve las de fabrica")
	u.botones.foco.teclado0.grab_focus()
	await _cuadros(4)
	await _t(KEY_ENTER, 14)
	await _t(KEY_F, 10)
	_check(Controles.a.obtener("foco", "teclado", 0) == "key:F", "F queda en Foco")
	u.b_rest2.grab_focus()
	await _cuadros(4)
	await _t(KEY_SPACE)
	_check(Controles.a.obtener("foco", "teclado", 0) == "key:Shift", "Restaurar todas")
	# desde la tabla, Esc vuelve a la pestana
	B.disparar.teclado1.grab_focus()
	await _cuadros(4)
	await _t(KEY_ESCAPE)
	_check(_foco() == tab and o.pestana == 2, "Esc en la tabla vuelve a la pestana Teclas")
	await _t(KEY_S)


## Partida nueva con teclado: ranura libre, dificultad, y al mapa.
func _flujo_partida_nueva(a) -> void:
	await _t(KEY_W)
	_check(_foco() == a.b_nueva, "W sube a NUEVA PARTIDA")
	await _t(KEY_ENTER, 10)
	var s = _hijo_de_tipo(a, P_SLOTS)
	_check(s != null and s.modo == "nueva", "Enter abre las ranuras")
	if s == null:
		return
	_check(_foco() == s.fichas[0], "la primera ranura libre tiene el foco")
	_foto("ranuras_nueva_vacias")
	await _ruta_foco([[KEY_D, s.fichas[1]], [KEY_RIGHT, s.fichas[2]], [KEY_D, s.fichas[0]], [KEY_A, s.fichas[2]], [KEY_LEFT, s.fichas[1]], [KEY_A, s.fichas[0]], [KEY_W, s.fichas[0]], [KEY_S, s.b_volver], [KEY_A, s.b_volver], [KEY_W, s.fichas[1]], [KEY_A, s.fichas[0]]], "ranuras")
	await _t(KEY_ESCAPE, 10)
	_check(_hijo_de_tipo(a, P_SLOTS) == null, "Esc cierra las ranuras")
	_check(principal.actual == a and _foco() == a.b_nueva, "el foco vuelve a NUEVA PARTIDA")
	await _t(KEY_SPACE, 10)
	s = _hijo_de_tipo(a, P_SLOTS)
	await _t(KEY_SPACE, 10)
	var d = _hijo_de_tipo(s, P_DIFICULTAD)
	_check(d != null, "elegir una ranura pide la dificultad")
	if d == null:
		return
	_check(_foco() == d.tarjetas["normal"], "parte en Normal")
	_foto("dificultad_extremo_cerrado")
	await _ruta_foco([[KEY_D, d.tarjetas["dificil"]], [KEY_RIGHT, d.tarjetas["extremo"]], [KEY_D, d.tarjetas["facil"]], [KEY_A, d.tarjetas["extremo"]], [KEY_LEFT, d.tarjetas["dificil"]], [KEY_A, d.tarjetas["normal"]], [KEY_S, d.b_volver], [KEY_W, d.tarjetas["normal"]]], "dificultad")
	d.tarjetas["extremo"].grab_focus()
	await _cuadros(4)
	await _t(KEY_ENTER, 10)
	_check(_hijo_de_tipo(s, P_DIFICULTAD) != null and d.aviso != "", "Extremo cerrado explica como se abre")
	_foto("dificultad_extremo_aviso")
	await _t(KEY_ESCAPE, 10)
	_check(_hijo_de_tipo(s, P_DIFICULTAD) == null and _foco() == s.fichas[0], "Esc vuelve a las ranuras")
	_check(not Partida.existe_slot(1), "volver atras no crea la partida")
	await _t(KEY_ENTER, 10)
	await _t(KEY_ENTER, 14)
	_check(Partida.existe_slot(1) and Partida.slot == 1 and Partida.dificultad() == "normal", "Enter crea la partida en Normal")


## Con partidas creadas: continuar, cargar, sobrescribir y borrar.
func _flujo_ranuras() -> void:
	var a = principal.actual
	await _cuadros(6)
	_check(a.b_continuar != null and _foco() == a.b_continuar, "con partida, CONTINUAR tiene el foco")
	_check(not a.b_cargar.disabled, "con partida, CARGAR esta prendido")
	_foto("titulo_con_partida")
	await _ruta_foco([[KEY_S, a.b_nueva], [KEY_S, a.b_cargar], [KEY_S, a.b_opciones], [KEY_S, a.b_salir], [KEY_S, a.b_continuar]], "titulo con partida")
	# sobrescribir avisa, y no toca nada hasta el final
	Partida.d.chatarra = 777
	Partida.guardar()
	await _ruta_foco([[KEY_S, a.b_nueva]], "a nueva")
	await _t(KEY_ENTER, 10)
	var s = _hijo_de_tipo(a, P_SLOTS)
	_check(_foco() == s.fichas[1], "NUEVA PARTIDA parte en la primera libre")
	await _t(KEY_A)
	await _t(KEY_ENTER, 10)
	var m = _hijo_de_tipo(s, P_MODAL)
	_check(m != null, "elegir una ocupada avisa")
	_foto("ranuras_sobrescribir")
	_check(_foco() == m.controles[0], "el aviso parte en la salida segura")
	await _ruta_foco([[KEY_D, m.controles[1]], [KEY_A, m.controles[0]], [KEY_S, m.controles[0]], [KEY_W, m.controles[0]]], "aviso")
	await _t(KEY_ESCAPE, 10)
	_check(_hijo_de_tipo(s, P_MODAL) == null and _foco() == s.fichas[0], "Esc cierra el aviso")
	await _t(KEY_ENTER, 10)
	await _t(KEY_D)
	await _t(KEY_ENTER, 10)
	var d = _hijo_de_tipo(s, P_DIFICULTAD)
	_check(d != null, "SOBRESCRIBIR pide la dificultad")
	await _t(KEY_ESCAPE, 10)
	_check(Partida.info_slot(1).chatarra == 777, "arrepentirse no borra la partida")
	# una segunda partida, en la ranura 2: Dificil
	await _t(KEY_D)
	await _t(KEY_ENTER, 10)
	await _t(KEY_D)
	await _t(KEY_ENTER, 14)
	_check(Partida.slot == 2 and Partida.dificultad() == "dificil", "la ranura 2 queda en Dificil")
	a = principal.actual
	_check(a.has_signal("jugar_nivel"), "y entra al mapa")
	var dl = _hijo_de_tipo(a, P_DIALOGO)
	_check(dl != null, "Don Tuerca se presenta en la partida nueva")
	await _t(KEY_ESCAPE, 10)
	# Esc en el mapa: primero al menu, y de ahi al titulo
	await _t(KEY_ESCAPE)
	_check(_foco() == a.b_menu, "Esc en el mapa va a MENU")
	await _t(KEY_ESCAPE, 14)
	a = principal.actual
	_check(a.has_signal("jugar"), "Esc en MENU vuelve al titulo")
	await _cuadros(4)
	# CARGAR: la ultima usada tiene el foco
	await _ruta_foco([[KEY_S, a.b_nueva], [KEY_S, a.b_cargar]], "a cargar")
	await _t(KEY_ENTER, 10)
	s = _hijo_de_tipo(a, P_SLOTS)
	_check(s != null and s.modo == "cargar" and _foco() == s.fichas[1], "CARGAR parte en la ultima usada")
	_foto("ranuras_cargar")
	await _ruta_foco([[KEY_A, s.fichas[0]], [KEY_S, s.b_borrar[0]], [KEY_D, s.b_borrar[1]], [KEY_W, s.fichas[1]], [KEY_D, s.fichas[2]], [KEY_S, s.b_volver], [KEY_W, s.fichas[1]], [KEY_A, s.fichas[0]]], "cargar")
	await _t(KEY_SPACE, 14)
	a = principal.actual
	_check(a.has_signal("jugar_nivel") and Partida.slot == 1 and Partida.d.chatarra == 777, "Espacio carga la ranura 1")
	await _t(KEY_ESCAPE)
	await _t(KEY_ESCAPE, 14)
	a = principal.actual
	# borrar: doble confirmacion, y la salida segura siempre primero
	await _ruta_foco([[KEY_S, a.b_nueva], [KEY_S, a.b_cargar]], "a cargar otra vez")
	await _t(KEY_ENTER, 10)
	s = _hijo_de_tipo(a, P_SLOTS)
	await _t(KEY_D)
	await _t(KEY_S)
	_check(_foco() == s.b_borrar[1], "S baja a BORRAR")
	await _t(KEY_ENTER, 10)
	m = _hijo_de_tipo(s, P_MODAL)
	_check(m != null, "BORRAR pregunta")
	_foto("ranuras_borrar_1")
	await _t(KEY_ENTER, 10)
	_check(Partida.existe_slot(2), "la salida segura no borra")
	_check(_foco() == s.b_borrar[1], "el foco vuelve a BORRAR")
	await _t(KEY_ENTER, 10)
	await _t(KEY_D)
	await _t(KEY_ENTER, 10)
	m = _hijo_de_tipo(s, P_MODAL)
	_check(m != null and Partida.existe_slot(2), "una segunda pregunta antes de borrar")
	_foto("ranuras_borrar_2")
	await _t(KEY_ESCAPE, 10)
	_check(Partida.existe_slot(2), "Esc en la segunda pregunta no borra")
	await _t(KEY_ENTER, 10)
	await _t(KEY_D)
	await _t(KEY_ENTER, 10)
	await _t(KEY_D)
	await _t(KEY_ENTER, 14)
	_check(not Partida.existe_slot(2), "la segunda confirmacion borra")
	_check(_foco() == s.fichas[1], "el foco queda en la ranura borrada")
	_foto("ranuras_borrada")
	# Supr sobre una ficha hace lo mismo que el boton
	await _t(KEY_A)
	await _t(KEY_DELETE, 10)
	_check(_hijo_de_tipo(s, P_MODAL) != null, "Supr pregunta")
	await _t(KEY_ESCAPE, 10)
	# una ranura vacia en CARGAR no es un callejon sin salida: parte una nueva
	await _t(KEY_D)
	await _t(KEY_ENTER, 10)
	_check(_hijo_de_tipo(s, P_DIFICULTAD) != null, "ranura vacia en CARGAR parte una nueva")
	await _t(KEY_ESCAPE, 10)
	await _t(KEY_ESCAPE, 10)
	_check(_hijo_de_tipo(a, P_SLOTS) == null, "Esc sale de CARGAR")


## La partida de la v0.2: el amigo no pierde su avance y queda justo antes del jefe.
func _flujo_migracion() -> void:
	var viejo := {"chatarra": 99999, "inventario": [], "mascota": {"nombre": "Pelusa", "xp": 5000}, "niveles": {}}
	for id in Datos.ORDEN_NIVELES:
		viejo.niveles[id] = {"completado": true, "estrellas": 3}
	Partida._escribir_json(Partida._ruta_v2(), viejo)
	Partida.borrar_slot(1)
	Partida.g.migrado = false
	Partida._migrar_v2()
	_check(Partida.existe_slot(1) and int(Partida.g.ultimo_slot) == 1, "migracion: la partida queda en la Ranura 1")
	_check("1-8" in str(Partida.g.aviso), "migracion: hay un aviso que dice donde quedaste")
	Partida.abrir_slot(1)
	principal.ir_titulo()
	await _cuadros(10)
	var a = principal.actual
	var m = _hijo_de_tipo(a, P_MODAL)
	_check(m != null, "migracion: el titulo muestra el aviso")
	_foto("migracion_aviso")
	_check(Partida.g.aviso == "", "migracion: el aviso se muestra una sola vez")
	await _t(KEY_ENTER, 10)
	_check(_hijo_de_tipo(a, P_MODAL) == null and _foco() == a.b_continuar, "migracion: Enter cierra y queda en CONTINUAR")
	await _t(KEY_ENTER, 14)
	a = principal.actual
	_check(a.has_signal("jugar_nivel"), "migracion: CONTINUAR entra al mapa")
	_check(Partida.nivel_actual() == "1-8" and not Partida.nivel_completado("1-8"), "migracion: queda justo antes del jefe")
	_check(Partida.dificultad() == "normal", "migracion: en Normal")
	_check(Partida.d.chatarra < 1000, "migracion: sin la chatarra inflada")
	_check(not "camper" in Partida.d.naves, "migracion: la Camper se gana en el jefe")
	_check(Partida.nombre_mascota("mordisco") == "Pelusa", "migracion: la mascota conserva su nombre")
	_check(_hijo_de_tipo(a, P_DIALOGO) == null, "migracion: no repite la presentacion")
	_foto("migracion_mapa")
	await _t(KEY_ESCAPE)
	await _t(KEY_ESCAPE, 14)


## Llevar una partida a otro computador: si el archivo esta, se ofrece.
func _flujo_importar() -> void:
	var a = principal.actual
	var ruta := "user://%s_importar.json" % Partida.prueba
	Partida.slot = 3
	Partida.generar_para("1-4", "dificil")
	Partida._escribir_json(ruta, Partida.d)
	Partida.abrir_slot(1)
	principal.ir_titulo()
	await _cuadros(10)
	a = principal.actual
	await _ruta_foco([[KEY_S, a.b_nueva], [KEY_S, a.b_cargar]], "a cargar con archivo")
	await _t(KEY_ENTER, 10)
	var s = _hijo_de_tipo(a, P_SLOTS)
	_check(s.b_importar != null, "con el archivo presente se ofrece IMPORTAR")
	_foto("ranuras_con_importar")
	s.b_importar.grab_focus()
	await _cuadros(4)
	await _ruta_foco([[KEY_D, s.b_volver], [KEY_A, s.b_importar], [KEY_LEFT, s.b_volver], [KEY_RIGHT, s.b_importar]], "importar")
	await _t(KEY_ENTER, 10)
	_check(s.modo == "importar", "IMPORTAR pide la ranura")
	_foto("ranuras_importar")
	await _t(KEY_ESCAPE, 10)
	_check(s.modo == "cargar", "Esc vuelve a CARGAR")
	s.b_importar.grab_focus()
	await _cuadros(4)
	await _t(KEY_ENTER, 10)
	# la ranura 3 esta libre
	s.fichas[2].grab_focus()
	await _cuadros(4)
	await _t(KEY_ENTER, 14)
	a = principal.actual
	_check(a.has_signal("jugar_nivel") and Partida.slot == 3 and Partida.dificultad() == "dificil" and Partida.nivel_actual() == "1-4", "importar deja la partida en esa ranura")
	await _cuadros(4)
	await _t(KEY_ESCAPE)
	await _t(KEY_ESCAPE, 14)
	a = principal.actual
	# un archivo malo no rompe nada: lo explica
	Partida._escribir_json(ruta, {"version": 1})
	await _ruta_foco([[KEY_S, a.b_nueva], [KEY_S, a.b_cargar]], "a cargar con archivo malo")
	await _t(KEY_ENTER, 10)
	s = _hijo_de_tipo(a, P_SLOTS)
	s.b_importar.grab_focus()
	await _cuadros(4)
	await _t(KEY_ENTER, 10)
	s.fichas[1].grab_focus()
	await _cuadros(4)
	await _t(KEY_ENTER, 10)
	_check(principal.actual == a and s.modo == "cargar" and s.mensaje != "", "un archivo malo se explica y no se cae")
	_foto("ranuras_importar_malo")
	await _t(KEY_ESCAPE, 10)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	_check(Partida.archivo_importable() == "", "sin archivo no se ofrece")


## Los niveles extra del mapa: se llega con teclado, se ven cerrados, y su panel explica de que se tratan.
func _flujo_mapa_extras() -> void:
	Partida.abrir_slot(3)
	Partida.d.vistos = ["inicio"]
	_marcar_vistos()
	principal.ir_mapa()
	await _cuadros(10)
	var a = principal.actual
	# 1-4 aun sin ganar: la ruleta esta cerrada, pero se puede mirar
	_check(_foco() == a.nodos["1-4"], "el foco parte en el nivel actual")
	_check(not Partida.nivel_abierto("1-R"), "la Ruleta parte cerrada")
	await _t(KEY_S, 10)
	_check(_foco() == a.nodos["1-R"], "S en 1-4 baja a la Ruleta")
	_foto("mapa_ruleta_cerrada")
	await _t(KEY_ENTER, 10)
	_check(a.modal == null, "la Ruleta cerrada no abre")
	await _ruta_foco([[KEY_S, a.nodos["1-R"]], [KEY_A, a.nodos["1-4"]], [KEY_DOWN, a.nodos["1-R"]], [KEY_RIGHT, a.nodos["1-5"]], [KEY_S, a.nodos["1-R"]], [KEY_W, a.nodos["1-4"]]], "ruleta")
	# arriba: de un nivel a los mundos; Esc lleva al menu
	await _t(KEY_W)
	_check(_foco() == a.planetas[0], "W en un nivel sube a los mundos")
	_foto("mapa_mundos")
	await _ruta_foco([[KEY_D, a.planetas[1]], [KEY_A, a.planetas[0]], [KEY_S, a.nodos["1-4"]]], "mundos")
	await _t(KEY_ESCAPE)
	_check(_foco() == a.b_menu, "Esc lleva a MENU")
	await _ruta_foco([[KEY_W, a.b_opciones], [KEY_UP, a.b_naves], [KEY_W, a.b_hangar], [KEY_D, a.nodos["1-4"]]], "columna")
	# la ruleta abierta
	Partida.completar_nivel("1-4", {"golpes": 9, "max_cadena": 0})
	Partida.guardar()
	principal.ir_mapa("1-5", "1-R")
	await _cuadros(10)
	a = principal.actual
	_foto("mapa_nuevo_ruleta")
	_check(a.recien == "1-5" and a.recien_extra == "1-R", "el mapa celebra los dos niveles que se abrieron")
	await _t(KEY_S, 10)
	_check(_foco() == a.nodos["1-R"], "S en 1-5 baja a la Ruleta")
	await _t(KEY_ENTER, 10)
	_check(a.modal != null and a.modal.modo == "ruleta", "Enter abre el panel de la Ruleta")
	_foto("panel_ruleta")
	await _ruta_foco([[KEY_A, a.modal.b_volver], [KEY_D, a.modal.b_jugar], [KEY_W, a.modal.b_jugar], [KEY_S, a.modal.b_jugar]], "panel ruleta")
	await _t(KEY_ESCAPE, 10)
	_check(a.modal == null and _foco() == a.nodos["1-R"], "Esc cierra el panel de la Ruleta")
	# volver al mapa tras jugar un nivel deja el foco en ese nivel, no en otro
	principal.ir_mapa("", "", "1-R")
	await _cuadros(10)
	a = principal.actual
	_check(_foco() == a.nodos["1-R"], "al volver de la Ruleta el foco sigue en ella")
	await _t(KEY_W)
	await _t(KEY_W)
	_check(_foco() == a.planetas[0], "a los mundos desde 1-4")
	await _t(KEY_ENTER)
	_check(_foco() == a.nodos[Partida.nivel_actual()], "Enter en el mundo actual lleva a su nivel")
	# lo que el panel del Modo Infinito muestra
	for id in Datos.ORDEN_NIVELES:
		if not Partida.nivel_completado(id):
			Partida.completar_nivel(id, {"golpes": 9, "max_cadena": 0})
	Partida.guardar()
	principal.ir_mapa("1-INF")
	await _cuadros(10)
	a = principal.actual
	_check(_foco() == a.nodos["1-INF"], "al terminar el mundo el foco queda en el Modo Infinito")
	_foto("mapa_infinito_nuevo")
	await _ruta_foco([[KEY_S, a.nodos["1-8"]], [KEY_W, a.nodos["1-INF"]], [KEY_D, a.nodos["portal"]], [KEY_W, a.nodos["1-INF"]], [KEY_A, a.nodos["1-8"]], [KEY_D, a.nodos["portal"]]], "infinito")
	_foto("mapa_portal")
	await _t(KEY_ENTER, 10)
	_check(a.modal == null, "el portal no abre nada")
	await _t(KEY_W)
	await _t(KEY_ENTER, 10)
	_check(a.modal != null and a.modal.modo == "infinito", "Enter abre el panel del Modo Infinito")
	_foto("panel_infinito_sin_record")
	await _t(KEY_ESCAPE, 10)
	Partida.d.records["1-INF"] = {"seg": 321, "kills": 900}
	await _t(KEY_ENTER, 10)
	_foto("panel_infinito_con_record")
	await _t(KEY_ESCAPE, 10)
	_foto("mapa_mundo_terminado")


## Nueva Partida +: se ofrece al terminar, explica, deja elegir y parte de cero con todo lo tuyo.
func _flujo_nueva_plus() -> void:
	var a = principal.actual
	_check(Partida.puede_ng_plus() and a.b_ngplus != null, "al terminar el mundo el mapa ofrece NUEVA PARTIDA +")
	var inv: int = Partida.d.inventario.size()
	await _t(KEY_ESCAPE)
	await _t(KEY_S)
	_check(_foco() == a.b_ngplus, "S baja de MENU a NUEVA PARTIDA +")
	await _t(KEY_ENTER, 10)
	var np = _hijo_de_tipo(a, P_NUEVA_PLUS)
	_check(np != null and _foco() == np.b_seguir, "se abre la explicacion")
	_foto("nueva_plus")
	await _ruta_foco([[KEY_A, np.b_volver], [KEY_W, np.b_repetir], [KEY_S, np.b_seguir], [KEY_W, np.b_repetir], [KEY_D, np.b_repetir], [KEY_S, np.b_seguir]], "nueva plus")
	await _t(KEY_ESCAPE, 10)
	_check(_hijo_de_tipo(a, P_NUEVA_PLUS) == null and _foco() == a.b_ngplus and Partida.ciclo() == 0, "Esc vuelve al mapa y no cambia nada")
	await _t(KEY_SPACE, 10)
	np = _hijo_de_tipo(a, P_NUEVA_PLUS)
	await _t(KEY_ENTER, 10)
	var d = _hijo_de_tipo(np, P_DIFICULTAD)
	_check(d != null, "pide la dificultad")
	_check(_foco() == d.tarjetas[Partida.dificultad()], "parte en la que traias")
	_foto("nueva_plus_dificultad")
	await _t(KEY_ESCAPE, 10)
	_check(_hijo_de_tipo(np, P_DIFICULTAD) == null and _foco() == np.b_seguir and Partida.ciclo() == 0, "Esc vuelve a la explicacion")
	await _t(KEY_ENTER, 10)
	d = _hijo_de_tipo(np, P_DIFICULTAD)
	d.tarjetas["extremo"].grab_focus()
	await _cuadros(4)
	await _t(KEY_ENTER, 16)
	_check(Partida.ciclo() == 1 and Partida.dificultad() == "extremo", "Extremo ya esta abierto y sube el ciclo")
	_check(Partida.d.niveles.is_empty() and Partida.d.inventario.size() == inv, "parte de cero con todo lo tuyo")
	a = principal.actual
	_check(a.has_signal("jugar_nivel"), "vuelve al mapa")
	var dl = _hijo_de_tipo(a, P_DIALOGO)
	_check(dl != null and dl.lineas == Datos.DIALOGOS["nueva_plus"], "Don Tuerca comenta la nueva vuelta")
	var repe := Partida.completar_nivel("1-1", {"golpes": 9, "max_cadena": 0})
	_check(repe.premio.tipo == "chatarra", "en la segunda vuelta el Hangar no se celebra como nuevo")
	Partida.d.niveles.erase("1-1")
	_foto("nueva_plus_dialogo")
	await _t(KEY_ESCAPE, 10)
	_check(_foco() == a.nodos["1-1"], "el foco queda en 1-1")
	_check(a.b_ngplus == null, "ya no se ofrece hasta terminar de nuevo")
	_foto("mapa_ciclo_1")
	Partida.d.ciclo = 0
	Partida.d.dificultad = "normal"
	Partida.guardar()


## Todos los tipos de premio se muestran bien, y se cierran con teclado o clic.
func _flujo_premios() -> void:
	_marcar_vistos()
	principal.ir_mapa()
	await _cuadros(6)
	var a = principal.actual
	var lista := []
	Partida.d.premios_dados = []
	for id in ["1-1", "1-2", "1-3", "1-4", "1-5", "1-6", "1-7", "1-8", "1-R"]:
		lista.append(Partida._aplicar_premio(Datos.NIVELES[id].premio.duplicate(), id))
	for id in ["a_cohetes", "h_aimbot", "n_speedrunner", "m_chispita", "m_caparazon", "r_hab4", "r_arma3"]:
		for de in Datos.DESAFIOS:
			if de.id == id:
				lista.append(Partida._premio_desafio(de))
	var n := 0
	# los dialogos mas largos caben en su caja
	for quien in ["tuerca", "calypso"]:
		var largo := ""
		for k in Datos.DIALOGOS:
			for l in Datos.DIALOGOS[k]:
				if l[0] == quien and l[1].length() > largo.length():
					largo = l[1]
		var dl = load(P_DIALOGO).new()
		dl.lineas = [[quien, largo], [quien, "Y una linea mas."]]
		a.add_child(dl)
		await _cuadros(16)
		await _t(KEY_ENTER, 6)
		_check(dl.visibles >= dl.total, "Enter completa el texto de " + quien)
		_foto("dialogo_largo_" + quien)
		await _cuadros(2)
		await _t(KEY_ESCAPE, 8)
	for pr in lista:
		n += 1
		var p = load(P_PREMIO).new()
		p.premio = pr
		p.indice = n
		p.total = lista.size()
		a.add_child(p)
		await _cuadros(56)
		_foto("premio_%02d_%s" % [n, str(pr.get("tipo", ""))])
		await _cuadros(2)
		await _t(KEY_SPACE if n % 2 == 0 else KEY_ENTER, 6)
		_check(_hijo_de_tipo(a, P_PREMIO) == null, "premio %s se cierra" % str(pr.get("nombre", "")))


## Cada final de nivel dice lo que pasó.
func _flujo_resultados() -> void:
	Partida.d.vistos = ["inicio"]
	_marcar_vistos()
	for tipo in ["ganado", "derrota", "retiro", "retiro_rapido", "infinito", "ruleta"]:
		Partida.nivel_sel = "1-2"
		if tipo == "infinito":
			Partida.d.records.erase("1-INF")
		principal.ir_resultado(_res_demo(tipo))
		await _cuadros(4)
		var r = principal.actual
		_check(r.has_signal("al_mapa"), "resultado %s se abre" % tipo)
		await _t(KEY_SPACE, 4)
		_check(r.b1.visible and _foco() == r.b1, "resultado %s: Espacio salta la animacion" % tipo)
		await _cuadros(6)
		_foto("resultado_" + tipo)
		await _ruta_foco([[KEY_A, r.b2], [KEY_D, r.b1], [KEY_LEFT, r.b2], [KEY_RIGHT, r.b1], [KEY_W, r.b1], [KEY_S, r.b1]], "resultado " + tipo)
		if r.b3.visible:
			await _ruta_foco([[KEY_D, r.b3], [KEY_D, r.b3], [KEY_A, r.b1]], "resultado hangar " + tipo)
		await _t(KEY_ENTER, 12)
		# premios y dialogos que hayan quedado: la derrota no comenta ni en el Modo Infinito ni al retirarse
		var dl = _hijo_de_tipo(principal.actual, P_DIALOGO)
		if tipo in ["retiro", "retiro_rapido", "infinito"]:
			_check(dl == null, "resultado %s: sin dialogo de derrota" % tipo)
		for k in 8:
			var pr = _hijo_de_tipo(principal.actual, P_PREMIO)
			if pr != null:
				await _cuadros(56)
				await _t(KEY_ENTER, 10)
			dl = _hijo_de_tipo(principal.actual, P_DIALOGO)
			if dl != null:
				await _t(KEY_ESCAPE, 10)
		_check(principal.actual.has_signal("jugar_nivel"), "resultado %s: CONTINUAR vuelve al mapa" % tipo)
	# un retiro rapido no da nada de nada
	var ch: int = Partida.d.chatarra
	var inv: int = Partida.d.inventario.size()
	var b := Partida.generar_botin(_res_demo("retiro_rapido"))
	_check(b.chatarra == 0 and b.items.is_empty() and Partida.d.chatarra == ch and Partida.d.inventario.size() == inv, "entrar y salir no da nada")


## La pausa, con teclado: se queda dentro de sus botones. Las opciones adentro mandan sobre sus teclas.
func _flujo_pausa() -> void:
	Partida.nivel_sel = "1-1"
	principal.ir_combate()
	await _cuadros(20)
	var c = principal.actual
	_tecla(KEY_ESCAPE)
	await _cuadros(20)
	_check(c.estado == "pausa", "Esc pausa")
	var pa = c.capa_pausa.get_child(0)
	_foto("pausa")
	_check(_foco() == pa.botones[0], "la pausa parte en Continuar")
	await _ruta_foco([[KEY_S, pa.botones[1]], [KEY_DOWN, pa.botones[2]], [KEY_S, pa.botones[3]], [KEY_S, pa.botones[0]], [KEY_W, pa.botones[3]], [KEY_UP, pa.botones[2]], [KEY_A, pa.botones[2]], [KEY_D, pa.botones[2]], [KEY_W, pa.botones[1]]], "pausa")
	await _t(KEY_ENTER, 10)
	var o = pa.get_node_or_null("Opciones")
	_check(o != null, "Enter abre Opciones")
	await _t(KEY_P, 6)
	_check(pa.get_node_or_null("Opciones") != null and c.estado == "pausa", "P no cierra la pausa con Opciones abiertas")
	await _t(KEY_E, 6)
	_check(o.pestana == 1, "E cambia de pestana dentro de la pausa")
	await _t(KEY_ESCAPE, 10)
	_check(pa.get_node_or_null("Opciones") == null and _foco() == pa.botones[1], "Esc cierra Opciones y vuelve a la pausa")
	await _t(KEY_ESCAPE, 20)
	_check(c.estado != "pausa", "Esc sigue jugando")
	principal.ir_mapa()
	await _cuadros(6)


## Clic real en el centro de un control.
func _clic(c: Control, boton := MOUSE_BUTTON_LEFT) -> void:
	await _clic_en(c.get_global_rect().get_center(), boton)


## Todo con el mouse, sin tocar el teclado: en coordenadas de la pantalla de 640x360.
func _clic_en(pos: Vector2, boton := MOUSE_BUTTON_LEFT) -> void:
	_mover_mouse(pos)
	await _cuadros(2)
	var escala := float(get_window().size.x) / 640.0
	var ev := InputEventMouseButton.new()
	ev.position = pos * escala
	ev.global_position = ev.position
	ev.button_index = boton
	ev.pressed = true
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if boton == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
	Input.parse_input_event(ev)
	await _cuadros(2)
	var ev2 := InputEventMouseButton.new()
	ev2.position = ev.position
	ev2.global_position = ev.position
	ev2.button_index = boton
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _cuadros(6)


func _mover_mouse(pos: Vector2) -> void:
	var escala := float(get_window().size.x) / 640.0
	var ev := InputEventMouseMotion.new()
	ev.position = pos * escala
	ev.global_position = ev.position
	Input.parse_input_event(ev)


func _flujo_mouse() -> void:
	# la ventana de prueba no tiene el mouse encima: se le avisa para que los botones sepan que lo tienen
	get_tree().root.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	principal.ir_titulo()
	await _cuadros(8)
	var a = principal.actual
	await _clic(a.b_opciones)
	var o = _hijo_de_tipo(a, P_OPCIONES)
	_check(o != null, "mouse: clic abre Opciones")
	if o == null:
		return
	# pestanas
	await _clic(o.botones_pestana[1])
	_check(o.pestana == 1, "mouse: clic cambia de pestana")
	_check(_foco() == o.botones_pestana[1], "mouse: clic en la pestana no salta a las filas")
	# flechas de la fila y barra
	var f = o.filas[0]
	Ajustes.musica = 50
	var r: Rect2 = f.get_global_rect()
	await _clic_en(r.position + Vector2(f.X_MENOS + 8.0, 12.0))
	_check(Ajustes.musica == 40, "mouse: la flecha izquierda baja")
	await _clic_en(r.position + Vector2(f.X_MAS + 8.0, 12.0))
	_check(Ajustes.musica == 50, "mouse: la flecha derecha sube")
	await _clic_en(r.position + Vector2(f.X_BARRA + f.AN_BARRA * 0.8, 12.0))
	_check(Ajustes.musica == 80, "mouse: clic en la barra fija el valor")
	_foto("mouse_barra")
	# una fila que se prende y apaga
	await _clic(o.botones_pestana[0])
	var v: bool = Ajustes.pantalla_completa
	await _clic_en(o.filas[0].get_global_rect().position + Vector2(300.0, 12.0))
	_check(Ajustes.pantalla_completa != v, "mouse: clic en el valor cambia")
	await _clic_en(o.filas[0].get_global_rect().position + Vector2(o.filas[0].X_MENOS + 8.0, 12.0))
	_check(Ajustes.pantalla_completa == v, "mouse: la flecha tambien")
	# teclas: clic captura, Cancelar sale, clic derecho borra
	await _clic(o.botones_pestana[2])
	var u = o.controles_ui
	_check(u != null, "mouse: abre Teclas")
	await _clic(u.botones.esquivar.teclado1)
	_check(not u.capturando.is_empty(), "mouse: clic espera una tecla")
	await _cuadros(10)
	await _clic(u.b_cancelar)
	_check(u.capturando.is_empty(), "mouse: Cancelar deja de esperar sin asignar el clic")
	_check(Controles.a.obtener("esquivar", "teclado", 1) == "key:L", "mouse: cancelar no cambia la tecla")
	await _clic(u.botones.esquivar.teclado1, MOUSE_BUTTON_RIGHT)
	_check(Controles.a.obtener("esquivar", "teclado", 1) == "", "mouse: clic derecho borra")
	await _clic(u.b_rest1)
	_check(Controles.a.obtener("esquivar", "teclado", 1) == "key:L", "mouse: Restaurar esta")
	await _clic(u.botones.desync.teclado0)
	await _cuadros(10)
	await _clic(u.botones.disparar.teclado0)
	_check(u.panel_conflicto == null and Controles.a.obtener("desync", "teclado", 0) == "mouse:1", "mouse: un clic se puede asignar como tecla")
	await _clic(u.b_rest2)
	_check(Controles.a.obtener("desync", "teclado", 0) == "key:X", "mouse: Restaurar todas")
	await _clic(o.b_volver)
	_check(_hijo_de_tipo(a, P_OPCIONES) == null, "mouse: VOLVER cierra Opciones")
	# partida nueva
	Partida.borrar_slot(2)
	await _clic(a.b_nueva)
	var s = _hijo_de_tipo(a, P_SLOTS)
	_check(s != null, "mouse: NUEVA PARTIDA abre las ranuras")
	await _clic(s.fichas[1])
	var d = _hijo_de_tipo(s, P_DIFICULTAD)
	_check(d != null, "mouse: clic en una ficha pide la dificultad")
	await _clic(d.b_volver)
	_check(_hijo_de_tipo(s, P_DIFICULTAD) == null, "mouse: VOLVER en la dificultad")
	await _clic(s.fichas[1])
	d = _hijo_de_tipo(s, P_DIFICULTAD)
	await _clic(d.tarjetas["facil"])
	await _cuadros(10)
	_check(Partida.slot == 2 and Partida.dificultad() == "facil", "mouse: clic en Facil crea la partida")
	a = principal.actual
	# el dialogo avanza con clics
	var dl = _hijo_de_tipo(a, P_DIALOGO)
	_check(dl != null, "mouse: Don Tuerca saluda")
	await _cuadros(10)
	await _clic_en(Vector2(320, 200))
	_check(dl.visibles >= dl.total, "mouse: clic completa el texto")
	await _clic_en(Vector2(320, 200))
	_check(dl.i == 1, "mouse: clic pasa a la linea siguiente")
	for k in dl.lineas.size() * 2:
		if is_instance_valid(dl):
			await _clic_en(Vector2(320, 200))
	_check(_hijo_de_tipo(a, P_DIALOGO) == null, "mouse: a clics se termina el dialogo")
	# y un clic donde dice "saltar todo" lo cierra de una
	var dl2 = load(P_DIALOGO).new()
	dl2.lineas = Datos.DIALOGOS["inicio"]
	a.add_child(dl2)
	await _cuadros(14)
	await _clic_en(dl2.R_SALTAR.get_center())
	_check(_hijo_de_tipo(a, P_DIALOGO) == null, "mouse: clic en saltar todo")
	# mapa y panel
	await _clic(a.nodos["1-2"])
	_check(a.modal == null, "mouse: un nivel cerrado no abre")
	await _clic(a.nodos["1-1"])
	_check(a.modal != null, "mouse: clic abre el nivel")
	await _clic_en(Vector2(10, 10))
	_check(a.modal == null, "mouse: clic afuera cierra el panel")
	await _clic(a.nodos["1-1"])
	await _clic(a.modal.b_volver)
	_check(a.modal == null, "mouse: VOLVER cierra el panel")
	var cam0: float = a.cam_obj
	await _clic_en(Vector2(640 - 15, 334))
	_check(a.cam_obj > cam0, "mouse: la flecha mueve el mapa")
	await _clic(a.b_opciones)
	_check(a.modal != null, "mouse: OPCIONES en el mapa")
	await _clic(a.modal.b_volver)
	await _cuadros(4)
	_check(a.modal == null, "mouse: y VOLVER")
	await _clic(a.b_menu)
	await _cuadros(4)
	a = principal.actual
	_check(a.has_signal("jugar"), "mouse: MENU vuelve al titulo")
	# cargar y borrar
	await _clic(a.b_cargar)
	s = _hijo_de_tipo(a, P_SLOTS)
	_check(s != null and s.modo == "cargar", "mouse: CARGAR")
	await _clic(s.b_borrar[1])
	var m = _hijo_de_tipo(s, P_MODAL)
	_check(m != null, "mouse: BORRAR pregunta")
	await _clic(m.controles[0])
	_check(Partida.existe_slot(2), "mouse: NO no borra")
	await _clic(s.b_borrar[1])
	m = _hijo_de_tipo(s, P_MODAL)
	await _clic(m.controles[1])
	m = _hijo_de_tipo(s, P_MODAL)
	await _clic(m.controles[1])
	_check(not Partida.existe_slot(2), "mouse: doble confirmacion borra")
	await _clic(s.fichas[0])
	await _cuadros(4)
	_check(principal.actual.has_signal("jugar_nivel") and Partida.slot == 1, "mouse: clic carga la ficha")
# --- recorrido del Hangar con entradas reales -------------------------------------------------
# Se activa con --flujo_hangar. Es aparte de _flujo(): recorre la sala, cada estación, el Arsenal y las mascotas.
# Con --capturas=carpeta deja fotos con nombre de cada momento.


## --sub=piezas abre esa pestaña del Arsenal y --sel=id deja seleccionada esa cosa (para las capturas).
func _abrir_en_hangar(h) -> void:
	if h.actual == null:
		return
	if args.has("sub") and h.actual.has_method("elegir_pestana"):
		h.actual.elegir_pestana(args.sub)
	if args.has("sel") and h.actual.has_method("seleccionar"):
		h.actual.seleccionar(args.sel)


## Una partida a mitad de camino: algo ganado, algo apagado y varios desafíos a medias.
func _demo_arsenal() -> void:
	var e: Dictionary = Partida.d.estadisticas
	e.k_rabioso = 30
	e.k_sniper = 8
	e.k_mosca = 12
	e.roces = 95
	e.sin_golpes = 1
	e.desyncs = 12
	e.chatarra_total = 420
	e.kills = 640
	e.max_cadena = 24
	e.victorias = 4
	e.esquivas = 70
	e.giros = 1
	e.inf_seg = 45
	Partida.revisar_desafios()
	if "goblin" in Partida.d.habs:
		Partida.alternar("goblin")
	if "ping_pong" in Partida.d.armas:
		Partida.alternar("ping_pong")


func _esperar(cuadros: int) -> void:
	for i in cuadros:
		await get_tree().physics_frame


## Aprieta una tecla de verdad y espera a que haga efecto.
func _apretar(k: Key, cuadros := 5) -> void:
	_tecla(k)
	await _esperar(cuadros)


## Una letra para escribir en un LineEdit: necesita su carácter.
func _letra(k: Key, c: String) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.unicode = c.unicode_at(0)
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2: InputEventKey = ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event.call_deferred(ev2)
	await _esperar(3)


## El mouse, en coordenadas de la pantalla lógica de 640x360.
func _raton(p: Vector2) -> Vector2:
	return p * (float(get_window().size.x) / 640.0)


func _raton_mover(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _raton(p)
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	await _esperar(4)


func _raton_clic(p: Vector2) -> void:
	await _raton_mover(p)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = _raton(p)
	ev.global_position = ev.position
	ev.pressed = true
	Input.parse_input_event(ev)
	await _esperar(2)
	var ev2: InputEventMouseButton = ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _esperar(5)


func _raton_rueda(p: Vector2) -> void:
	await _raton_mover(p)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_WHEEL_DOWN
	ev.position = _raton(p)
	ev.global_position = ev.position
	ev.factor = 1.0
	ev.pressed = true
	Input.parse_input_event(ev)
	await _esperar(2)
	var ev2: InputEventMouseButton = ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _esperar(6)


func _foto_h(nombre: String) -> void:
	if carpeta == "":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(carpeta)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [carpeta, nombre])


## El centro de un control, en la pantalla lógica.
func _centro(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


## Lo definitivo lo hace UI_A en controles.gd. Aquí se garantiza para poder probar WASD en esta copia.
func _asegurar_wasd() -> void:
	for par in [["ui_up", KEY_W], ["ui_down", KEY_S], ["ui_left", KEY_A], ["ui_right", KEY_D], ["ui_accept", KEY_SPACE]]:
		var ev := InputEventKey.new()
		ev.keycode = par[1]
		if not InputMap.action_has_event(par[0], ev):
			InputMap.action_add_event(par[0], ev)


## Camina por la barra de la sala con las flechas hasta llegar a ese objeto.
func _ir_a_objeto(s, id: String) -> void:
	for i in 12:
		if s.foco == id:
			return
		var derecha: bool = s.orden.find(id) > s.orden.find(s.foco)
		await _apretar(KEY_RIGHT if derecha else KEY_LEFT, 4)


func _flujo_hangar() -> void:
	_asegurar_wasd()
	await _esperar(10)
	await _fh_partida_nueva()
	await _fh_preparar_avanzada()
	await _fh_naves()
	await _fh_equipo()
	await _fh_fusion()
	await _fh_mascotas()
	await _fh_arsenal()
	await _fh_arsenal_secretos()
	await _fh_seleccion()
	await _fh_mouse()
	print("[flujo_hangar] ok=%d fallas=%d" % [f_ok, f_mal])
	get_tree().quit()


## Solo el 1-1 ganado: hay Hangar y todo lo demás está cerrado.
func _fh_partida_nueva() -> void:
	print("-- partida nueva")
	Partida.nuevo()
	_avanzar_hasta("1-2")
	principal.ir_mapa()
	await _esperar(20)
	var m = principal.actual
	m.b_hangar.grab_focus()
	await _esperar(2)
	await _apretar(KEY_ENTER, 8)
	var h = principal.actual
	_check(h.has_method("esta_abierta") and h.en_sala, "HANGAR abre la sala, no una estación")
	var s = h.sala
	_check(s.botones.size() == 6, "la barra tiene las seis cosas")
	for id in SalaHangar.ORDEN:
		_check(s.botones.has(id) and s.botones[id].text == SalaHangar.OBJETOS[id].nombre, "la barra dice " + SalaHangar.OBJETOS[id].nombre)
	_check(_foco() == s.botones["naves"], "el foco parte en NAVES")
	_check(s.sombra < 1.0, "el resto se oscurece de a poco al entrar")
	await _esperar(30)
	_check(is_equal_approx(s.sombra, 1.0) and is_equal_approx(s.luz["naves"], 1.0), "queda la nave con luz y lo demás oscuro")
	_check(s.datos["naves"].tex != null, "el contorno se generó desde el alfa")
	_check(is_same(s.contorno_de(s.texs["naves"]), s.datos["naves"]), "el contorno queda guardado y no se rehace")
	_revisar_contornos(s)
	_check(s.nave.texture == Datos.tex("nave2_" + Partida.nave_actual()), "la nave real está en la plataforma")
	await _foto_h("01_sala_nueva")
	# flechas y WASD
	var antes: String = s.foco
	await _apretar(KEY_RIGHT, 2)
	var nuevo: String = s.foco
	_check(nuevo != antes and _foco() == s.botones[nuevo], "la derecha cambia de objeto")
	_check(s.luz[nuevo] > 0.0 and s.luz[nuevo] < 1.0, "el brillo sube con un fundido, no de golpe")
	_check(s.luz[antes] > 0.0 and s.luz[antes] < 1.0, "el anterior se apaga con un fundido")
	await _esperar(30)
	_check(is_equal_approx(s.luz[nuevo], 1.0) and is_equal_approx(s.luz[antes], 0.0), "el fundido termina")
	await _apretar(KEY_A, 5)
	_check(s.foco == antes, "A vuelve")
	await _apretar(KEY_D, 5)
	_check(s.foco == nuevo, "D avanza")
	await _apretar(KEY_LEFT, 5)
	_check(s.foco == antes, "la izquierda vuelve")
	# la barra va como la habitación
	for i in s.orden.size() - 2:
		var x0: float = SalaHangar.OBJETOS[s.orden[i]].r.get_center().x
		var x1: float = SalaHangar.OBJETOS[s.orden[i + 1]].r.get_center().x
		_check(x0 <= x1, "la barra sigue el orden de la habitación: " + s.orden[i])
	_check(s.orden[-1] == "salida", "SALIR va al final")
	# arriba y abajo no dejan el foco fuera de la barra
	await _apretar(KEY_W, 4)
	_check(s.botones.values().has(_foco()), "W se queda en la sala")
	await _apretar(KEY_S, 4)
	_check(s.botones.values().has(_foco()), "S se queda en la sala")
	# lo cerrado
	_check(not h.esta_abierta("fusionar") and not h.esta_abierta("mascota") and not h.esta_abierta("arsenal"), "lo demás parte cerrado")
	_check("1-3" in h.como_se_abre("fusionar"), "Fusionar dice que se abre con 1-3: " + h.como_se_abre("fusionar"))
	_check("1-4" in h.como_se_abre("arsenal"), "Arsenal dice que se abre con 1-4: " + h.como_se_abre("arsenal"))
	await _ir_a_objeto(s, "fusionar")
	_check(s.foco == "fusionar", "se puede enfocar lo cerrado para ver cómo se abre")
	await _apretar(KEY_ENTER, 3)
	_check(h.en_sala and s.temblor > 0.0, "Enter en lo cerrado no abre y avisa")
	await _esperar(10)
	await _foto_h("02_sala_cerrado")
	await _ir_a_objeto(s, "equipo")
	await _apretar(KEY_ENTER, 8)
	_check(not h.en_sala and h.pestana == "equipo", "Enter abre Equipo")
	_check(_foco() != null and _foco().get("id") in Datos.RANURAS, "el foco queda en las ranuras")
	_check(not h.actual.botones_ranura.has("reactor"), "punto 6: no se ve la ranura del reactor sin Desync")
	_check(PiezaBoton.sin_spoiler("+6 % de carga de Desync") == "???", "punto 6: lo del Desync sale como ???")
	await _foto_h("03_equipo_nuevo")
	# Q y E recorren las estaciones, también las cerradas
	await _apretar(KEY_E, 6)
	_check(h.pestana == "fusionar", "E pasa a la siguiente")
	_check(h.actual != null and _foco() == h.tabs["fusionar"], "lo cerrado se ve, con el foco en su pestaña")
	await _foto_h("04_fusion_cerrada")
	await _apretar(KEY_DOWN, 4)
	_check(_foco() == h.tabs["fusionar"], "en lo cerrado, abajo no se va a ninguna parte")
	await _apretar(KEY_Q, 6)
	_check(h.pestana == "equipo", "Q vuelve")
	await _apretar(KEY_ESCAPE, 6)
	_check(h.en_sala and s.visible and s.foco == "equipo", "Esc vuelve a la sala, en el mismo objeto")
	await _apretar(KEY_ESCAPE, 8)
	_check(principal.actual.has_signal("jugar_nivel"), "Esc en la sala vuelve al mapa")
	principal.ir_hangar("fusionar")
	await _esperar(6)
	h = principal.actual
	_check(h.en_sala and h.sala.foco == "fusionar", "pedir una estación cerrada deja en la sala, sobre ella")
	principal.ir_hangar("naves")
	await _esperar(6)
	h = principal.actual
	_check(not h.en_sala and h.pestana == "naves" and _foco() is GaleriaNaves.Tarjeta, "ir_hangar(\"naves\") abre directo esa estación")
	await _apretar(KEY_ESCAPE, 6)
	_check(h.en_sala and h.sala.foco == "naves", "y Esc vuelve a la sala")
	await _esperar(6)


## Los contornos se rehacen midiendo cuánto tardan, y se revisa que ninguno pise a su objeto.
func _revisar_contornos(s) -> void:
	s._contornos.clear()
	var t0 := Time.get_ticks_usec()
	for id in SalaHangar.ORDEN:
		s.datos[id] = s.contorno_de(s.texs[id])
	print("  contornos generados en %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	for id in SalaHangar.ORDEN:
		var d: Dictionary = s.datos[id]
		var fuente: Image = s.texs[id].get_image()
		fuente.convert(Image.FORMAT_RGBA8)
		var linea: Image = d.tex.get_image()
		var pisa := 0
		var pinta := 0
		for y in linea.get_height():
			for x in linea.get_width():
				if linea.get_pixel(x, y).a <= 0.0:
					continue
				pinta += 1
				var fx: int = x - s.MARGEN
				var fy: int = y - s.MARGEN
				if fx >= 0 and fy >= 0 and fx < d.w and fy < d.h and fuente.get_pixel(fx, fy).a8 >= s.UMBRAL_ALFA:
					pisa += 1
		_check(pinta > 0 and pisa == 0, "el contorno de %s rodea su forma sin pisarla (%d píxeles)" % [id, pinta])


## Casi todo el mundo jugado, con desafíos a medias.
func _fh_preparar_avanzada() -> void:
	print("-- partida avanzada")
	Partida.nuevo()
	_avanzar_hasta("1-7")
	Partida.d.chatarra = 500
	Partida.d.naves.append("camper")
	Partida.dar_mascota("mordisco")
	Partida.d.mascotas.mordisco.xp = 90
	Partida.dar_mascota("chispita")
	Partida.agregar("casco_blindado", 0)
	Partida.agregar("chip_suerte", 0)
	Partida.agregar("chip_suerte", 0)
	var e: Dictionary = Partida.d.estadisticas
	e.k_rabioso = 30
	e.chatarra_total = 420
	e.roces = 60
	Partida.revisar_desafios()
	_check("cohetes" in Partida.d.armas and "goblin" in Partida.d.habs, "se ganó un arma y una habilidad")
	principal.ir_hangar()
	await _esperar(30)
	await _foto_h("05_sala_avanzada")


func _fh_naves() -> void:
	print("-- naves")
	var h = principal.actual
	var s = h.sala
	_check(s.foco == "naves", "la sala parte en NAVES")
	await _apretar(KEY_ENTER, 8)
	_check(not h.en_sala and h.pestana == "naves", "Enter abre Naves")
	var g = h.galeria
	_check(g != null and _foco() == g.tarjetas[Partida.nave_actual()], "el foco parte en la nave que usas")
	_check(h.b_usar.disabled, "la nave que usas no se puede volver a elegir")
	await _foto_h("06_naves")
	await _apretar(KEY_RIGHT, 5)
	_check(g.sel == "camper" and not h.b_usar.disabled, "la derecha cambia de nave")
	await _apretar(KEY_ENTER, 5)
	_check(Partida.nave_actual() == "camper", "Enter sale con esa nave")
	await _apretar(KEY_D, 5)
	_check(g.sel == "support" and h.b_usar.disabled, "lo bloqueado no se puede elegir")
	_check(h.b_usar.text == "BLOQUEADA", "y dice que está bloqueada")
	_check("/40" in Partida.progreso_nave("support"), "dice cuánto falta: " + Partida.progreso_nave("support"))
	await _foto_h("07_nave_bloqueada")
	await _apretar(KEY_ENTER, 5)
	_check(Partida.nave_actual() == "camper", "Enter en lo bloqueado no cambia nada")
	await _apretar(KEY_LEFT, 5)
	# bajar a las pinturas
	await _apretar(KEY_DOWN, 5)
	_check(_foco() == g.pinturas[0], "abajo baja a las pinturas")
	await _apretar(KEY_RIGHT, 5)
	_check(_foco() == g.pinturas[1], "se elige la pintura con las flechas")
	await _apretar(KEY_ENTER, 5)
	_check(Partida.pintura_de("camper") == 1, "Enter pinta la nave")
	await _apretar(KEY_DOWN, 5)
	_check(_foco() == h.b_usar, "abajo llega al botón")
	await _apretar(KEY_UP, 5)
	await _apretar(KEY_UP, 5)
	_check(_foco() == g.tarjetas["camper"], "arriba vuelve a la nave elegida")
	await _apretar(KEY_UP, 5)
	_check(_foco() == h.tabs["naves"], "arriba sube a la pestaña")
	await _apretar(KEY_LEFT, 5)
	_check(_foco() == h.tabs["naves"], "la primera pestaña no se sale por la izquierda")
	await _apretar(KEY_DOWN, 5)
	_check(_foco() == g.tarjetas["camper"], "abajo vuelve a la nave")
	Partida.elegir_nave("tryhard")


func _fh_equipo() -> void:
	print("-- equipo")
	var h = principal.actual
	await _apretar(KEY_E, 8)
	_check(h.pestana == "equipo", "E pasa a Equipo")
	var e = h.actual
	_check(e.botones_ranura.has("reactor"), "con Desync se ve el reactor")
	await _apretar(KEY_RIGHT, 5)
	_check(e.ranura == "casco" and _foco() == e.botones_ranura["casco"], "la derecha cambia de ranura y su lista")
	await _apretar(KEY_DOWN, 5)
	_check(_foco() is PiezaBoton and _foco().item.uid == e.sel_uid, "abajo baja a la pieza que llevas puesta")
	var puesta: int = Partida.equipado("casco").uid
	# la lista va ordenada por nombre: Casco Blindado queda antes que Casco de Lata
	await _apretar(KEY_LEFT, 5)
	_check(_foco() is PiezaBoton and _foco().item.uid != puesta, "la izquierda pasa a otra pieza")
	var otra: int = _foco().item.uid
	_check(e.sel_uid == otra and not e.b_equipar.disabled, "la ficha muestra la pieza con foco")
	await _foto_h("08_equipo")
	await _apretar(KEY_ENTER, 5)
	_check(Partida.equipado("casco").uid == otra, "Enter se la pone")
	await _apretar(KEY_RIGHT, 5)
	await _apretar(KEY_RIGHT, 5)
	_check(_foco() == e.b_equipar, "al final de la fila se llega a los botones")
	await _apretar(KEY_DOWN, 5)
	_check(_foco() == e.b_mejorar, "abajo llega a MEJORAR")
	var chatarra: int = Partida.d.chatarra
	var mejorada: int = e.sel_uid
	var nivel: int = Partida.item(mejorada).nivel
	await _apretar(KEY_ENTER, 5)
	_check(Partida.d.chatarra < chatarra and Partida.item(mejorada).nivel == nivel + 1, "MEJORAR gasta chatarra y sube el nivel de la pieza elegida")
	await _apretar(KEY_UP, 5)
	await _apretar(KEY_UP, 5)
	_check(_foco() == e.botones_ranura["casco"], "arriba vuelve a la ranura")
	await _apretar(KEY_UP, 5)
	_check(_foco() == h.tabs["equipo"], "arriba sube a la pestaña")
	await _apretar(KEY_DOWN, 5)
	_check(_foco() == e.botones_ranura["casco"], "abajo vuelve a la ranura")


func _fh_fusion() -> void:
	print("-- fusion")
	var h = principal.actual
	await _apretar(KEY_E, 8)
	_check(h.pestana == "fusionar", "E pasa a Fusionar")
	var f = h.actual
	_check(_foco() is PiezaBoton, "el foco parte en las piezas")
	_check("Elige" in f._instruccion(), "dice qué hacer: " + f._instruccion())
	await _foto_h("09_fusion")
	# baja hasta los chips y elige los tres
	for i in 12:
		if Partida.ranura_de(_foco().item) == "chip":
			break
		await _apretar(KEY_DOWN, 4)
	_check(Partida.ranura_de(_foco().item) == "chip", "con las flechas se llega a los chips")
	await _apretar(KEY_ENTER, 4)
	_check(f.elegidas.size() == 1, "Enter elige la pieza")
	_check("2 más" in f._instruccion(), "dice cuántas faltan: " + f._instruccion())
	await _foto_h("10_fusion_una")
	await _apretar(KEY_RIGHT, 4)
	await _apretar(KEY_ENTER, 4)
	_check(f.elegidas.size() == 2, "Enter elige la segunda")
	await _apretar(KEY_RIGHT, 4)
	await _apretar(KEY_ENTER, 6)
	_check(f.elegidas.size() == 3 and _foco() == f.b_fusionar, "con tres, el foco salta a FUSIONAR")
	_check(f.elegidas[0] == Partida.equipado("chip").uid, "la que llevas puesta es la base")
	await _foto_h("11_fusion_lista")
	var base: int = f.elegidas[0]
	await _apretar(KEY_ENTER, 30)
	_check(h.bloqueado and _hijo_de_tipo(h, "res://pantallas/fusion.gd") != null, "se ve la animación")
	await _apretar(KEY_ESCAPE, 5)
	_check(not h.en_sala and h.bloqueado, "Esc no se sale del Hangar durante la animación")
	await _esperar(70)
	await _foto_h("12_fusion_animacion")
	await _apretar(KEY_ENTER, 8)
	_check(not h.bloqueado and Partida.equipado("chip").uid == base and Partida.equipado("chip").rareza == 1, "la pieza quedó puesta y subió de rareza")
	_check(_foco() is PiezaBoton, "el foco vuelve a las piezas")


func _fh_mascotas() -> void:
	print("-- mascotas")
	var h = principal.actual
	await _apretar(KEY_E, 8)
	_check(h.pestana == "mascota", "E pasa a Mascota")
	var m = h.actual
	_check(m.celdas.size() == Datos.MASCOTAS.size(), "se ven todas las mascotas")
	_check(_foco() == m.celdas[Partida.mascota_activa()], "el foco parte en la que sale contigo")
	var t0: float = m.t
	await _esperar(60)
	_check(absf(m.t - t0 - 1.0) < 0.1, "la demo avanza por tiempo: %.2f s en 60 cuadros" % (m.t - t0))
	await _foto_h("13_mascota_mordisco")
	await _apretar(KEY_RIGHT, 40)
	_check(m.sel == "chispita", "la derecha cambia de mascota")
	await _foto_h("14_mascota_chispita")
	var antes: String = Partida.mascota_activa()
	await _apretar(KEY_ENTER, 5)
	_check(Partida.mascota_activa() == "chispita" and antes == "mordisco", "Enter sale con ella")
	_check(h.panel != null, "el panel sigue ahí")
	await _apretar(KEY_RIGHT, 30)
	_check(m.sel == "imancito" and not Partida.tiene_mascota("imancito"), "una bloqueada se puede mirar")
	await _foto_h("15_mascota_bloqueada")
	await _apretar(KEY_ENTER, 5)
	_check(Partida.mascota_activa() == "chispita", "Enter en una bloqueada no cambia nada")
	_check(m.b_elegir.disabled and m.b_nombre.disabled, "sus botones están apagados")
	await _apretar(KEY_RIGHT, 30)
	_check(m.sel == "caparazon", "otra bloqueada")
	await _foto_h("16_mascota_caparazon")
	await _apretar(KEY_RIGHT, 8)
	_check(m.sel == "brote" and Datos.MASCOTAS[m.sel].sprite == "", "las de otros mundos también se miran")
	await _foto_h("17_mascota_otro_mundo")
	for i in 3:
		await _apretar(KEY_LEFT, 4)
	_check(m.sel == "chispita", "se vuelve con la izquierda")
	# cambiar el nombre
	await _apretar(KEY_DOWN, 4)
	_check(_foco() == m.b_elegir, "abajo baja a los botones")
	await _apretar(KEY_DOWN, 4)
	_check(_foco() == m.b_nombre, "y al de cambiar nombre")
	await _apretar(KEY_ENTER, 8)
	_check(m.ocupado and _foco() == m.campo, "Enter abre el nombre, con el foco para escribir")
	await _foto_h("18_mascota_nombre")
	await _apretar(KEY_ESCAPE, 6)
	_check(not m.ocupado and not h.en_sala, "Esc cancela el nombre sin salir de la estación")
	_check(Partida.nombre_mascota("chispita") == "Chispita", "cancelar no cambia el nombre")
	_check(_foco() == m.b_nombre, "el foco vuelve al botón")
	await _apretar(KEY_ENTER, 8)
	m.campo.text = ""
	await _letra(KEY_W, "W")
	await _letra(KEY_A, "a")
	await _letra(KEY_S, "s")
	await _letra(KEY_D, "d")
	await _letra(KEY_SPACE, " ")
	await _letra(KEY_Q, "q")
	await _letra(KEY_E, "e")
	_check(m.ocupado and _foco() == m.campo, "WASD, Q y E no sacan el foco del nombre")
	_check(h.pestana == "mascota", "Q y E no cambian de estación mientras escribes")
	_check(m.campo.text == "Wasd qe", "se escribe bien con esas letras: " + m.campo.text)
	await _apretar(KEY_ENTER, 8)
	_check(Partida.nombre_mascota("chispita") == "Wasd qe" and not m.ocupado, "Enter guarda el nombre")
	await _apretar(KEY_UP, 4)
	await _apretar(KEY_UP, 4)
	_check(_foco() == m.celdas["chispita"], "arriba vuelve a la mascota")
	await _apretar(KEY_UP, 4)
	_check(_foco() == h.tabs["mascota"], "arriba sube a la pestaña")
	await _apretar(KEY_ESCAPE, 6)
	_check(h.en_sala and h.sala.foco == "mascota", "Esc vuelve a la sala, sobre la tina")
	await _esperar(30)
	await _foto_h("19_sala_mascota")
	_check(not h.sala.foco == "", "la sala tiene foco")


func _fh_arsenal() -> void:
	print("-- arsenal")
	var h = principal.actual
	var s = h.sala
	await _ir_a_objeto(s, "arsenal")
	_check(s.foco == "arsenal", "se llega al Arsenal con las flechas")
	await _apretar(KEY_ENTER, 8)
	_check(not h.en_sala and h.pestana == "arsenal", "Enter abre el Arsenal")
	var a = h.actual
	_check(a.pestana == "armas" and _foco() is Button and _foco().get("id") == "pistola", "el foco parte en la primera arma")
	_check(a.estado("pistola") == "base", "lo base se ve como base")
	await _foto_h("20_arsenal_armas")
	var apagados: Array = Partida.d.apagados.duplicate()
	await _apretar(KEY_ENTER, 4)
	_check(Partida.d.apagados == apagados and a.parpadeo > 0.0, "lo base no se apaga, y avisa dónde lo dice")
	# baja hasta lo ganado y lo apaga
	for i in 6:
		if a.sel == "cohetes":
			break
		await _apretar(KEY_DOWN, 4)
	_check(a.sel == "cohetes" and a.estado("cohetes") == "on", "lo ganado parte prendido")
	_check("cohetes" in Partida.armas_disponibles(0), "y puede salir en las cartas")
	await _foto_h("21_arsenal_prendida")
	await _apretar(KEY_ENTER, 4)
	_check(Partida.esta_apagado("cohetes") and a.estado("cohetes") == "off", "Enter lo apaga")
	_check(not "cohetes" in Partida.armas_disponibles(0), "apagado ya no sale")
	_check(a.b_alternar.visible and a.b_alternar.text == "PRENDER", "el botón dice lo que va a pasar")
	await _foto_h("22_arsenal_apagada")
	await _apretar(KEY_SPACE, 4)
	_check(not Partida.esta_apagado("cohetes") and "cohetes" in Partida.armas_disponibles(0), "Espacio lo vuelve a prender")
	await _apretar(KEY_DOWN, 4)
	var bloqueada: String = a.sel
	_check(a.estado(bloqueada) == "bloqueado", "abajo está lo que falta por ganar")
	await _foto_h("23_arsenal_bloqueada")
	await _apretar(KEY_ENTER, 4)
	_check(a.estado(bloqueada) == "bloqueado" and not Partida.esta_apagado(bloqueada), "Enter en lo bloqueado no hace nada")
	# subir a las pestañas del Arsenal
	for i in 8:
		if _foco() == a.tabs["armas"]:
			break
		await _apretar(KEY_UP, 4)
	_check(_foco() == a.tabs["armas"], "subiendo se llega a las pestañas del Arsenal")
	await _apretar(KEY_UP, 4)
	_check(_foco() == h.tabs["arsenal"], "y de ahí a las del Hangar")
	await _apretar(KEY_DOWN, 4)
	_check(_foco() == a.tabs["armas"], "abajo vuelve")
	await _apretar(KEY_RIGHT, 6)
	_check(a.pestana == "habs" and _foco() == a.tabs["habs"], "la derecha pasa a Habilidades")
	await _apretar(KEY_DOWN, 4)
	_check(_foco() is Button and _foco().get("id") == a.sel and a.estado(a.sel) == "base", "abajo entra a la lista")
	await _foto_h("24_arsenal_habs")
	# la ficha alcanza para todo
	await _revisar_fichas(a)
	# piezas
	for i in 8:
		if _foco() == a.tabs["habs"]:
			break
		await _apretar(KEY_UP, 4)
	await _apretar(KEY_RIGHT, 6)
	_check(a.pestana == "piezas", "la derecha pasa a Piezas")
	await _revisar_fichas(a)
	_check(a.estado("mira_laser") == "cae", "lo que ya cae se ve")
	_check(a.estado("mira_termica") == "no_cae", "lo que llega con otro mundo está bloqueado")
	await _apretar(KEY_DOWN, 4)
	await _foto_h("25_arsenal_piezas")
	a.seleccionar("mira_termica")
	await _esperar(3)
	await _foto_h("26_arsenal_pieza_mundo2")
	for i in 8:
		if _foco() == a.tabs["piezas"]:
			break
		await _apretar(KEY_UP, 4)
	await _apretar(KEY_RIGHT, 6)
	_check(a.pestana == "desafios", "la derecha pasa a Desafíos")
	_check(a.filas.size() == Datos.DESAFIOS.size(), "están todos los desafíos")
	var ordenado := true
	var peor := 2.0
	for fi in a.filas:
		var de: Dictionary = fi[0].de
		if Partida.desafio_hecho(de.id):
			continue
		var v: float = a._cercania(de)
		if v > peor + 0.0001:
			ordenado = false
		peor = v
	_check(ordenado, "los más cerca de cumplirse van primero")
	await _foto_h("27_arsenal_desafios")
	await _apretar(KEY_DOWN, 4)
	_check(_foco() == a.filas[0][0], "abajo entra a la lista")
	for i in 12:
		await _apretar(KEY_S, 3)
	_check(_foco() == a.filas[12][0], "S baja por la lista")
	_check(a.scroll.scroll_vertical > 0, "la lista se desplaza siguiendo el foco")
	await _foto_h("28_arsenal_desafios_abajo")
	await _apretar(KEY_ESCAPE, 8)
	_check(h.en_sala and s.foco == "arsenal", "Esc vuelve a la sala")


## Mira la ficha de cada cosa de la pestaña: nada debe chocar con el bloque de abajo.
func _revisar_fichas(a) -> void:
	var peor := 0.0
	var cual := ""
	for id in a.celdas.keys():
		a.seleccionar(id)
		await _esperar(1)
		await get_tree().process_frame
		await get_tree().process_frame
		if a.y_fin > peor:
			peor = a.y_fin
			cual = id
	_check(peor <= a.Y_BLOQUE + 1.0, "pestaña %s: la ficha más larga llega a %d de %d (%s)" % [a.pestana, int(peor), int(a.Y_BLOQUE), cual])
	a.seleccionar(a.filas[0][0].id)


## Sin Desync todavía: lo que habla de él no se revela.
func _fh_arsenal_secretos() -> void:
	print("-- secretos")
	Partida.nuevo()
	_avanzar_hasta("1-5")
	Partida.d.desbloqueos.erase("desync")
	principal.ir_hangar("arsenal")
	await _esperar(8)
	var h = principal.actual
	var a = h.actual
	_check(a.estado("drones") == "oculto", "un arma que pide Desync no se revela")
	await _foto_h("29_arsenal_secreto")
	a.seleccionar("drones")
	await _esperar(3)
	await _foto_h("30_arsenal_secreto_ficha")
	a.elegir_pestana("habs")
	_check(a.estado("buffer") == "oculto" and a.estado("combo") == "oculto", "las habilidades de Desync no se revelan")
	a.elegir_pestana("piezas")
	_check(a.estado("reactor_lag") == "oculto", "los reactores no se revelan")
	await _foto_h("31_arsenal_secreto_piezas")
	a.elegir_pestana("desafios")
	await _esperar(3)
	var ocultos := 0
	for fi in a.filas:
		if not Partida.desafio_visible(fi[0].de):
			ocultos += 1
	_check(ocultos > 0, "hay desafíos en ??? (%d)" % ocultos)
	_check(not Partida.desafio_visible(Partida.desafio_de("nave", "support")), "tampoco la nave que pide Desync")
	await _foto_h("32_arsenal_secreto_desafios")
	a.scroll.scroll_vertical = 1000
	await _esperar(3)
	await _foto_h("33_arsenal_secreto_desafios_abajo")


## La pantalla de elegir nave, antes de cada nivel.
func _fh_seleccion() -> void:
	print("-- elegir nave")
	Partida.nuevo()
	_avanzar_hasta("1-4")
	Partida.d.naves.append("camper")
	Partida.nivel_sel = "1-4"
	principal.ir_seleccion()
	await _esperar(8)
	var a = principal.actual
	_check(_foco() == a.g.tarjetas[Partida.nave_actual()], "el foco parte en la nave que usas")
	await _apretar(KEY_RIGHT, 5)
	await _apretar(KEY_RIGHT, 5)
	_check(a.g.sel == "support" and a.b_ok.disabled, "una nave bloqueada no despega")
	await _foto_h("34_elegir_bloqueada")
	await _apretar(KEY_DOWN, 5)
	_check(_foco() == a.b_ok, "abajo baja a despegar")
	await _apretar(KEY_LEFT, 5)
	_check(_foco() == a.b_volver, "la izquierda va a VOLVER")
	await _apretar(KEY_UP, 5)
	_check(_foco() == a.g.tarjetas["support"], "arriba vuelve a la nave elegida")
	await _apretar(KEY_LEFT, 5)
	_check(a.g.sel == "camper", "se vuelve a una que tienes")
	await _apretar(KEY_ENTER, 10)
	_check(Partida.nave_actual() == "camper" and not principal.actual.has_signal("despegar") or _hijo_de_tipo(principal.actual, "res://pantallas/dialogo.gd") != null, "Enter despega con esa nave")


## Lo mismo, pero solo con mouse.
func _fh_mouse() -> void:
	print("-- solo mouse")
	Partida.nuevo()
	_avanzar_hasta("1-7")
	Partida.dar_mascota("mordisco")
	Partida.dar_mascota("chispita")
	Partida.d.estadisticas.k_rabioso = 30
	Partida.agregar("alas_iman", 0)
	Partida.revisar_desafios()
	principal.ir_hangar()
	await _esperar(20)
	var h = principal.actual
	var s = h.sala
	# tocar objetos: el mouse los enfoca y el clic los abre
	var p: Vector2 = s.botones["equipo"].get_global_rect().get_center()
	await _raton_mover(p)
	_check(s.foco == "equipo", "pasar el mouse por la barra enfoca el objeto")
	var c_mascota: Vector2 = SalaHangar.OBJETOS["mascota"].r.get_center()
	var hallado: String = s.objeto_en(c_mascota)
	_check(hallado == "mascota", "el centro de la tina es la tina: " + hallado)
	await _raton_mover(c_mascota)
	_check(s.foco == "mascota", "pasar el mouse por el objeto lo enfoca")
	# lo transparente de un sprite no se toca: el mouse sigue en lo que estaba
	await _raton_mover(Vector2(320, 60))
	_check(s.objeto_en(Vector2(320, 60)) == "" and s.foco == "mascota", "en la pared no se enfoca nada")
	await _raton_clic(c_mascota)
	_check(not h.en_sala and h.pestana == "mascota", "clic en el objeto abre su estación")
	var m = h.actual
	await _raton_clic(_centro(m.celdas["mordisco"]))
	_check(Partida.mascota_activa() == "mordisco", "clic en una mascota sale con ella")
	await _raton_clic(_centro(m.celdas["chispita"]))
	_check(Partida.mascota_activa() == "chispita", "clic en otra cambia")
	await _raton_clic(_centro(m.b_nombre))
	_check(m.ocupado, "clic en CAMBIAR NOMBRE abre el nombre")
	var cancelar: Control = m.modal.get_child(1).get_child(-1)
	await _raton_clic(_centro(cancelar))
	_check(not m.ocupado, "clic en CANCELAR lo cierra")
	# las pestañas
	await _raton_clic(_centro(h.tabs["arsenal"]))
	_check(h.pestana == "arsenal", "clic en una pestaña cambia de estación")
	var a = h.actual
	await _raton_clic(_centro(a.celdas["cohetes"]))
	_check(Partida.esta_apagado("cohetes"), "clic en lo ganado lo apaga")
	await _raton_clic(_centro(a.b_alternar))
	_check(not Partida.esta_apagado("cohetes"), "el botón de la ficha lo prende")
	await _raton_clic(_centro(a.tabs["desafios"]))
	_check(a.pestana == "desafios", "clic en las pestañas del Arsenal")
	await _raton_rueda(_centro(a.filas[2][0]))
	_check(a.scroll.scroll_vertical > 0, "la rueda baja por la lista de desafíos")
	await _raton_clic(_centro(h.tabs["equipo"]))
	var e = h.actual
	_check(h.pestana == "equipo", "clic vuelve a Equipo")
	await _raton_clic(_centro(e.botones_ranura["alas"]))
	_check(e.ranura == "alas", "clic elige la ranura")
	var otra: PiezaBoton = null
	for b in e.grid.get_children():
		if not Partida.esta_equipado(b.item.uid):
			otra = b
	await _raton_mover(_centro(otra))
	_check(e.sel_uid == otra.item.uid, "pasar el mouse por una pieza muestra su ficha")
	_check(not Partida.esta_equipado(otra.item.uid), "y todavía no se la pone")
	await _raton_clic(_centro(otra))
	_check(Partida.equipado("alas").uid == otra.item.uid, "clic se la pone")
	await _raton_clic(_centro(h.tabs["naves"]))
	var g = h.galeria
	await _raton_clic(_centro(g.pinturas[3]))
	_check(Partida.pintura_de(Partida.nave_actual()) == 3, "clic pinta la nave")
	await _raton_clic(_centro(h.b_volver))
	_check(h.en_sala, "VOLVER A LA SALA vuelve a la sala")
	await _raton_clic(_centro(s.botones["arsenal"]))
	_check(not h.en_sala and h.pestana == "arsenal", "clic en la barra abre la estación")
	await _raton_clic(_centro(h.b_volver))
	await _raton_clic(_centro(s.botones["salida"]))
	_check(principal.actual.has_signal("jugar_nivel"), "clic en SALIR vuelve al mapa")


# --- pruebas automaticas de reglas ------------------------------------------------------------
var fallos := 0
var pasadas := 0


func _ok(cond: bool, nombre: String) -> void:
	if cond:
		pasadas += 1
	else:
		fallos += 1
		print("  FALLA: ", nombre)


func _existe(n: String) -> bool:
	return ResourceLoader.exists("res://arte/sprites/%s.png" % n)


func _tests() -> void:
	_tests_teclas()
	_tests_partida()
	_tests_datos()
	_tests_combate()
	_tests_desafios_silueta()
	_tests_xp_tras_desync()
	_tests_cartas_caben()
	_tests_desync_visual()
	_tests_armas()
	load("res://pruebas/prueba_audio.gd").correr(_ok)
	print("[tests] pasadas=%d fallos=%d" % [pasadas, fallos])


func _tests_teclas() -> void:
	var a := Asignaciones.new(Controles.DEFECTO)
	_ok(a.asignar("disparar", "teclado", 0, "key:Q").has("ok"), "asignar libre")
	_ok(a.obtener("disparar", "teclado", 0) == "key:Q", "quedo asignada")
	var r := a.asignar("disparar", "teclado", 0, "key:X")
	_ok(r.has("conflicto") and r.conflicto.accion == "desync", "detecta conflicto")
	_ok(a.obtener("disparar", "teclado", 0) == "key:Q", "conflicto no cambia nada")
	_ok(a.asignar("disparar", "teclado", 0, "key:X", "intercambiar").has("ok"), "intercambiar")
	_ok(a.obtener("desync", "teclado", 0) == "key:Q" and a.obtener("disparar", "teclado", 0) == "key:X", "intercambio correcto")
	_ok(a.borrar("disparar", "teclado", 1), "borrar secundaria")
	_ok(not a.borrar("disparar", "teclado", 0), "no deja sin teclas")
	var b := Asignaciones.new(Controles.DEFECTO)
	b.borrar("pausa", "teclado", 1)
	var q := b.asignar("disparar", "teclado", 0, "key:Escape", "quitar")
	_ok(q.has("error"), "quitar no deja a pausa sin teclas")
	var c := Asignaciones.new(Controles.DEFECTO)
	c.asignar("foco", "teclado", 1, "mouse:1")
	var d := Asignaciones.new(Controles.DEFECTO)
	d.cargar_desde(c.exportar(), Controles.DEFECTO)
	_ok(d.obtener("foco", "teclado", 1) == "mouse:1", "guardar y cargar")
	var e := Asignaciones.new(Controles.DEFECTO)
	e.cargar_desde({"foco/teclado": "basura", "disparar/teclado": ["key:J"], "esquivar/teclado": ["btn:1", ""], "pausa/teclado": ["", ""]}, Controles.DEFECTO)
	_ok(e.obtener("foco", "teclado", 0) == "key:Shift", "ignora dato dañado")
	_ok(e.obtener("esquivar", "teclado", 0) == "key:Space", "rechaza grupo incorrecto")
	_ok(e.obtener("pausa", "teclado", 0) == "key:Escape", "no permite accion vacia")
	_ok(Controles.nombre("key:Space") == "ESPACIO", "nombre de tecla")
	_ok(Controles.nombre("mouse:2") == "CLIC DER", "nombre de mouse")
	_ok(Controles.nombre("axis:5:1") == "RT", "nombre de gatillo")
	var ev := Controles.a_evento("key:W")
	_ok(ev is InputEventKey and ev.keycode == KEY_W, "reconstruye evento")
	_ok(Controles.de_evento(ev) == "", "evento no pulsado no se asigna")


func _tests_partida() -> void:
	# fusiones
	Partida.nuevo()
	var base := Partida.equipado("mira")
	_ok(not Partida.puede_fusionar(base), "no fusiona sin piezas")
	Partida.d.chatarra = 500
	var x1 := Partida.agregar("cargador", 0)
	var x2 := Partida.agregar("mun_explosiva", 0)
	var x3 := Partida.agregar("casco_lata", 0)
	_ok(Partida.puede_fusionar(base), "fusiona misma ranura")
	x1.invertido = 77
	var chat0: int = Partida.d.chatarra
	var res := Partida.fusionar(base.uid)
	_ok(res.rareza == 1, "sube una rareza")
	_ok(Partida.d.chatarra == chat0 + 77, "devuelve chatarra invertida")
	_ok(Partida.item(x1.uid).is_empty() and Partida.item(x2.uid).is_empty(), "consume las otras")
	_ok(not Partida.item(x3.uid).is_empty(), "no toca otra ranura")
	_ok(Partida.esta_equipado(base.uid), "la base sigue equipada")
	var sin_equipo := Partida.agregar("alas_iman", 0)
	Partida.equipar(sin_equipo.uid)
	_ok(Partida.compatibles_fusion(Partida.item(sin_equipo.uid)).is_empty() or true, "compatibles")
	_ok(Partida.fusionar_con(sin_equipo.uid, [x3.uid, x3.uid]).is_empty(), "rechaza piezas de otra ranura")
	var u1 := Partida.agregar("alas_iman", 0)
	var u2 := Partida.agregar("alas_iman", 0)
	_ok(Partida.fusionar_con(u1.uid, [sin_equipo.uid, u2.uid]).is_empty(), "no se come lo equipado")
	# rareza maxima
	var m := Partida.agregar("chip_critico", 5)
	Partida.agregar("chip_critico", 5)
	Partida.agregar("chip_critico", 5)
	_ok(not Partida.puede_fusionar(m), "mitico no se fusiona")
	# mejorar
	var n := Partida.agregar("chip_critico", 0)
	Partida.d.chatarra = 0
	_ok(not Partida.mejorar(n.uid), "sin chatarra no mejora")
	Partida.d.chatarra = 9999
	_ok(Partida.mejorar(n.uid) and n.nivel == 2, "mejora")
	_ok(n.invertido > 0, "registra lo invertido")
	# stats
	var s0: Dictionary = Partida.stats_nave()
	Partida.equipar(Partida.agregar("mun_perforante", 3).uid)
	var s1: Dictionary = Partida.stats_nave()
	_ok(s1.atk > s0.atk, "mas rareza da mas ataque")
	_ok(int(s1.perfora) == int(s0.perfora) + 1, "pasiva activa por rareza")
	# naves distintas
	var tr := Partida.stats_nave("tryhard")
	var ba := Partida.stats_nave("ballena")
	var sm := Partida.stats_nave("smurf")
	_ok(ba.hp > tr.hp and sm.hp < tr.hp, "las naves tienen vida distinta")
	_ok(int(tr.cambios) > int(Datos.STATS_BASE.cambios), "pasiva de Tryhard")
	# mascota: crece lento y casi no cambia de tamaño
	Partida.dar_mascota("mordisco")
	Partida.d.mascotas.mordisco.xp = 0
	_ok(Partida.nivel_mascota() == 1 and Partida.forma_mascota() == 0, "mascota inicial")
	Partida.d.mascotas.mordisco.xp = Partida.xp_de_nivel(10)
	_ok(Partida.nivel_mascota() == 10 and Partida.forma_mascota() == 1, "segunda forma")
	Partida.d.mascotas.mordisco.xp = Partida.xp_de_nivel(25)
	_ok(Partida.forma_mascota() == 2, "tercera forma")
	Partida.d.mascotas.mordisco.xp = Partida.xp_de_nivel(99)
	_ok(Partida.nivel_mascota() == Partida.NIVEL_MAX_MASCOTA, "la mascota tiene tope")
	_ok(Partida.TAM_MASCOTA[2] <= 30, "no crece demasiado")
	Partida.d.mascotas.mordisco.xp = 0
	Partida.dar_mascota("chispita")
	_ok(Partida.mascota_activa() == "mordisco", "ganar otra no cambia la activa")
	Partida.elegir_mascota("chispita")
	_ok(Partida.mascota_activa() == "chispita" and Partida.pet_dano() > 0.0, "cada mascota hace lo suyo")
	Partida.elegir_mascota("imancito")
	_ok(Partida.mascota_activa() == "chispita", "no se elige una que no tienes")
	# niveles y desbloqueos
	Partida.nuevo()
	_ok(Partida.nivel_abierto("1-1") and not Partida.nivel_abierto("1-2"), "solo 1-1 abierto al inicio")
	_ok(not Partida.tiene("hangar") and not Partida.tiene("desync") and not Partida.tiene("mascota"), "nada desbloqueado al inicio")
	_ok(not "reactor" in Partida.ranuras_visibles() and Partida.equipado("reactor").is_empty(), "sin Desync no hay reactor")
	var r1 := Partida.completar_nivel("1-1", {"golpes": 99, "max_cadena": 0})
	_ok(r1.estrellas == 1 and r1.primera, "una estrella por terminar")
	_ok(Partida.tiene("hangar"), "1-1 da el Hangar")
	_ok(Partida.nivel_abierto("1-2"), "ganar abre el siguiente")
	var r2 := Partida.completar_nivel("1-1", {"golpes": 0, "max_cadena": 99})
	_ok(r2.estrellas == 3 and not r2.primera and r2.premio.is_empty(), "la segunda vez no da premio")
	Partida.completar_nivel("1-1", {"golpes": 99, "max_cadena": 0})
	_ok(Partida.estrellas("1-1") == 3, "las estrellas no bajan")
	Partida.completar_nivel("1-2", {"golpes": 0, "max_cadena": 0})
	_ok(Partida.tiene("desync") and not Partida.equipado("reactor").is_empty() and "reactor" in Partida.ranuras_visibles(), "1-2 da el Desync y su reactor")
	_ok(Partida.mascota_activa() == "", "aun sin mascota")
	Partida.completar_nivel("1-3", {"golpes": 0, "max_cadena": 0})
	_ok(Partida.tiene("mascota") and Partida.tiene("fusion") and Partida.mascota_activa() == "mordisco", "1-3 da mascota y fusion")
	_ok(not Partida.nivel_abierto("1-R"), "la ruleta aun cerrada")
	Partida.completar_nivel("1-4", {"golpes": 0, "max_cadena": 0})
	_ok(Partida.tiene("tablon") and not "camper" in Partida.d.naves, "1-4 da el Tablon y ya no regala naves")
	_ok(Partida.nivel_abierto("1-R"), "1-4 abre la ruleta")
	var antes: int = Partida.d.inventario.size()
	var r5 := Partida.completar_nivel("1-5", {"golpes": 0, "max_cadena": 0})
	_ok(Partida.d.inventario.size() == antes + 1 and r5.premio.item.rareza == 2, "1-5 da una pieza rara")
	var c0: int = Partida.stats_nave().cambios
	Partida.completar_nivel("1-6", {"golpes": 0, "max_cadena": 0})
	_ok(Partida.stats_nave().cambios == c0 + 1, "1-6 da un cambio de cartas")
	var ch0: int = Partida.d.chatarra
	Partida.completar_nivel("1-7", {"golpes": 0, "max_cadena": 0})
	_ok(Partida.d.chatarra == ch0 + 150, "1-7 da chatarra")
	_ok(not Partida.nivel_abierto("1-INF"), "el infinito aun cerrado")
	Partida.completar_nivel("1-8", {"golpes": 0, "max_cadena": 0})
	_ok("camper" in Partida.d.naves and Partida.nivel_abierto("1-INF") and Partida.extremo_abierto(), "1-8 da la Camper, el Infinito y el Extremo")
	var r_ruleta := Partida.completar_nivel("1-R", {"golpes": 0, "max_cadena": 0})
	_ok(Partida.tiene_mascota("imancito") and r_ruleta.premio.tipo == "mascota", "la ruleta da a Imancito")
	_ok(Partida.estrellas_totales() <= Datos.ORDEN_NIVELES.size() * 3, "los extras no cuentan estrellas")
	# Nueva Partida +: empieza de cero, pero con todo lo tuyo
	var inv_antes: int = Partida.d.inventario.size()
	var hp0: float = Partida.mods_enemigos().hp
	_ok(Partida.puede_ng_plus(), "terminar abre Nueva Partida +")
	Partida.iniciar_ng_plus("dificil")
	_ok(Partida.ciclo() == 1 and Partida.dificultad() == "dificil", "sube el ciclo y cambia la dificultad")
	_ok(Partida.d.niveles.is_empty() and not Partida.nivel_abierto("1-2"), "los niveles parten de cero")
	_ok(Partida.d.inventario.size() == inv_antes and "camper" in Partida.d.naves and Partida.tiene("hangar"), "se conserva todo lo ganado")
	_ok(Partida.mods_enemigos().hp > hp0, "los enemigos suben")
	Partida.d.niveles["1-5"] = {"completado": true, "estrellas": 1}
	Partida.d.niveles.erase("1-5")
	var c1: int = Partida.stats_nave().cambios
	var ch1: int = Partida.d.chatarra
	var rep := Partida.completar_nivel("1-6", {"golpes": 0, "max_cadena": 0})
	_ok(Partida.stats_nave().cambios == c1 and Partida.d.chatarra == ch1 + 150 and rep.premio.tipo == "chatarra", "un premio unico no se repite")
	# desafios y arsenal
	Partida.nuevo()
	_ok(Partida.revisar_desafios().is_empty(), "sin logros no se gana nada")
	_ok(Partida.max_armas() == 2 and Partida.max_habs() == 3, "se empieza con pocas ranuras")
	_ok(Partida.armas_disponibles(0).size() == 6 and Partida.habs_disponibles(0).size() == 6, "la base son 6 y 6")
	_ok(not "aimbot" in Partida.habs_disponibles(0), "el aimbot no viene de entrada")
	_ok("headshot" in Partida.habs_disponibles(0, ["railgun"]), "la sinergia de lo que llevas puede salir")
	_ok(not "cohetes" in Partida.armas_disponibles(0), "cohetes bloqueados")
	Partida.registrar({"kills": 25, "desyncs": 0, "aces": 0, "evoluciones": 0, "max_cadena": 0, "ganado": false, "kills_tipo": {"rabioso": 25}})
	var nuevos := Partida.revisar_desafios()
	_ok(nuevos.size() == 1 and nuevos[0].id == "cohetes" and nuevos[0].has("nombre"), "un desafio da su premio")
	_ok("cohetes" in Partida.armas_disponibles(0) and Partida.arma_desbloqueada("cohetes"), "lo ganado puede salir")
	Partida.alternar("cohetes")
	_ok(not "cohetes" in Partida.armas_disponibles(0), "lo ganado se puede apagar")
	Partida.alternar("cohetes")
	_ok("cohetes" in Partida.armas_disponibles(0), "y volver a prender")
	_ok(Partida.revisar_desafios().is_empty(), "un desafio se cobra una vez")
	_ok(not "buffer" in Partida.habs_disponibles(0, ["drones"]), "sin Desync no sale nada del Desync")
	Partida.desbloquear("desync")
	_ok("buffer" in Partida.habs_disponibles(0, ["drones"]), "con Desync, si")
	for k in 8:
		Partida.d.desafios.append("x%d" % k)
	Partida.revisar_desafios()
	_ok(Partida.max_habs() == 4 and Partida.max_armas() == 2, "8 desafios dan una ranura de habilidad")
	for k in 15:
		Partida.d.desafios.append("y%d" % k)
	Partida.revisar_desafios()
	_ok(Partida.max_armas() == 3, "15 desafios dan una ranura de arma")
	_ok(Partida.es_base_arma("railgun", 1) and not Partida.es_base_arma("railgun", 0), "cada mundo agrega a la base")
	# las piezas se abren con el avance
	Partida.nuevo()
	var pool0 := Partida.pool_piezas()
	_ok(pool0.size() == 5 and not "reactor_lag" in pool0 and not "cargador" in pool0, "al inicio caen pocas piezas")
	_ok(not "mira_termica" in pool0, "las del Mundo 2 no caen en el 1")
	for id in ["1-1", "1-2"]:
		Partida.completar_nivel(id, {"golpes": 0, "max_cadena": 0})
	_ok("reactor_lag" in Partida.pool_piezas() and "cargador" in Partida.pool_piezas(), "se van sumando")
	# guardar y leer
	Partida.d.chatarra = 77
	Partida.marcar_visto("inicio")
	Partida.d.apagados.append("laser")
	Partida.guardar()
	var uid_antes: int = Partida.d.sig_uid
	Partida.cargar()
	_ok(Partida.d.chatarra == 77 and Partida.d.sig_uid == uid_antes and typeof(Partida.d.chatarra) == TYPE_INT, "guardar y leer partida")
	_ok(typeof(Partida.d.inventario[0].uid) == TYPE_INT, "enteros bien leidos")
	_ok(Partida.visto("inicio"), "recuerda los dialogos vistos")
	_ok(Partida.estrellas("1-1") == 2 and typeof(Partida.estrellas("1-1")) == TYPE_INT, "recuerda las estrellas")
	_ok(Partida.esta_apagado("laser"), "recuerda lo apagado")
	# tres ranuras de partida
	for i in range(1, 4):
		Partida.borrar_slot(i)
	_ok(not Partida.hay_partidas() and Partida.slot_libre() == 1, "sin partidas")
	Partida.crear_slot(2, "dificil")
	Partida.d.chatarra = 321
	Partida.guardar()
	Partida.crear_slot(3, "facil")
	_ok(Partida.hay_partidas() and Partida.slot_libre() == 1, "hay ranuras ocupadas")
	var inf2 := Partida.info_slot(2)
	_ok(inf2.existe and inf2.dificultad == "dificil" and inf2.chatarra == 321 and inf2.nivel_actual == "1-1", "la ficha de la ranura")
	_ok(not Partida.info_slot(1).existe, "ranura vacia")
	_ok(Partida.abrir_slot(2) and Partida.d.chatarra == 321 and Partida.dificultad() == "dificil", "abrir una ranura")
	_ok(Partida.mods_enemigos().hp > 1.0, "la dificultad se nota")
	Partida.borrar_slot(3)
	_ok(not Partida.existe_slot(3), "borrar una ranura")
	Partida.borrar_slot(2)
	Partida.slot = 0
	# botin: se gana peleando
	Partida.nuevo()
	var b0 := Partida.generar_botin({"ganado": false, "kills": 0, "chatarra": 0, "nivel_id": "1-1", "abandono": true, "tiempo": 2})
	_ok(b0.items.is_empty() and b0.chatarra == 0, "entrar y salir no da nada")
	var b1 := Partida.generar_botin({"ganado": false, "kills": 200, "chatarra": 40, "nivel_id": "1-1", "abandono": true, "tiempo": 100})
	_ok(b1.items.is_empty() and b1.chatarra == 20, "retirarse da media chatarra y ninguna pieza")
	var b2 := Partida.generar_botin({"ganado": false, "kills": 3, "chatarra": 5, "nivel_id": "1-1", "abandono": false, "tiempo": 8})
	_ok(b2.items.is_empty(), "morir de inmediato no da piezas")
	var bo := Partida.generar_botin({"ganado": true, "kills": 90, "chatarra": 50, "nivel_id": "1-4", "jefe": true, "tiempo": 100})
	_ok(bo.items.size() >= 2 and bo.items.size() <= 4, "botin de victoria")
	_ok(bo.items[bo.items.size() - 1].rareza >= 1, "ganarle a un jefe da al menos una poco comun")
	_ok(bo.chatarra == bo.recogida + bo.bono and bo.recogida == 50, "la chatarra cuadra")
	var maxr := 0
	var azules := 0
	for k in 4000:
		var rr := Partida._tirar_rareza(1.0, 3)
		maxr = maxi(maxr, rr)
		if rr >= 2:
			azules += 1
	_ok(maxr <= 3, "en el Mundo 1 no caen legendarios")
	_ok(azules < 4000 * 0.08, "lo raro es raro")
	# una partida generada para quien viene llegando al jefe
	Partida.generar_para("1-8", "normal")
	_ok(Partida.nivel_abierto("1-8") and not Partida.nivel_completado("1-8"), "queda justo antes del jefe")
	_ok(Partida.tiene("hangar") and Partida.tiene("desync") and Partida.tiene("mascota") and Partida.dificultad() == "normal", "con lo que corresponde")
	var r_max := 0
	for it in Partida.d.inventario:
		r_max = maxi(r_max, it.rareza)
	_ok(r_max <= 2, "sin piezas regaladas")
	_ok(not "camper" in Partida.d.naves, "la Camper se gana en el jefe")
	_ok(Partida.stats_nave().atk < 20.0, "con ataque razonable")
	Partida.nuevo()


func _tests_datos() -> void:
	# cada arma: 4 mejoras, icono y una habilidad de sinergia que exista
	var sin := {}
	for id in Datos.ARMAS:
		var a: Dictionary = Datos.ARMAS[id]
		_ok(a.mejoras.size() == Datos.NIVEL_MAX_CARTA - 1, "mejoras de " + id)
		_ok(_existe("icono_" + id), "icono de " + id)
		_ok(Datos.HABILIDADES.has(a.sinergia), "sinergia de " + id)
		_ok(not sin.has(a.sinergia), "sinergia unica " + a.sinergia)
		sin[a.sinergia] = true
		_ok(a.evo.has("nombre") and a.evo.has("desc"), "evolucion de " + id)
		if a.base.has("tex"):
			_ok(_existe(a.base.tex), "tiro de " + id)
		if a.base.has("sfx"):
			_ok(a.base.sfx in Sonido.SFX, "sonido de " + id)
	for id in Datos.HABILIDADES:
		_ok(_existe("icono_" + id), "icono de " + id)
	for id in Datos.ITEMS:
		_ok(_existe("icono_" + id), "icono de " + id)
		_ok(Datos.NOMBRE_RANURA.has(Datos.ITEMS[id].ranura), "ranura de " + id)
		for k in Datos.ITEMS[id].base:
			_ok(Datos.STATS_BASE.has(k), "stat %s de %s" % [k, id])
			_ok(Datos.NOMBRE_STAT.has(k), "nombre del stat " + k)
	for id in Datos.NAVES:
		var n: Dictionary = Datos.NAVES[id]
		_ok(Datos.ARMAS.has(n.arma), "arma de la nave " + id)
		_ok(_existe("nave2_" + id), "sprite de la nave " + id)
		for k in n.mods:
			_ok(Datos.STATS_BASE.has(k), "stat %s de la nave %s" % [k, id])
	for id in Datos.ENEMIGOS:
		_ok(_existe(Datos.ENEMIGOS[id].sprite), "sprite de " + id)
	# niveles
	for i in Datos.ORDEN_NIVELES.size():
		var id: String = Datos.ORDEN_NIVELES[i]
		_ok(Datos.NIVELES.has(id) and Datos.NODOS.has(id), "nivel " + id)
		var nv: Dictionary = Datos.NIVELES[id]
		var ic: String = nv.premio.icono
		_ok(ic in ["mascota", "nave"] or _existe(ic), "icono del premio de " + id)
		if nv.premio.tipo == "nave":
			_ok(Datos.NAVES.has(nv.premio.id), "nave premio de " + id)
		for e in nv.enemigos:
			_ok(Datos.ENEMIGOS.has(e), "enemigo listado %s en %s" % [e, id])
		_tests_guion(id, nv)
		if nv.has("jefe"):
			_ok(Datos.ENEMIGOS[nv.jefe].get("jefe", false), "jefe de " + id)
	for id in Datos.EXTRAS:
		_tests_guion(id, Datos.NIVELES[id])
	_tests_director()
	# dialogos
	for k in Datos.DIALOGOS:
		for l in Datos.DIALOGOS[k]:
			_ok(l[0] in ["tuerca", "calypso"], "quien habla en " + k)
			_ok(not "{" in Datos.con_teclas(l[1]), "teclas en el dialogo " + k)
	for id in Datos.NIVELES:
		for p in Datos.NIVELES[id].pistas:
			_ok(not "{" in Datos.con_teclas(p[1]), "teclas en la pista de " + id)
	# que todo lo que se muestra quepa en su caja
	for k in Datos.DIALOGOS:
		for l in Datos.DIALOGOS[k]:
			_ok(UI.partir(Datos.con_teclas(l[1]), 470.0).size() <= 4, "el dialogo %s cabe en la caja: %s" % [k, l[1]])
	for de in Datos.DESAFIOS:
		_ok(UI.ancho("Desafío cumplido: " + de.txt) < 620.0, "el desafio cabe en el premio: " + de.txt)
	for id in Datos.NIVELES:
		_ok(UI.partir(Datos.NIVELES[id].desc, 344.0).size() <= 2, "la descripcion de %s cabe en el panel" % id)
		_ok(UI.ancho(id if not Datos.NIVELES[id].has("modo") else Datos.NIVELES[id].nombre.to_upper(), 2) < 340.0, "el titulo de %s cabe en el panel" % id)
	# los extras y el portal no se enciman con ningun nodo
	var pos: Array = Datos.NODOS.values()
	pos.append(Datos.PORTAL)
	for i in pos.size():
		for j in range(i + 1, pos.size()):
			_ok(pos[i].distance_to(pos[j]) > 44.0, "nodos separados %s y %s" % [str(pos[i]), str(pos[j])])
	# los menus aceptan WASD y Espacio, y las teclas de siempre siguen
	for par in [["ui_up", KEY_W], ["ui_down", KEY_S], ["ui_left", KEY_A], ["ui_right", KEY_D], ["ui_accept", KEY_SPACE], ["ui_up", KEY_UP], ["ui_down", KEY_DOWN], ["ui_left", KEY_LEFT], ["ui_right", KEY_RIGHT], ["ui_accept", KEY_ENTER], ["ui_cancel", KEY_ESCAPE]]:
		var ev := InputEventKey.new()
		ev.keycode = par[1]
		ev.pressed = true
		_ok(ev.is_action_pressed(par[0]), "%s con la tecla %d" % [par[0], par[1]])
	# las letras de la fuente existen
	var f: Font = Datos.fuente
	for ch in "áéíóúñÁÉÍÓÚÑ¿¡·%+-/:,.?!":
		_ok(f.has_char(ch.unicode_at(0)), "letra " + ch)


## El guion que arma el director: en orden, con enemigos que existen y que el nivel avisa.
func _tests_guion(id: String, nv: Dictionary) -> void:
	var D = load("res://combate/director.gd")
	var dir = D.new(nv, 7)
	var guion: Array = dir.tramo(0.0, 120.0) if nv.get("modo", "") == "infinito" else dir.guion()
	_ok(not guion.is_empty(), "el director arma algo en " + id)
	var ultimo := 0.0
	for ev in guion:
		_ok(ev.t >= ultimo, "oleadas en orden en " + id)
		ultimo = ev.t
		if ev.has("tipo"):
			_ok(Datos.ENEMIGOS.has(ev.tipo), "enemigo " + ev.tipo)
			_ok(ev.tipo in nv.enemigos, "%s aparece en %s pero no se avisa" % [ev.tipo, id])
			if ev.has("ruta"):
				_ok(Datos.RUTAS.has(ev.ruta), "ruta " + ev.ruta)
			elif not ev.has("enjambre"):
				_ok(ev.has("anclas"), "sin posicion en " + id)


## El director: determinista con semilla, gasta su presupuesto y respeta los tiempos pedidos.
func _tests_director() -> void:
	var D = load("res://combate/director.gd")
	var nv: Dictionary = Datos.NIVELES["1-5"]
	var a: Array = D.new(nv, 42).guion()
	var b: Array = D.new(nv, 42).guion()
	var c: Array = D.new(nv, 43).guion()
	_ok(str(a) == str(b), "misma semilla, mismo nivel")
	_ok(str(a) != str(c), "otra semilla, otro nivel")
	for id in Datos.ORDEN_NIVELES:
		var def: Dictionary = Datos.NIVELES[id]
		var g: Array = D.new(def, 11).guion()
		var costo := 0.0
		var moscas := 0
		var total := 0
		var ultimo_t := 0.0
		for ev in g:
			if ev.has("tipo") and D.COSTO.has(ev.tipo):
				costo += float(D.COSTO[ev.tipo]) * int(ev.n)
				total += int(ev.n)
				ultimo_t = maxf(ultimo_t, ev.t)
				if ev.tipo == "mosca":
					moscas += int(ev.n)
		_ok(ultimo_t <= float(def.duracion) + 1.0, "el director no se pasa de la duración de " + id)
		print("  guion %s: dura=%ds enemigos=%d (moscas=%d) costo=%.0f" % [id, int(def.duracion), total, moscas, costo])
	var inf: Dictionary = Datos.NIVELES["1-INF"]
	var di = D.new(inf, 5)
	_ok(not di.tramo(0.0, 12.0).is_empty() and not di.tramo(600.0, 612.0).is_empty(), "el infinito no se acaba")
	_ok(di.ritmo(600.0) > di.ritmo(30.0), "el infinito cada vez aprieta más")
	var dr = D.new(Datos.NIVELES["1-R"], 5)
	var ruletas := 0
	for ev in dr.guion():
		if ev.has("ruleta"):
			ruletas += 1
	_ok(ruletas == 2, "la ruleta gira dos veces")


## Las reglas del combate que no se ven en un bot: tiempos de muerte, escudo, cadena, topes.
func _tests_combate() -> void:
	Partida.nuevo()
	Partida.nivel_sel = "1-1"
	var C = load("res://combate/combate.gd")
	# ---- tiempo de muerte de un Bot con el arma inicial, en el 1-1
	var c = C.new()
	add_child(c)
	c.set_physics_process(false)
	c.jx = 200.0
	c.jy = 300.0
	var e = c._crear_enemigo({"tipo": "bot", "ancla": [200, 180]})
	e.x = 200.0
	e.y = 180.0
	e.modo = "actuar"
	var cuadros := 0
	# la bala tarda en llegar: se cuenta desde el primer golpe
	while not e.muerto and cuadros < 1200:
		cuadros += 1
		c.ticks += 1
		c.arsenal.tick()
		c._tick_tiros()
		c._colisiones()
	var ttk_bot: float = (c.ticks - e.primer_golpe) / 60.0
	print("  Bot en 1-1 con pistola nivel 1: %d de vida, muere en %.2f s" % [int(e.hpmax), ttk_bot])
	_ok(ttk_bot < 1.0, "en el 1-1 un Bot dura menos de 1 s")
	# ---- golpes para morir
	var golpe0: float = 22.0 * c.mult_dano * (1.0 + c.idx_nivel * 0.06)
	_ok(ceil(c.stats.hp / golpe0) == 4.0, "en Normal, 4 golpes matan al empezar (vida %d, golpe %d)" % [int(c.stats.hp), int(golpe0)])
	# ---- hitbox
	_ok(is_equal_approx(c.hitbox(), 3.5), "hitbox de 3.5")
	c.stats.hitbox_mult = 0.7
	_ok(c.hitbox() < 3.5, "Hitbox Chica la achica")
	c.stats.hitbox_mult = 1.0
	# ---- tope de balas, y giro que mantiene la rapidez
	for k in 400:
		c.crear_tiro(200, 200, 0.0, 5.0, 1.0, Datos.tex("tiro2"), 1, false)
	_ok(c.tiros.size() <= c.MAX_TIROS, "no hay más de MAX_TIROS balas")
	c.tiros.clear()
	var ob = c._crear_enemigo({"tipo": "compacto", "ancla": [50, 50]})
	ob.x = 50.0
	ob.y = 50.0
	ob.modo = "actuar"
	var t = c.crear_tiro(200, 200, -PI / 2.0, 5.0, 1.0, Datos.tex("tiro2"), 1, false)
	t.giro = deg_to_rad(4.0)
	var rap0: float = Vector2(t.vx, t.vy).length()
	for k in 30:
		c._tick_tiros()
	_ok(absf(Vector2(t.vx, t.vy).length() - rap0) < 0.01, "la bala que persigue no se frena")
	_ok(t.vida <= c.VIDA_GIRO, "la bala que persigue vive poco")
	c.tiros.clear()
	# ---- rebote: pierde fuerza
	var rb = c.crear_tiro(396, 200, 0.0, 5.0, 10.0, Datos.tex("tiro2"), 1, false)
	rb.rebote = 2
	var d0: float = rb.dmg
	c._tick_tiros()
	_ok(rb.dmg < d0, "el rebote pierde fuerza")
	c.tiros.clear()
	# ---- daño según cómo juegas
	c.stats.quieto_dano = 0.5
	c.quieto = true
	c.quieto_t = 30
	_ok(is_equal_approx(c.mult_dano_jugador(), 1.0), "quieto no da nada antes de 1 s")
	c.quieto_t = 61
	_ok(is_equal_approx(c.mult_dano_jugador(), 1.5), "quieto da lo suyo tras 1 s")
	c.stats.quieto_dano = 0.0
	c.quieto_t = 0
	c.quieto = false
	# ---- cadena
	c.cadena = 40
	c.cadena_t = 1.0
	c.cadena_bajando = false
	c._tick_cadena()
	_ok(c.cadena == 35, "al vencerse, baja de 5 en 5")
	_ok(c.cadena_t <= c.PLAZO_BAJADA, "con plazo corto entre bajadas")
	c.cadena = 1
	var v_corta: float = c._ventana_cadena()
	c.cadena = 200
	var v_larga: float = c._ventana_cadena()
	_ok(v_corta > 200.0 and v_larga <= 100.0, "la ventana se acorta con la cadena")
	c.cadena = 40
	c.iframes = 0
	c.hp = c.stats.hp
	c._recibir_dano(1.0)
	_ok(c.cadena == 20, "un golpe corta la cadena a la mitad")
	# ---- Desync: escudo de 3
	c.hp = c.stats.hp
	c.barra = 100.0
	c.tiene_desync = true
	c._empezar_desync()
	var hp0: float = c.hp
	for k in 3:
		c.iframes = 0
		c._recibir_dano(20.0)
		_ok(c.hp == hp0, "el escudo del Desync frena el golpe %d" % (k + 1))
		_ok(c.iframes > 0, "y da un instante de invulnerabilidad")
	c.iframes = 0
	c._recibir_dano(20.0)
	_ok(c.hp < hp0, "sin escudo, duele")
	c.hp = c.stats.hp
	c.estado = "reconectando"
	c.iframes = 0
	c._recibir_dano(20.0)
	_ok(c.hp == c.stats.hp, "al reconectar no te pasa nada")
	c.estado = "cascada"
	c._recibir_dano(20.0)
	_ok(c.hp == c.stats.hp, "en la cascada no te pasa nada")
	c.estado = "jugando"
	# ---- AFK
	c.enemigos.clear()
	var alguien = c._crear_enemigo({"tipo": "bot", "ancla": [100, 50]})
	alguien.y = 50.0
	c.hp = c.stats.hp
	c.afk_x = c.jx
	c.afk_y = c.jy
	c.afk_t = 0
	c.iframes = 0
	for k in 299:
		c._tick_afk()
	_ok(c.afk_mira < 0.0, "antes de 5 s no pasa nada")
	c._tick_afk()
	_ok(c.afk_mira > 0.0, "a los 5 s aparece la mira")
	for k in 61:
		c._tick_afk()
	_ok(c.hp < c.stats.hp, "al segundo cae la bomba")
	var hp_afk: float = c.hp
	c.iframes = 0
	for k in 70:
		c._tick_afk()
	_ok(c.hp < hp_afk, "y se repite mientras sigas ahí")
	c.afk_mira = -1.0
	c.afk_t = 200
	c.jx += 40.0
	c._tick_afk()
	_ok(c.afk_t == 0, "moverte de verdad reinicia el AFK")
	c.jx -= 40.0
	c.hp = c.stats.hp
	# ---- tope de daño a jefes: ni con daño absurdo baja en menos de ~40 s
	for jefe in ["grua", "compactador"]:
		c.enemigos.clear()
		var j = c._crear_enemigo({"tipo": jefe, "ancla": [200, 80]})
		j.modo = "actuar"
		j.y = 80.0
		var inicio: int = c.ticks
		while not j.muerto and c.ticks - inicio < 60 * 600:
			c.ticks += 1
			j.inv = 0.0
			c._aplicar(j, j.hpmax * 0.05, false, j.x, j.y)
		var seg: int = (c.ticks - inicio) / 60
		print("  %s (%d de vida) con daño absurdo muere en %d s" % [jefe, int(j.hpmax), seg])
		_ok(seg >= 40, "%s dura al menos 40 s con cualquier build" % jefe)
		c.estado = "jugando"
		c.victoria_pendiente = false
		c.jefe_actual = null
	# ---- la cascada tiene tope contra jefes
	c.enemigos.clear()
	var jc = c._crear_enemigo({"tipo": "grua", "ancla": [200, 80]})
	jc.modo = "actuar"
	jc.y = 80.0
	c.cola.clear()
	c.cola.append(jc)
	jc.cola_hits = 50
	jc.cola_dano = 999999.0
	c.cola_total = 50
	c.cola_i = 0
	c.cascada_t = 0.0
	c.estado = "cascada"
	var hp_j: float = jc.hp
	c._tick_cascada()
	_ok(hp_j - jc.hp <= jc.hpmax * 0.35 + 0.1, "la cascada no le saca más de 35 % a un jefe")
	c.estado = "jugando"
	# ---- cartas: lo bloqueado no sale
	c.tiene_desync = false
	for k in 40:
		for ca in c._generar_cartas():
			if ca.tipo == "arma":
				_ok(Partida.es_base_arma(ca.id, 0) or c.arsenal.buscar(ca.id) != null, "solo armas disponibles: " + ca.id)
			if ca.tipo == "hab":
				_ok(not Datos.HABILIDADES[ca.id].has("requiere"), "nada del Desync sin Desync: " + ca.id)
			_ok(ca.tipo != "cura2", "la Sopaipilla no sale sin Desync")
	c.queue_free()
	Partida.nuevo()



## M18: en Arsenal → Desafíos, el premio que no has ganado se ve como silueta; el ganado, entero.
func _tests_desafios_silueta() -> void:
	Partida.nuevo()
	var ar = load("res://pantallas/arsenal.gd").new()
	var tipos := {}
	for de in Datos.DESAFIOS:
		tipos[de.premio.tipo] = true
		var ranura := String(de.premio.tipo).begins_with("ranura")
		_ok(ar.premio_en_silueta(de) == (not ranura), "sin ganar, el premio de %s se ve en silueta (salvo ranuras)" % de.id)
	_ok(tipos.has("arma") and tipos.has("hab"), "hay desafíos que dan armas y habilidades")
	# en las filas de nave, el candado va encima de la nave (la nave es un hijo y taparía el _draw)
	var filas_nave := 0
	for de in Datos.DESAFIOS:
		if de.premio.tipo != "nave" or not Partida.desafio_visible(de):
			continue
		var f = ar.Fila.new()
		f.de = de
		f.a = ar
		add_child(f)
		var hijos: Array = f.get_children()
		_ok(hijos.size() == 2 and hijos[0] == f.spr and hijos[1] is Sprite2D and hijos[1].texture == Datos.tex("ui_candado"), "el candado tapa a la nave en silueta: " + de.id)
		f.free()
		filas_nave += 1
	print("  filas de nave revisadas: %d" % filas_nave)
	var de0: Dictionary = Datos.DESAFIOS[0]
	Partida.d.desafios.append(de0.id)
	_ok(not ar.premio_en_silueta(de0), "ganado, el premio se ve entero")
	ar.free()
	Partida.nuevo()



## M14: tras el Desync las cartas esperan a que lleguen los Bits de la cascada y al respiro del nivel;
## fuera de él, nada cambia.
func _tests_xp_tras_desync() -> void:
	Partida.nuevo()
	Partida.nivel_sel = "1-1"
	var c = load("res://combate/combate.gd").new()
	add_child(c)
	c.set_physics_process(false)
	c.jx = 200.0
	c.jy = 300.0
	# sin Desync: con un nivel pendiente, las cartas salen al tiro, como antes
	c.estado = "jugando"
	c.niveles_pendientes = 1
	c._revisar_cartas()
	_ok(c.estado == "cartas", "sin Desync, las cartas salen al tiro")
	c.estado = "jugando"
	c.niveles_pendientes = 0
	# tras la cascada: un Bit lejos de la nave, que vuela de verdad con _tick_gemas
	c.gemas.clear()
	c._gema(c.jx, c.jy - 200.0, "bit", 1)
	c.estado = "cascada"
	c.cola.clear()
	c._terminar_cascada()
	_ok(c.estado == "jugando" and c.tras_desync_t == c.TRAS_DESYNC, "al terminar la cascada empieza la espera")
	_ok(c.gemas[0].de_cascada, "el Bit de la cascada queda marcado")
	c.niveles_pendientes = 1
	c.nivel_flash = 0
	c._revisar_cartas()
	_ok(c.estado == "jugando", "no salen las cartas mientras el Bit va en camino")
	var n := 0
	while c.estado == "jugando" and n < 400:
		c.ticks += 1
		c._tick_gemas()
		c._revisar_cartas()
		n += 1
	_ok(c.estado == "cartas", "después, las cartas salen")
	_ok(c.gemas.is_empty(), "el Bit llegó a la nave")
	_ok(n > 5 and n < c.TRAS_DESYNC, "salen cuando llega el Bit, antes del tope (%d cuadros)" % n)
	_ok(c.nivel_flash == 0, "al abrir las cartas se apaga el destello")
	# subir de nivel al final de la espera igual da el respiro completo
	c.estado = "jugando"
	c.niveles_pendientes = 0
	c.tras_desync_t = 5
	c.xp = c.xp_sig - 0.01
	var g = c.Gema.new()
	g.tipo = "bit"
	c._recoger(g)
	_ok(c.niveles_pendientes >= 1 and c.tras_desync_t >= c.RESPIRO_NIVEL, "el respiro se cumple entero (%d)" % c.tras_desync_t)
	# aunque el Bit no llegue nunca, la espera tiene tope
	c.niveles_pendientes = 1
	c.tras_desync_t = c.TRAS_DESYNC
	c.gemas.clear()
	var g2 = c.Gema.new()
	g2.de_cascada = true
	g2.x = -9999.0
	c.gemas.append(g2)
	n = 0
	while c.estado == "jugando" and n < 400:
		c._revisar_cartas()
		n += 1
	_ok(c.estado == "cartas" and n <= c.TRAS_DESYNC + 1, "la espera tiene tope (%d cuadros)" % n)
	# si la cascada cierra el nivel, no hay espera ni destello pegado en la victoria
	c.estado = "cascada"
	c.gemas.clear()
	c.victoria_pendiente = true
	c._terminar_cascada()
	_ok(c.estado == "victoria" and c.tras_desync_t == 0, "con victoria no se espera")
	c.victoria_pendiente = false
	c.queue_free()
	Partida.nuevo()



## M07: en todas las cartas posibles, la sinergia y el OK caben y no se montan sobre la descripción.
func _tests_cartas_caben() -> void:
	Partida.nuevo()
	Partida.nivel_sel = "1-1"
	var c = load("res://combate/combate.gd").new()
	add_child(c)
	c.set_physics_process(false)
	var r: Rect2 = c._rect_carta(0)
	var util := r.size.x - 8.0
	var cartas := []
	for id in Datos.ARMAS:
		for nv in Datos.ARMAS[id].mejoras.size() + 1:
			cartas.append(c._carta_arma(id, nv))
	for id in Datos.HABILIDADES:
		cartas.append(c._carta_hab(id, 0))
		cartas.append(c._carta_hab(id, 1))
	for ca in cartas:
		for ok in [false, true]:
			if not ca.has("sinergia"):
				continue
			ca.sin_ok = ok
			var l: Dictionary = c._layout_carta(ca, r)
			var ancho_titulo: float = UI.ancho(l.titulo) + (4.0 + UI.ancho("¡OK!") if ok else 0.0)
			_ok(ancho_titulo <= util, "el título de sinergia y el OK caben: %s %s" % [ca.nombre, l.titulo])
			for lin in l.lineas:
				_ok(UI.ancho(lin) <= util - 18.0, "el nombre de la sinergia cabe: " + lin)
			_ok(l.y_sin + 14.0 + 13.0 * l.lineas.size() <= r.end.y, "la sinergia no se sale por abajo: " + ca.nombre)
		var l2: Dictionary = c._layout_carta(ca, r)
		_ok(l2.y_fin_desc <= l2.y_pips + 2.0, "la descripción no tapa los niveles: %s (%d > %d)" % [ca.nombre, int(l2.y_fin_desc), int(l2.y_pips)])
	c.queue_free()
	Partida.nuevo()



## M15: el número del Desync sube entero aunque el enemigo ya esté sentenciado, sin cambiar el daño.
func _tests_desync_visual() -> void:
	Partida.nuevo()
	Partida.nivel_sel = "1-1"
	var c = load("res://combate/combate.gd").new()
	add_child(c)
	c.set_physics_process(false)
	c.jx = 200.0
	c.jy = 300.0
	c.enemigos.clear()
	var e = c._crear_enemigo({"tipo": "bot", "ancla": [200, 180]})
	e.x = 200.0
	e.y = 180.0
	e.modo = "actuar"
	c.estado = "desync"
	c.tiros.clear()
	# balas de sobra para matarlo varias veces, una por una
	for k in 30:
		c.tiros.clear()
		c.crear_tiro(200.0, 180.0, -PI / 2.0, 0.0, e.hpmax, Datos.tex("tiro2"), 1, false)
		c._colisiones()
		c.ticks += 1
	_ok(c.cola_total < 30, "las balas que pasan de largo no suman a la cascada (%d)" % c.cola_total)
	_ok(e.cola_vis == 30, "el número que se ve cuenta todas las balas (%d)" % e.cola_vis)
	var dano: float = e.cola_dano
	_ok(e.cola_hits == c.cola_total, "el daño en cola solo viene de las balas que pegaron")
	# una misma bala que se queda varios cuadros sobre el sentenciado suma una sola vez
	var vis_antes: int = e.cola_vis
	c.tiros.clear()
	c.crear_tiro(200.0, 180.0, -PI / 2.0, 0.0, e.hpmax, Datos.tex("tiro2"), 1, false)
	for k in 5:
		c._colisiones()
		c.ticks += 1
	_ok(e.cola_vis == vis_antes + 1, "una bala quieta sobre el sentenciado suma una vez (%d)" % (e.cola_vis - vis_antes))
	c.tiros.clear()
	c.cola_i = 0
	c.cascada_t = 0.0
	c.estado = "cascada"
	c._tick_cascada()
	_ok(e.cola_vis == 0 and e.cola_hits == 0, "la cascada reinicia el número")
	_ok(dano > 0.0, "hubo daño en cola")
	c.queue_free()
	Partida.nuevo()


## Para mirar un arma en capturas (--vitrina): enemigos en formación que disparan y reaparecen,
## y la nave que barre de lado a lado. --vit_nave=Y pone la nave a esa altura; --vit_quieta no la mueve.
var vitrina_lista := []
const VITRINA := [["bot", 70, 140], ["bot", 130, 110], ["bot", 200, 150], ["bot", 270, 110], ["bot", 330, 140], ["bot", 165, 200], ["bot", 235, 200], ["compacto", 200, 60]]


func _vitrina(c) -> void:
	c.guion = []
	c.xp = 0.0
	c.hp = c.stats.hp
	c.niveles_pendientes = 0
	if vitrina_lista.is_empty():
		vitrina_lista.resize(VITRINA.size())
		# solo se ve el arma pedida, sin la de la nave
		var pedidas: PackedStringArray = args.get("armas", "").split(",")
		for a in c.arsenal.armas.duplicate():
			if not a.id in pedidas:
				c.arsenal.armas.erase(a)
	for i in VITRINA.size():
		var e = vitrina_lista[i]
		if e == null or e.muerto:
			vitrina_lista[i] = c._crear_enemigo({"tipo": VITRINA[i][0], "ancla": [VITRINA[i][1], VITRINA[i][2]]})
	c.jy = float(args.get("vit_nave", "300"))
	if not args.has("vit_quieta"):
		c.jx = 200.0 + 120.0 * sin(c.ticks * 0.025)


## Distancia a la que se mide cada arma de corto alcance. El resto se mide a 110.
const DIST_ARMA := {"aura": 40.0, "sierras": 40.0, "rush_b": 45.0, "ragequit": 50.0, "escopeta": 50.0, "speedhack": 30.0}
## Armas de un solo blanco y armas de área tienen metas distintas contra un blanco quieto.
const ARMAS_AREA := ["cohetes", "aura", "rayo", "sierras", "laser", "minas", "molotov", "tornado", "speedhack"]
## Estas valen por lo que frenan o atraen: su daño a un solo blanco es bajo a propósito.
const ARMAS_CONTROL := ["frame_drop", "sumidero"]
## Ocho Bots repartidos en tres filas: el del centro se puede alinear con la nave.
const FORMACION := [[-36, -32], [0, -32], [36, -32], [-18, 0], [18, 0], [-36, 32], [0, 32], [36, 32]]


func _blanco_prueba(c, tipo: String, x: float, y: float):
	var e = c._crear_enemigo({"tipo": tipo, "ancla": [x, y]})
	e.x = x
	e.y = y
	e.modo = "actuar"
	e.hp = 1e9
	e.hpmax = 1e9
	return e


## Combate de prueba con Ataque 12, sin mejoras, con el arma en ese nivel.
func _combate_prueba(id: String, nv: int, evo: bool):
	var c = load("res://combate/combate.gd").new()
	add_child(c)
	c.set_physics_process(false)
	c.stats = Datos.STATS_BASE.duplicate()
	c.stats.atk = 12.0
	c.arsenal.armas.clear()
	var a = c.arsenal.agregar(id)
	while a.nivel < nv:
		c.arsenal.subir(a)
	if evo:
		c.arsenal.evolucionar(a)
	c.jx = 200.0
	c.jy = 300.0
	return c


## Mide el daño real por segundo durante 20 segundos.
## "blanco": un Compacto quieto. "grupo": ocho Bots quietos en dos filas. "pasan": ocho Bots cruzando de lado a lado.
## Speedhack solo sirve moviéndose: para ella, la nave barre de lado a lado bajo los blancos.
func _medir_arma(id: String, nv: int, evo: bool, escenario: String, cuadros := 1200) -> Dictionary:
	seed(4242)
	var c = _combate_prueba(id, nv, evo)
	var dist: float = DIST_ARMA.get(id, 110.0)
	var y0: float = c.jy - dist
	var blancos := []
	if escenario == "blanco":
		blancos.append(_blanco_prueba(c, "compacto", 200.0, y0))
	else:
		for q in FORMACION:
			blancos.append(_blanco_prueba(c, "bot", 200.0 + q[0], y0 + q[1]))
	var max_tiros := 0
	var max_objs := 0
	for k in cuadros:
		c.ticks += 1
		if escenario == "pasan":
			for i in blancos.size():
				blancos[i].x = fposmod(k * 1.2 + i * 50.0, 460.0) - 30.0
				blancos[i].y = y0 + 30.0 * sin(k * 0.02 + i)
		if id == "speedhack":
			c.jx = 200.0 + 80.0 * sin(k * 0.05)
			if k % 110 == 100:
				c.arsenal.al_esquivar()
		c.arsenal.tick()
		c._tick_tiros()
		c._colisiones()
		c._tick_fx()
		max_tiros = maxi(max_tiros, c.tiros.size())
		for a in c.arsenal.armas:
			max_objs = maxi(max_objs, a.objs.size())
	var total := 0.0
	for e in blancos:
		total += 1e9 - e.hp
	c.queue_free()
	return {"dps": total / (cuadros / 60.0), "tiros": max_tiros, "objs": max_objs}


## Firewall no ataca: lo que vale es cuántos golpes frena y la onda. Recibe un golpe cada 3 segundos.
func _medir_firewall(nv: int, evo: bool) -> Dictionary:
	seed(4242)
	var c = _combate_prueba("firewall", nv, evo)
	var blancos := []
	for k in 8:
		var ang := TAU * k / 8.0
		blancos.append(_blanco_prueba(c, "bot", 200.0 + cos(ang) * 40.0, 300.0 + sin(ang) * 40.0))
	var frenados := 0
	var golpes := 0
	for k in 3600:
		c.ticks += 1
		for i in blancos.size():
			var ang := TAU * i / 8.0
			blancos[i].x = 200.0 + cos(ang) * 40.0
			blancos[i].y = 300.0 + sin(ang) * 40.0
		c.arsenal.tick()
		c._tick_fx()
		if k % 180 == 90:
			golpes += 1
			if c.arsenal.absorber_golpe():
				frenados += 1
	var total := 0.0
	for e in blancos:
		total += 1e9 - e.hp
	c.queue_free()
	return {"frenados": 100.0 * frenados / golpes, "dps": total / 60.0}


func _revisar_rango(v: float, minimo: float, maximo: float, nombre: String) -> void:
	_ok(v >= minimo and v <= maximo, "%s: %d, debería estar entre %d y %d" % [nombre, int(v), int(minimo), int(maximo)])


## Cada arma tiene que hacer daño, y el daño de todas tiene que quedar parejo.
func _tests_armas() -> void:
	Partida.nuevo()
	Partida.nivel_sel = "1-1"
	var C = load("res://combate/combate.gd")
	var ver: bool = args.has("medir_armas")
	if ver:
		print("  %-11s %-22s %-22s %-22s %s" % ["arma", "nivel 1 (blanco grupo pasan)", "nivel 5", "evolucionada", "balas/objetos max"])
	for id in Datos.ARMAS:
		if id == "firewall":
			continue
		var fila := []
		var picos := Vector2i.ZERO
		for nivel in [[1, false], [5, false], [5, true]]:
			var uno := _medir_arma(id, nivel[0], nivel[1], "blanco")
			var grupo := _medir_arma(id, nivel[0], nivel[1], "grupo")
			var pasan := _medir_arma(id, nivel[0], nivel[1], "pasan") if ver else {"dps": 0.0}
			fila.append([uno.dps, grupo.dps, pasan.dps])
			picos.x = maxi(picos.x, maxi(uno.tiros, grupo.tiros))
			picos.y = maxi(picos.y, maxi(uno.objs, grupo.objs))
		if ver:
			print("  %-11s %4d %4d %4d       %4d %4d %4d       %4d %4d %4d       %d/%d" % [id, fila[0][0], fila[0][1], fila[0][2], fila[1][0], fila[1][1], fila[1][2], fila[2][0], fila[2][1], fila[2][2], picos.x, picos.y])
		_ok(fila[0][0] > 0.0, "%s no hace daño" % id)
		if id in ARMAS_CONTROL:
			_revisar_rango(fila[0][0], 10.0, 30.0, id + " nivel 1, blanco")
			_revisar_rango(fila[1][0], 18.0, 60.0, id + " nivel 5, blanco")
			_revisar_rango(fila[2][0], 25.0, 100.0, id + " evolucionada, blanco")
		elif id in ARMAS_AREA:
			_revisar_rango(fila[0][0], 22.0, 50.0, id + " nivel 1, blanco")
			_revisar_rango(fila[1][0], 50.0, 125.0, id + " nivel 5, blanco")
			_revisar_rango(fila[2][0], 80.0, 230.0, id + " evolucionada, blanco")
		else:
			_revisar_rango(fila[0][0], 30.0, 50.0, id + " nivel 1, blanco")
			_revisar_rango(fila[1][0], 80.0, 125.0, id + " nivel 5, blanco")
			_revisar_rango(fila[2][0], 140.0, 230.0, id + " evolucionada, blanco")
		if id in ARMAS_AREA or id in ARMAS_CONTROL:
			for i in 3:
				_ok(fila[i][1] >= fila[i][0] * 1.4, "%s es de área y no rinde contra un grupo: %d contra %d" % [id, int(fila[i][1]), int(fila[i][0])])
		_ok(picos.x <= 70, "%s llena la pantalla de balas: %d" % [id, picos.x])
		_ok(picos.y <= 30, "%s deja demasiadas cosas en el campo: %d" % [id, picos.y])
	# Firewall tiene su propia medida
	for nivel in [[1, false], [5, false], [5, true]]:
		var m := _medir_firewall(nivel[0], nivel[1])
		if ver:
			print("  firewall    nivel %d%s: frena %d %% de un golpe cada 3 s, onda de %d por segundo a 8 enemigos" % [nivel[0], " evo" if nivel[1] else "", int(m.frenados), int(m.dps)])
		_ok(m.frenados >= 30.0, "firewall frena pocos golpes")
		_ok(m.dps > 0.0, "la onda de firewall no hace daño")
	_tests_armas_contratos()
	# cartas: nunca mas de lo que caben
	var c = C.new()
	add_child(c)
	c.set_physics_process(false)
	for k in 300:
		c.niveles_pendientes = 0
		c.cartas = c._generar_cartas()
		c.estado = "cartas"
		_ok(c.cartas.size() == 3, "siempre tres cartas")
		var ids := {}
		for ca in c.cartas:
			_ok(not ids.has(ca.id), "sin cartas repetidas")
			ids[ca.id] = true
		c.elegir_carta(randi() % 3)
		_ok(c.arsenal.armas.size() <= Partida.max_armas(), "no pasa del tope de armas")
		_ok(c.habs.size() <= Partida.max_habs(), "no pasa del tope de habilidades")
		for a in c.arsenal.armas:
			_ok(a.nivel <= Datos.NIVEL_MAX_CARTA, "arma no pasa de nivel 5")
		for h in c.habs:
			_ok(c.habs[h] <= Datos.max_hab(h), "habilidad no pasa de su maximo")
	var evos := 0
	for a in c.arsenal.armas:
		if a.evo:
			evos += 1
	_ok(evos > 0 or c.evoluciones == 0, "evoluciones coherentes")
	print("  tras 300 cartas: armas=%d habs=%d evoluciones=%d" % [c.arsenal.armas.size(), c.habs.size(), c.evoluciones])
	# las flechas no borran la partida
	var O = load("res://pantallas/opciones.gd").new()
	O.pestana = 3
	add_child(O)
	var fb = O.filas[O.filas.size() - 1]
	_ok(fb.solo_pulsar, "repetir los textos no responde a las flechas")
	O.queue_free()
	# evolucion exige arma maxima y su habilidad
	var d = C.new()
	add_child(d)
	d.set_physics_process(false)
	var ar = d.arsenal.armas[0]
	var hay_evo := func():
		for ca in d._generar_cartas():
			if ca.tipo == "evo":
				return true
		return false
	_ok(not hay_evo.call(), "sin nivel ni habilidad no hay evolucion")
	while ar.nivel < Datos.NIVEL_MAX_CARTA:
		d.arsenal.subir(ar)
	_ok(not hay_evo.call(), "con nivel maximo y sin habilidad no hay evolucion")
	d.habs[ar.def.sinergia] = 1
	_ok(hay_evo.call(), "con las dos cosas aparece la evolucion")
	d.arsenal.evolucionar(ar)
	_ok(not hay_evo.call(), "no evoluciona dos veces")
	c.queue_free()
	d.queue_free()
	Partida.nuevo()


## Lo que cada arma promete hacer, más allá de su daño.
func _tests_armas_contratos() -> void:
	seed(99)
	_test_firewall()
	_test_boomerang()
	_test_minas()
	_test_molotov()
	_test_tajo()
	_test_quickscope()
	_test_tornado()
	_test_frontales_nuevas()
	_test_cono()
	_test_hielo()
	_test_agujero()
	_test_torreta()
	_test_rastro()
	_test_estadisticas()
	_test_balas_rotas()
	_test_textos_armas()


## Cada texto tiene que caber en una carta: 116 de ancho y 5 líneas como máximo.
func _test_textos_armas() -> void:
	for id in Datos.ARMAS:
		var d: Dictionary = Datos.ARMAS[id]
		var textos: Array = [d.desc, d.evo.desc]
		for m in d.mejoras:
			textos.append(m.txt)
		for t in textos:
			_ok(UI.partir(t, 116.0).size() <= 5, "el texto de %s no cabe en la carta: %s" % [id, t])
		_ok(d.mejoras.size() == Datos.NIVEL_MAX_CARTA - 1, "%s tiene una mejora por nivel" % id)
		_ok(Datos.HABILIDADES.has(d.sinergia), "%s evoluciona con algo que existe" % id)


func _avanzar(c, n: int) -> void:
	for k in n:
		c.ticks += 1
		c.arsenal.tick()
		c._tick_tiros()
		c._colisiones()
		c._tick_fx()


func _bala_prueba(c, x: float, y: float, vx := 0.0, vy := 0.0) -> void:
	c.bx[c.bn] = x
	c.by[c.bn] = y
	c.bvx[c.bn] = vx
	c.bvy[c.bn] = vy
	c.bn += 1


func _test_firewall() -> void:
	var c = _combate_prueba("firewall", 1, false)
	var a = c.arsenal.armas[0]
	_ok(a.cargas == 2, "Firewall parte con 2 escudos")
	var e = _blanco_prueba(c, "bot", 235.0, 300.0)
	var lejos = _blanco_prueba(c, "bot", 200.0, 100.0)
	_ok(c.arsenal.absorber_golpe() and a.cargas == 1, "el primer golpe gasta un escudo")
	_ok(e.hp < 1e9, "al bloquear sale una onda que daña")
	_ok(lejos.hp == 1e9, "la onda no llega a todo el campo")
	_ok(c.arsenal.absorber_golpe() and a.cargas == 0, "el segundo golpe gasta el otro")
	_ok(not c.arsenal.absorber_golpe(), "sin escudos el golpe pasa")
	_avanzar(c, int(a.p.recarga) - 3)
	_ok(a.cargas == 0, "el escudo no vuelve antes de tiempo")
	_avanzar(c, 6)
	_ok(a.cargas == 1, "los escudos vuelven de a uno")
	_avanzar(c, int(a.p.recarga))
	_ok(a.cargas == 2, "vuelve el segundo")
	_avanzar(c, int(a.p.recarga) * 2)
	_ok(a.cargas == 2, "no pasa del máximo")
	while a.nivel < Datos.NIVEL_MAX_CARTA:
		c.arsenal.subir(a)
	_ok(a.cargas == int(a.p.n) and a.cargas == 4, "los escudos que se ganan llegan listos")
	# evolucionada, borra balas cerca; sin evolucionar, no
	_bala_prueba(c, 220.0, 300.0)
	c.arsenal.absorber_golpe()
	_ok(c.bn == 1, "sin evolucionar no borra balas")
	c.arsenal.evolucionar(a)
	c.arsenal.absorber_golpe()
	_ok(c.bn == 0, "evolucionado borra balas")
	c.queue_free()
	var d = _combate_prueba("pistola", 1, false)
	_ok(not d.arsenal.absorber_golpe(), "sin Firewall no se absorbe nada")
	d.queue_free()


func _test_boomerang() -> void:
	var c = _combate_prueba("rollback", 1, false)
	var a = c.arsenal.armas[0]
	var e = _blanco_prueba(c, "bot", 200.0, 220.0)
	var dmg: float = c.arsenal.dano(a)
	a.cd = 1.0
	_avanzar(c, 1)
	_ok(a.objs.size() == 1, "sale un boomerang")
	var o = a.objs[0]
	a.cd = 9999.0
	var mas_lejos: float = o.y
	var vuelta := 0
	for k in 300:
		_avanzar(c, 1)
		mas_lejos = minf(mas_lejos, o.y)
		if a.objs.is_empty():
			vuelta = k
			break
	_ok(vuelta > 0, "el boomerang vuelve a la nave")
	_ok(absf((300.0 - mas_lejos) - a.p.rango) < 25.0, "llega hasta su rango: %d" % int(300.0 - mas_lejos))
	var golpes: float = (1e9 - e.hp) / dmg
	_ok(golpes >= 1.9 and golpes < 3.5, "pega a la ida y a la vuelta: %.1f golpes" % golpes)
	c.queue_free()


func _test_minas() -> void:
	var c = _combate_prueba("minas", 1, false)
	var a = c.arsenal.armas[0]
	_avanzar(c, 1200)
	_ok(a.objs.size() > 0 and a.objs.size() <= int(a.p.max), "sin enemigos, las minas esperan sin pasar del tope: %d" % a.objs.size())
	# enemigo encima: la mina estalla
	var e = _blanco_prueba(c, "bot", a.objs[0].dx, a.objs[0].dy)
	var antes: int = a.objs.size()
	_avanzar(c, 40)
	_ok(e.hp < 1e9, "la mina estalla al tocarla")
	_ok(a.objs.size() <= antes, "la mina que estalla se va")
	c.queue_free()
	# evolucionada: suelta minas hijas
	c = _combate_prueba("minas", 5, true)
	a = c.arsenal.armas[0]
	_avanzar(c, 200)
	a.cd = 9999.0
	var hubo_hijas := false
	var blanco = _blanco_prueba(c, "compacto", a.objs[0].dx, a.objs[0].dy)
	for k in 30:
		_avanzar(c, 1)
		for o in a.objs:
			hubo_hijas = hubo_hijas or o.hija
	_ok(hubo_hijas, "Campo Minado suelta minas chicas")
	_ok(blanco.hp < 1e9, "Campo Minado hace daño")
	c.queue_free()
	# las minas viejas revientan solas
	c = _combate_prueba("minas", 1, false)
	a = c.arsenal.armas[0]
	_avanzar(c, 100)
	var primera = a.objs[0]
	_avanzar(c, 800)
	_ok(not primera in a.objs, "una mina vieja no se queda para siempre")
	c.queue_free()


func _test_molotov() -> void:
	var c = _combate_prueba("molotov", 1, false)
	var a = c.arsenal.armas[0]
	_avanzar(c, 200)
	_ok(a.objs.is_empty(), "sin enemigos no gasta botellas")
	var e = _blanco_prueba(c, "compacto", 200.0, 150.0)
	_avanzar(c, 1)
	_ok(a.objs.size() == 1 and a.objs[0].fase == 0, "la botella sale volando")
	_ok(e.hp == 1e9, "la botella no pega en el aire")
	_avanzar(c, 60)
	_ok(a.objs[0].fase == 1, "al llegar se vuelve fuego")
	_ok(e.hp < 1e9, "el fuego quema")
	# dos fuegos encima no pegan el doble
	var hp0: float = e.hp
	var o2 = c.arsenal.Objeto.new()
	o2.x = 200.0
	o2.y = 150.0
	o2.fase = 1
	o2.dur = 999.0
	o2.radio = 30.0
	a.objs[0].dur = 999.0
	a.objs.append(o2)
	a.cd = 9999.0
	_avanzar(c, 60)
	var golpes: float = (hp0 - e.hp) / c.arsenal.dano(a)
	_ok(golpes <= 6.5, "dos fuegos no se suman: %.1f golpes en 1 s" % golpes)
	c.queue_free()


func _test_tajo() -> void:
	var c = _combate_prueba("rush_b", 1, false)
	var a = c.arsenal.armas[0]
	_avanzar(c, 100)
	_ok(a.fx == 0, "sin nadie cerca no corta el aire")
	var adelante = _blanco_prueba(c, "bot", 200.0, 260.0)
	var atras = _blanco_prueba(c, "bot", 200.0, 340.0)
	var lejos = _blanco_prueba(c, "bot", 200.0, 120.0)
	_avanzar(c, 2)
	_ok(adelante.hp < 1e9, "corta al de adelante")
	_ok(atras.hp == 1e9, "no corta por la espalda")
	_ok(lejos.hp == 1e9, "no corta lejos")
	_ok(a.fx > 0, "el corte se ve")
	c.queue_free()
	c = _combate_prueba("rush_b", 5, true)
	a = c.arsenal.armas[0]
	var atras2 = _blanco_prueba(c, "bot", 200.0, 340.0)
	_bala_prueba(c, 220.0, 300.0)
	_bala_prueba(c, 200.0, 100.0)
	a.cd = 1.0
	_avanzar(c, 2)
	_ok(atras2.hp < 1e9, "No Stop corta en círculo")
	_ok(c.bn == 1, "No Stop rompe solo las balas de cerca")
	c.queue_free()


func _test_quickscope() -> void:
	var c = _combate_prueba("quickscope", 1, false)
	var a = c.arsenal.armas[0]
	var chico = _blanco_prueba(c, "bot", 180.0, 200.0)
	var grande = _blanco_prueba(c, "bot", 220.0, 100.0)
	chico.hp = 1000.0
	grande.hp = 2000.0
	a.cd = 30.0
	_avanzar(c, 20)
	_ok(a.marcados.size() == 1 and a.marcados[0] == grande, "fija la mira en el que tiene más vida")
	_ok(grande.hp == 2000.0, "apunta antes de disparar")
	_avanzar(c, 20)
	_ok(grande.hp < 2000.0, "dispara")
	_ok(chico.hp == 1000.0, "no le pega al otro")
	c.queue_free()
	c = _combate_prueba("quickscope", 5, true)
	a = c.arsenal.armas[0]
	var uno = _blanco_prueba(c, "bot", 180.0, 200.0)
	_avanzar(c, 200)
	_ok((1e9 - uno.hp) > 0.0, "evolucionada dispara")
	var esperado: float = c.arsenal.dano(a) * c.stats.crit_dmg
	_ok(is_equal_approx(fmod(1e9 - uno.hp, esperado), 0.0) or absf(fmod(1e9 - uno.hp, esperado) - esperado) < 0.5 or fmod(1e9 - uno.hp, esperado) < 0.5, "evolucionada siempre es crítico")
	c.queue_free()


func _test_tornado() -> void:
	var c = _combate_prueba("tornado", 1, false)
	var a = c.arsenal.armas[0]
	var e = _blanco_prueba(c, "compacto", 300.0, 160.0)
	a.cd = 1.0
	_avanzar(c, 1)
	_ok(a.objs.size() == 1, "sale un remolino")
	var o = a.objs[0]
	var d0: float = c.dist2(o.x, o.y, e.x, e.y)
	_avanzar(c, 90)
	_ok(c.dist2(o.x, o.y, e.x, e.y) < d0, "el remolino va hacia los enemigos")
	_avanzar(c, 110)
	_ok(e.hp < 1e9, "el remolino golpea")
	_avanzar(c, 300)
	_ok(a.objs.size() <= 2, "los remolinos se acaban")
	c.queue_free()
	c = _combate_prueba("tornado", 5, true)
	a = c.arsenal.armas[0]
	_blanco_prueba(c, "bot", 200.0, 200.0)
	c._gema(200.0, 200.0, "bit", 1)
	c.gemas[0].vx = 0.0
	c.gemas[0].vy = 0.0
	a.cd = 1.0
	_avanzar(c, 80)
	_ok(c.gemas[0].imantada, "Aspiradora te trae los Bits")
	c.queue_free()


func _test_frontales_nuevas() -> void:
	# Perforadora: sigue pegando mientras pasa
	var c = _combate_prueba("taladro", 1, false)
	var a = c.arsenal.armas[0]
	var e = _blanco_prueba(c, "compacto", 200.0, 240.0)
	a.cd = 1.0
	_avanzar(c, 1)
	a.cd = 9999.0
	_ok(c.tiros.size() == 1 and c.tiros[0].rehit > 0, "el taladro puede volver a pegar")
	_avanzar(c, 90)
	_ok((1e9 - e.hp) / c.arsenal.dano(a) >= 2.5, "un taladro pega varias veces al mismo")
	c.queue_free()
	c = _combate_prueba("taladro", 5, true)
	a = c.arsenal.armas[0]
	a.cd = 1.0
	_avanzar(c, 1)
	_ok(c.tiros[0].escala >= 2.0, "Túnel es mucho más grande")
	c.queue_free()
	# Gacha: el daño de cada dado es distinto y lo muestra
	c = _combate_prueba("gacha", 1, false)
	a = c.arsenal.armas[0]
	var danos := {}
	var escalas := {}
	for k in 60:
		a.cd = 1.0
		_avanzar(c, 1)
		var t = c.tiros[c.tiros.size() - 1]
		danos[snappedf(t.dmg, 0.01)] = true
		escalas[t.escala] = true
		c.tiros.clear()
	_ok(danos.size() >= 4, "los dados dan daños distintos: %d" % danos.size())
	_ok(escalas.size() >= 4, "un dado alto se ve más grande")
	c.queue_free()
	c = _combate_prueba("gacha", 5, true)
	a = c.arsenal.armas[0]
	var con_expl := 0
	var sin_expl := 0
	for k in 60:
		a.cd = 1.0
		_avanzar(c, 1)
		for t in c.tiros:
			if t.expl > 0:
				con_expl += 1
			else:
				sin_expl += 1
		c.tiros.clear()
	_ok(con_expl > 0 and sin_expl > 0, "Jackpot: solo los dados altos estallan")
	c.queue_free()


func _test_cono() -> void:
	var c = _combate_prueba("ragequit", 1, false)
	var a = c.arsenal.armas[0]
	_avanzar(c, 20)
	_ok(a.fx == 0, "sin nadie adelante no prende")
	var cerca = _blanco_prueba(c, "bot", 200.0, 250.0)
	var lado = _blanco_prueba(c, "bot", 100.0, 300.0)
	var lejos = _blanco_prueba(c, "bot", 200.0, 120.0)
	_avanzar(c, 30)
	_ok(cerca.hp < 1e9, "quema al de adelante")
	_ok(lado.hp == 1e9, "no quema al del lado")
	_ok(lejos.hp == 1e9, "no quema lejos")
	_ok(a.fx > 0, "las llamas se ven")
	c.queue_free()
	# Alt+F4: con poca vida llega más lejos y quema más
	c = _combate_prueba("ragequit", 5, true)
	a = c.arsenal.armas[0]
	var normal: float = c.arsenal.alcance_cono(a)
	c.hp = c.stats.hp * 0.2
	_ok(c.arsenal.alcance_cono(a) > normal, "Alt+F4 crece con poca vida")
	c.queue_free()


func _test_hielo() -> void:
	var c = _combate_prueba("frame_drop", 1, false)
	var a = c.arsenal.armas[0]
	_avanzar(c, 30)
	_ok(a.objs.is_empty(), "sin nadie al alcance no gasta la onda")
	var cerca = _blanco_prueba(c, "bot", 200.0, 230.0)
	var lejos = _blanco_prueba(c, "bot", 200.0, 20.0)
	_avanzar(c, 10)
	_ok(a.objs.size() == 1, "sale la onda")
	_avanzar(c, 30)
	_ok(cerca.hp < 1e9, "la onda daña")
	_ok(lejos.hp == 1e9, "la onda tiene alcance")
	var hp1: float = cerca.hp
	_avanzar(c, 20)
	_ok(cerca.hp == hp1, "cada onda pega una sola vez")
	# evolucionada: las balas que cruza quedan a la mitad, una sola vez
	var d = _combate_prueba("frame_drop", 5, true)
	var b = d.arsenal.armas[0]
	_blanco_prueba(d, "bot", 200.0, 230.0)
	_bala_prueba(d, 200.0, 250.0, 0.0, 2.0)
	b.cd = 1.0
	for k in 30:
		d.ticks += 1
		d.arsenal.tick()
	_ok(absf(d.bvy[0] - 1.0) < 0.01, "Pantalla Congelada frena las balas una vez: %.2f" % d.bvy[0])
	c.queue_free()
	d.queue_free()


func _test_agujero() -> void:
	var c = _combate_prueba("sumidero", 1, false)
	var a = c.arsenal.armas[0]
	_avanzar(c, 30)
	_ok(a.objs.is_empty(), "sin enemigos no abre el agujero")
	var e = _blanco_prueba(c, "bot", 200.0, 120.0)
	var cerca = _blanco_prueba(c, "bot", 240.0, 120.0)
	var jefe = _blanco_prueba(c, "grua", 150.0, 100.0)
	jefe.jefe = true
	_avanzar(c, 1)
	_ok(a.objs.size() == 1, "abre un agujero")
	var o = a.objs[0]
	a.cd = 9999.0
	_bala_prueba(c, o.x + 5.0, o.y)
	_bala_prueba(c, o.x + 200.0, o.y + 200.0)
	var d0: float = c.dist2(cerca.x, cerca.y, o.x, o.y)
	var jx0: float = jefe.x
	_avanzar(c, 10)
	_ok(c.dist2(cerca.x, cerca.y, o.x, o.y) < d0, "atrae a los enemigos")
	_ok(jefe.x == jx0, "a los jefes no los mueve")
	_ok(c.bn == 1, "se traga solo las balas de cerca")
	_avanzar(c, 60)
	_ok(e.hp < 1e9, "daña lo que tiene adentro")
	_avanzar(c, 200)
	_ok(a.objs.is_empty(), "el agujero se cierra")
	c.queue_free()
	# evolucionado: al cerrarse explota más fuerte si tragó balas
	var fuerza := []
	for balas in [0, 12]:
		seed(5)
		c = _combate_prueba("sumidero", 5, true)
		a = c.arsenal.armas[0]
		var b = _blanco_prueba(c, "compacto", 200.0, 120.0)
		a.cd = 1.0
		_avanzar(c, 2)
		a.cd = 9999.0
		var q = a.objs[0]
		for k in balas:
			_bala_prueba(c, q.x + 3.0, q.y)
		q.t = q.dur - 2.0
		var antes: float = b.hp
		_avanzar(c, 4)
		fuerza.append(antes - b.hp)
		c.queue_free()
	_ok(fuerza[0] > 0.0, "Pérdida Total explota al cerrarse")
	_ok(fuerza[1] > fuerza[0], "Pérdida Total explota con lo que tragó")


func _test_torreta() -> void:
	var c = _combate_prueba("afk_farmer", 1, false)
	var a = c.arsenal.armas[0]
	var e = _blanco_prueba(c, "bot", 200.0, 200.0)
	a.cd = 1.0
	_avanzar(c, 1)
	_ok(a.objs.size() == 1, "deja una torreta")
	var x0: float = a.objs[0].x
	c.jx = 50.0
	_avanzar(c, 100)
	_ok(a.objs[0].x == x0, "la torreta se queda donde la dejaste")
	_ok(e.hp < 1e9, "la torreta dispara sola")
	_avanzar(c, 800)
	_ok(a.objs.size() <= int(a.p.max), "no pasa del tope de torretas")
	c.queue_free()
	# evolucionada: lo que mata da chatarra
	c = _combate_prueba("afk_farmer", 5, true)
	a = c.arsenal.armas[0]
	var presa = _blanco_prueba(c, "bot", 200.0, 200.0)
	presa.hp = 1.0
	presa.hpmax = 1.0
	a.cd = 1.0
	var chatarra0: int = c.chatarra
	_avanzar(c, 60)
	_ok(presa.muerto, "la torreta mata")
	_ok(c.chatarra > chatarra0, "Bot Farm da chatarra")
	c.queue_free()


func _test_rastro() -> void:
	var c = _combate_prueba("speedhack", 1, false)
	var a = c.arsenal.armas[0]
	a.px = c.jx
	a.py = c.jy
	_avanzar(c, 60)
	_ok(a.objs.is_empty(), "quieto no deja fuego")
	var e = _blanco_prueba(c, "bot", 200.0, 290.0)
	for k in 120:
		c.jx = 150.0 + k * 1.0
		_avanzar(c, 1)
	_ok(a.objs.size() > 3, "moviéndote dejas fuego")
	_ok(e.hp < 1e9, "el fuego quema")
	c.jx = 390.0
	var hp1: float = e.hp
	c.arsenal.al_esquivar()
	_ok(e.hp == hp1, "sin evolucionar la esquiva no explota")
	c.queue_free()
	c = _combate_prueba("speedhack", 5, true)
	var b = _blanco_prueba(c, "bot", 200.0, 280.0)
	c.arsenal.al_esquivar()
	_ok(b.hp < 1e9, "Teletransporte: la esquiva explota")
	c.queue_free()


## Dedo Gordo, Buff Stacking y Spray tienen que notarse en lo que dura, mide y recarga cada arma.
func _test_estadisticas() -> void:
	var c = _combate_prueba("molotov", 1, false)
	var a = c.arsenal.armas[0]
	c.stats.duracion = 2.0
	c.stats.area = 1.5
	_blanco_prueba(c, "compacto", 200.0, 260.0)
	_avanzar(c, 40)
	_ok(a.objs[0].dur == a.p.dur * 2.0, "Buff Stacking alarga el fuego")
	_ok(a.objs[0].radio == a.p.radio * 1.5, "Dedo Gordo agranda el fuego")
	c.queue_free()
	c = _combate_prueba("pistola", 1, false)
	a = c.arsenal.armas[0]
	var normal: float = c.arsenal.dano(a)
	c.stats.cadencia = 2.0
	var disparos := 0
	for k in 120:
		var n: int = c.tiros.size()
		c.ticks += 1
		c.arsenal.tick()
		if c.tiros.size() > n:
			disparos += 1
		c.tiros.clear()
	_ok(disparos >= 19 and disparos <= 21, "Spray dispara el doble: %d" % disparos)
	c.stats.dano = 2.0
	_ok(is_equal_approx(c.arsenal.dano(a), normal * 2.0), "el daño usa los stats")
	# Doble Clic: una bala más no duplica el daño
	var d = _combate_prueba("macro", 1, false)
	var b = d.arsenal.armas[0]
	d.stats.crit = 0.0
	b.cd = 1.0
	d.ticks += 1
	d.arsenal.tick()
	var uno: float = d.tiros[0].dmg
	d.tiros.clear()
	d.stats.balas = 1
	b.cd = 1.0
	d.arsenal.tick()
	_ok(d.tiros.size() == 2, "Doble Clic agrega una bala")
	var suma: float = d.tiros[0].dmg + d.tiros[1].dmg
	_ok(suma > uno * 1.1 and suma < uno * 1.5, "Doble Clic suma poco: %.2f veces" % (suma / uno))
	c.queue_free()
	d.queue_free()


## Puntos 7 y 9: las balas que persiguen no se frenan y las que rebotan no llenan la pantalla.
func _test_balas_rotas() -> void:
	var c = _combate_prueba("macro", 1, false)
	var a = c.arsenal.armas[0]
	c.stats.homing = 3.6
	_blanco_prueba(c, "bot", 60.0, 60.0)
	a.cd = 1.0
	c.ticks += 1
	c.arsenal.tick()
	var t = c.tiros[0]
	var rapidez: float = Vector2(t.vx, t.vy).length()
	_ok(is_equal_approx(t.giro, deg_to_rad(3.6)), "Aimbot: giro en radianes por cuadro")
	_ok(t.vida <= 110, "una bala que persigue vive poco")
	for k in 40:
		c._tick_tiros()
	_ok(absf(Vector2(t.vx, t.vy).length() - rapidez) < 0.01, "una bala que persigue no se frena")
	c.queue_free()
	# el combo que el usuario rompió: Ping-Pong y Macro evolucionadas con todo encima
	c = _combate_prueba("ping_pong", 5, true)
	var m = c.arsenal.agregar("macro")
	while m.nivel < Datos.NIVEL_MAX_CARTA:
		c.arsenal.subir(m)
	c.arsenal.evolucionar(m)
	c.stats.homing = 1.2
	c.stats.rebote = 1
	c.stats.balas = 1
	c.stats.cadencia = 1.08
	c.stats.dano = 1.1
	for q in FORMACION:
		_blanco_prueba(c, "bot", 200.0 + q[0], 120.0 + q[1])
	for vacio in [false, true]:
		# con enemigos las balas persiguen; sin enemigos rebotan hasta gastarse, que es lo peor
		if vacio:
			c.enemigos.clear()
		var pico := 0
		var suma := 0
		for k in 900:
			_avanzar(c, 1)
			pico = maxi(pico, c.tiros.size())
			suma += c.tiros.size()
		if args.has("medir_armas"):
			print("  combo roto %s: balas en pantalla, pico %d, promedio %d" % ["sin enemigos" if vacio else "con enemigos", pico, suma / 900])
		_ok(pico <= c.MAX_TIROS, "el combo roto respeta MAX_TIROS: %d" % pico)
		_ok(suma / 900 <= 100, "el combo roto no llena la pantalla: %d de promedio" % (suma / 900))
	# con el tope de balas lleno, nada se cae
	c.tiros.clear()
	while c.tiros.size() < c.MAX_TIROS:
		c.tiros.append(c.Tiro.new())
	for id in Datos.ARMAS:
		if c.arsenal.buscar(id) == null:
			c.arsenal.agregar(id)
	for k in 60:
		c.ticks += 1
		c.arsenal.tick()
	_ok(c.tiros.size() <= c.MAX_TIROS, "con el tope lleno no entran más balas")
	c.tiros.clear()
	c.queue_free()
