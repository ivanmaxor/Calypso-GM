extends "res://pruebas/pruebas_menus.gd"
## --flujo_hangar: recorre la sala del Hangar y sus estaciones (naves, equipo, fusión, mascotas, Arsenal)
## con teclas y mouse. También --demo_arsenal.

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
