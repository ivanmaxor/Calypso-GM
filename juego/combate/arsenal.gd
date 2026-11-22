class_name Arsenal
extends RefCounted
## Las armas de una partida. Hay un máximo de ranuras; cada arma sube hasta nivel 5
## y evoluciona si además tienes su habilidad de sinergia.
##
## Lo que un arma deja en el campo (minas, fuego, remolinos, torretas...) vive y se dibuja aquí.
## Regla de dibujo: lo grande va en dibujar_detras, debajo de enemigos y balas, para no tapar nada.
## En dibujar_frente solo van cosas chicas: drones, escudos, sierras, boomerangs, lo que va volando.

## Cuánto daño total suma cada bala de Doble Clic: una bala más no duplica el arma.
const SUMA_BALA_EXTRA := 0.25
## Las balas que rebotan no pueden vivir para siempre: así no llenan la pantalla.
const VIDA_REBOTE := 170
## Una bala que persigue vive como máximo esto (el combate también lo revisa).
const VIDA_GIRO := 110
## Multiplicador de daño de cada cara del dado de la Gacha (promedio 1,25).
const DADO := [0.25, 0.5, 0.8, 1.2, 1.75, 3.0]
## Cuando un rayo no tiene a quién más saltar, vuelve a caer sobre el mismo con esta fuerza.
const RAYO_REPETIDO := 0.35
## Cuadros antes del disparo en que la mira del Quickscope se fija en su blanco.
const MIRA_QUICKSCOPE := 24.0
## Velocidad con que crece la onda de hielo, en píxeles por cuadro.
const VEL_ONDA := 3.5
## Remolinos: qué tan rápido vagan por el campo.
const VEL_TORNADO := 1.5


class Arma:
	var id := ""
	var def: Dictionary
	var nivel := 1
	var p := {}
	var cd := 10.0
	var evo := false
	var ang := 0.0
	var activo := 0.0
	var golpes := {}  # enemigo -> cuadro desde el que puede volver a recibir daño de esta arma
	var objs: Array = []  # lo que esta arma tiene en el campo
	var cargas := 0  # Firewall: escudos disponibles
	var recarga := 0.0  # Firewall: cuadros para que vuelva el siguiente
	var fx := 0  # cuadros que queda visible el efecto del arma (tajo, llamas)
	var lado := 1  # Rush B: hacia dónde va el corte
	var px := 0.0  # Speedhack: dónde dejó el último fuego
	var py := 0.0
	var marcados: Array = []  # Quickscope: blancos fijados


## Algo que un arma dejó en el campo. Cada tipo usa los campos que necesita.
class Objeto:
	var x := 0.0
	var y := 0.0
	var vx := 0.0
	var vy := 0.0
	var ox := 0.0  # de dónde salió
	var oy := 0.0
	var dx := 0.0  # a dónde va
	var dy := 0.0
	var t := 0.0  # cuadros que lleva
	var dur := 0.0  # cuadros que dura
	var radio := 0.0
	var fase := 0
	var cd := 0.0
	var rot := 0.0
	var n := 0
	var hija := false
	var golpes := {}
	var blanco = null


var c  # el combate
var armas: Array = []
var tick_laser := 0
var anillos: Array = []  # ondas que se ven: crecen hasta el radio real de su daño


func _init(combate) -> void:
	c = combate


func agregar(id: String) -> Arma:
	var a := Arma.new()
	a.id = id
	a.def = Datos.ARMAS[id]
	a.p = a.def.base.duplicate()
	if a.def.tipo == "escudos":
		a.cargas = int(a.p.n)
	a.px = c.jx
	a.py = c.jy
	armas.append(a)
	return a


func buscar(id: String) -> Arma:
	for a in armas:
		if a.id == id:
			return a
	return null


func subir(a: Arma) -> void:
	_mejorar(a, a.def.mejoras[a.nivel - 1])
	a.nivel += 1


func evolucionar(a: Arma) -> void:
	a.evo = true
	_mejorar(a, a.def.evo)


func _mejorar(a: Arma, m: Dictionary) -> void:
	var antes: int = int(a.p.get("n", 0))
	_aplicar(a, m)
	# un escudo nuevo llega listo
	if a.def.tipo == "escudos":
		a.cargas += int(a.p.n) - antes


## Los valores terminados en _pct multiplican (cad_pct cambia cad); los demás se suman.
func _aplicar(a: Arma, m: Dictionary) -> void:
	for k: String in m:
		if k in ["txt", "nombre", "desc"]:
			continue
		if k.ends_with("_pct"):
			var base := k.trim_suffix("_pct")
			a.p[base] *= 1.0 + m[k]
		else:
			a.p[k] = a.p.get(k, 0) + m[k]


func dano(a: Arma) -> float:
	return c.stats.atk * c.stats.dano * a.p.dmg * c.mult_dano_jugador()


func tiene_laser_activo(a: Arma) -> bool:
	return a.def.tipo == "laser" and a.activo > 0


# =========================================================================================
# AYUDAS
# =========================================================================================
func _gatillo() -> bool:
	return Ajustes.disparo_auto or Input.is_action_pressed("disparar")


func _recarga(a: Arma) -> float:
	return a.p.cad / c.stats.cadencia


## Vuelve a cargar el arma guardando lo que sobró del cuadro: si no, una recarga de 5,1 cuadros dura 6.
func _rearmar(a: Arma) -> void:
	a.cd = maxf(a.cd, -1.0) + _recarga(a)


func _duracion(a: Arma) -> float:
	return a.p.dur * c.stats.duracion


## Un golpe directo de un arma: aquí se tira el crítico de lo que no es bala.
func _pegar(a: Arma, e, x: float, y: float, mult := 1.0) -> void:
	var d: float = dano(a) * mult
	var crit: bool = a.p.get("siempre_crit", 0) > 0 or randf() < c.stats.crit
	if crit:
		d *= c.stats.crit_dmg
	c.golpear(e, d, crit, x, y)


## Golpea a todo lo que esté en el círculo y devuelve cuántos tocó.
## Con "cada" > 0, "registro" evita que un enemigo reciba más de un golpe cada tantos cuadros.
func _golpear_zona(a: Arma, x: float, y: float, r: float, mult := 1.0, cada := 0, registro = null) -> int:
	var tocados := 0
	var tk: int = c.ticks
	for e in c.enemigos:
		if e.muerto or e.y < -12.0:
			continue
		var rr: float = r + e.def.radio
		var ex: float = e.x - x
		var ey: float = e.y - y
		if ex * ex + ey * ey >= rr * rr:
			continue
		if cada > 0:
			if registro.get(e.id, 0) > tk:
				continue
			registro[e.id] = tk + cada
		_pegar(a, e, e.x, e.y, mult)
		tocados += 1
	return tocados


## ¿Está el enemigo delante de la nave, dentro del radio y del arco? "medio" en radianes; PI es todo el círculo.
func _en_arco(e, x: float, y: float, r: float, medio: float) -> bool:
	var dx: float = e.x - x
	var dy: float = e.y - y
	var d := sqrt(dx * dx + dy * dy)
	if d > r + e.def.radio:
		return false
	if medio >= PI or d < 1.0:
		return true
	var margen := asin(minf(e.def.radio / d, 1.0))
	return absf(wrapf(atan2(dy, dx) + PI / 2.0, -PI, PI)) <= medio + margen


func _borrar_balas(x: float, y: float, r: float, col: Color) -> int:
	var b: int = c.bn - 1
	var borradas := 0
	var r2 := r * r
	while b >= 0:
		var ex: float = c.bx[b] - x
		var ey: float = c.by[b] - y
		if ex * ex + ey * ey < r2:
			c.chispa(c.bx[b], c.by[b], col, 2)
			c.quitar_bala(b)
			borradas += 1
		b -= 1
	return borradas


func _anillo(x: float, y: float, r: float, col: Color, vel := 6.0) -> void:
	anillos.append({"x": x, "y": y, "r": 6.0, "max": r, "v": vel, "c": col})


func _tick_anillos() -> void:
	var i := anillos.size() - 1
	while i >= 0:
		anillos[i].r += anillos[i].v
		if anillos[i].r >= anillos[i].max:
			anillos.remove_at(i)
		i -= 1


## El enemigo que tiene más vecinos cerca: ahí conviene caer. Si hay empate, el más cercano a la nave.
func _centro_de_enemigos(radio: float) -> Vector2:
	var mejor := Vector2(-1.0, -1.0)
	var puntaje := -1.0
	var r2 := radio * radio
	for e in c.enemigos:
		if e.muerto or e.y < 4.0:
			continue
		var vecinos := 0.0
		for o in c.enemigos:
			if not o.muerto and c.dist2(e.x, e.y, o.x, o.y) < r2:
				vecinos += 1.0
		vecinos -= c.dist2(e.x, e.y, c.jx, c.jy) * 0.00001
		if vecinos > puntaje:
			puntaje = vecinos
			mejor = Vector2(e.x, e.y)
	return mejor


# =========================================================================================
# CADA CUADRO
# =========================================================================================
func tick() -> void:
	for a in armas:
		match a.def.tipo:
			"frontal":
				_tick_frontal(a)
			"misil":
				_tick_misil(a)
			"drones":
				_tick_drones(a)
			"aura":
				_tick_aura(a)
			"rayo":
				_tick_rayo(a)
			"sierras":
				_tick_sierras(a)
			"laser":
				_tick_laser(a)
			"escudos":
				_tick_escudos(a)
			"boomerang":
				_tick_boomerang(a)
			"minas":
				_tick_minas(a)
			"zona":
				_tick_zona(a)
			"tajo":
				_tick_tajo(a)
			"francotirador":
				_tick_francotirador(a)
			"tornado":
				_tick_tornado(a)
			"cono":
				_tick_cono(a)
			"onda_hielo":
				_tick_onda_hielo(a)
			"agujero":
				_tick_agujero(a)
			"torreta":
				_tick_torreta(a)
			"rastro":
				_tick_rastro(a)
		if a.golpes.size() > 200:
			a.golpes.clear()
	_tick_anillos()


## Las balas que salen de la nave heredan Aimbot y Wallbang.
func _preparar_tiro(t, a: Arma) -> void:
	t.perfora = int(a.p.get("perfora", 0)) + int(c.stats.perfora)
	var grados: float = c.stats.homing + a.p.get("giro", 0.0)
	if grados > 0.0:
		t.giro = deg_to_rad(grados)
		t.vida = mini(t.vida, VIDA_GIRO)
		t.rotar = true


func _tick_frontal(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd > 0 or not _gatillo():
		return
	_rearmar(a)
	var base_n: int = int(a.def.base.n)
	var propias: int = int(a.p.n)
	var extra: int = int(c.stats.balas)
	var n: int = propias + extra
	var abanico: float = a.p.get("abanico", 0.0)
	var paralelo: float = a.p.get("paralelo", 0.0)
	var disp: float = maxf(a.p.get("dispersion", 0.0), 0.0)
	var expl: float = a.p.get("expl", 0.0) * c.stats.area
	var tx: Texture2D = Datos.tex(a.p.tex)
	var cuadros: int = a.p.get("cuadros", 1)
	var suerte: int = int(a.p.get("dado", 0))
	var vida: int = int(a.p.get("vida", 400))
	var rebote: int = int(a.p.get("rebote", 0)) + int(c.stats.rebote)
	if rebote > 0:
		vida = mini(vida, VIDA_REBOTE)
	var dmg: float = dano(a) * propias * (1.0 + SUMA_BALA_EXTRA * extra) / float(n)
	for i in n:
		var ang := -PI / 2.0
		var ox := 0.0
		var f := 0.0 if n == 1 else float(i) / float(n - 1) - 0.5
		if abanico > 0:
			ang += deg_to_rad(abanico) * f
		elif paralelo > 0:
			ox = paralelo * (1.0 + (n - base_n) * 0.4) * f
			ang += f * deg_to_rad(3.0) * (n - base_n)
		elif n > 1:
			ang += deg_to_rad(7.0 * (n - 1)) * f
		if disp > 0:
			ang += deg_to_rad(randf_range(-disp, disp))
		var cara := -1
		var d := dmg
		if suerte > 0:
			cara = _tirar_dado(suerte)
			d *= DADO[cara]
		var t = c.crear_tiro(c.jx + ox, c.jy - 14, ang, a.p.vel, d, tx, cuadros, a.p.get("siempre_crit", 0) > 0)
		if t == null:
			continue
		t.vida = vida
		_preparar_tiro(t, a)
		t.rebote = rebote
		t.divide = a.p.get("divide", 0) > 0
		t.expl = expl
		t.rehit = int(a.p.get("rehit", 0))
		t.escala = a.p.get("escala", 1.0)
		if cara >= 0:
			# se ve qué tan buena salió: los dados altos son más grandes y los únicos que estallan,
			# y un seis marca su número en dorado
			t.escala = 0.8 + cara * 0.12
			t.expl = expl if cara >= 4 else 0.0
			if cara == 5:
				t.crit = true
	Sonido.tocar(a.p.sfx, randf_range(0.96, 1.05), -2.0, 3)
	c.fogonazo = 3


## Se lanzan tantos dados como "suerte" y vale el mejor.
func _tirar_dado(suerte: int) -> int:
	var mejor := 0
	for k in suerte:
		mejor = maxi(mejor, randi() % DADO.size())
	return mejor


func _tick_misil(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd > 0:
		return
	_rearmar(a)
	var n: int = int(a.p.n)
	for k in n:
		var ang := -PI / 2.0 + (k - (n - 1) / 2.0) * 0.45
		var t = c.crear_tiro(c.jx, c.jy - 8, ang, a.p.vel, dano(a), Datos.tex("obj_misil"), 2, false)
		if t == null:
			continue
		t.vida = VIDA_GIRO
		_preparar_tiro(t, a)
		t.expl = a.p.expl * c.stats.area
		t.rotar = true
	Sonido.tocar("disparo_cohete", 1.1, -3.0)


func _tick_drones(a: Arma) -> void:
	a.ang += 0.05
	a.cd -= 1.0
	if a.cd > 0:
		return
	if c.enemigo_cercano(c.jx, c.jy) == null:
		a.cd = 0.0
		return
	_rearmar(a)
	var n: int = int(a.p.n)
	for k in n:
		var q := pos_orbita(a, k, n, 28.0)
		var ob = c.enemigo_cercano(q.x, q.y)
		if ob == null:
			continue
		var t = c.crear_tiro(q.x, q.y, atan2(ob.y - q.y, ob.x - q.x), a.p.vel, dano(a), Datos.tex("tiro2"), 1, false)
		if t != null:
			_preparar_tiro(t, a)
			t.rotar = true
	Sonido.tocar("disparo", 1.35, -9.0, 4)


func pos_orbita(a: Arma, k: int, n: int, radio: float) -> Vector2:
	var ang: float = a.ang + TAU * k / maxi(n, 1)
	return Vector2(c.jx + cos(ang) * radio, c.jy + sin(ang) * radio)


func radio_aura(a: Arma) -> float:
	return a.p.radio * c.stats.area


func _tick_aura(a: Arma) -> void:
	a.ang += 0.01
	a.cd -= 1.0
	if a.cd > 0:
		return
	_rearmar(a)
	if _golpear_zona(a, c.jx, c.jy, radio_aura(a)) > 0 and a.p.get("cura", 0) > 0:
		c.curar(0.6)


func _tick_rayo(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd > 0:
		return
	var ax: float = c.jx
	var ay: float = c.jy
	var usados := {}
	var ultimo = null
	var pego := 0
	var alcance2: float = a.p.alcance * a.p.alcance
	for k in int(a.p.saltos):
		var ob = c.enemigo_cercano(ax, ay, usados)
		if ob == null or c.dist2(ax, ay, ob.x, ob.y) > alcance2:
			break
		usados[ob.id] = true
		c.rayos.append({"a": Vector2(ax, ay), "b": Vector2(ob.x, ob.y), "t": 8})
		_pegar(a, ob, ob.x, ob.y)
		ax = ob.x
		ay = ob.y
		ultimo = ob
		pego += 1
	if pego == 0:
		a.cd = 0.0
		return
	_rearmar(a)
	# sin nadie más a quien saltar, el resto del rayo cae sobre el último, más débil
	if ultimo != null and not ultimo.muerto:
		for k in int(a.p.saltos) - pego:
			if not ultimo.muerto:
				_pegar(a, ultimo, ultimo.x, ultimo.y, RAYO_REPETIDO)
	Sonido.tocar("impacto", 1.8, 2.0)


func _tick_sierras(a: Arma) -> void:
	a.ang += a.p.giro
	var n: int = int(a.p.n)
	var r: float = a.p.radio * c.stats.area
	var tk: int = c.ticks
	for k in n:
		var q := pos_orbita(a, k, n, r)
		for e in c.enemigos:
			if e.muerto:
				continue
			var rr: float = e.def.radio + 8.0
			# cada sierra lleva su propia cuenta: más sierras, más cortes
			var clave: int = e.id * 8 + k
			if c.dist2(q.x, q.y, e.x, e.y) < rr * rr and a.golpes.get(clave, 0) <= tk:
				a.golpes[clave] = tk + int(_recarga(a))
				_pegar(a, e, q.x, q.y)
				Sonido.tocar("impacto", 0.75, -6.0, 3)
		if a.p.get("corta", 0) > 0:
			var b: int = c.bn - 1
			while b >= 0:
				if c.dist2(q.x, q.y, c.bx[b], c.by[b]) < 100.0:
					c.chispa(c.bx[b], c.by[b], Color.WHITE, 2)
					c.quitar_bala(b)
				b -= 1


func _tick_laser(a: Arma) -> void:
	if a.activo > 0:
		a.activo -= 1.0
		tick_laser += 1
		if tick_laser % 5 == 0:
			var ancho: float = a.p.ancho * c.stats.area
			for e in c.enemigos:
				if e.muerto or e.y > c.jy:
					continue
				if absf(e.x - c.jx) < ancho + e.def.radio:
					_pegar(a, e, e.x, e.y + 6.0)
		return
	a.cd -= 1.0
	if a.cd <= 0:
		_rearmar(a)
		a.activo = _duracion(a)
		Sonido.tocar("disparo_riel", 1.4, -4.0)


# =========================================================================================
# FIREWALL: el Aegis. Escudos que frenan golpes, lanzan una onda y vuelven de a uno.
# =========================================================================================
func _tick_escudos(a: Arma) -> void:
	a.ang += 0.045
	if a.cargas >= int(a.p.n):
		return
	a.recarga -= 1.0
	if a.recarga <= 0:
		a.cargas += 1
		a.recarga = a.p.recarga / c.stats.cadencia
		c.chispa(c.jx, c.jy - 26.0, UI.C_CIAN, 8)
		Sonido.tocar("racha", 1.5, -4.0)


## Lo llama el combate al principio de _recibir_dano. Si devuelve true, ese golpe no hizo daño.
func absorber_golpe() -> bool:
	for a in armas:
		if a.def.tipo == "escudos" and a.cargas > 0:
			_bloquear(a)
			return true
	return false


func _bloquear(a: Arma) -> void:
	if a.cargas >= int(a.p.n):
		a.recarga = a.p.recarga / c.stats.cadencia
	a.cargas -= 1
	var r: float = a.p.radio_onda * c.stats.area
	_golpear_zona(a, c.jx, c.jy, r)
	# la onda aparta a los que estaban encima
	for e in c.enemigos:
		if e.muerto:
			continue
		var d := Vector2(e.x - c.jx, e.y - c.jy)
		var rr: float = r + e.def.radio
		if d.length_squared() < rr * rr and d.length_squared() > 1.0:
			var dir := d.normalized()
			c.empujar(e, dir.x * 16.0, dir.y * 16.0)
	if a.p.get("borra", 0) > 0:
		_borrar_balas(c.jx, c.jy, r, UI.C_CIAN)
	_anillo(c.jx, c.jy, r, UI.C_ROJO if a.evo else UI.C_CIAN)
	c.sacudir(4.0)
	c.texto(c.jx, c.jy - 26.0, "¡BLOQUEADO!", UI.C_CIAN, 1)
	Sonido.tocar("impacto", 0.6, 4.0)


# =========================================================================================
# ROLLBACK: sale frenando, se da vuelta y vuelve a la nave. Pega una vez a la ida y otra a la vuelta.
# =========================================================================================
func _tick_boomerang(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd <= 0 and _gatillo():
		_rearmar(a)
		var n: int = int(a.p.n)
		var v: float = a.p.vel * c.stats.vel_tiro
		for k in n:
			var f := 0.0 if n == 1 else float(k) / float(n - 1) - 0.5
			var ang := -PI / 2.0 + deg_to_rad(11.0 * (n - 1)) * f
			var o := Objeto.new()
			o.x = c.jx
			o.y = c.jy - 10.0
			o.vx = cos(ang) * v
			o.vy = sin(ang) * v
			# frenado justo para detenerse al llegar a su rango
			o.cd = v * v / (2.0 * a.p.rango)
			a.objs.append(o)
		Sonido.tocar("dash", 1.7, -9.0, 4)
	var i: int = a.objs.size() - 1
	while i >= 0:
		var o: Objeto = a.objs[i]
		o.t += 1.0
		if _mover_boomerang(a, o):
			a.objs.remove_at(i)
		i -= 1


## Devuelve true cuando el boomerang volvió a la nave.
func _mover_boomerang(a: Arma, o: Objeto) -> bool:
	var rap := Vector2(o.vx, o.vy).length()
	if o.fase == 0:
		var nueva: float = rap - o.cd
		if nueva <= 0.3:
			o.fase = 1
			o.golpes.clear()
			o.vx = 0.0
			o.vy = 0.0
		else:
			o.vx *= nueva / rap
			o.vy *= nueva / rap
	else:
		var dest := Vector2(c.jx, c.jy)
		if a.p.get("persigue", 0) > 0 and o.n < 2:
			if o.blanco == null or o.blanco.muerto or o.golpes.has(o.blanco.id):
				o.blanco = c.enemigo_cercano(o.x, o.y, o.golpes)
				if o.blanco != null and c.dist2(o.x, o.y, o.blanco.x, o.blanco.y) > 170.0 * 170.0:
					o.blanco = null
			if o.blanco != null:
				dest = Vector2(o.blanco.x, o.blanco.y)
		var hacia := dest - Vector2(o.x, o.y)
		var tope: float = a.p.vel * c.stats.vel_tiro * 1.25
		var dir := hacia.normalized()
		rap = minf(rap + o.cd, tope)
		o.vx = lerpf(o.vx, dir.x * rap, 0.3)
		o.vy = lerpf(o.vy, dir.y * rap, 0.3)
		if o.t > 420.0 or (o.blanco == null and hacia.length_squared() < 196.0):
			return true
	o.x += o.vx
	o.y += o.vy
	for e in c.enemigos:
		if e.muerto or e.y < -12.0 or o.golpes.has(e.id):
			continue
		var rr: float = e.def.radio + 7.0
		if c.dist2(o.x, o.y, e.x, e.y) < rr * rr:
			o.golpes[e.id] = true
			_pegar(a, e, e.x, e.y)
			if e == o.blanco:
				o.n += 1
				o.blanco = null
	return false


# =========================================================================================
# SPAWN TRAP: minas que se lanzan adelante y esperan a que alguien pase.
# =========================================================================================
func _tick_minas(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd <= 0.0:
		if _minas_grandes(a) < int(a.p.max):
			_rearmar(a)
			_lanzar_mina(a)
		else:
			a.cd = 12.0
	var nuevas := []
	var i: int = a.objs.size() - 1
	while i >= 0:
		var o: Objeto = a.objs[i]
		o.t += 1.0
		var estalla := false
		if o.fase == 0:
			var u := o.t / o.dur
			o.x = lerpf(o.ox, o.dx, u)
			o.y = lerpf(o.oy, o.dy, u)
			if u >= 1.0:
				o.fase = 1
				o.t = 0.0
		else:
			# una mina vieja revienta sola, y las chicas antes: el campo no se queda lleno
			estalla = o.t > (240.0 if o.hija else 660.0)
			if not estalla:
				for e in c.enemigos:
					if e.muerto or e.y < -12.0:
						continue
					var rr: float = 9.0 + e.def.radio
					if c.dist2(o.x, o.y, e.x, e.y) < rr * rr:
						estalla = true
						break
		if estalla:
			_estallar_mina(a, o, nuevas)
			a.objs.remove_at(i)
		i -= 1
	a.objs.append_array(nuevas)


func _minas_grandes(a: Arma) -> int:
	var n := 0
	for o in a.objs:
		if not o.hija:
			n += 1
	return n


## Cae sobre el enemigo más cercano, con algo de error; si no hay nadie, en cualquier parte de adelante.
func _lanzar_mina(a: Arma) -> void:
	var ob = c.enemigo_cercano(c.jx, c.jy)
	var dest := Vector2(c.jx + randf_range(-70.0, 70.0), c.jy - randf_range(60.0, 170.0))
	if ob != null:
		dest = Vector2(ob.x + randf_range(-16.0, 16.0), ob.y + randf_range(-10.0, 22.0))
	_crear_mina(a, c.jx, c.jy - 8.0, dest, false)
	Sonido.tocar("disparo_grueso", 1.5, -8.0, 4)


func _crear_mina(a: Arma, x: float, y: float, dest: Vector2, hija: bool) -> Objeto:
	var o := Objeto.new()
	o.ox = x
	o.oy = y
	o.x = x
	o.y = y
	o.dx = clampf(dest.x, 10.0, c.ANCHO - 10.0)
	o.dy = clampf(dest.y, 10.0, c.ALTO - 10.0)
	o.dur = clampf(Vector2(o.dx - x, o.dy - y).length() / 5.5, 8.0, 36.0)
	o.hija = hija
	if not hija:
		a.objs.append(o)
	return o


func _estallar_mina(a: Arma, o: Objeto, nuevas: Array) -> void:
	var r: float = a.p.expl * c.stats.area * (0.7 if o.hija else 1.0)
	_golpear_zona(a, o.x, o.y, r, 0.5 if o.hija else 1.0)
	c.explosion(o.x, o.y, "expl_chica" if r < 40.0 else "expl_media")
	Sonido.tocar("kill", 1.3, -5.0, 3)
	if o.hija:
		return
	var racimo: int = int(a.p.get("racimo", 0))
	for k in racimo:
		var ang := TAU * k / maxi(racimo, 1) + randf() * 0.6
		var dest := Vector2(o.x + cos(ang) * r * 1.5, o.y + sin(ang) * r * 1.5)
		nuevas.append(_crear_mina(a, o.x, o.y, dest, true))


# =========================================================================================
# MOLOTOV: la botella vuela al enemigo y deja fuego en el suelo. El fuego no se acumula:
# un enemigo recibe un golpe cada tanto, aunque esté en dos fuegos.
# =========================================================================================
func _tick_zona(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd <= 0.0:
		var ob = c.enemigo_cercano(c.jx, c.jy)
		if ob == null:
			a.cd = 0.0
		else:
			_rearmar(a)
			var usados := {}
			for k in int(a.p.n):
				var e = c.enemigo_cercano(c.jx, c.jy, usados)
				if e == null:
					e = ob
				usados[e.id] = true
				var o := Objeto.new()
				o.x = c.jx
				o.y = c.jy - 8.0
				o.ox = o.x
				o.oy = o.y
				o.dx = e.x
				o.dy = e.y
				o.dur = clampf(Vector2(e.x - c.jx, e.y - c.jy).length() / 4.5, 14.0, 44.0)
				a.objs.append(o)
			Sonido.tocar("disparo_grueso", 1.7, -8.0, 4)
	var i: int = a.objs.size() - 1
	while i >= 0:
		var o: Objeto = a.objs[i]
		o.t += 1.0
		if o.fase == 0:
			var u := o.t / o.dur
			o.x = lerpf(o.ox, o.dx, u)
			o.y = lerpf(o.oy, o.dy, u)
			o.rot += 0.3
			if u >= 1.0:
				o.fase = 1
				o.t = 0.0
				o.dur = _duracion(a)
				o.radio = a.p.radio * c.stats.area
				c.chispa(o.x, o.y, Color("ffb04a"), 8)
				Sonido.tocar("kill", 0.8, -6.0, 3)
		else:
			if o.t >= o.dur:
				a.objs.remove_at(i)
			else:
				_golpear_zona(a, o.x, o.y, o.radio, 1.0, int(a.p.golpe), a.golpes)
		i -= 1


# =========================================================================================
# RUSH B: un corte enorme por delante. Solo se lanza si hay alguien al alcance.
# =========================================================================================
func _tick_tajo(a: Arma) -> void:
	if a.fx > 0:
		a.fx -= 1
	a.cd -= 1.0
	if a.cd > 0.0 or not _gatillo():
		return
	var r: float = a.p.radio * c.stats.area
	var medio: float = deg_to_rad(a.p.arco) / 2.0
	var pego := false
	for e in c.enemigos:
		if e.muerto or e.y < -12.0:
			continue
		if _en_arco(e, c.jx, c.jy, r, medio):
			_pegar(a, e, e.x, e.y)
			pego = true
	if not pego:
		a.cd = 0.0
		return
	_rearmar(a)
	a.fx = 12
	a.lado = -a.lado
	if a.p.get("rompe", 0) > 0:
		_borrar_balas(c.jx, c.jy, r * 0.65, Color.WHITE)
	Sonido.tocar("dash", 1.15, -2.0, 3)


# =========================================================================================
# QUICKSCOPE: fija la mira en el enemigo con más vida y, un instante después, dispara.
# =========================================================================================
func _tick_francotirador(a: Arma) -> void:
	var i: int = a.objs.size() - 1
	while i >= 0:
		a.objs[i].t += 1.0
		if a.objs[i].t >= a.objs[i].dur:
			a.objs.remove_at(i)
		i -= 1
	a.cd -= 1.0
	if a.cd > MIRA_QUICKSCOPE:
		return
	if a.marcados.is_empty():
		a.marcados = _mas_vida(int(a.p.n))
		if a.marcados.is_empty():
			a.cd = MIRA_QUICKSCOPE
			return
	# si se le murió el blanco antes del disparo, busca otro
	for k in a.marcados.size():
		if a.marcados[k].muerto:
			var otros := _mas_vida(int(a.p.n))
			a.marcados = otros
			break
	if a.marcados.is_empty():
		a.cd = MIRA_QUICKSCOPE
		return
	if a.cd > 0.0:
		return
	_rearmar(a)
	for e in a.marcados:
		_pegar(a, e, e.x, e.y)
		var o := Objeto.new()
		o.x = c.jx
		o.y = c.jy - 12.0
		o.dx = e.x
		o.dy = e.y
		o.dur = 8.0
		a.objs.append(o)
		c.chispa(e.x, e.y, UI.C_ORO, 8)
	a.marcados = []
	Sonido.tocar("disparo_riel", 1.25, 0.0)


func _mas_vida(n: int) -> Array:
	var lista := []
	for e in c.enemigos:
		if not e.muerto and e.y > 0.0:
			lista.append(e)
	lista.sort_custom(func(p, q): return p.hp > q.hp)
	return lista.slice(0, n)


# =========================================================================================
# SPIN TO WIN: remolinos que vagan hacia los enemigos.
# =========================================================================================
func _tick_tornado(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd <= 0.0:
		if c.enemigo_cercano(c.jx, c.jy) == null:
			a.cd = 0.0
		else:
			_rearmar(a)
			var n: int = int(a.p.n)
			for k in n:
				var o := Objeto.new()
				o.x = c.jx + (k - (n - 1) / 2.0) * 22.0
				o.y = c.jy - 16.0
				o.vy = -VEL_TORNADO
				o.dur = _duracion(a)
				o.radio = a.p.radio * c.stats.area
				o.rot = randf() * TAU
				a.objs.append(o)
			Sonido.tocar("dash", 0.7, -6.0, 4)
	var i: int = a.objs.size() - 1
	while i >= 0:
		var o: Objeto = a.objs[i]
		o.t += 1.0
		if o.t >= o.dur:
			a.objs.remove_at(i)
			i -= 1
			continue
		var ob = c.enemigo_cercano(o.x, o.y)
		var deseo := Vector2(cos(o.t * 0.06 + o.rot), sin(o.t * 0.05 + o.rot)) * 0.6
		if ob != null:
			var hacia := Vector2(ob.x - o.x, ob.y - o.y)
			if hacia.length() > 3.0:
				deseo += hacia.normalized()
		deseo = deseo.limit_length(1.0) * VEL_TORNADO
		o.vx = lerpf(o.vx, deseo.x, 0.05)
		o.vy = lerpf(o.vy, deseo.y, 0.05)
		o.x = clampf(o.x + o.vx, 10.0, c.ANCHO - 10.0)
		o.y = clampf(o.y + o.vy, 10.0, c.ALTO - 10.0)
		if _golpear_zona(a, o.x, o.y, o.radio, 1.0, int(a.p.golpe), o.golpes) > 0:
			Sonido.tocar("impacto", 0.9, -11.0, 6)
		if a.p.get("aspira", 0) > 0:
			var r2: float = (o.radio * 3.5) * (o.radio * 3.5)
			for g in c.gemas:
				if not g.imantada and c.dist2(o.x, o.y, g.x, g.y) < r2:
					g.imantada = true
		i -= 1


# =========================================================================================
# RAGEQUIT: lanzallamas corto. Prende solo cuando hay alguien adelante.
# =========================================================================================
func alcance_cono(a: Arma) -> float:
	return a.p.alcance * c.stats.area * (1.4 if _con_furia(a) else 1.0)


func _con_furia(a: Arma) -> bool:
	return a.p.get("furia", 0) > 0 and c.hp < c.stats.hp * 0.4


func _tick_cono(a: Arma) -> void:
	if a.fx > 0:
		a.fx -= 1
	a.cd -= 1.0
	if a.cd > 0.0 or not _gatillo():
		return
	var r := alcance_cono(a)
	var medio: float = deg_to_rad(a.p.abanico) / 2.0
	var mult := 1.5 if _con_furia(a) else 1.0
	var pego := false
	for e in c.enemigos:
		if e.muerto or e.y < -12.0:
			continue
		if _en_arco(e, c.jx, c.jy - 12.0, r, medio):
			_pegar(a, e, e.x, e.y, mult)
			pego = true
	if not pego:
		a.cd = 0.0
		return
	_rearmar(a)
	a.fx = 14
	Sonido.tocar("dash", 0.55, -10.0, 8)


# =========================================================================================
# FRAME DROP: un anillo de hielo sale de la nave. Daña y frena al pasar.
# =========================================================================================
func _tick_onda_hielo(a: Arma) -> void:
	a.cd -= 1.0
	var r_max: float = a.p.radio * c.stats.area
	if a.cd <= 0.0:
		var ob = c.enemigo_cercano(c.jx, c.jy)
		if ob == null or c.dist2(c.jx, c.jy, ob.x, ob.y) > (r_max + ob.def.radio) * (r_max + ob.def.radio):
			a.cd = 0.0
		else:
			_rearmar(a)
			var o := Objeto.new()
			o.x = c.jx
			o.y = c.jy
			o.dur = r_max
			a.objs.append(o)
			Sonido.tocar("roce", 0.55, 2.0, 4)
	var i: int = a.objs.size() - 1
	while i >= 0:
		var o: Objeto = a.objs[i]
		var antes := o.radio
		o.radio += VEL_ONDA
		for e in c.enemigos:
			if e.muerto or e.y < -12.0 or o.golpes.has(e.id):
				continue
			var rr: float = o.radio + e.def.radio
			if c.dist2(o.x, o.y, e.x, e.y) < rr * rr:
				o.golpes[e.id] = true
				_pegar(a, e, e.x, e.y)
				c.frenar_enemigo(e, a.p.lento, a.p.lento_dur * c.stats.duracion)
		if a.p.get("balas", 0) > 0:
			_frenar_balas(o.x, o.y, antes, o.radio)
		if o.radio >= o.dur:
			a.objs.remove_at(i)
		i -= 1


## Frena las balas que el anillo acaba de cruzar: cada bala se cruza una sola vez.
func _frenar_balas(x: float, y: float, r0: float, r1: float) -> void:
	var a2 := r0 * r0
	var b2 := r1 * r1
	for b in c.bn:
		var d: float = c.dist2(x, y, c.bx[b], c.by[b])
		if d >= a2 and d < b2 and c.bvx[b] * c.bvx[b] + c.bvy[b] * c.bvy[b] > 0.64:
			c.bvx[b] *= 0.5
			c.bvy[b] *= 0.5


# =========================================================================================
# PACKET LOSS: un agujero que atrae enemigos y se traga las balas de cerca.
# =========================================================================================
func _tick_agujero(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd <= 0.0:
		var r: float = a.p.radio * c.stats.area
		var q := _centro_de_enemigos(r)
		if q.x < 0.0:
			a.cd = 0.0
		else:
			_rearmar(a)
			var o := Objeto.new()
			o.x = clampf(q.x, 20.0, c.ANCHO - 20.0)
			o.y = clampf(q.y, 20.0, c.ALTO - 40.0)
			o.dur = _duracion(a)
			o.radio = r
			a.objs.append(o)
			Sonido.tocar("reconectar", 0.7, -8.0, 4)
	var i: int = a.objs.size() - 1
	while i >= 0:
		var o: Objeto = a.objs[i]
		o.t += 1.0
		for e in c.enemigos:
			if e.muerto:
				continue
			var d := Vector2(o.x - e.x, o.y - e.y)
			var rr: float = o.radio + e.def.radio
			var l2 := d.length_squared()
			if l2 < rr * rr and l2 > 4.0:
				var l := sqrt(l2)
				var fuerza := lerpf(1.3, 0.35, minf(l / rr, 1.0))
				c.empujar(e, d.x / l * fuerza, d.y / l * fuerza)
		_golpear_zona(a, o.x, o.y, o.radio * 0.7, 1.0, int(a.p.golpe), o.golpes)
		o.n += _borrar_balas(o.x, o.y, o.radio * 0.5, Color("c9a0ff"))
		if o.t >= o.dur:
			if a.p.get("explota", 0) > 0:
				_golpear_zona(a, o.x, o.y, o.radio, 4.0 + minf(o.n * 0.5, 8.0))
				c.explosion(o.x, o.y, "expl_media")
				_anillo(o.x, o.y, o.radio, Color("c9a0ff"))
				c.sacudir(3.0)
				Sonido.tocar("kill_grande", 1.2, -3.0, 3)
			a.objs.remove_at(i)
		i -= 1


# =========================================================================================
# AFK FARMER: torretas que se quedan donde las dejas y disparan solas.
# =========================================================================================
func _tick_torreta(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd <= 0.0:
		_rearmar(a)
		while a.objs.size() >= int(a.p.max):
			var vieja: Objeto = a.objs.pop_front()
			c.chispa(vieja.x, vieja.y, UI.C_CIAN, 5)
		var o := Objeto.new()
		o.x = c.jx
		o.y = c.jy + 4.0
		o.dur = _duracion(a)
		o.rot = -PI / 2.0
		o.cd = 12.0
		a.objs.append(o)
		Sonido.tocar("ui_ok", 0.7, -6.0, 4)
	var i: int = a.objs.size() - 1
	while i >= 0:
		var o: Objeto = a.objs[i]
		o.t += 1.0
		o.cd -= 1.0
		if o.t >= o.dur:
			c.chispa(o.x, o.y, UI.C_CIAN, 5)
			a.objs.remove_at(i)
			i -= 1
			continue
		if o.blanco != null and o.blanco.muerto:
			# Bot Farm: lo que mata tu torreta deja chatarra
			if a.p.get("chatarra", 0) > 0 and o.blanco.hp <= 0.0:
				c.chatarra += 1
				c.chispa(o.blanco.x, o.blanco.y, UI.C_ORO, 4)
			o.blanco = null
		if o.blanco == null:
			o.blanco = c.enemigo_cercano(o.x, o.y)
		if o.blanco != null:
			o.rot = atan2(o.blanco.y - o.y, o.blanco.x - o.x)
			if o.cd <= 0.0:
				o.cd = a.p.disparo / c.stats.cadencia
				o.n = 6
				var t = c.crear_tiro(o.x, o.y, o.rot, a.p.vel, dano(a), Datos.tex("tiro2"), 1, false)
				if t != null:
					_preparar_tiro(t, a)
					t.rotar = true
				Sonido.tocar("disparo", 1.5, -11.0, 4)
		if o.n > 0:
			o.n -= 1
		i -= 1


# =========================================================================================
# SPEEDHACK: fuego por donde pasas. El fuego sube, así que se usa moviéndose de lado a lado.
# =========================================================================================
func _tick_rastro(a: Arma) -> void:
	a.cd -= 1.0
	if a.cd <= 0.0 and c.dist2(c.jx, c.jy, a.px, a.py) > 49.0:
		a.cd = float(a.p.paso)
		a.px = c.jx
		a.py = c.jy
		var o := Objeto.new()
		o.x = c.jx + randf_range(-2.0, 2.0)
		o.y = c.jy + 6.0
		o.dur = _duracion(a)
		o.radio = a.p.radio * c.stats.area
		a.objs.append(o)
	var i: int = a.objs.size() - 1
	while i >= 0:
		var o: Objeto = a.objs[i]
		o.t += 1.0
		o.y -= a.p.sube
		if o.t >= o.dur:
			a.objs.remove_at(i)
		else:
			_golpear_zona(a, o.x, o.y, o.radio, 1.0, int(a.p.golpe), a.golpes)
		i -= 1


## Lo llama el combate al empezar una esquiva.
func al_esquivar() -> void:
	for a in armas:
		if a.def.tipo == "rastro" and a.p.get("dash_expl", 0) > 0:
			var r: float = 44.0 * c.stats.area
			_golpear_zona(a, c.jx, c.jy, r, 5.0)
			c.explosion(c.jx, c.jy, "expl_media")
			_anillo(c.jx, c.jy, r, Color("ffb04a"))
			c.sacudir(3.0)
			Sonido.tocar("kill", 1.1, -2.0, 3)


# =========================================================================================
# DIBUJO
# =========================================================================================
## Dibuja un cuadro de una hoja horizontal. Se corta con el tamaño de cuadro que dice el contrato.
func _cuadro(cv: CanvasItem, nombre: String, w: int, h: int, f: int, x: float, y: float, esc := 1.0, rot := 0.0, mod := Color.WHITE) -> void:
	var tx: Texture2D = Datos.tex(nombre)
	var fuente := Rect2(f * w, 0, w, h)
	if esc == 1.0 and rot == 0.0:
		cv.draw_texture_rect_region(tx, Rect2(round(x - w / 2.0), round(y - h / 2.0), w, h), fuente, mod)
		return
	cv.draw_set_transform(Vector2(round(x), round(y)), rot, Vector2(esc, esc))
	cv.draw_texture_rect_region(tx, Rect2(-w / 2.0, -h / 2.0, w, h), fuente, mod)
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func dibujar_detras(cv: CanvasItem) -> void:
	for a in armas:
		match a.def.tipo:
			"laser":
				_dib_laser(cv, a)
			"aura":
				_dib_aura(cv, a)
			"minas":
				_dib_minas(cv, a)
			"zona":
				_dib_fuegos(cv, a)
			"tajo":
				_dib_tajo(cv, a)
			"francotirador":
				_dib_trazas(cv, a)
			"tornado":
				_dib_tornados(cv, a)
			"cono":
				_dib_cono(cv, a)
			"onda_hielo":
				_dib_onda(cv, a)
			"agujero":
				_dib_agujeros(cv, a)
			"torreta":
				_dib_torretas(cv, a)
			"rastro":
				_dib_rastro(cv, a)
	for an in anillos:
		var col: Color = an.c
		col.a = 0.75 * (1.0 - an.r / an.max)
		cv.draw_arc(Vector2(an.x, an.y), an.r, 0.0, TAU, 40, col, 2.0)


func dibujar_frente(cv: CanvasItem) -> void:
	if not c.vivo:
		return
	for a in armas:
		match a.def.tipo:
			"drones":
				var tx: Texture2D = Datos.tex("obj_dron")
				var n: int = int(a.p.n)
				for k in n:
					var q := pos_orbita(a, k, n, 28.0)
					cv.draw_texture(tx, Vector2(round(q.x) - 7, round(q.y) - 7))
			"sierras":
				var tx: Texture2D = Datos.tex("obj_sierra_evo" if a.evo else "obj_sierra")
				var n: int = int(a.p.n)
				var r: float = a.p.radio * c.stats.area
				var fr: int = (c.ticks / 3) % 4
				for k in n:
					var q := pos_orbita(a, k, n, r)
					cv.draw_texture_rect_region(tx, Rect2(round(q.x) - 9, round(q.y) - 9, 18, 18), Rect2(fr * 18, 0, 18, 18))
			"escudos":
				_dib_escudos(cv, a)
			"boomerang":
				var mod := Color(1.5, 1.2, 0.6) if a.evo else Color.WHITE
				for o in a.objs:
					_cuadro(cv, "tiro_boomerang", 16, 16, (c.ticks / 3) % 4, o.x, o.y, 1.0, 0.0, mod)
			"zona":
				for o in a.objs:
					if o.fase == 0:
						_cuadro(cv, "obj_molotov", 10, 14, 0, o.x, o.y - sin(o.t / o.dur * PI) * 22.0, 1.0, o.rot)
			"minas":
				for o in a.objs:
					if o.fase == 0:
						_cuadro(cv, "obj_mina", 14, 14, 0, o.x, o.y - sin(o.t / o.dur * PI) * 16.0, 0.7 if o.hija else 1.0)
			"francotirador":
				_dib_miras(cv, a)


func _dib_laser(cv: CanvasItem, a: Arma) -> void:
	if a.activo <= 0:
		return
	var ancho: float = a.p.ancho * c.stats.area
	var y1: float = round(c.jy) - 18.0
	var x0: float = round(c.jx)
	var pulso := 1.0 + (1.0 if c.ticks % 6 < 3 else 0.0)
	cv.draw_rect(Rect2(x0 - ancho - pulso, 0, ancho * 2 + pulso * 2, y1), Color(1, 0.3, 0.65, 0.55))
	cv.draw_rect(Rect2(x0 - ancho * 0.5, 0, ancho, y1), Color(1, 0.85, 0.95))


func _dib_aura(cv: CanvasItem, a: Arma) -> void:
	var r := radio_aura(a)
	var n := int(r * 0.9)
	var col: Color = UI.C_ORO if a.evo else Color("7ee850")
	var centro := Vector2(round(c.jx), round(c.jy))
	cv.draw_circle(centro, r, Color(col.r, col.g, col.b, 0.07))
	for k in n:
		var ang: float = TAU * k / n + a.ang
		cv.draw_rect(Rect2(round(c.jx + cos(ang) * r), round(c.jy + sin(ang) * r), 2, 2), col)


func _dib_minas(cv: CanvasItem, a: Arma) -> void:
	for o in a.objs:
		if o.fase == 1:
			# laten más rápido cuando les queda poco
			var ritmo := 6 if o.t > 480.0 else 14
			_cuadro(cv, "obj_mina", 14, 14, (c.ticks / ritmo) % 2, o.x, o.y, 0.7 if o.hija else 1.0)


## Llamas repartidas en un círculo, más planas de alto, como si estuvieran en el suelo.
func _dib_fuegos(cv: CanvasItem, a: Arma) -> void:
	for o in a.objs:
		if o.fase != 1:
			continue
		var alfa := clampf((o.dur - o.t) / 24.0, 0.0, 1.0) * clampf(o.t / 8.0, 0.0, 1.0)
		var centro := Vector2(round(o.x), round(o.y))
		cv.draw_circle(centro, o.radio, Color(1.0, 0.42, 0.1, 0.16 * alfa))
		cv.draw_arc(centro, o.radio, 0.0, TAU, 32, Color(1.0, 0.6, 0.2, 0.35 * alfa), 1.0)
		var n := int(o.radio * o.radio / 110.0) + 2
		var mod := Color(1, 1, 1, 0.75 * alfa)
		for k in n:
			var ang := k * 2.39996
			var d: float = o.radio * sqrt((k + 0.5) / n) * 0.9
			_cuadro(cv, "obj_llama", 14, 14, (c.ticks / 5 + k) % 4, o.x + cos(ang) * d, o.y + sin(ang) * d * 0.85 - 3.0, 1.0, 0.0, mod)


## El dibujo del corte es un arco de 64 de ancho y 24 de alto (de y=12 a y=36 en su cuadro de 64x40).
## Se estira para que calce justo con el alcance real del golpe.
func _dib_tajo(cv: CanvasItem, a: Arma) -> void:
	if a.fx <= 0:
		return
	var r: float = a.p.radio * c.stats.area
	var f: int = clampi((12 - a.fx) / 4, 0, 2)
	var mod := Color(1, 1, 1, clampf(a.fx / 5.0, 0.0, 1.0))
	var tx: Texture2D = Datos.tex("fx_tajo")
	var fuente := Rect2(f * 64, 0, 64, 40)
	# con arco completo, tres cortes de 120 grados giran alrededor de la nave
	var veces := 3 if a.p.arco >= 300.0 else 1
	var medio: float = deg_to_rad(a.p.arco / veces) / 2.0
	var cuerda: float = 2.0 * r * sin(medio)
	var flecha: float = r * (1.0 - cos(medio))
	var base: float = r * cos(medio)
	var esc := Vector2(cuerda / 64.0 * a.lado, flecha / 24.0)
	for k in veces:
		var rot: float = TAU * k / veces + (c.ticks * 0.1 if veces > 1 else 0.0)
		var pos := Vector2(round(c.jx), round(c.jy)) + Vector2(0.0, -base).rotated(rot)
		cv.draw_set_transform(pos, rot, esc)
		cv.draw_texture_rect_region(tx, Rect2(-32.0, -36.0, 64.0, 40.0), fuente, mod)
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _dib_trazas(cv: CanvasItem, a: Arma) -> void:
	for o in a.objs:
		var alfa: float = 1.0 - o.t / o.dur
		var col: Color = UI.C_ORO
		col.a = alfa
		cv.draw_line(Vector2(o.x, o.y), Vector2(o.dx, o.dy), col, 2.0)
		cv.draw_line(Vector2(o.x, o.y), Vector2(o.dx, o.dy), Color(1, 1, 1, alfa), 1.0)


## La mira sobre el blanco: cuatro esquinas que se cierran hasta el disparo.
func _dib_miras(cv: CanvasItem, a: Arma) -> void:
	if a.marcados.is_empty():
		return
	var u := clampf(a.cd / MIRA_QUICKSCOPE, 0.0, 1.0)
	var col: Color = UI.C_ORO
	for e in a.marcados:
		var r: float = e.def.radio + 4.0 + u * 14.0
		var x: float = round(e.x)
		var y: float = round(e.y)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var q := Vector2(x + sx * r, y + sy * r)
				cv.draw_line(q, q - Vector2(sx * 5.0, 0.0), col, 1.0)
				cv.draw_line(q, q - Vector2(0.0, sy * 5.0), col, 1.0)
		cv.draw_rect(Rect2(x - 1.0, y - 1.0, 2.0, 2.0), col)


func _dib_tornados(cv: CanvasItem, a: Arma) -> void:
	for o in a.objs:
		var alfa := clampf((o.dur - o.t) / 20.0, 0.0, 1.0)
		_cuadro(cv, "obj_tornado", 28, 28, (c.ticks / 3) % 4, o.x, o.y, o.radio / 14.0, 0.0, Color(1, 1, 1, 0.9 * alfa))


## Un chorro de llamas: nacen chicas en la punta de la nave y crecen mientras se apagan.
func _dib_cono(cv: CanvasItem, a: Arma) -> void:
	if a.fx <= 0:
		return
	var r := alcance_cono(a)
	var medio: float = deg_to_rad(a.p.abanico) / 2.0
	var x0: float = c.jx
	var y0: float = c.jy - 12.0
	var n := int(r / 3.0)
	var furia := _con_furia(a)
	var tinte := Color(1.0, 0.7, 0.7) if furia else Color.WHITE
	var origen := Vector2(x0, y0)
	var cuna := PackedVector2Array([origen])
	for k in 9:
		var ang_k: float = -PI / 2.0 + medio * (k / 4.0 - 1.0)
		cuna.append(origen + Vector2(cos(ang_k), sin(ang_k)) * r)
	cv.draw_colored_polygon(cuna, Color(1.0, 0.45, 0.1, 0.1 * a.fx / 14.0))
	for k in n:
		var u := fposmod(c.ticks * 0.045 + k * 0.618, 1.0)
		var ang := -PI / 2.0 + medio * sin(k * 12.9898)
		var d := r * u
		var col := tinte
		col.a = 0.9 * (1.0 - u * u)
		_cuadro(cv, "obj_llama", 14, 14, (c.ticks / 4 + k) % 4, x0 + cos(ang) * d, y0 + sin(ang) * d, 0.4 + u * 0.9, 0.0, col)


func _dib_onda(cv: CanvasItem, a: Arma) -> void:
	for o in a.objs:
		var u: float = o.radio / o.dur
		var centro := Vector2(round(o.x), round(o.y))
		cv.draw_arc(centro, o.radio, 0.0, TAU, 56, Color(0.6, 0.9, 1.0, 0.6 * (1.0 - u * u)), 2.0)
		var n := maxi(int(TAU * o.radio / 26.0), 6)
		var mod := Color(1, 1, 1, 1.0 - u * u * u)
		for k in n:
			var ang := TAU * k / n + u * 1.5
			_cuadro(cv, "tiro_hielo", 12, 12, (c.ticks / 5 + k) % 2, o.x + cos(ang) * o.radio, o.y + sin(ang) * o.radio, 1.0, 0.0, mod)


func _dib_agujeros(cv: CanvasItem, a: Arma) -> void:
	for o in a.objs:
		# se abre y se cierra rápido
		var u := clampf(minf(o.t, o.dur - o.t) / 14.0, 0.0, 1.0)
		var centro := Vector2(round(o.x), round(o.y))
		var morado := Color(0.55, 0.3, 1.0, 0.35 * u)
		var r_vista: float = o.radio * (1.0 - fposmod(c.ticks * 0.02, 0.35))
		cv.draw_arc(centro, r_vista, 0.0, TAU, 40, morado, 1.0)
		cv.draw_arc(centro, o.radio, 0.0, TAU, 40, Color(0.55, 0.3, 1.0, 0.22 * u), 1.0)
		_cuadro(cv, "obj_agujero", 40, 40, (c.ticks / 4) % 4, o.x, o.y, u * o.radio * 0.5 / 20.0 * 1.4)


func _dib_torretas(cv: CanvasItem, a: Arma) -> void:
	for o in a.objs:
		# parpadea cuando se le acaba el tiempo
		if o.dur - o.t < 50.0 and int(o.t) % 8 < 3:
			continue
		# el dibujo apunta hacia arriba: se gira hacia su blanco
		_cuadro(cv, "obj_torreta", 22, 22, 1 if o.n > 0 else 0, o.x, o.y, 1.0, o.rot + PI / 2.0)


func _dib_rastro(cv: CanvasItem, a: Arma) -> void:
	for o in a.objs:
		var u: float = o.t / o.dur
		var esc: float = (o.radio / 7.0) * (1.0 - u * 0.5)
		_cuadro(cv, "obj_llama", 14, 14, (c.ticks / 4 + int(o.x)) % 4, o.x, o.y, esc, 0.0, Color(1, 1, 1, 0.85 * (1.0 - u * u)))


func _dib_escudos(cv: CanvasItem, a: Arma) -> void:
	var n: int = int(a.p.n)
	var r := 27.0
	for k in n:
		var q := pos_orbita(a, k, n, r)
		if k < a.cargas:
			_cuadro(cv, "obj_escudo", 16, 16, 0, q.x, q.y, 1.0, 0.0, Color(1.5, 0.95, 0.75) if a.evo else Color.WHITE)
		elif k == a.cargas:
			# el que viene volviendo se va haciendo sólido
			var u: float = 1.0 - a.recarga / (a.p.recarga / c.stats.cadencia)
			_cuadro(cv, "obj_escudo", 16, 16, 0, q.x, q.y, 0.75, 0.0, Color(1, 1, 1, 0.1 + 0.35 * clampf(u, 0.0, 1.0)))
