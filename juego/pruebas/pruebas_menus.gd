extends "res://pruebas/pruebas_bot.gd"
## --flujo: recorre los menús con teclas, mando y mouse simulados, y revisa que cada paso haga lo que debe.

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
			var d := _hijo_de_tipo(a, "res://pantallas/dialogo.gd")
			_check(d != null and d.lineas == Datos.DIALOGOS["derrota"], "Don Tuerca consuela la primera derrota antes de que elijas (#65)")
			_pulsar("ui_cancel")
			espera_f = 20
		61:
			_check(_hijo_de_tipo(a, "res://pantallas/dialogo.gd") == null, "#65: Esc cierra el consejo y sigue en el resultado")
			_check(_foco() == a.b3, "#65: después del consejo, el foco queda en HANGAR")
			_check(a.b2.visible, "#65: REINTENTAR sigue a mano")
			a.b1.grab_focus()
			_pulsar("ui_accept")
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
		if tipo == "derrota":
			# al perder, el foco queda en HANGAR (#65). El consejo de Don Tuerca sale solo la primera vez:
			# aquí ya está visto, y lo prueba el recorrido principal (paso 60)
			_check(_foco() == (r.b3 if r.b3.visible else r.b1), "#65: resultado derrota: el foco queda en HANGAR")
			r.b1.grab_focus()
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
