extends "res://pruebas/pruebas_reglas.gd"
## --bot y --campana: el bot que juega solo (bueno, torpe, ciego o quieto), la campaña con el Hangar,
## la medición de presión (enemigos y balas en pantalla), los resúmenes y las capturas automáticas (--auto).

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
	_cerrar_presion()


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
	_resumen_presion(n)


# ---- presión en pantalla: cuántos enemigos y balas enemigas hay mientras se juega (M10) ----
## Por partida: suma y máximo de enemigos y balas en cada cuadro jugando (sin cartas, pausa ni Desync,
## que va en cámara lenta), y aparte los primeros 30 s, para ver si hay presión desde el inicio.
var presion := {}


## Lo mismo juntando todas las partidas, para el resumen.
var presion_tot := {}


const PRESION_INICIO := 30 * 60


func _medir_presion(c) -> void:
	_medir_presion_jefe(c)
	if c.estado != "jugando":
		return
	var en := 0
	for e in c.enemigos:
		if not e.muerto and e.x > 0.0 and e.x < c.ANCHO and e.y > 0.0 and e.y < c.ALTO:
			en += 1
	var b: int = c.bn
	presion["n"] = presion.get("n", 0) + 1
	presion["enem"] = presion.get("enem", 0) + en
	presion["balas"] = presion.get("balas", 0) + b
	presion["max_enem"] = maxi(presion.get("max_enem", 0), en)
	presion["max_balas"] = maxi(presion.get("max_balas", 0), b)
	if presion["n"] <= PRESION_INICIO:
		presion["enem_ini"] = presion.get("enem_ini", 0) + en
		presion["balas_ini"] = presion.get("balas_ini", 0) + b


## Mientras hay un jefe en pantalla (M12): cuánto dura la pelea, cuántas balas hay y cuántos golpes recibes.
func _medir_presion_jefe(c) -> void:
	if c.jefe_actual == null or c.jefe_actual.muerto:
		return
	if not presion.has("jefe_g0"):
		presion["jefe_g0"] = c.golpes
	presion["jefe_g1"] = c.golpes
	if c.estado != "jugando":
		return
	presion["jefe_n"] = presion.get("jefe_n", 0) + 1
	presion["jefe_balas"] = presion.get("jefe_balas", 0) + int(c.bn)
	presion["jefe_max_balas"] = maxi(presion.get("jefe_max_balas", 0), int(c.bn))


func _presion_jefe_txt() -> String:
	if not presion.has("jefe_g0"):
		return ""
	var n: float = maxf(presion.get("jefe_n", 0), 1.0)
	var golpes: int = int(presion.jefe_g1) - int(presion.jefe_g0)
	presion_tot["jefes"] = presion_tot.get("jefes", 0.0) + 1.0
	presion_tot["jefe_seg"] = presion_tot.get("jefe_seg", 0.0) + n / 60.0
	presion_tot["jefe_balas"] = presion_tot.get("jefe_balas", 0.0) + presion.get("jefe_balas", 0) / n
	presion_tot["jefe_max_balas"] = presion_tot.get("jefe_max_balas", 0.0) + float(presion.get("jefe_max_balas", 0))
	presion_tot["jefe_golpes"] = presion_tot.get("jefe_golpes", 0.0) + float(golpes)
	return " | con jefe: %.0f s jugando, balas prom=%.1f max=%d, golpes=%d" % [n / 60.0, presion.get("jefe_balas", 0) / n, presion.get("jefe_max_balas", 0), golpes]


## Imprime la presión de la partida que terminó, la suma al total y parte de cero.
func _cerrar_presion() -> void:
	var n: float = maxf(presion.get("n", 0), 1.0)
	var ni: float = minf(n, PRESION_INICIO)
	var fila := {
		"enem": presion.get("enem", 0) / n, "balas": presion.get("balas", 0) / n,
		"max_enem": presion.get("max_enem", 0), "max_balas": presion.get("max_balas", 0),
		"enem_ini": presion.get("enem_ini", 0) / ni, "balas_ini": presion.get("balas_ini", 0) / ni,
	}
	print("      presión: enemigos prom=%.1f max=%d | balas prom=%.1f max=%d | primeros 30 s: enemigos=%.1f balas=%.1f" % [fila.enem, fila.max_enem, fila.balas, fila.max_balas, fila.enem_ini, fila.balas_ini], _presion_jefe_txt())
	for k in fila:
		presion_tot[k] = presion_tot.get(k, 0.0) + float(fila[k])
	presion_tot["max_max_enem"] = maxf(presion_tot.get("max_max_enem", 0.0), fila.max_enem)
	presion_tot["max_max_balas"] = maxf(presion_tot.get("max_max_balas", 0.0), fila.max_balas)
	presion = {}


func _resumen_presion(n: float) -> void:
	var t := presion_tot
	print("[bot] presión promedio por partida: enemigos prom=%.1f max=%.1f (pico %d) | balas prom=%.1f max=%.1f (pico %d) | primeros 30 s: enemigos=%.1f balas=%.1f" % [t.get("enem", 0.0) / n, t.get("max_enem", 0.0) / n, int(t.get("max_max_enem", 0.0)), t.get("balas", 0.0) / n, t.get("max_balas", 0.0) / n, int(t.get("max_max_balas", 0.0)), t.get("enem_ini", 0.0) / n, t.get("balas_ini", 0.0) / n])
	var j: float = t.get("jefes", 0.0)
	if j > 0.0:
		print("[bot] con jefe (%d partidas que llegaron): %.0f s jugando | balas prom=%.1f max=%.1f | golpes=%.1f" % [int(j), t.jefe_seg / j, t.jefe_balas / j, t.jefe_max_balas / j, t.jefe_golpes / j])


func _soltar() -> void:
	for a in ACCIONES:
		Input.action_release(a)
	Input.action_release("foco")
	Input.action_release("esquivar")
	Input.action_release("desync")


func _bot_combate(c) -> void:
	_medir_presion(c)
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
		if args.has("foco"):
			Input.action_press("foco")
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
