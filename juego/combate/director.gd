extends RefCounted
## El director de oleadas: arma el guion de un nivel gastando un presupuesto por segundo.
## Cada enemigo cuesta puntos; el ritmo sube a lo largo del nivel y respira en olas, para que haya momentos
## de apuro y momentos para recoger lo que cayó. Los "hitos" del catálogo son fijos (presentar enemigos, jefes):
## así las pistas calzan. Todo sale de un generador propio: la misma semilla da exactamente el mismo nivel.

## Lo que cuesta cada enemigo, en puntos de presupuesto.
const COSTO := {"mosca": 0.8, "bot": 2.0, "rabioso": 3.0, "reparador": 6.0, "sniper": 6.0, "spammer": 10.0, "compacto": 16.0}
## Cuántos de cada uno como máximo en una misma formación.
const TOPE_GRUPO := {"mosca": 26, "bot": 16, "rabioso": 8, "reparador": 2, "sniper": 3, "spammer": 3, "compacto": 2}
## Cuántos anclados pueden estar a la vez, según lo que alcanzan a durar en pantalla.
const TOPE_VIVOS := {"reparador": 3, "sniper": 4, "spammer": 3, "compacto": 2}
const DURA_VIVO := {"reparador": 16.0, "sniper": 12.0, "spammer": 14.0, "compacto": 16.0}
## Altura en que se paran los que usan ancla.
const ALTURAS := {"rabioso": [60.0, 120.0], "reparador": [28.0, 45.0], "sniper": [25.0, 50.0], "spammer": [40.0, 70.0], "compacto": [60.0, 85.0]}
const ESPEJOS := [["arco_izq", "arco_der"], ["s_izq", "s_der"], ["rulo_izq", "rulo_der"], ["caida_a", "caida_c"], ["cruce_izq", "cruce_der"], ["barrido_izq", "barrido_der"], ["v_izq", "v_der"]]
const ORIGENES := ["izq", "der", "arriba", "arriba_izq", "arriba_der"]
const OLA := 34.0  # segundos entre un apuro y otro

var rng := RandomNumberGenerator.new()
var def: Dictionary
var dur := 100.0
var r0 := 2.0
var r1 := 4.0
var mezcla: Array = []
var fase_ola := 0.0
var ultima_forma := ""
var ultimo_tipo := ""
var vivos := {}  # tipo -> lista de instantes en que se van


## "mult_ritmo" y "mult_inicio" vienen de la dificultad: más puntos por segundo es más enemigos a la vez,
## y el inicio sube aparte para que haya presión desde el primer segundo.
func _init(nivel: Dictionary, semilla: int, mult_ritmo := 1.0, mult_inicio := 1.0) -> void:
	def = nivel
	rng.seed = semilla
	dur = maxf(float(nivel.get("duracion", 100.0)), 1.0)
	var ri: Array = nivel.get("ritmo", [2.0, 4.0])
	r0 = float(ri[0]) * mult_ritmo * mult_inicio
	r1 = float(ri[1]) * mult_ritmo
	mezcla = nivel.get("mezcla", [["bot", 1.0, 0.0]])
	fase_ola = rng.randf() * TAU
	if nivel.get("modo", "") == "infinito":
		dur = float(nivel.get("ritmo_seg", 360.0))


## El guion completo de un nivel que termina: hitos más lo que el presupuesto alcance a pagar.
func guion() -> Array:
	var ev: Array = []
	for h in def.get("hitos", []):
		ev.append(h.duplicate())
	var huecos := []
	if def.get("modo", "") == "ruleta":
		for f in [0.45, 0.9]:
			var t: float = dur * f
			huecos.append([t - 5.0, t + 1.0])
			ev.append({"t": t, "ruleta": true})
			ev.append({"t": t + 0.01, "espera": true})
	_llenar(2.0, dur, ev, huecos)
	ev.sort_custom(func(a, b): return a.t < b.t)
	return ev


## Un tramo más de guion, para el Modo Infinito. "alivio" baja el ritmo mientras hay un jefe en pantalla.
func tramo(t0: float, t1: float, alivio := 1.0) -> Array:
	var ev: Array = []
	_llenar(t0, t1, ev, [], alivio)
	ev.sort_custom(func(a, b): return a.t < b.t)
	return ev


## Puntos por segundo en ese momento: sube con el tiempo y respira en olas.
func ritmo(t: float) -> float:
	var f := clampf(t / dur, 0.0, 1.0)
	var base: float = lerpf(r0, r1, pow(f, 1.25))
	# en el infinito sigue subiendo después de la meta, más despacio
	if t > dur:
		base = r1 + (t - dur) / dur * (r1 - r0) * 0.8
	return base * (1.0 + 0.25 * sin(TAU * t / OLA + fase_ola))


func _llenar(t0: float, t1: float, ev: Array, huecos: Array, alivio := 1.0) -> void:
	var t := t0
	while t < t1:
		for h in huecos:
			if t >= h[0] and t < h[1]:
				t = h[1]
		if t >= t1:
			break
		var r: float = maxf(ritmo(t) * alivio, 0.5)
		# el grupo se compra con lo que junta el presupuesto en unos segundos
		var plata: float = r * rng.randf_range(2.6, 4.6)
		var g := _grupo(t, plata)
		for e: Dictionary in g.ev:
			var x: Dictionary = e.duplicate()
			x.t = t + float(e.get("t", 0.0))
			ev.append(x)
		t += maxf(float(g.coste) / r, 0.9)


func _elegir_tipo(t: float) -> String:
	var total := 0.0
	for m: Array in mezcla:
		if t >= float(m[2]) and _hay_cupo(m[0], t):
			total += float(m[1])
	var x: float = rng.randf() * total
	for m: Array in mezcla:
		if t >= float(m[2]) and _hay_cupo(m[0], t):
			x -= float(m[1])
			if x <= 0.0:
				return m[0]
	return "bot"


func _hay_cupo(tipo: String, t: float) -> bool:
	if not TOPE_VIVOS.has(tipo):
		return true
	var quedan := 0
	for fin: float in vivos.get(tipo, []):
		if fin > t:
			quedan += 1
	return quedan < int(TOPE_VIVOS[tipo])


func _anotar(tipo: String, n: int, t: float) -> void:
	if not DURA_VIVO.has(tipo):
		return
	var lista: Array = vivos.get(tipo, [])
	var limpia := []
	for fin: float in lista:
		if fin > t:
			limpia.append(fin)
	for k in n:
		limpia.append(t + float(DURA_VIVO[tipo]))
	vivos[tipo] = limpia


func _grupo(t: float, plata: float) -> Dictionary:
	var tipo := _elegir_tipo(t)
	# dos veces seguidas lo mismo cansa, salvo que sea lo único que hay
	if tipo == ultimo_tipo and rng.randf() < 0.5:
		tipo = _elegir_tipo(t)
	ultimo_tipo = tipo
	var costo: float = COSTO[tipo]
	var n: int = clampi(int(round(plata / costo)), 1, int(TOPE_GRUPO[tipo]))
	# los enjambres grandes llegan cuando ya tienes con qué recibirlos
	if tipo == "mosca":
		n = mini(n, 6 + int(clampf(t / dur, 0.0, 1.0) * 20.0))
	if TOPE_VIVOS.has(tipo):
		var quedan := 0
		for fin: float in vivos.get(tipo, []):
			if fin > t:
				quedan += 1
		n = mini(n, maxi(int(TOPE_VIVOS[tipo]) - quedan, 1))
	_anotar(tipo, n, t)
	var ev: Array = []
	match tipo:
		"mosca":
			ev = _enjambre(n)
		"bot":
			ev = _formacion_bots(n, t)
		_:
			ev = [{"tipo": tipo, "n": n, "sep": rng.randf_range(0.25, 0.45), "anclas": _anclas(tipo, n)}]
	return {"ev": ev, "coste": n * costo}


func _enjambre(n: int) -> Array:
	var o: String = ORIGENES[rng.randi() % ORIGENES.size()]
	# a veces llegan de dos lados a la vez
	if n >= 12 and rng.randf() < 0.4:
		return [{"tipo": "mosca", "n": n / 2, "sep": 0.06, "enjambre": "izq"}, {"tipo": "mosca", "n": n - n / 2, "sep": 0.06, "enjambre": "der"}]
	return [{"tipo": "mosca", "n": n, "sep": 0.06, "enjambre": o}]


func _formacion_bots(n: int, t: float) -> Array:
	var f := clampf(t / dur, 0.0, 1.0)
	var sep: float = lerpf(0.34, 0.18, f)
	var forma := rng.randi() % 10
	if n >= 5 and forma < 2:
		return [_cortina(n)]
	if n >= 4 and forma < 6:
		var par: Array = ESPEJOS[rng.randi() % ESPEJOS.size()]
		var uno := n / 2
		return [{"tipo": "bot", "n": uno, "sep": sep, "ruta": par[0]}, {"tipo": "bot", "n": n - uno, "sep": sep, "ruta": par[1]}]
	var par2: Array = ESPEJOS[rng.randi() % ESPEJOS.size()]
	var ruta: String = par2[rng.randi() % 2]
	if ruta == ultima_forma:
		ruta = par2[0] if ruta == par2[1] else par2[1]
	ultima_forma = ruta
	return [{"tipo": "bot", "n": n, "sep": sep, "ruta": ruta}]


## Una fila que baja derecho, en V: obliga a abrirse paso por un lado.
func _cortina(n: int) -> Dictionary:
	var m := mini(n, 9)
	var paso: float = 340.0 / float(maxi(m - 1, 1))
	var xs := []
	for k in m:
		xs.append(30.0 + paso * k + rng.randf_range(-4.0, 4.0))
	# los del centro salen antes
	var orden := []
	var c := (m - 1) / 2.0
	for k in m:
		orden.append([absf(k - c), xs[k]])
	orden.sort_custom(func(a, b): return a[0] < b[0])
	var xs2 := []
	for o: Array in orden:
		xs2.append(o[1])
	return {"tipo": "bot", "n": m, "sep": 0.12, "ruta": "recta", "xs": xs2}


## Posiciones repartidas de lado a lado, con algo de azar.
func _anclas(tipo: String, n: int) -> Array:
	var al: Array = ALTURAS.get(tipo, [50.0, 80.0])
	var r := []
	var ancho: float = 340.0 / float(maxi(n, 1))
	var cargado := rng.randf_range(-20.0, 20.0)
	for k in n:
		var x: float = 30.0 + ancho * (k + 0.5) + rng.randf_range(-ancho * 0.2, ancho * 0.2) + (cargado if n < 3 else 0.0)
		r.append([clampf(x, 30.0, 370.0), rng.randf_range(al[0], al[1])])
	return r
