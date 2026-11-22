extends "res://pruebas/pruebas_base.gd"
## --tests de las armas: cada arma se mide en un combate de prueba (daño por segundo, alcance, contratos de
## cada familia) y las que tienen mecánica propia (firewall, minas, tornado...) tienen su _test_*.
## _tests_armas() las llama; la llama _tests() de pruebas_reglas.gd.

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
	_test_rayo_decae()


## M11: cada salto del Reportado pega menos que el anterior, y contra un solo blanco no cambia nada.
func _test_rayo_decae() -> void:
	var c = _combate_prueba("rayo", 1, false)
	c.stats.crit = 0.0
	var bs := []
	for k in 3:
		bs.append(_blanco_prueba(c, "bot", 200.0 + k * 30.0, 220.0 - k * 10.0))
	for k in 90:
		c.ticks += 1
		c.arsenal.tick()
	var golpes := []
	for e in bs:
		golpes.append(1e9 - e.hp)
	_ok(golpes[0] > 0.0 and golpes[1] > 0.0 and golpes[2] > 0.0, "el rayo salta a los tres")
	_ok(golpes[1] < golpes[0] and golpes[2] < golpes[1], "cada salto del rayo pega menos: %s" % str(golpes))
	_ok(absf(golpes[1] / golpes[0] - (1.0 - float(Datos.ARMAS.rayo.base.decae))) < 0.01, "el rayo pierde lo que dice el catálogo por salto")
	c.queue_free()


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
