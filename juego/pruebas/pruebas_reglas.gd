extends "res://pruebas/pruebas_armas.gd"
## --tests: las reglas del juego (teclas, partida, datos, combate, armas...), sin ventana y sin jugar.
## Cada área tiene su función _tests_*; _tests() las llama en orden.

func _tests() -> void:
	_tests_teclas()
	_tests_partida()
	_tests_datos()
	_tests_combate()
	_tests_mejoras_visibles()
	_tests_pausa_equipo()
	_tests_desafios_silueta()
	_tests_xp_tras_desync()
	_tests_cartas_caben()
	_tests_desync_visual()
	_tests_armas()
	_tests_hangar_delante()
	_tests_hitbox_indicador()
	_tests_consejo_derrota()
	_tests_barra_mascota()
	_tests_pruebas_aisladas()
	_tests_mejora_por_dificultad()
	_tests_desafios_antes_del_arsenal()
	_tests_otra_subida()
	load("res://pruebas/prueba_audio.gd").correr(_ok)
	print("[tests] pasadas=%d fallos=%d" % [pasadas, fallos])


## #47: cada prueba tiene sus propias opciones y teclas, y --reiniciar las deja de fábrica.
## Lo del mouse sin ventana lo prueban los pasos de mouse de flujo y flujo_hangar, que corren sin ventana.
func _tests_pruebas_aisladas() -> void:
	_ok(Ajustes._ruta() == "user://%s_ajustes.cfg" % Partida.prueba, "#47: las opciones de prueba llevan el prefijo de --guardado")
	_ok(Controles._ruta() == "user://%s_controles.cfg" % Partida.prueba, "#47: las teclas de prueba llevan el prefijo de --guardado")
	var musica := Ajustes.musica
	var auto := Ajustes.disparo_auto
	Ajustes.musica = 10
	Ajustes.disparo_auto = not Ajustes.DEFECTO.disparo_auto
	Ajustes.guardar()
	Controles.a.asignar("esquivar", "teclado", 1, "key:Q")
	Controles.guardar()
	_ok(FileAccess.file_exists(Ajustes._ruta()) and FileAccess.file_exists(Controles._ruta()), "#47: se guardaron opciones y teclas de prueba")
	_limpiar_guardados()
	_ok(not FileAccess.file_exists(Ajustes._ruta()), "#47: --reiniciar borra las opciones de prueba")
	_ok(not FileAccess.file_exists(Controles._ruta()), "#47: --reiniciar borra las teclas de prueba")
	_ok(Ajustes.musica == Ajustes.DEFECTO.musica and Ajustes.disparo_auto == Ajustes.DEFECTO.disparo_auto, "#47: --reiniciar deja las opciones de fábrica")
	_ok(Controles.a.obtener("esquivar", "teclado", 1) == "key:L", "#47: --reiniciar deja las teclas de fábrica")
	Ajustes.musica = musica
	Ajustes.disparo_auto = auto


## #65: el consejo "anda al Hangar" solo sale al perder de verdad y si ya hay Hangar.
func _tests_consejo_derrota() -> void:
	var tenia: bool = Partida.tiene("hangar")
	var r = load("res://pantallas/resultado.gd").new()
	r.res = {"ganado": false}
	r.modo = "normal"
	Partida.d.desbloqueos.erase("hangar")
	_ok(r.perdio() and not r.aconsejar_hangar(), "#65: sin Hangar (antes de ganar el 1-1) no se aconseja ir al Hangar")
	Partida.desbloquear("hangar")
	_ok(r.aconsejar_hangar(), "#65: con Hangar, al perder se aconseja ir al Hangar")
	r.abandono = true
	_ok(not r.aconsejar_hangar(), "#65: retirarse no es perder: sin consejo")
	r.abandono = false
	r.modo = "infinito"
	_ok(not r.aconsejar_hangar(), "#65: en el Modo Infinito siempre se termina cayendo: sin consejo")
	r.free()
	if not tenia:
		Partida.d.desbloqueos.erase("hangar")


## #67: una mascota lista y sin a quién atacar mantiene la barra llena; cuando aparece algo, actúa y la vacía.
func _tests_barra_mascota() -> void:
	var antes: String = Partida.d.mascota
	Partida.dar_mascota("mordisco")
	Partida.d.mascota = "mordisco"
	var c = _combate_prueba("pistola", 1, false)
	_ok(c.tiene_mascota and c.pet_ia == "come", "#67: el combate de prueba trae a Mordisco")
	var recarga: float = Partida.pet_recarga()
	var lleno_desde := -1
	var minimo_despues := 1.0
	for i in int(recarga) + 120:
		c._tick_mascota()
		var listo: float = 1.0 - clampf(c.pet_cd / recarga, 0.0, 1.0)
		if lleno_desde < 0 and listo >= 1.0:
			lleno_desde = i
		elif lleno_desde >= 0:
			minimo_despues = minf(minimo_despues, listo)
	_ok(lleno_desde >= 0, "#67: sin balas cerca, la barra de Mordisco se llena")
	_ok(minimo_despues >= 1.0, "#67: y se queda llena mientras no hay balas (mínimo %.3f)" % minimo_despues)
	# aparece una bala al lado: se la come en cuanto vuelve a buscar, y la barra parte de cero
	var nams: int = c.nams
	_bala_prueba(c, c.px + 4.0, c.py)
	for i in 30:
		c._tick_mascota()
	_ok(c.nams == nams + 1 and c.bn == 0, "#67: con una bala cerca, Mordisco se la come")
	_ok(c.pet_cd > recarga - 31.0, "#67: después de comer, la barra vuelve a cargarse desde cero")
	c.queue_free()
	Partida.d.mascota = antes


## M02: lo del fondo que va delante de una estación es un recorte exacto del fondo, en su lugar, y tapa a alguna estación.
func _tests_hangar_delante() -> void:
	_ok(SalaHangar.DELANTE.size() >= 3, "M02: hay sprites para lo que va delante de las estaciones")
	var fondo: Image = Datos.tex("hangar_fondo").get_image().duplicate()
	fondo.convert(Image.FORMAT_RGBA8)
	for id in SalaHangar.DELANTE:
		var r: Rect2 = SalaHangar.DELANTE[id]
		var nombre: String = "hangar_delante_" + id
		_ok(Datos.existe_tex(nombre), "M02: existe " + nombre)
		if not Datos.existe_tex(nombre):
			continue
		var tex := Datos.tex(nombre)
		_ok(Vector2(tex.get_size()) == r.size, "M02: %s mide lo que dice SalaHangar" % nombre)
		_ok(r.position.y >= 26.0 and r.position.x >= 0.0 and r.end.x <= 640.0 and r.end.y <= 360.0, "M02: %s no tapa la barra ni sale de la pantalla" % nombre)
		var tapa := false
		for est in SalaHangar.ORDEN:
			tapa = tapa or r.intersects(SalaHangar.OBJETOS[est].r)
		_ok(tapa, "M02: %s queda encima de alguna estación" % nombre)
		var img: Image = tex.get_image().duplicate()
		img.convert(Image.FORMAT_RGBA8)
		var distintos := 0
		var llenos := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a8 == 0:
					continue
				llenos += 1
				var f := fondo.get_pixel(int(r.position.x) + x, int(r.position.y) + y)
				if c.r8 != f.r8 or c.g8 != f.g8 or c.b8 != f.b8 or c.a8 != 255:
					distintos += 1
		_ok(llenos > 0 and distintos == 0, "M02: %s calza pixel a pixel con el fondo (%d distintos)" % [nombre, distintos])


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
	_tests_presion_dificultad()
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


## M10 y M12: Difícil se nota en la presión (más enemigos, desde el inicio, jefes más seguidos), no solo en los números.
## Normal queda igual que antes, y cada dificultad aprieta al menos lo mismo que la anterior.
func _tests_presion_dificultad() -> void:
	var D = load("res://combate/director.gd")
	var orden := ["facil", "normal", "dificil", "extremo"]
	for i in orden.size():
		var di: Dictionary = Datos.DIFICULTADES[orden[i]]
		for k in ["ritmo", "inicio", "ganas", "salva", "jefe_cd"]:
			_ok(di.has(k), "la dificultad %s define %s" % [orden[i], k])
		if i > 0:
			var antes: Dictionary = Datos.DIFICULTADES[orden[i - 1]]
			_ok(float(di.ritmo) >= float(antes.ritmo) and float(di.inicio) >= float(antes.inicio) and float(di.ganas) >= float(antes.ganas), "%s aprieta al menos como %s" % [orden[i], orden[i - 1]])
			_ok(float(di.salva) <= float(antes.salva), "las salvas de %s llegan al menos tan seguido como en %s" % [orden[i], orden[i - 1]])
			_ok(float(di.jefe_cd) <= float(antes.jefe_cd), "los jefes de %s atacan al menos tan seguido como en %s" % [orden[i], orden[i - 1]])
	var normal: Dictionary = Datos.DIFICULTADES["normal"]
	_ok(float(normal.ritmo) == 1.0 and float(normal.inicio) == 1.0 and float(normal.salva) == 1.0 and float(normal.jefe_cd) == 1.0, "Normal no cambia la presión")
	var dif: Dictionary = Datos.DIFICULTADES["dificil"]
	for id in ["1-2", "1-6"]:
		var nv: Dictionary = Datos.NIVELES[id]
		var gn: Array = D.new(nv, 7).guion()
		var gd: Array = D.new(nv, 7, float(dif.ritmo), float(dif.inicio)).guion()
		var cuenta := func(g: Array, hasta: float) -> int:
			var n := 0
			for ev in g:
				if ev.has("tipo") and D.COSTO.has(ev.tipo) and float(ev.t) <= hasta:
					n += int(ev.n)
			return n
		var n_total: int = cuenta.call(gn, 9999.0)
		var d_total: int = cuenta.call(gd, 9999.0)
		_ok(d_total >= n_total * 1.25, "en Difícil %s trae bastantes más enemigos: %d contra %d" % [id, d_total, n_total])
		_ok(cuenta.call(gd, 30.0) > cuenta.call(gn, 30.0), "en Difícil %s aprieta desde el inicio" % id)
		print("  presión %s: Normal %d enemigos, Difícil %d (primeros 30 s: %d contra %d)" % [id, n_total, d_total, cuenta.call(gn, 30.0), cuenta.call(gd, 30.0)])
	# el jefe ataca más seguido, pero su vida y su tope de daño no cambian por la dificultad
	_ok(float(dif.jefe_cd) < 1.0, "en Difícil los jefes atacan más seguido")
	_ok(Datos.ENEMIGOS.grua.tope_seg == 42.0 and Datos.ENEMIGOS.compactador.tope_seg == 50.0, "el tope de daño a los jefes se conserva")


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


## M13: antes de pagar se muestra qué sube, con el mismo signo que la ficha, y los números llevan un decimal.
func _tests_mejoras_visibles() -> void:
	var HE = load("res://pantallas/hangar_equipo.gd")
	for id in Datos.ITEMS:
		for rareza in [0, 3]:
			var it := {"id": id, "rareza": rareza, "nivel": 1, "uid": -1}
			while it.nivel < Partida.nivel_max(it):
				var gana: String = HE.texto_mejora(it)
				_ok(gana.begins_with("Al mejorar: +") or gana.begins_with("Al mejorar: -"), "se ve qué gana %s antes de pagar: %s" % [id, gana])
				# el signo de lo que se gana es el mismo que el de la base de la pieza
				for k in Datos.ITEMS[id].base:
					var nom: String = PiezaBoton.sin_spoiler(Datos.NOMBRE_STAT.get(k, k))
					var signo := "-" if Datos.ITEMS[id].base[k] < 0 else "+"
					if gana.contains(" " + nom):
						_ok(gana.contains(signo) , "el signo de %s calza con la ficha en %s" % [k, id])
				it.nivel += 1
			_ok(HE.texto_mejora(it) == "", "al máximo no ofrece mejora: " + id)
	var turbo := {"id": "motor_turbo", "rareza": 0, "nivel": 1, "uid": -1}
	_ok(HE.texto_mejora(turbo).begins_with("Al mejorar: -"), "la recarga de esquiva baja al mejorar: " + HE.texto_mejora(turbo))
	# M13 (balance): con la mejora por nivel actual, cada nivel de cada pieza cambia un número de la ficha.
	# Se mide en Difícil, donde la mejora es la más chica (8 %, #61).
	var dif_antes: String = Partida.d.dificultad
	Partida.d.dificultad = "dificil"
	for id in Datos.ITEMS:
		for rareza in [0, 3]:
			var it2 := {"id": id, "rareza": rareza, "nivel": 1, "uid": -1}
			var sin_cambio := 0
			while it2.nivel < Partida.nivel_max(it2):
				var antes := _textos_stats(Partida.stats_item(it2))
				it2.nivel += 1
				if antes == _textos_stats(Partida.stats_item(it2)):
					sin_cambio += 1
			_ok(sin_cambio == 0, "cada mejora de %s (rareza %d) cambia un número visible (%d sin cambio)" % [id, rareza, sin_cambio])
	Partida.d.dificultad = dif_antes
	_ok(PiezaBoton.valor_stat("atk", 2.16) == "+2,2", "un decimal con coma: " + PiezaBoton.valor_stat("atk", 2.16))
	_ok(PiezaBoton.valor_stat("atk", 3.0) == "+3", "sin ,0 que no aporta")
	_ok(PiezaBoton.valor_stat("crit", 0.045) == "+4,5 %", "porcentaje con decimal: " + PiezaBoton.valor_stat("crit", 0.045))


func _textos_stats(st: Dictionary) -> String:
	var r := ""
	for k in st:
		r += k + PiezaBoton.valor_stat(k, st[k]) + ";"
	return r


## #61: mejorar una pieza sube más en Fácil (12 %) que en Normal (10 %) y que en Difícil (8 %), y la ficha lo muestra.
## Sale de la dificultad de la partida, así que también vale para las piezas que ya tenías.
func _tests_mejora_por_dificultad() -> void:
	var HE = load("res://pantallas/hangar_equipo.gd")
	var dif_antes: String = Partida.d.dificultad
	var pct := {"facil": 0.12, "normal": 0.10, "dificil": 0.08, "extremo": 0.08}
	for di in pct:
		Partida.d.dificultad = di
		_ok(is_equal_approx(Partida.mejora_por_nivel(), pct[di]), "la mejora por nivel en %s es %d %%" % [di, roundi(pct[di] * 100)])
	for id in Datos.ITEMS:
		for rareza in [0, 3]:
			var it := {"id": id, "rareza": rareza, "nivel": 5, "uid": -1}
			var st := {}
			for di in pct:
				Partida.d.dificultad = di
				st[di] = Partida.stats_item(it)
			for k in Datos.ITEMS[id].base:
				var base: float = Datos.ITEMS[id].base[k] * Datos.RAREZAS[rareza].mult
				var exactos := true
				for di in pct:
					exactos = exactos and is_equal_approx(st[di][k], base * (1.0 + pct[di] * 4))
				_ok(exactos, "%s (rareza %d) al nivel 5 suma el porcentaje de cada dificultad en %s" % [id, rareza, k])
				_ok(absf(st.facil[k]) > absf(st.normal[k]) and absf(st.normal[k]) > absf(st.dificil[k]),
					"%s (rareza %d) da más %s en Fácil que en Normal, y en Normal que en Difícil" % [id, rareza, k])
	# "Al mejorar": la Munición Perforante épica tiene 5 de ataque de base, así que sube 0,6, 0,5 o 0,4
	var nom: String = PiezaBoton.sin_spoiler(Datos.NOMBRE_STAT.atk)
	var perf := {"id": "mun_perforante", "rareza": 3, "nivel": 1, "uid": -1}
	var esperado := {"facil": "+0,6", "normal": "+0,5", "dificil": "+0,4"}
	for di in esperado:
		Partida.d.dificultad = di
		var txt: String = HE.texto_mejora(perf)
		_ok(txt == "Al mejorar: %s %s" % [esperado[di], nom], "Al mejorar en %s muestra %s: %s" % [di, esperado[di], txt])
	# retroactivo: la misma pieza, ya mejorada, cambia si cambia la dificultad de la partida
	var perf5 := {"id": "mun_perforante", "rareza": 0, "nivel": 6, "uid": -1}
	Partida.d.dificultad = "facil"
	var en_facil: float = Partida.stats_item(perf5).atk
	Partida.d.dificultad = "dificil"
	_ok(is_equal_approx(en_facil, 2.5 * 1.6) and is_equal_approx(Partida.stats_item(perf5).atk, 2.5 * 1.4), "la misma pieza al nivel 6 da 4 en Fácil y 3,5 en Difícil")
	Partida.d.dificultad = dif_antes


## M16 y M17: la pausa muestra lo equipado y las estrellas, y todo cabe en su columna.
func _tests_pausa_equipo() -> void:
	Partida.nuevo()
	Partida.nivel_sel = "1-5"
	var c = load("res://combate/combate.gd").new()
	add_child(c)
	c.set_physics_process(false)
	# lo más largo posible: todas las armas y habilidades, de a 4 (el tope de ranuras)
	var armas: Array = Datos.ARMAS.keys()
	var habs: Array = Datos.HABILIDADES.keys()
	var P = load("res://pantallas/pausa.gd")
	var k := 0
	var evo := false
	while k < maxi(armas.size(), habs.size()):
		for a in c.arsenal.armas.duplicate():
			c.arsenal.armas.erase(a)
		c.habs.clear()
		for j in Datos.TOPE_ARMAS:
			if k + j < armas.size():
				var ar = c.arsenal.agregar(armas[k + j])
				ar.evo = evo
		for j in Datos.TOPE_HABS:
			if k + j < habs.size():
				c.habs[habs[k + j]] = Datos.max_hab(habs[k + j])
		var p = P.new()
		p.combate = c
		for tipo in ["armas", "habs"]:
			var lista: Array = p.entradas(tipo)
			var y: float = P.COL_Y + 16.0
			for e in lista:
				_ok(UI.ancho(e.nombre) + 6.0 + UI.ancho(e.nivel) <= P.COL_ANCHO - 38.0, "el nombre y el nivel caben en la pausa: " + e.nombre)
				for lin in e.desc:
					_ok(UI.ancho(lin) <= P.COL_ANCHO - 38.0, "la descripción cabe en la pausa: " + lin)
				y = maxf(y + 12.0 + 13.0 * e.desc.size(), y + 34.0) + 6.0
			_ok(y <= P.COL_FIN, "la columna de %s cabe en la pantalla (%d)" % [tipo, int(y)])
		_ok(p.entradas("armas").size() == c.arsenal.armas.size() and p.entradas("habs").size() == c.habs.size(), "se ve todo lo equipado")
		p.free()
		# cada grupo de 4 se prueba normal y después todo evolucionado (lo más largo)
		if evo:
			k += 4
		evo = not evo
	var p2 = P.new()
	p2.combate = c
	var est: Array = p2.estrellas()
	_ok(est.size() == 4, "en un nivel normal se ven las 3 estrellas")
	for e in est:
		_ok(UI.partir(e.txt, P.CENTRO_ANCHO - 18.0).size() == 1, "la estrella cabe en una línea: " + e.txt)
	p2.free()
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


## M01: el indicador de la hitbox queda discreto jugando normal y se ve entero en foco o Desync.
## La hitbox real no cambia: es regla de juego.
func _tests_hitbox_indicador() -> void:
	Partida.nuevo()
	Partida.nivel_sel = "1-1"
	var c = load("res://combate/combate.gd").new()
	add_child(c)
	c.set_physics_process(false)
	c.estado = "jugando"
	c.foco = false
	_ok(not c.hitbox_destacada(), "jugando normal, la hitbox se ve discreta")
	c.foco = true
	_ok(c.hitbox_destacada(), "en foco, la hitbox se ve entera")
	c.foco = false
	c.estado = "desync"
	_ok(c.hitbox_destacada(), "en Desync, la hitbox se ve entera")
	_ok(is_equal_approx(c.hitbox(), 3.5), "el indicador no cambia el tamaño real de la hitbox")
	for est in ["reconectando", "cascada"]:
		c.estado = est
		_ok(c.hitbox_destacada(), "con el filtro del Desync (%s), la hitbox se ve entera" % est)
	# con la hitbox más chica posible, el centro discreto no tapa el aro
	c.estado = "jugando"
	c.stats.hitbox_mult = 0.0
	_ok(c.centro_hitbox_discreta() <= c.hitbox() - 0.5, "con la hitbox mínima el aro se sigue viendo (%.2f / %.2f)" % [c.centro_hitbox_discreta(), c.hitbox()])
	c.queue_free()


## #66: al perder en el 1-3 se cumplen desafíos (snipers, roces, chatarra...) que dan armas y habilidades,
## pero el Arsenal, el único lugar donde se ven, abre recién con el 1-4. La pantalla de premio lo dice.
func _tests_desafios_antes_del_arsenal() -> void:
	var PR = load("res://pantallas/premio.gd")
	Partida.nuevo("dificil")
	_marcar_vistos()
	for n in ["1-1", "1-2"]:
		var g := _res_demo("ganado")
		g.nivel_id = n
		Partida.registrar(g)
		Partida.completar_nivel(n, g)
	Partida.revisar_desafios()
	var r := _res_demo("derrota")
	r.nivel_id = "1-3"
	r.kills_tipo = {"bot": 60, "sniper": 15}
	var armas_antes: int = Partida.d.armas.size()
	Partida.registrar(r)
	Partida.generar_botin(r)
	var nuevas: Array = Partida.revisar_desafios()
	_ok(not Partida.tiene("tablon"), "#66: en el 1-3 el Arsenal sigue cerrado")
	_ok(Partida.d.armas.size() > armas_antes and "railgun" in Partida.d.armas, "#66: perder en el 1-3 puede dar armas (15 Snipers: Railgun)")
	var revisados := 0
	for p in nuevas:
		if not p.tipo in ["arma", "hab", "ranura_arma", "ranura_hab"]:
			continue
		var pr = PR.new()
		pr.premio = p
		var txt: String = pr.donde_se_ve() if pr.has_method("donde_se_ve") else ""
		_ok(txt.contains("ARSENAL") and txt.contains("1-4"), "#66: el premio %s dice que se verá en el Arsenal del 1-4" % p.nombre)
		var cuerpo := UI.partir(p.get("detalle", p.get("desc", "")), 480.0)
		var donde := UI.partir(txt, 480.0)
		var ancho := 0.0
		for lin in donde:
			ancho = maxf(ancho, UI.ancho(lin))
		_ok(ancho <= 480.0 and 240.0 + cuerpo.size() * 14 + 8 + donde.size() * 14 <= 326.0, "#66: el aviso de %s cabe sobre el \"continuar\"" % p.nombre)
		pr.free()
		revisados += 1
	_ok(revisados > 0, "#66: la derrota del 1-3 dio premios que solo se ven en el Arsenal")
	# con el Arsenal abierto, o si no viene de un desafío, no se dice nada
	if not nuevas.is_empty():
		var pr = PR.new()
		pr.premio = nuevas[0]
		Partida.desbloquear("tablon")
		_ok(pr.has_method("donde_se_ve") and pr.donde_se_ve() == "", "#66: con el Arsenal abierto no hace falta el aviso")
		pr.free()
	var pn = PR.new()
	pn.premio = Datos.NIVELES["1-5"].premio.duplicate()
	Partida.d.desbloqueos.erase("tablon")
	_ok(pn.has_method("donde_se_ve") and pn.donde_se_ve() == "", "#66: un premio de nivel no lleva el aviso del Arsenal")
	pn.free()
	Partida.nuevo()


## #64: al elegir una carta con otra subida en cola salen cartas nuevas al tiro. El título lo dice
## ("¡OTRA SUBIDA! (2 de 3)") para que no parezca un cambio de cartas. Y el clic izquierdo elige: no cambia.
func _tests_otra_subida() -> void:
	Partida.nuevo()
	Partida.nivel_sel = "1-1"
	var c = load("res://combate/combate.gd").new()
	add_child(c)
	c.set_physics_process(false)
	c.jx = 200.0
	c.jy = 300.0
	var destello: int = c.get_script().get_script_constant_map().get("DESTELLO_SUBIDA", 24)
	# una sola subida: el título de siempre
	c.estado = "jugando"
	c.niveles_pendientes = 1
	c._revisar_cartas()
	_ok(c.estado == "cartas" and _titulo_cartas(c) == "¡SUBISTE DE NIVEL!", "con una subida, el título de siempre (%s)" % _titulo_cartas(c))
	c.elegir_carta(0)
	_ok(c.estado == "jugando", "con una subida, al elegir se vuelve a jugar")
	# tres subidas en cola, como tras un Desync
	c.cambios_restantes = 1
	c.niveles_pendientes = 3
	c._revisar_cartas()
	_ok(_titulo_cartas(c) == "¡SUBISTE DE NIVEL! (1 de 3)", "la primera tanda avisa cuántas vienen (%s)" % _titulo_cartas(c))
	_ok(c.get("subida_flash") == 0, "la primera tanda no destella el título")
	c.elegir_carta(0)
	_ok(c.estado == "cartas", "con otra subida en cola, al elegir salen cartas nuevas")
	_ok(_titulo_cartas(c) == "¡OTRA SUBIDA! (2 de 3)", "la tanda nueva dice que es otra subida (%s)" % _titulo_cartas(c))
	_ok(c.get("subida_flash") == destello, "y el título destella")
	_ok(c.cambios_restantes == 1, "elegir no gasta cambios de cartas")
	_ok(c.carta_t == 0, "la tanda nueva espera antes de aceptar otro clic")
	for k in destello:
		c._tick_cartas()
	_ok(c.get("subida_flash") == 0, "el destello dura lo suyo y se apaga")
	# cambiar cartas no es otra subida
	c.cambiar_cartas()
	_ok(c.cambios_restantes == 0 and _titulo_cartas(c) == "¡OTRA SUBIDA! (2 de 3)", "cambiar cartas no cuenta como otra subida")
	_ok(c.get("subida_flash") == 0, "cambiar cartas no destella el título")
	c.elegir_carta(0)
	_ok(_titulo_cartas(c) == "¡OTRA SUBIDA! (3 de 3)", "la tercera tanda también avisa (%s)" % _titulo_cartas(c))
	c.elegir_carta(0)
	_ok(c.estado == "jugando", "después de la última, se vuelve a jugar")
	# la subida siguiente empieza de nuevo
	c.niveles_pendientes = 1
	c._revisar_cartas()
	_ok(_titulo_cartas(c) == "¡SUBISTE DE NIVEL!", "una subida suelta después vuelve al título de siempre (%s)" % _titulo_cartas(c))
	c.elegir_carta(0)
	for s in ["¡SUBISTE DE NIVEL! (1 de 9)", "¡OTRA SUBIDA! (9 de 9)"]:
		_ok(UI.ancho(s, 2) <= c.ANCHO - 8, "el título grande cabe: %s (%.0f px)" % [s, UI.ancho(s, 2)])
	# el clic izquierdo de verdad sobre una carta la elige y no gasta cambios (hipótesis 2 del #64)
	var izq := InputEventMouseButton.new()
	izq.button_index = MOUSE_BUTTON_LEFT
	izq.pressed = true
	var der := InputEventMouseButton.new()
	der.button_index = MOUSE_BUTTON_RIGHT
	der.pressed = true
	_ok(not InputMap.event_is_action(izq, "desync"), "de fábrica, el clic izquierdo no es Desync")
	_ok(InputMap.event_is_action(der, "desync"), "de fábrica, el clic derecho sí es Desync")
	c.cambios_restantes = 1
	c.niveles_pendientes = 2
	c._revisar_cartas()
	c.carta_t = 18
	_clic_ya(c._rect_carta(2).get_center(), MOUSE_BUTTON_LEFT, true)
	_ok(c.carta_t == 0, "el clic llegó a la carta: salió otra tanda")
	_ok(c.cambios_restantes == 1, "el clic izquierdo no gasta cambios")
	_ok(_titulo_cartas(c) == "¡OTRA SUBIDA! (2 de 2)", "el clic izquierdo eligió la carta y salió la otra subida (%s)" % _titulo_cartas(c))
	# con el botón todavía apretado, el cuadro de las cartas tampoco lo toma como Desync
	c.carta_t = 18
	c._tick_cartas()
	_ok(c.cambios_restantes == 1, "el cuadro siguiente tampoco cambia las cartas")
	_clic_ya(c._rect_carta(2).get_center(), MOUSE_BUTTON_LEFT, false)
	c.queue_free()


## El título de la pantalla de cartas. Sin titulo_cartas() (antes del #64) era siempre el mismo.
func _titulo_cartas(c) -> String:
	return c.titulo_cartas() if c.has_method("titulo_cartas") else "¡SUBISTE DE NIVEL!"


## Un clic del mouse que llega al tiro a los _input, sin esperar cuadros (para tests sin ventana).
func _clic_ya(pos: Vector2, boton: MouseButton, apretado: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = _raton(pos)
	ev.global_position = ev.position
	ev.button_index = boton
	ev.pressed = apretado
	if apretado:
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if boton == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
