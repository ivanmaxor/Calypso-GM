extends Control
## Fin de un nivel: estrellas, de dónde salió la chatarra y qué piezas cayeron.
## Si te retiraste, lo dice claro: no hay botín. En el Modo Infinito: tiempo y récord.

signal al_mapa
signal otra_vez
signal al_hangar

const T_ESTRELLA := 26
const INICIO_PIEZAS := 90
const PASO_PIEZA := 12

var res := {}
var botin := {}
var avance := {}
var record_antes := 0  # el récord que había antes de esta partida
var items := []
var t := 0
var mostrados := 0
var estrellas_vistas := 0
var modo := "normal"
var abandono := false
var desafio_cerca := ""
## Segundos en que los botones no aceptan clics tras cerrar el consejo: si no, el clic que cierra el diálogo
## (o un doble clic) caía sobre REINTENTAR, que queda justo debajo del cuadro de Don Tuerca (#65).
const SIN_CLIC := 0.35
var sin_clic_t := 0.0
var b1: Button
var b2: Button
var b3: Button


func _ready() -> void:
	size = Vector2(640, 360)
	theme = UI.tema()
	items = botin.items
	modo = res.get("modo", Datos.NIVELES[res.nivel_id].get("modo", "normal"))
	abandono = res.get("abandono", false)
	desafio_cerca = _desafio_cercano()
	b1 = UI.boton("CONTINUAR", Vector2(232, 328), Vector2(176, 26), self, func(): al_mapa.emit())
	b1.add_theme_color_override("font_color", UI.C_ORO)
	b2 = UI.boton("REINTENTAR", Vector2(90, 328), Vector2(136, 26), self, func(): otra_vez.emit())
	b3 = UI.boton("HANGAR", Vector2(414, 328), Vector2(136, 26), self, func(): al_hangar.emit())
	for b in [b1, b2, b3]:
		b.visible = false


## El desafío que más cerca está de cumplirse, para animarte a seguir. Vacío si ninguno anda cerca.
func _desafio_cercano() -> String:
	var mejor := 0.7
	var txt := ""
	for de in Datos.DESAFIOS:
		if Partida.desafio_hecho(de.id) or not Partida.desafio_visible(de):
			continue
		var v: int = Partida.valor_stat(de.stat)
		var f: float = float(v) / float(de.meta)
		if f >= mejor and f < 1.0:
			mejor = f
			txt = "%s (%d/%d)" % [de.txt, v, de.meta]
	return txt


var _t_acum := 0.0


func _process(delta: float) -> void:
	sin_clic_t = maxf(sin_clic_t - delta, 0.0)
	_t_acum += delta * 60.0
	t = int(_t_acum)
	if res.ganado:
		var est: int = avance.estrellas
		var deben: int = clampi((t - 20) / T_ESTRELLA + 1, 0, est) if t >= 20 else 0
		while estrellas_vistas < deben:
			estrellas_vistas += 1
			Sonido.tocar("estrella", 0.9 + estrellas_vistas * 0.12)
	var d: int = clampi((t - INICIO_PIEZAS) / PASO_PIEZA + 1, 0, items.size()) if t >= INICIO_PIEZAS else 0
	while mostrados < d:
		var it: Dictionary = items[mostrados]
		mostrados += 1
		Sonido.tocar("botin_%d" % it.rareza, 1.0, -3.0 if it.rareza < 3 else 2.0)
	if not b1.visible and t > INICIO_PIEZAS + PASO_PIEZA * items.size() + 12:
		_mostrar_botones()
	queue_redraw()


func _mostrar_botones() -> void:
	b1.visible = true
	b2.visible = true
	b3.visible = Partida.tiene("hangar")
	var lista: Array = [b2, b1, b3] if b3.visible else [b2, b1]
	UI.lista_foco(lista, false, false)
	# Al perder, Don Tuerca aconseja ir al Hangar: lo dice antes de que elijas y el foco queda ahí.
	# Reintentar sigue a mano, pero es una elección (#65).
	var foco: Button = b3 if perdio() and b3.visible else b1
	if aconsejar_hangar():
		load("res://pantallas/dialogo.gd").mostrar(self, "derrota", func():
			foco.grab_focus()
			sin_clic_t = SIN_CLIC)
	else:
		foco.grab_focus()


## Retirarse no es perder, y el Modo Infinito siempre termina así.
func perdio() -> bool:
	return not res.ganado and not abandono and modo != "infinito"


## "Anda al Hangar" solo tiene sentido si ya hay Hangar (se abre al ganar el 1-1). Si no, el consejo
## espera a una derrota con Hangar: no se marca como visto (#65).
func aconsejar_hangar() -> bool:
	return perdio() and Partida.tiene("hangar")


## Enter o clic mientras se cuenta todo: ver el final de inmediato.
func _input(ev: InputEvent) -> void:
	if sin_clic_t > 0.0 and ev is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		return
	if b1.visible or ev is InputEventMouseMotion:
		return
	if ev.is_action_pressed("ui_accept") or (ev is InputEventMouseButton and ev.pressed):
		get_viewport().set_input_as_handled()
		estrellas_vistas = avance.estrellas if res.ganado else 0
		mostrados = items.size()
		_t_acum = float(INICIO_PIEZAS + PASO_PIEZA * items.size() + 13)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), UI.C_FONDO)
	var def: Dictionary = Datos.NIVELES[res.nivel_id]
	var seg: int = res.tiempo
	if modo == "infinito":
		UI.tc(self, 320, 0, "AGUANTASTE " + UI.reloj(seg), UI.C_CIAN, 3, true)
	elif res.ganado:
		UI.tc(self, 320, 0, "¡NIVEL COMPLETADO!", UI.C_ORO, 3, true)
	elif abandono:
		UI.tc(self, 320, 0, "TE RETIRASTE", UI.C_GRIS, 3, true)
	else:
		UI.tc(self, 320, 0, "SKILL ISSUE", UI.C_ROJO, 3, true)
	UI.tc(self, 320, 44, "%s: %s" % [res.nivel_id, def.nombre], UI.C_TEXTO)
	if modo == "infinito":
		_bloque_record(seg)
	elif abandono:
		_bloque_retiro(seg)
	else:
		_bloque_estrellas(def)
	_numeros(seg)
	_chatarra()
	_piezas()
	_pie_consejos()


func _bloque_estrellas(def: Dictionary) -> void:
	var ok := [res.ganado, res.ganado and res.golpes <= def.golpes, res.ganado and res.max_cadena >= def.cadena]
	var txt := ["Terminaste el nivel", "Golpes: %d (máx. %d)" % [res.golpes, def.golpes], "Cadena: %d (mín. %d)" % [res.max_cadena, def.cadena]]
	var orden := []
	for k in 3:
		if ok[k]:
			orden.append(k)
	var y := 66.0
	for k in 3:
		var encendida: bool = ok[k] and orden.find(k) < estrellas_vistas
		var x := 140.0
		draw_texture(Datos.tex("ui_estrella" if encendida else "ui_estrella_vacia"), Vector2(x, y))
		UI.t(self, x + 20, y - 2, txt[k], UI.C_TEXTO if encendida else UI.C_GRIS)
		y += 16


func _bloque_retiro(seg: int) -> void:
	if seg < Partida.ANTES_DE_GANAR_NADA:
		UI.t(self, 110, 66, "Te saliste al tiro: no hay botín.", UI.C_ROJO)
		UI.t(self, 110, 80, "Ni piezas ni chatarra.", UI.C_GRIS)
	else:
		UI.t(self, 110, 66, "Te saliste antes de terminar: no hay piezas.", UI.C_ROJO)
		UI.t(self, 110, 80, "Solo te llevas la mitad de la chatarra.", UI.C_GRIS)
	UI.t(self, 110, 94, "Para llevarte todo, termina el nivel.", UI.C_GRIS)


func _bloque_record(seg: int) -> void:
	if seg > record_antes:
		if record_antes > 0:
			UI.t(self, 140, 66, "¡NUEVO RÉCORD!", UI.C_ORO, 1, true)
			UI.t(self, 140, 80, "El anterior era " + UI.reloj(record_antes), UI.C_GRIS)
		else:
			UI.t(self, 140, 66, "¡Tu primer récord!", UI.C_ORO, 1, true)
	else:
		UI.t(self, 140, 66, "Tu récord sigue siendo " + UI.reloj(record_antes), UI.C_TEXTO)
		var falta: int = record_antes - seg
		if falta > 0:
			UI.t(self, 140, 80, "Te faltaron %s para superarlo" % UI.reloj(falta), UI.C_GRIS)


func _numeros(seg: int) -> void:
	var filas := [["Kills", str(res.kills)], ["Tiempo", UI.reloj(seg)], ["Nivel de nave", str(res.nivel)]]
	if Partida.tiene("desync"):
		filas.append(["Desync", str(res.desyncs)])
		filas.append(["Ace", str(res.aces)])
	if modo == "ruleta":
		filas.append(["Giros", str(res.get("giros", 0))])
		filas.append(["Jackpots", str(res.get("jackpots", 0))])
	var fy := 60.0
	for f in filas:
		UI.t(self, 400, fy, f[0], UI.C_GRIS)
		UI.t(self, 490, fy, f[1], UI.C_TEXTO)
		fy += 13


func _chatarra() -> void:
	var cy := 152.0
	draw_line(Vector2(60, cy), Vector2(580, cy), UI.C_LINEA, 1.0)
	var total: int = botin.chatarra
	draw_texture(Datos.tex("obj_tuerca_grande"), Vector2(112, cy + 4))
	if total <= 0:
		UI.t(self, 132, cy + 3, "Sin chatarra", UI.C_GRIS, 1, true)
		return
	var txt := "+%d chatarra" % total
	UI.t(self, 132, cy + 3, txt, UI.C_ORO, 1, true)
	var x: float = 132.0 + UI.ancho(txt) + 10.0
	if abandono:
		UI.t(self, x, cy + 3, "= la mitad de lo que recogiste", UI.C_GRIS)
	elif modo == "infinito":
		UI.t(self, x, cy + 3, "= %d que soltaron los enemigos + %d por aguantar" % [botin.recogida, botin.bono], UI.C_GRIS)
	else:
		UI.t(self, x, cy + 3, "= %d que soltaron los enemigos + %d de premio" % [botin.recogida, botin.bono], UI.C_GRIS)


func _piezas() -> void:
	var cy := 152.0
	var total: int = items.size()
	if total == 0:
		return
	UI.tc(self, 320, cy + 22, "PIEZAS QUE CAYERON", UI.C_ROSA)
	var col := 7
	var tam := 36
	var paso := 62
	for i in mostrados:
		var it: Dictionary = items[i]
		var fila: int = i / col
		var en_fila: int = mini(col, total - fila * col)
		var x0 := 320.0 - en_fila * paso / 2.0 + (paso - tam) / 2.0
		var q := Vector2(x0 + (i % col) * paso, cy + 40 + fila * (tam + 16))
		UI.pieza(self, q, tam, it)
		var edad: int = t - (INICIO_PIEZAS + i * PASO_PIEZA)
		if edad < 6:
			draw_rect(Rect2(q, Vector2(tam, tam)).grow(2), Color.WHITE)
		if it.rareza >= 3:
			UI.tc(self, q.x + tam / 2.0, q.y + tam - 1, Datos.RAREZAS[it.rareza].nombre, Datos.RAREZAS[it.rareza].color)


func _pie_consejos() -> void:
	if not b1.visible:
		return
	var y := 310.0
	if not res.ganado and not abandono and Partida.tiene("hangar"):
		UI.tc(self, 320, y, "Consejo: pon las piezas nuevas en el Hangar y vuelve.", UI.C_GRIS)
		y -= 15.0
	if desafio_cerca != "":
		UI.tc(self, 320, y, "Desafío a punto de salir: " + desafio_cerca, UI.C_CIAN)
