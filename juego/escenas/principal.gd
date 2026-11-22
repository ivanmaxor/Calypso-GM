extends Node
## Une las pantallas. El flujo del juego esta completo aqui:
## titulo > (ranuras > dificultad) > mapa > (panel del nivel) > elegir nave > dialogo > combate > resultado > premio > dialogo > mapa

const COMBATE := preload("res://combate/combate.gd")
const HANGAR := preload("res://pantallas/hangar.gd")
const TITULO := preload("res://pantallas/titulo.gd")
const MAPA := preload("res://pantallas/mapa.gd")
const RESULTADO := preload("res://pantallas/resultado.gd")
const SELECCION := preload("res://pantallas/seleccion_nave.gd")
const DIALOGO := preload("res://pantallas/dialogo.gd")
const PREMIO := preload("res://pantallas/premio.gd")

var actual: Node = null
var fundido: ColorRect
var fundido_a := 0.0


func _ready() -> void:
	ThemeDB.fallback_font = Datos.fuente
	ThemeDB.fallback_font_size = UI.TAM
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var capa := CanvasLayer.new()
	capa.layer = 20
	add_child(capa)
	fundido = ColorRect.new()
	fundido.color = Color(0.02, 0.01, 0.05, 0.0)
	fundido.size = Vector2(640, 360)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(fundido)
	ir_titulo()
	Pruebas.iniciar(self)


func _process(d: float) -> void:
	if fundido_a > 0.0:
		fundido_a = maxf(fundido_a - d * 5.0, 0.0)
		fundido.color.a = fundido_a


func _poner(n: Node) -> void:
	if actual:
		actual.queue_free()
	actual = n
	add_child(n)
	move_child(n, 0)
	fundido_a = 1.0


func ir_titulo() -> void:
	var t := TITULO.new()
	t.jugar.connect(ir_mapa)
	_poner(t)


## recien y extra: lo que se acaba de abrir, para celebrarlo. foco: el nivel donde queda el foco.
func ir_mapa(recien := "", extra := "", foco := "") -> void:
	var m := MAPA.new()
	m.recien = recien
	m.recien_extra = extra
	m.foco_en = foco
	m.jugar_nivel.connect(_elegir_nivel)
	m.ir_hangar.connect(ir_hangar)
	m.ir_titulo.connect(ir_titulo)
	m.ng_plus_hecho.connect(_tras_ng_plus)
	_poner(m)
	DIALOGO.mostrar(m, "inicio", func(): pass)


## Empezó otra vuelta: el mapa se vuelve a armar desde cero y Don Tuerca lo comenta.
func _tras_ng_plus() -> void:
	ir_mapa()
	DIALOGO.mostrar(actual, "nueva_plus", func(): pass)


func ir_hangar(pestana := "") -> void:
	var h := HANGAR.new()
	h.inicial = pestana
	h.volver.connect(ir_mapa)
	_poner(h)


func _elegir_nivel(id: String) -> void:
	Partida.nivel_sel = id
	if Partida.d.naves.size() >= 2:
		ir_seleccion()
	else:
		_antes_de_jugar()


func ir_seleccion() -> void:
	var s := SELECCION.new()
	s.despegar.connect(_antes_de_jugar)
	s.volver.connect(func(): ir_mapa("", "", Partida.nivel_sel))
	_poner(s)


func _antes_de_jugar() -> void:
	DIALOGO.mostrar(actual, "antes_" + Partida.nivel_sel, ir_combate)


func ir_combate() -> void:
	var c := COMBATE.new()
	c.terminado.connect(ir_resultado)
	c.reiniciar.connect(ir_combate)
	_poner(c)


func ir_resultado(res: Dictionary) -> void:
	var record_antes: int = int(Partida.d.records.get(res.nivel_id, {}).get("seg", 0))
	Partida.registrar(res)
	var avance := {}
	if res.ganado:
		avance = Partida.completar_nivel(res.nivel_id, res)
	var botin := Partida.generar_botin(res)
	var nuevas: Array = Partida.revisar_desafios()
	Partida.guardar()
	var r := RESULTADO.new()
	r.res = res
	r.botin = botin
	r.avance = avance
	r.record_antes = record_antes
	r.al_mapa.connect(func():
		var abiertos := _abiertos_por(res, avance)
		_despues(res, avance, nuevas, func(): ir_mapa(abiertos[0], abiertos[1], res.nivel_id)))
	r.otra_vez.connect(func(): _despues(res, avance, nuevas, ir_combate))
	r.al_hangar.connect(func(): _despues(res, avance, nuevas, ir_hangar))
	_poner(r)


## Lo que se acaba de abrir, para celebrarlo en el mapa: [el nivel que sigue, el extra que se abrió con él].
func _abiertos_por(res: Dictionary, avance: Dictionary) -> Array:
	var r := ["", ""]
	if not res.ganado or not avance.primera:
		return r
	var i: int = Datos.ORDEN_NIVELES.find(res.nivel_id)
	if i >= 0 and i + 1 < Datos.ORDEN_NIVELES.size():
		r[0] = Datos.ORDEN_NIVELES[i + 1]
	for ex in Datos.EXTRAS:
		if Datos.EXTRAS[ex].requiere == res.nivel_id:
			if r[0] == "":
				r[0] = ex
			else:
				r[1] = ex
	return r


## Lo que pasa al salir del resultado: los premios nuevos y lo que dice Don Tuerca.
func _despues(res: Dictionary, avance: Dictionary, nuevas: Array, destino: Callable) -> void:
	var premios := []
	if res.ganado and not avance.premio.is_empty():
		premios.append(avance.premio)
	premios.append_array(nuevas)
	avance.premio = {}
	nuevas.clear()
	var clave: String = "despues_" + res.nivel_id if res.ganado else "derrota"
	# retirarse no es perder, y en el Modo Infinito siempre se termina cayendo
	if res.get("abandono", false) or res.get("modo", Datos.NIVELES[res.nivel_id].get("modo", "normal")) == "infinito":
		clave = ""
	var total: int = premios.size()
	_mostrar_premios(premios, total, func(): DIALOGO.mostrar(actual, clave, destino))


func _mostrar_premios(premios: Array, total: int, luego: Callable) -> void:
	if premios.is_empty():
		luego.call()
		return
	var p := PREMIO.new()
	p.indice = total - premios.size() + 1
	p.total = total
	p.premio = premios.pop_front()
	p.terminado.connect(func(): _mostrar_premios(premios, total, luego))
	actual.add_child(p)
