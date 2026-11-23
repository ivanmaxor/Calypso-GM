extends "res://pruebas/pruebas_hangar.gd"
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
##   --foco                                       el bot juega con el foco apretado (para mirar la hitbox en capturas)
##   --hitbox=tenue|cercana|foco                  cómo se ve la hitbox jugando normal (#58; sin esto, ESTILO_HITBOX)
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
##   --hangar_luz=a|b|c|antes                     opción de luz y foco de la sala del Hangar (#63, ver hangar_sala.gd)
##   --hangar_foco=id                             con --pantalla=hangar, deja enfocada esa estación de la sala
##
## Este archivo solo arranca y reparte: lee los argumentos, prepara la partida y despacha a cada módulo.
## Cadena (cada uno hereda del anterior): pruebas_base.gd -> pruebas_armas.gd -> pruebas_reglas.gd -> pruebas_bot.gd -> pruebas_menus.gd -> pruebas_hangar.gd -> pruebas.gd

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
	if args.has("hangar_luz"):
		load("res://pantallas/hangar_sala.gd").opcion_luz = args.hangar_luz
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
