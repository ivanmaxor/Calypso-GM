extends Node
## Progreso permanente: tres ranuras de partida, dificultad, Nueva Partida +, niveles, naves, inventario,
## fusiones, mascotas, desafíos y lo que se puede apagar en el Arsenal.

const VERSION := 3
const NUM_SLOTS := 3
const ARCHIVO_SLOT := "user://partida3_%d.json"
const ARCHIVO_GLOBAL := "user://global3.json"
const ARCHIVO_V2 := "user://partida2.json"
const ARCHIVO_IMPORTAR := "partida_importar.json"
const CICLO_MAX := 7
const FORMAS_MASCOTA := [1, 10, 25]  # nivel en que cambia de forma
const TAM_MASCOTA := [22, 24, 28]  # lado del cuadro en cada forma: crece poco a propósito
const NIVEL_MAX_MASCOTA := 30
const ANTES_DE_GANAR_NADA := 20  # segundos: salirse antes de esto no da absolutamente nada

var d := {}  # la partida abierta
var g := {}  # lo que vale para todas las ranuras
var slot := 1  # en las pruebas parte en 0: el archivo de prueba, hasta abrir una ranura
var nivel_sel := "1-1"  # el nivel que se va a jugar
var prueba := ""  # nombre del guardado cuando corren las pruebas


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--guardado="):
			prueba = arg.get_slice("=", 1)
			slot = 0
	_cargar_global()
	nuevo()
	if prueba != "":
		cargar()
		return
	_migrar_v2()
	var u: int = int(g.get("ultimo_slot", 0))
	if u >= 1 and existe_slot(u):
		abrir_slot(u)


# =================================================================================================
# ARCHIVOS Y RANURAS
# =================================================================================================
func _ruta() -> String:
	if prueba != "" and slot == 0:
		return "user://%s.json" % prueba
	return _ruta_slot(slot)


func _ruta_slot(i: int) -> String:
	if prueba != "":
		return "user://%s_%d.json" % [prueba, i]
	return ARCHIVO_SLOT % i


## Las pruebas nunca leen el archivo real de la versión anterior.
func _ruta_v2() -> String:
	if prueba != "":
		return "user://%s_v2.json" % prueba
	return ARCHIVO_V2


func _ruta_global() -> String:
	if prueba != "":
		return "user://%s_global.json" % prueba
	return ARCHIVO_GLOBAL


func _leer_json(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var f := FileAccess.open(ruta, FileAccess.READ)
	if not f:
		return {}
	var leido = JSON.parse_string(f.get_as_text())
	return leido if typeof(leido) == TYPE_DICTIONARY else {}


func _escribir_json(ruta: String, datos: Dictionary) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(datos, "\t"))


func _cargar_global() -> void:
	g = _leer_json(_ruta_global())
	for k in ["extremo", "migrado"]:
		if not g.has(k):
			g[k] = false
	if not g.has("ultimo_slot"):
		g["ultimo_slot"] = 0
	if not g.has("aviso"):
		g["aviso"] = ""


func guardar_global() -> void:
	_escribir_json(_ruta_global(), g)


func extremo_abierto() -> bool:
	return g.extremo


func existe_slot(i: int) -> bool:
	return FileAccess.file_exists(_ruta_slot(i))


func hay_partidas() -> bool:
	for i in range(1, NUM_SLOTS + 1):
		if existe_slot(i):
			return true
	return false


func slot_libre() -> int:
	for i in range(1, NUM_SLOTS + 1):
		if not existe_slot(i):
			return i
	return 0


## Lo que muestra la pantalla de ranuras, sin abrir la partida.
func info_slot(i: int) -> Dictionary:
	var r := {"existe": false, "slot": i}
	var o := _leer_json(_ruta_slot(i))
	if o.is_empty() or int(o.get("version", 0)) != VERSION:
		return r
	r.existe = true
	r["dificultad"] = o.dificultad
	r["ciclo"] = int(o.ciclo)
	r["chatarra"] = int(o.chatarra)
	r["nave"] = o.nave
	r["mascota"] = o.mascota
	r["tiempo"] = int(o.get("tiempo", 0))
	r["kills"] = int(o.estadisticas.get("kills", 0))
	var est := 0
	var hechos := 0
	var actual := ""
	for id in Datos.ORDEN_NIVELES:
		if o.niveles.has(id) and o.niveles[id].completado:
			est += int(o.niveles[id].estrellas)
			hechos += 1
		elif actual == "":
			actual = id
	r["estrellas"] = est
	r["completados"] = hechos
	r["nivel_actual"] = actual if actual != "" else Datos.ULTIMO_NIVEL
	r["terminado"] = actual == ""
	return r


func abrir_slot(i: int) -> bool:
	slot = i
	if not cargar():
		return false
	g.ultimo_slot = i
	guardar_global()
	return true


func crear_slot(i: int, dificultad := "normal") -> void:
	slot = i
	nuevo(dificultad)
	guardar()
	g.ultimo_slot = i
	guardar_global()


func borrar_slot(i: int) -> void:
	if existe_slot(i):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_ruta_slot(i)))
	if g.ultimo_slot == i:
		g.ultimo_slot = 0
		guardar_global()


func nuevo(dificultad := "normal") -> void:
	d = {
		"version": VERSION, "dificultad": dificultad, "ciclo": 0, "chatarra": 0, "sig_uid": 1, "inventario": [], "equipo": {},
		"nave": "tryhard", "naves": ["tryhard"], "pinturas": {}, "mascotas": {}, "mascota": "", "desbloqueos": [], "niveles": {}, "vistos": [],
		"cambios_extra": 0, "armas": [], "habs": [], "apagados": [], "desafios": [], "ranuras_arma": 0, "ranuras_hab": 0,
		"records": {}, "premios_dados": [], "tiempo": 0,
		"estadisticas": {"partidas": 0, "victorias": 0, "kills": 0, "fusiones": 0, "muertes": 0, "desyncs": 0, "aces": 0, "evoluciones": 0, "max_cadena": 0,
			"roces": 0, "nams": 0, "esquivas": 0, "cambios": 0, "chatarra_total": 0, "jefes": 0, "golpes_total": 0, "sin_golpes": 0, "clutch": 0, "mejoras": 0,
			"giros": 0, "jackpots": 0, "inf_seg": 0, "tres_estrellas": 0},
	}
	for id in ["mira_laser", "casco_lata", "alas_ligeras", "motor_turbo", "chip_suerte"]:
		var it := agregar(id, 0)
		d.equipo[Datos.ITEMS[id].ranura] = it.uid


func guardar() -> void:
	_escribir_json(_ruta(), d)


func cargar() -> bool:
	var leido := _leer_json(_ruta())
	if leido.is_empty() or int(leido.get("version", 0)) != VERSION:
		nuevo()
		return false
	# JSON convierte todo a decimal: se normalizan los enteros
	for k in ["chatarra", "sig_uid", "cambios_extra", "ciclo", "ranuras_arma", "ranuras_hab", "tiempo", "version"]:
		leido[k] = int(leido[k])
	var inv := []
	for it in leido.inventario:
		if not Datos.ITEMS.has(it.id):
			continue
		it.uid = int(it.uid)
		it.rareza = int(it.rareza)
		it.nivel = int(it.nivel)
		it.invertido = int(it.get("invertido", 0))
		inv.append(it)
	leido.inventario = inv
	for k in leido.equipo.keys():
		leido.equipo[k] = int(leido.equipo[k])
	for k in leido.estadisticas.keys():
		leido.estadisticas[k] = int(leido.estadisticas[k])
	for k in leido.pinturas.keys():
		leido.pinturas[k] = int(leido.pinturas[k])
	for k in leido.niveles.keys():
		leido.niveles[k].estrellas = int(leido.niveles[k].estrellas)
	for k in leido.mascotas.keys():
		leido.mascotas[k].xp = int(leido.mascotas[k].xp)
	d = leido
	return true


# =================================================================================================
# DIFICULTAD Y NUEVA PARTIDA +
# =================================================================================================
func dificultad() -> String:
	return d.dificultad


func dif() -> Dictionary:
	return Datos.DIFICULTADES[d.dificultad]


func ciclo() -> int:
	return d.ciclo


## Cuánto cambian los enemigos, juntando dificultad y Nueva Partida +. Lo usa el combate.
## hp y dano multiplican; vel multiplica la velocidad de las balas; disparo multiplica el tiempo entre tiros.
func mods_enemigos() -> Dictionary:
	var c: int = mini(d.ciclo, CICLO_MAX)
	var di := dif()
	return {
		"hp": di.hp * pow(1.3, c),
		"dano": di.dano * pow(1.15, c),
		"vel": di.vel * minf(1.0 + 0.04 * c, 1.25),
		"disparo": di.disparo * maxf(1.0 - 0.04 * c, 0.75),
	}


func juego_terminado() -> bool:
	return nivel_completado(Datos.ULTIMO_NIVEL)


func puede_ng_plus() -> bool:
	return juego_terminado() and d.ciclo < CICLO_MAX


## Otra vuelta desde cero: se conserva todo lo ganado, los niveles se reinician y los enemigos suben.
func iniciar_ng_plus(nueva_dificultad := "", repetir_dialogos := true) -> void:
	d.ciclo += 1
	if nueva_dificultad != "":
		d.dificultad = nueva_dificultad
	d.niveles = {}
	if repetir_dialogos:
		d.vistos = []
	nivel_sel = Datos.ORDEN_NIVELES[0]
	guardar()


# =================================================================================================
# LO QUE TRAEMOS DE VERSIONES ANTERIORES
# =================================================================================================
## La partida de la versión 0.2 no sirve tal cual: estaba inflada. Se conserva hasta dónde llegaste y se arma
## el equipo que corresponde a ese punto. Si ya habías pasado todo, quedas justo antes del jefe.
func _migrar_v2() -> void:
	if g.migrado:
		return
	g.migrado = true
	var viejo := _leer_json(_ruta_v2())
	var hechos := 0
	var nombre_pet := ""
	if not viejo.is_empty() and viejo.has("niveles"):
		for id in Datos.ORDEN_NIVELES:
			if viejo.niveles.has(id) and viejo.niveles[id].completado:
				hechos += 1
			else:
				break
		if viejo.has("mascota") and typeof(viejo.mascota) == TYPE_DICTIONARY:
			nombre_pet = str(viejo.mascota.get("nombre", ""))
	if hechos > 0 and not existe_slot(1):
		var destino: String = Datos.ORDEN_NIVELES[mini(hechos, Datos.ORDEN_NIVELES.size() - 1)]
		slot = 1
		generar_para(destino, "normal")
		if nombre_pet != "" and d.mascotas.has("mordisco"):
			d.mascotas.mordisco.nombre = nombre_pet
		guardar()
		g.ultimo_slot = 1
		g.aviso = "Trajimos tu partida anterior a la Ranura 1, en Normal. Quedaste en el nivel %s, con el equipo que corresponde a ese punto." % destino
	guardar_global()
	nuevo()


## Arma una partida creíble para quien viene llegando a ese nivel: ni regalada ni pelada.
func generar_para(nivel: String, dificultad_nueva := "normal") -> void:
	nuevo(dificultad_nueva)
	var idx: int = maxi(Datos.ORDEN_NIVELES.find(nivel), 0)
	d.vistos = ["inicio", "derrota"]
	for i in idx:
		var id: String = Datos.ORDEN_NIVELES[i]
		d.niveles[id] = {"completado": true, "estrellas": 2 if i % 3 == 0 else 1}
		_aplicar_premio(Datos.NIVELES[id].premio.duplicate(), id)
		d.vistos.append("antes_" + id)
		d.vistos.append("despues_" + id)
	# equipo: gris al principio, algo de verde a mitad de camino y una azul antes del jefe
	var plan: Dictionary
	if idx < 3:
		plan = {"mira": [0, 1 + idx], "casco": [0, 1 + idx], "alas": [0, 1 + idx / 2], "motor": [0, 1 + idx / 2], "chip": [0, 1], "reactor": [0, 1]}
	elif idx < 5:
		plan = {"mira": [1, 3], "casco": [1, 2], "alas": [0, 3], "motor": [0, 3], "chip": [0, 2], "reactor": [0, 2]}
	elif idx < 7:
		plan = {"mira": [1, 5], "casco": [1, 4], "alas": [1, 2], "motor": [1, 2], "chip": [0, 4], "reactor": [0, 3]}
	else:
		plan = {"mira": [2, 4], "casco": [1, 6], "alas": [1, 4], "motor": [1, 4], "chip": [1, 2], "reactor": [1, 3]}
	for ranura in plan:
		var it := equipado(ranura)
		if it.is_empty():
			continue
		it.rareza = plan[ranura][0]
		it.nivel = plan[ranura][1]
	# unas cuantas piezas sueltas para fusionar
	var pool := pool_piezas()
	if not pool.is_empty():
		for k in idx * 2:
			agregar(pool[k * 7 % pool.size()], 0)
	d.chatarra = 40 + 45 * idx
	var e: Dictionary = d.estadisticas
	var despues_desync: int = maxi(idx - 2, 0)
	e.partidas = idx + 3
	e.victorias = idx
	e.muertes = 2 + idx / 2
	e.kills = 130 * idx
	e.k_bot = 90 * idx
	e.k_rabioso = 12 * maxi(idx - 1, 0)
	e.k_mosca = 10 * maxi(idx - 1, 0)
	e.k_sniper = 3 * maxi(idx - 2, 0)
	e.k_spammer = 2 * maxi(idx - 4, 0)
	e.k_compacto = 1 * maxi(idx - 5, 0)
	e.k_grua = 1 if idx >= 4 else 0
	e.jefes = e.k_grua
	e.desyncs = despues_desync * 2
	e.aces = despues_desync / 3
	e.fusiones = maxi(idx - 3, 0)
	e.max_cadena = 12 + idx * 2
	e.roces = idx * 20
	e.nams = maxi(idx - 3, 0) * 6
	e.esquivas = idx * 8
	e.chatarra_total = 110 * idx
	e.golpes_total = idx * 4
	e.mejoras = idx * 2
	if tiene("mascota"):
		d.mascotas[d.mascota].xp = 18 * idx
	# lo que ese avance ya habría abierto, sin celebrarlo
	revisar_desafios()


## Para llevar una partida a otro computador. La pantalla de ranuras la ofrece si el archivo está junto al juego.
func archivo_importable() -> String:
	var ruta: String = OS.get_executable_path().get_base_dir().path_join(ARCHIVO_IMPORTAR)
	if prueba != "":
		ruta = "user://%s_importar.json" % prueba
	return ruta if FileAccess.file_exists(ruta) else ""


func importar_a_slot(i: int) -> bool:
	var ruta := archivo_importable()
	if ruta == "":
		return false
	var o := _leer_json(ruta)
	if o.is_empty() or int(o.get("version", 0)) != VERSION:
		return false
	_escribir_json(_ruta_slot(i), o)
	return abrir_slot(i)


# =================================================================================================
# DESBLOQUEOS Y NIVELES
# =================================================================================================
func tiene(cosa: String) -> bool:
	return cosa in d.desbloqueos


func desbloquear(cosa: String) -> void:
	if not tiene(cosa):
		d.desbloqueos.append(cosa)


## Las ranuras que se ven en el Hangar: el reactor aparece junto con el Desync.
func ranuras_visibles() -> Array:
	var r := []
	for x in Datos.RANURAS:
		if x != "reactor" or tiene("desync"):
			r.append(x)
	return r


func nivel_completado(id: String) -> bool:
	return d.niveles.has(id) and d.niveles[id].completado


func estrellas(id: String) -> int:
	return d.niveles[id].estrellas if d.niveles.has(id) else 0


func estrellas_totales() -> int:
	var n := 0
	for id in Datos.ORDEN_NIVELES:
		n += estrellas(id)
	return n


func nivel_abierto(id: String) -> bool:
	if Datos.EXTRAS.has(id):
		return nivel_completado(Datos.EXTRAS[id].requiere)
	var i: int = Datos.ORDEN_NIVELES.find(id)
	return i == 0 or nivel_completado(Datos.ORDEN_NIVELES[i - 1])


func nivel_actual() -> String:
	for id in Datos.ORDEN_NIVELES:
		if not nivel_completado(id):
			return id
	return Datos.ORDEN_NIVELES[-1]


func mundo_alcanzado() -> int:
	return Datos.mundo_de(nivel_actual())


func visto(clave: String) -> bool:
	return clave in d.vistos


func marcar_visto(clave: String) -> void:
	if not visto(clave):
		d.vistos.append(clave)
		guardar()


## Aplica un premio de nivel. La segunda vuelta (Nueva Partida +) no da dos veces lo mismo: da chatarra.
func _aplicar_premio(p: Dictionary, nivel: String) -> Dictionary:
	var repetido: bool = nivel in d.premios_dados
	if not repetido:
		d.premios_dados.append(nivel)
	# lo que ya tienes no se vuelve a celebrar como si fuera nuevo: se cambia por chatarra
	if repetido and p.tipo in ["hangar", "desync", "mascota", "tablon", "nave"]:
		d.chatarra += 150
		return {"tipo": "chatarra", "cantidad": 150, "nombre": "BOLSA DE CHATARRA", "icono": "obj_tuerca_grande", "desc": "150 de chatarra"}
	match p.tipo:
		"hangar":
			desbloquear("hangar")
		"desync":
			desbloquear("desync")
			if d.equipo.get("reactor", 0) == 0:
				var it := agregar("reactor_lag", 0)
				d.equipo["reactor"] = it.uid
		"mascota":
			var id: String = p.get("id", "mordisco")
			dar_mascota(id)
			if id == "mordisco":
				desbloquear("mascota")
				desbloquear("fusion")
		"tablon":
			desbloquear("tablon")
		"nave":
			if not p.id in d.naves:
				d.naves.append(p.id)
		"pieza":
			var pool := pool_piezas()
			var it := agregar(pool[randi() % pool.size()], mini(int(p.rareza) + mini(d.ciclo, 2), Datos.RAREZAS.size() - 1))
			p["item"] = it
		"cambios":
			if repetido:
				d.chatarra += 150
				return {"tipo": "chatarra", "cantidad": 150, "nombre": "BOLSA DE CHATARRA", "icono": "obj_tuerca_grande", "desc": "150 de chatarra"}
			d.cambios_extra += 1
		"chatarra":
			d.chatarra += int(p.cantidad)
	return p


## Aplica el resultado de un nivel ganado. Devuelve lo que hay que celebrar.
func completar_nivel(id: String, res: Dictionary) -> Dictionary:
	var def: Dictionary = Datos.NIVELES[id]
	var primera := not nivel_completado(id)
	var est := 1
	if res.golpes <= def.golpes:
		est += 1
	if res.max_cadena >= def.cadena:
		est += 1
	var antes := estrellas(id)
	d.niveles[id] = {"completado": true, "estrellas": maxi(est, antes)}
	if est == 3 and antes < 3:
		d.estadisticas.tres_estrellas += 1
	var out := {"estrellas": est, "estrellas_antes": antes, "primera": primera, "premio": {}}
	if primera:
		out.premio = _aplicar_premio(def.premio.duplicate(), id)
	if id == Datos.ULTIMO_NIVEL:
		desbloquear("infinito")
		if not g.extremo:
			g.extremo = true
			guardar_global()
	return out


# =================================================================================================
# DESAFÍOS Y ARSENAL
# =================================================================================================
func valor_stat(stat: String) -> int:
	match stat:
		"estrellas":
			return estrellas_totales()
		"desafios":
			return d.desafios.size()
	return d.estadisticas.get(stat, 0)


func desafio_hecho(id: String) -> bool:
	return id in d.desafios


func desafio_visible(de: Dictionary) -> bool:
	return de.get("requiere", "") == "" or tiene(de.requiere)


## El desafío que da esa arma, habilidad, nave o mascota. Vacío si no se gana con desafío.
func desafio_de(tipo: String, id: String) -> Dictionary:
	for de in Datos.DESAFIOS:
		if de.premio.tipo == tipo and de.premio.id == id:
			return de
	return {}


## Revisa todos los desafíos. Devuelve los premios nuevos, listos para mostrarlos con la pantalla de premio.
func revisar_desafios() -> Array:
	var nuevos := []
	var hubo := true
	while hubo:
		hubo = false
		for de in Datos.DESAFIOS:
			if desafio_hecho(de.id) or not desafio_visible(de):
				continue
			if valor_stat(de.stat) >= de.meta:
				d.desafios.append(de.id)
				nuevos.append(_premio_desafio(de))
				hubo = true
	return nuevos


func _premio_desafio(de: Dictionary) -> Dictionary:
	var p: Dictionary = de.premio
	var r := {"tipo": p.tipo, "id": p.id, "desafio": de.txt}
	match p.tipo:
		"arma":
			if not p.id in d.armas:
				d.armas.append(p.id)
			r["nombre"] = "ARMA: " + Datos.ARMAS[p.id].nombre.to_upper()
			r["icono"] = "icono_" + p.id
			r["desc"] = Datos.ARMAS[p.id].desc
		"hab":
			if not p.id in d.habs:
				d.habs.append(p.id)
			r["nombre"] = "HABILIDAD: " + Datos.HABILIDADES[p.id].nombre.to_upper()
			r["icono"] = "icono_" + p.id
			r["desc"] = Datos.HABILIDADES[p.id].desc
		"nave":
			if not p.id in d.naves:
				d.naves.append(p.id)
			r["nombre"] = "NAVE: " + Datos.NAVES[p.id].nombre.to_upper()
			r["icono"] = "nave"
			r["desc"] = Datos.NAVES[p.id].desc
		"mascota":
			dar_mascota(p.id)
			r["nombre"] = "MASCOTA: " + Datos.MASCOTAS[p.id].nombre.to_upper()
			r["icono"] = "mascota"
			r["desc"] = Datos.MASCOTAS[p.id].desc
		"ranura_arma":
			d.ranuras_arma += 1
			r["nombre"] = "RANURA DE ARMA"
			r["icono"] = "icono_ranura_arma"
			r["desc"] = "Ahora llevas hasta %d armas" % max_armas()
		"ranura_hab":
			d.ranuras_hab += 1
			r["nombre"] = "RANURA DE HABILIDAD"
			r["icono"] = "icono_ranura_hab"
			r["desc"] = "Ahora llevas hasta %d habilidades" % max_habs()
	return r


func max_armas() -> int:
	return mini(Datos.RANURAS_ARMA_INICIO + d.ranuras_arma, Datos.TOPE_ARMAS)


func max_habs() -> int:
	return mini(Datos.RANURAS_HAB_INICIO + d.ranuras_hab, Datos.TOPE_HABS)


func es_base_arma(id: String, mundo := -1) -> bool:
	return _en_base("armas", id, mundo)


func es_base_hab(id: String, mundo := -1) -> bool:
	return _en_base("habs", id, mundo)


func _en_base(lista: String, id: String, mundo: int) -> bool:
	var m: int = mundo if mundo >= 0 else mundo_alcanzado()
	for i in mini(m + 1, Datos.BASE_POR_MUNDO.size()):
		if id in Datos.BASE_POR_MUNDO[i][lista]:
			return true
	return false


func arma_desbloqueada(id: String) -> bool:
	return es_base_arma(id) or id in d.armas


func hab_desbloqueada(id: String) -> bool:
	return es_base_hab(id) or id in d.habs


func esta_apagado(id: String) -> bool:
	return id in d.apagados


## Lo de la base no se apaga; lo ganado con desafíos, sí.
func alternar(id: String) -> void:
	if esta_apagado(id):
		d.apagados.erase(id)
	else:
		d.apagados.append(id)
	guardar()


## Las armas que pueden salir en las cartas de esta partida.
func armas_disponibles(mundo: int) -> Array:
	var r := []
	for id in Datos.ARMAS:
		if es_base_arma(id, mundo) or (id in d.armas and not esta_apagado(id)):
			r.append(id)
	return r


## Las habilidades que pueden salir. "en_mano": las armas que llevas: la sinergia de lo que llevas
## siempre puede salir, aunque no la hayas ganado. Lo que requiere algo que no tienes, nunca sale.
func habs_disponibles(mundo: int, en_mano := []) -> Array:
	var r := []
	for id in Datos.HABILIDADES:
		var h: Dictionary = Datos.HABILIDADES[id]
		if h.get("requiere", "") != "" and not tiene(h.requiere):
			continue
		var ok: bool = es_base_hab(id, mundo) or (id in d.habs and not esta_apagado(id))
		if not ok:
			for a in en_mano:
				if Datos.ARMAS[a].sinergia == id:
					ok = true
		if ok:
			r.append(id)
	return r


# =================================================================================================
# NAVES
# =================================================================================================
func nave_actual() -> String:
	return d.nave


func elegir_nave(id: String) -> void:
	if id in d.naves:
		d.nave = id
		guardar()


func pintura_de(id: String) -> int:
	if d.pinturas.has(id):
		return d.pinturas[id]
	return Datos.NAVES[id].pintura


func pintar_nave(id: String, p: int) -> void:
	d.pinturas[id] = p
	guardar()


func preparar_material(mat: ShaderMaterial, id: String) -> void:
	Datos.pintar(mat, pintura_de(id), rareza_equipada("alas"), rareza_equipada("motor"))


func progreso_nave(id: String) -> String:
	var u: Dictionary = Datos.NAVES[id].desbloqueo
	if u.tipo == "desafio":
		var de := desafio_de("nave", id)
		return "%s (%d/%d)" % [u.txt, mini(valor_stat(de.stat), de.meta), de.meta]
	return u.get("txt", "")


# =================================================================================================
# INVENTARIO
# =================================================================================================
func agregar(id: String, rareza: int) -> Dictionary:
	var it := {"uid": d.sig_uid, "id": id, "rareza": rareza, "nivel": 1, "invertido": 0}
	d.sig_uid += 1
	d.inventario.append(it)
	return it


func item(uid: int) -> Dictionary:
	for it in d.inventario:
		if it.uid == uid:
			return it
	return {}


func quitar(uid: int) -> void:
	for i in d.inventario.size():
		if d.inventario[i].uid == uid:
			d.inventario.remove_at(i)
			return


func def_de(it: Dictionary) -> Dictionary:
	return Datos.ITEMS[it.id]


func ranura_de(it: Dictionary) -> String:
	return Datos.ITEMS[it.id].ranura


func esta_equipado(uid: int) -> bool:
	return uid in d.equipo.values()


func equipado(ranura: String) -> Dictionary:
	if d.equipo.has(ranura):
		return item(d.equipo[ranura])
	return {}


func equipar(uid: int) -> void:
	var it := item(uid)
	if it.is_empty():
		return
	d.equipo[ranura_de(it)] = uid
	guardar()


func rareza_equipada(ranura: String) -> int:
	var it := equipado(ranura)
	return it.rareza if not it.is_empty() else 0


func piezas_de(ranura: String) -> Array:
	var r := []
	for it in d.inventario:
		if ranura == "" or ranura_de(it) == ranura:
			r.append(it)
	r.sort_custom(func(a, b):
		if a.rareza != b.rareza:
			return a.rareza > b.rareza
		if a.id != b.id:
			return a.id < b.id
		return a.nivel > b.nivel)
	return r


## Las piezas que pueden caer ahora: se van sumando con el avance y con los mundos.
func pool_piezas() -> Array:
	var r := []
	for id in Datos.ITEMS:
		if pieza_abierta(id):
			r.append(id)
	return r


func pieza_abierta(id: String) -> bool:
	var it: Dictionary = Datos.ITEMS[id]
	if it.get("mundo", 1) - 1 > mundo_alcanzado():
		return false
	if it.ranura == "reactor" and not tiene("desync"):
		return false
	var desde: String = it.get("desde", "")
	if desde == "" or d.ciclo > 0:
		return true
	# "desde": cae desde que juegas ese nivel, o sea, cuando se abre
	return nivel_abierto(desde)


# =================================================================================================
# MEJORAR
# =================================================================================================
func nivel_max(it: Dictionary) -> int:
	return 10 + 5 * it.rareza


func costo_mejora(it: Dictionary) -> int:
	return int((20 + 12 * it.nivel) * (1 + it.rareza * 0.5))


func mejorar(uid: int) -> bool:
	var it := item(uid)
	if it.is_empty() or it.nivel >= nivel_max(it):
		return false
	var c := costo_mejora(it)
	if d.chatarra < c:
		return false
	d.chatarra -= c
	it.nivel += 1
	it.invertido += c
	d.estadisticas.mejoras += 1
	guardar()
	return true


# =================================================================================================
# FUSIONAR: tres piezas de la misma ranura y rareza dan una de la rareza siguiente
# =================================================================================================
func compatibles_fusion(base: Dictionary) -> Array:
	var r := []
	for it in d.inventario:
		if it.uid != base.uid and ranura_de(it) == ranura_de(base) and it.rareza == base.rareza and not esta_equipado(it.uid):
			r.append(it)
	r.sort_custom(func(a, b): return a.nivel < b.nivel)
	return r


func puede_fusionar(base: Dictionary) -> bool:
	return base.rareza < Datos.RAREZAS.size() - 1 and compatibles_fusion(base).size() >= Datos.FUSION_PIEZAS - 1


## La base sube de rareza; las otras se las come la mascota y devuelven la chatarra invertida.
func fusionar_con(uid_base: int, otros: Array) -> Dictionary:
	var base := item(uid_base)
	if base.is_empty() or base.rareza >= Datos.RAREZAS.size() - 1 or otros.size() != Datos.FUSION_PIEZAS - 1:
		return {}
	for o in otros:
		var it := item(o)
		if it.is_empty() or o == uid_base or esta_equipado(o) or ranura_de(it) != ranura_de(base) or it.rareza != base.rareza:
			return {}
	var r_antes: int = base.rareza
	for o in otros:
		d.chatarra += item(o).invertido
		quitar(o)
	base.rareza += 1
	dar_xp_mascota(xp_por_rareza(r_antes))
	d.estadisticas.fusiones += 1
	guardar()
	return base


func fusionar(uid: int) -> Dictionary:
	var base := item(uid)
	if base.is_empty() or not puede_fusionar(base):
		return {}
	var otros := []
	for o in compatibles_fusion(base).slice(0, Datos.FUSION_PIEZAS - 1):
		otros.append(o.uid)
	return fusionar_con(uid, otros)


## Hace todas las fusiones posibles, de abajo hacia arriba. Devuelve los resultados.
func fusionar_todo() -> Array:
	var hechos := []
	var hubo := true
	while hubo:
		hubo = false
		for it in d.inventario.duplicate():
			if item(it.uid).is_empty():
				continue
			var eq := equipado(ranura_de(it))
			var base: Dictionary = eq if not eq.is_empty() and eq.rareza == it.rareza else it
			if puede_fusionar(base):
				hechos.append(fusionar(base.uid))
				hubo = true
				break
	return hechos


func hay_fusiones() -> bool:
	for it in d.inventario:
		if puede_fusionar(it):
			return true
	return false


func xp_por_rareza(r: int) -> int:
	return int(3 * pow(3, r))


# =================================================================================================
# MASCOTAS: una a la vez. Crecen lento y casi no cambian de tamaño.
# =================================================================================================
func dar_mascota(id: String) -> void:
	if not d.mascotas.has(id):
		d.mascotas[id] = {"xp": 0, "nombre": Datos.MASCOTAS[id].nombre}
	if d.mascota == "":
		d.mascota = id


func tiene_mascota(id: String) -> bool:
	return d.mascotas.has(id)


func mascota_activa() -> String:
	return d.mascota


func elegir_mascota(id: String) -> void:
	if d.mascotas.has(id):
		d.mascota = id
		guardar()


func dar_xp_mascota(xp: int) -> void:
	if d.mascota != "":
		d.mascotas[d.mascota].xp += xp


func nivel_mascota(id := "") -> int:
	var m: String = id if id != "" else d.mascota
	if m == "" or not d.mascotas.has(m):
		return 1
	return mini(int(floor(sqrt(float(d.mascotas[m].xp) / 10.0))) + 1, NIVEL_MAX_MASCOTA)


func xp_de_nivel(n: int) -> int:
	return (n - 1) * (n - 1) * 10


func xp_mascota(id := "") -> int:
	var m: String = id if id != "" else d.mascota
	return d.mascotas[m].xp if m != "" and d.mascotas.has(m) else 0


func forma_mascota(id := "") -> int:
	var n := nivel_mascota(id)
	var f := 0
	for i in FORMAS_MASCOTA.size():
		if n >= FORMAS_MASCOTA[i]:
			f = i
	return f


func tam_mascota(id := "") -> int:
	return TAM_MASCOTA[forma_mascota(id)]


func nombre_mascota(id := "") -> String:
	var m: String = id if id != "" else d.mascota
	return d.mascotas[m].nombre if m != "" and d.mascotas.has(m) else ""


func renombrar_mascota(nombre: String, id := "") -> void:
	var m: String = id if id != "" else d.mascota
	if m != "" and d.mascotas.has(m):
		d.mascotas[m].nombre = nombre
		guardar()


func _def_pet(id: String) -> Dictionary:
	var m: String = id if id != "" else d.mascota
	return Datos.MASCOTAS.get(m, {})


## Alcance de la habilidad de la mascota.
func pet_radio(id := "") -> float:
	var v: Array = _def_pet(id).get("radio", [0.0, 0.0])
	return v[0] + nivel_mascota(id) * v[1]


## Cuadros entre un uso y otro.
func pet_recarga(id := "") -> float:
	var v: Array = _def_pet(id).get("recarga", [300.0, 0.0, 100.0])
	return maxf(v[2], v[0] + nivel_mascota(id) * v[1])


## Daño de la mascota, en múltiplos de Ataque (solo las que pegan).
func pet_dano(id := "") -> float:
	var v: Array = _def_pet(id).get("dmg", [0.0, 0.0])
	return v[0] + nivel_mascota(id) * v[1]


# =================================================================================================
# STATS DE LA NAVE
# =================================================================================================
func _sumar(s: Dictionary, mods: Dictionary, factor := 1.0) -> void:
	for k in mods:
		s[k] = s.get(k, 0) + mods[k] * factor


## Cuánto sube cada nivel de mejora, sobre la base de la pieza. Con 4 % la Mira subía 0,08 de ataque
## por nivel y varios niveles no cambiaban ningún número visible (M13); con 8 % todos cambian.
const MEJORA_POR_NIVEL := 0.08


func stats_item(it: Dictionary) -> Dictionary:
	var r := {}
	var f: float = Datos.RAREZAS[it.rareza].mult * (1.0 + MEJORA_POR_NIVEL * (it.nivel - 1))
	_sumar(r, def_de(it).base, f)
	return r


func pasivas_activas(it: Dictionary) -> Array:
	var r := []
	for p in def_de(it).pasivas:
		if it.rareza >= p.r:
			r.append(p)
	return r


func stats_nave(id_nave := "") -> Dictionary:
	var s: Dictionary = Datos.STATS_BASE.duplicate()
	var idn: String = id_nave if id_nave != "" else d.nave
	_sumar(s, Datos.NAVES[idn].mods)
	for ranura in Datos.RANURAS:
		var it := equipado(ranura)
		if it.is_empty():
			continue
		_sumar(s, stats_item(it))
		for p in pasivas_activas(it):
			_sumar(s, p.mods)
	if d.mascota != "":
		_sumar(s, _def_pet("").get("mods_nivel", {}), nivel_mascota() - 1)
	s.dash_cd = maxf(s.dash_cd, 0.25)
	s.armadura = minf(s.armadura, 0.5)
	s.cambios += d.cambios_extra
	return s


# =================================================================================================
# BOTÍN: se gana peleando. Entrar y salir no da nada.
# =================================================================================================
func _tirar_rareza(suerte: float, indice_nivel: int, minimo := 0) -> int:
	var pesos := []
	var total := 0.0
	var empuje: float = (1.0 + d.ciclo * 0.35 + indice_nivel * 0.02) * dif().botin
	for i in Datos.RAREZAS.size():
		var p: float = Datos.RAREZAS[i].prob
		if CatalogoProgreso.PROB_CICLO.has(i) and d.ciclo >= i - 3:
			p = CatalogoProgreso.PROB_CICLO[i]
		if i >= 1:
			p *= pow(suerte * empuje, float(i) * 0.6)
		pesos.append(p)
		total += p
	var x := randf() * total
	for i in pesos.size():
		x -= pesos[i]
		if x <= 0:
			return maxi(i, minimo)
	return minimo


## res: lo que devuelve el combate al terminar.
func generar_botin(res: Dictionary) -> Dictionary:
	var s := stats_nave()
	var ids := pool_piezas()
	var seg: int = res.get("tiempo", 0)
	var abandono: bool = res.get("abandono", false)
	var modo: String = res.get("modo", "normal")
	var n := 0
	if modo == "infinito":
		n = mini(seg / 75, 6)
	elif res.ganado:
		n = 1 + mini(int(res.kills) / 80, 2)
		if res.get("jefe", false):
			n += 1
	elif not abandono and seg >= ANTES_DE_GANAR_NADA:
		n = mini(int(res.kills) / 60, 1)
	var items := []
	var idx: int = maxi(Datos.ORDEN_NIVELES.find(res.nivel_id), 0)
	if not ids.is_empty():
		for i in n:
			var minimo := 1 if res.ganado and res.get("jefe", false) and i == 0 else 0
			items.append(agregar(ids[randi() % ids.size()], _tirar_rareza(s.suerte, idx, minimo)))
	items.sort_custom(func(a, b): return a.rareza < b.rareza)
	var recogida: int = int(res.chatarra)
	var bono := 0
	if res.ganado:
		bono = 30 + idx * 15 + int(recogida * 0.25)
	elif modo == "infinito":
		bono = seg / 2
	if abandono:
		recogida = 0 if seg < ANTES_DE_GANAR_NADA else recogida / 2
		bono = 0
	var total := int((recogida + bono) * dif().chatarra * (1.0 + mini(d.ciclo, CICLO_MAX) * 0.25))
	d.chatarra += total
	d.estadisticas.chatarra_total += total
	return {"items": items, "chatarra": total, "recogida": recogida, "bono": total - recogida}


func registrar(res: Dictionary) -> void:
	var e: Dictionary = d.estadisticas
	var abandono: bool = res.get("abandono", false)
	d.tiempo += int(res.get("tiempo", 0))
	e.partidas += 1
	e.kills += res.kills
	e.desyncs += res.desyncs
	e.aces += res.aces
	e.evoluciones += res.evoluciones
	e.max_cadena = maxi(e.max_cadena, res.max_cadena)
	e.roces += res.get("roces", 0)
	e.nams += res.get("nams", 0)
	e.esquivas += res.get("esquivas", 0)
	e.cambios += res.get("cambios", 0)
	e.golpes_total += res.get("golpes", 0)
	e.jefes += res.get("jefes", 0)
	e.giros += res.get("giros", 0)
	e.jackpots += res.get("jackpots", 0)
	var por_tipo: Dictionary = res.get("kills_tipo", {})
	for t in por_tipo:
		var k: String = "k_" + t
		e[k] = e.get(k, 0) + por_tipo[t]
	if res.get("modo", "normal") == "infinito":
		var seg: int = res.get("tiempo", 0)
		e.inf_seg = maxi(e.inf_seg, seg)
		var r: Dictionary = d.records.get(res.nivel_id, {"seg": 0, "kills": 0})
		if seg > r.seg:
			d.records[res.nivel_id] = {"seg": seg, "kills": res.kills}
	if res.ganado:
		e.victorias += 1
		var dd: String = d.dificultad
		var kv: String = "v_dif_" + dd
		e[kv] = e.get(kv, 0) + 1
		var kn: String = "v_%s_%s" % [res.nivel_id, dd]
		e[kn] = e.get(kn, 0) + 1
		var kb: String = "v_nave_" + str(res.get("nave", d.nave))
		e[kb] = e.get(kb, 0) + 1
		if res.golpes == 0:
			e.sin_golpes += 1
		if float(res.get("hp", 100)) < float(res.get("hp_max", 100)) * 0.15:
			e.clutch += 1
		dar_xp_mascota(2 + int(res.get("nams", 0)) / 10)
	elif not abandono:
		e.muertes += 1
