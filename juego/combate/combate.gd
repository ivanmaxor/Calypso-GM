extends Node2D
## Un nivel: nave, enemigos, balas, Desync, cadena, cartas, ruleta y objetos.
## Toda la logica corre a 60 pasos fijos por segundo, sin nodos por bala.

signal terminado(res: Dictionary)
signal reiniciar

const Director := preload("res://combate/director.gd")

const ANCHO := 400.0
const ALTO := 360.0
const PX := 120
const ESC_DESYNC := 0.35
const MAX_BALAS := 1200
const MAX_TIROS := 140
const TOPE_DIVIDE := 60  # una bala que se divide no pasa de esto en pantalla
const VIDA_GIRO := 110  # una bala que persigue no vive más que esto
const HITBOX := 3.5
const IFRAMES_GOLPE := 70
const IFRAMES_ESCUDO_DESYNC := 45
const TIERS_CADENA := [10, 25, 50, 100, 200]
const MULT_CADENA := [1.0, 1.1, 1.2, 1.35, 1.5, 1.75]
const CADENA_LARGA := 120.0  # con esta cadena la ventana ya está en su mínimo
const VENTANA_MAX := 240.0  # 4 segundos para seguir la cadena al empezar
const VENTANA_MIN := 90.0  # 1.5 segundos con cadena larga
const PLAZO_BAJADA := 36.0  # al vencerse baja de 5 en 5, con este plazo entre bajadas
const BAJADA_CADENA := 5
const XP_BASE := 6.0
const XP_PASO := 10.5
const CURA_PIZZA := 30.0
const ESCALA := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26, 28, 31, 33, 36]
const BURBUJAS := ["burbuja_lol", "burbuja_gg", "burbuja_ez", "burbuja_f", "burbuja_excl"]
# AFK: quedarse en el mismo lugar se paga. "margen" es lo que hay que alejarse para que cuente como moverse.
const AFK_DEMORA := 300
const AFK_CAIDA := 60.0
const AFK_REPITE := 50
const AFK_MARGEN := 16.0
const AFK_RADIO := 30.0
const AFK_DANO := 34.0
const TOPE_ROCE := 0.4
const TIEMPO_ROCE := 180
# Ruleta: orden de los símbolos en cada rodillo.
const SIMBOLOS := ["jefe", "compacto", "horda", "moneda", "bolsa", "diamante", "pizza", "cofre"]
const PESOS_RULETA := [1.1, 1.4, 2.0, 2.2, 1.6, 0.9, 1.4, 1.2]
const PLATA_RULETA := {"moneda": 6, "bolsa": 12, "diamante": 24}
const T_RODILLO := [95, 135, 180]
const T_PAGO := 120
const ALTO_SIMBOLO := 44.0
const FRASES_INFINITO := ["¡Un minuto! Recién calentando, cabro.", "¡Dos minutos! Ya me debes plata.", "¡Tres minutos! Mira, no estás tan malo.", "¡Cuatro! Se me acabaron los robots chicos.",
	"¡Cinco minutos! ¿No tienes casa?", "¡Seis! Voy a tener que llamar a mi cuñado.", "¡Siete minutos! Esto ya es trabajo. No te voy a pagar."]
const FRASES_GIRO := ["¡Hagan sus apuestas!", "¡No hay reembolsos, cabro!", "¡La armé con una lavadora!", "¡Dale, que no muerde!"]
enum {B_ORBE, B_GRANDE, B_PELLET, B_PUNTA, B_BURBUJA}


class Capa extends Node2D:
	var dueno: Object
	var metodo: StringName

	func _draw() -> void:
		dueno.call(metodo, self)


class Enemigo:
	var id := 0
	var def: Dictionary
	var tipo := ""
	var radio := 10.0
	var x := 0.0
	var y := 0.0
	var hp := 1.0
	var hpmax := 1.0
	var t := 0.0
	var anim := 0.0
	var flash := 0
	var modo := "entrar"
	var mt := 0.0
	var ruta := []
	var dur := 1.0
	var ax := 0.0
	var ay := 0.0
	var ox := 0.0
	var oy := 0.0
	var dx := 0.0
	var dy := 0.0
	var vx := 0.0
	var vy := 0.0
	var cd := 60.0
	var cd2 := 120.0
	var cd3 := 200.0
	var muerto := false
	var cola_hits := 0
	## Solo para mostrar: cuenta también las balas que pasan de largo cuando ya está sentenciado (M15).
	var cola_vis := 0
	var cola_dano := 0.0
	var fase := 0
	var inv := 0.0
	var frame_extra := -1
	var linea := 0.0
	var mult_dano := 1.0
	var apertura := 0.0
	var giro := 0.0
	var jefe := false
	var final := false
	var enlace := 0.0
	var ex := 0.0
	var ey := 0.0
	# frenado y empujones (armas)
	var lento := 1.0
	var lento_t := 0.0
	var desv_x := 0.0
	var desv_y := 0.0
	# tope de daño a jefes, por ventana de 60 cuadros
	var v_raw := 0.0
	var v_ef := 0.0
	var v_inicio := 0
	# medidas y detalles
	var nacio := 0
	var primer_golpe := -1
	var ult_golpe := -1
	var bajo_fuego := 0.0
	var por_cascada := false
	var disparos := 0
	var amp := 118.0
	var mult_cd := 1.0
	var tinte := Color.WHITE
	var nombre := ""
	var super_jefe := false


class Tiro:
	var x := 0.0
	var y := 0.0
	var vx := 0.0
	var vy := 0.0
	var dmg := 1.0
	var crit := false
	var perfora := 0
	var rebote := 0
	var divide := false
	var expl := 0.0
	var giro := 0.0  # radianes máximos por cuadro al perseguir: mantiene la rapidez
	var rehit := 0  # cuadros para volver a golpear al mismo enemigo; 0 = una sola vez
	var escala := 1.0  # al dibujarse
	var decae := 0.75  # factor de daño por rebote
	var vida := 400
	var tex: Texture2D
	var cuadros := 1
	var rot := 0.0
	var rotar := false
	var golpeados := {}
	## Enemigos sentenciados que esta bala ya cruzó en el Desync: solo suman al contador visible.
	var vistos := {}
	var obj = null


class Gema:
	var x := 0.0
	var y := 0.0
	var vx := 0.0
	var vy := 0.0
	var valor := 1
	var tipo := "bit"
	var imantada := false
	var t := 0


var nivel_id := "1-1"
var nivel: Dictionary
var stats: Dictionary
var arsenal: Arsenal
var modo_nivel := "normal"
var ciclo := 0
var mods: Dictionary
var mult_hp := 1.0
var mult_dano := 1.0
var mult_vel := 1.0
var mult_disparo := 1.0
var presupuesto := 70
var nave_id := "tryhard"
var tiene_desync := false
var tiene_mascota := false
var director: Director

var campo: Node2D
var capa_fondo: Capa
var capa_mundo: Capa
var capa_frente: Capa
var capa_hud: Capa
var capa_cartas: Capa
var nave: Sprite2D
var mat_nave: ShaderMaterial
var filtro: ColorRect
var mat_filtro: ShaderMaterial
var capa_pausa: CanvasLayer

var estado := "jugando"
var estado_previo := "jugando"
var estado_t := 0.0
var ticks := 0
var tiempo_jugado := 0
var guion_t := 0.0
var guion_i := 0
var guion: Array = []
var pendientes := []
var sig_id := 1
var scroll := 0.0
var sacudida := 0.0
var destello := 0.0
var vineta := 0.0
var color_destello := Color.WHITE
var tiempo_shader := 0.0
var aviso_txt := ""
var aviso_t := 0
var congelado := 0
var fogonazo := 0
var pista_txt := ""
var pista_t := 0
var pista_i := 0
var regalo_dado := false
var abandono := false
var idx_nivel := 0
var salva_t := 9.0
var vida_baja_dicha := false
var sin_pausa_hasta := 0
var latido_t := 0

var jx := 200.0
var jy := 305.0
var jvx := 0.0
var jvy := 0.0
var hp := 100.0
var hp_visto := 100.0
var hp_flash := 0
var banco := 0.0
var iframes := 0
var dash_t := 0
var dash_cd := 0.0
var dvx := 0.0
var dvy := 0.0
var foco := false
var foco_alternado := false
var quieto := false
var quieto_t := 0
var vivo := true
var escudo := false
var escudo_cd := 0.0
var roce_bono := 0.0
var roce_t := 0

var afk_t := 0
var afk_x := 200.0
var afk_y := 305.0
var afk_mira := -1.0
var afk_mx := 0.0
var afk_my := 0.0
var afk_bombas := 0

var bn := 0
var bx := PackedFloat32Array()
var by := PackedFloat32Array()
var bvx := PackedFloat32Array()
var bvy := PackedFloat32Array()
var bt := PackedInt32Array()
var bs := PackedInt32Array()
var bd := PackedInt32Array()
var br := PackedByteArray()

var enemigos: Array[Enemigo] = []
var tiros: Array[Tiro] = []
var gemas: Array[Gema] = []
var explos := []
var parts := []
var textos := []
var rayos := []
var grandes := []
var ondas := []

var nivel_carta := 1
var xp := 0.0
var xp_sig := XP_BASE + XP_PASO
var niveles_pendientes := 0
var habs := {}
var cartas := []
var carta_sel := 0
var carta_t := 0
var cambios_restantes := 1
var kills := 0
var kills_tipo := {}
var cadena := 0
var cadena_t := 0.0
var cadena_bajando := false
var tier_cadena := 0
var max_cadena := 0
var roces := 0
var desyncs := 0
var aces := 0
var nams := 0
var golpes := 0
var esquivas := 0
var cambios_usados := 0
var evoluciones := 0
var chatarra := 0
var bit_racha := 0
var bit_t := 0
var jefe_actual: Enemigo = null
var jefes_muertos := 0
var victoria_pendiente := false
var ex_jefe := Vector2(-999, -999)
var pizza_cd := 900
var bomba_cd := 1800
# medidas para el balance: tiempo que dura cada tipo desde el primer golpe, y lo que duran los jefes
var ttk := {}
var ttk_tarde := {}
var t_jefes := []
var golpes_por := {}
var cascadas := []

var barra := 0.0
var cola: Array[Enemigo] = []
var cola_total := 0
var cola_i := 0
var cascada_kills := 0
var cascada_paso := 6.0
var cascada_t := 0.0
var cascada_nota := 0
var desync_esc := 0
var desync_esc_max := 0
var desync_esc_flash := 0

var px := 230.0
var py := 320.0
var pet_id := ""
var pet_ia := ""
var pet_cd := 200.0
var pet_boca := 0
var pet_forma := 0
var pet_nivel := 1
var pet_tam := 22
var pet_ox := 0.0
var pet_oy := 0.0

# Modo Infinito
var inf_hasta := 0.0
var inf_sig_jefe := 120.0
var inf_jefes := 0
var inf_esperando_jefe := false
var inf_minuto := 0

# Ruleta
var ruleta_t := 0
var ruleta_fase := ""
var ruleta_pos := [0.0, 0.0, 0.0]
var ruleta_res := [0, 0, 0]
var ruleta_parado := [false, false, false]
var ruleta_reb := [0, 0, 0]
var ruleta_txt := ""
var ruleta_txt2 := ""
var ruleta_col := Color.WHITE
var ruleta_jackpot := false
var ruleta_forzada := []
var ruleta_cara := 1
var giros := 0
var jackpots := 0


func _ready() -> void:
	nivel_id = Partida.nivel_sel
	nivel = Datos.NIVELES[nivel_id]
	modo_nivel = nivel.get("modo", "normal")
	nave_id = Partida.nave_actual()
	stats = Partida.stats_nave(nave_id)
	arsenal = Arsenal.new(self)
	arsenal.agregar(Datos.NAVES[nave_id].arma)
	ciclo = Partida.ciclo()
	mods = Partida.mods_enemigos()
	mult_hp = mods.hp
	mult_dano = mods.dano
	mult_disparo = mods.disparo
	idx_nivel = int(nivel.get("indice", maxi(Datos.ORDEN_NIVELES.find(nivel_id), 0)))
	mult_vel = mods.vel * (1.0 + idx_nivel * 0.035)
	presupuesto = nivel.presupuesto + ciclo * 10
	director = Director.new(nivel, randi())
	if modo_nivel != "infinito":
		guion = director.guion()
	hp = stats.hp
	hp_visto = hp
	cambios_restantes = int(stats.cambios)
	tiene_desync = Partida.tiene("desync")
	pet_id = Partida.mascota_activa()
	tiene_mascota = pet_id != ""
	if tiene_mascota:
		pet_ia = Datos.MASCOTAS[pet_id].ia
		pet_forma = Partida.forma_mascota()
		pet_nivel = Partida.nivel_mascota()
		pet_tam = Partida.tam_mascota()
		pet_cd = Partida.pet_recarga()
	_crear_capas()
	for arr in [bx, by, bvx, bvy, bt, bs, bd, br]:
		arr.resize(MAX_BALAS)
	Sonido.musica_juego()
	_grande("NIVEL " + nivel_id, UI.C_ORO, 3, 80, -30)
	_grande(nivel.nombre, UI.C_TEXTO, 1, 80, 14)


func _capa(metodo: StringName, padre: Node) -> Capa:
	var c := Capa.new()
	c.dueno = self
	c.metodo = metodo
	padre.add_child(c)
	return c


func _crear_capas() -> void:
	campo = Node2D.new()
	campo.position = Vector2(PX, 0)
	add_child(campo)
	capa_fondo = _capa(&"dibujar_fondo", campo)
	capa_mundo = _capa(&"dibujar_mundo", campo)
	var back := BackBufferCopy.new()
	back.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	campo.add_child(back)
	filtro = ColorRect.new()
	filtro.position = Vector2(-30, -30)
	filtro.size = Vector2(ANCHO + 60, ALTO + 60)
	filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat_filtro = ShaderMaterial.new()
	mat_filtro.shader = load("res://arte/desync.gdshader")
	filtro.material = mat_filtro
	filtro.visible = false
	campo.add_child(filtro)
	nave = Sprite2D.new()
	nave.texture = Datos.tex("nave2_" + nave_id)
	nave.region_enabled = true
	nave.region_rect = Rect2(0, 0, 48, 48)
	mat_nave = ShaderMaterial.new()
	mat_nave.shader = load("res://arte/nave.gdshader")
	Partida.preparar_material(mat_nave, nave_id)
	nave.material = mat_nave
	campo.add_child(nave)
	capa_frente = _capa(&"dibujar_frente", campo)
	var cl := CanvasLayer.new()
	cl.layer = 1
	add_child(cl)
	capa_hud = _capa(&"dibujar_hud", cl)
	var cl2 := CanvasLayer.new()
	cl2.layer = 2
	add_child(cl2)
	capa_cartas = _capa(&"dibujar_cartas", cl2)
	capa_pausa = CanvasLayer.new()
	capa_pausa.layer = 3
	add_child(capa_pausa)


# =========================================================================================
# BUCLE
# =========================================================================================
func _physics_process(_d: float) -> void:
	if estado == "pausa":
		return
	if congelado > 0:
		congelado -= 1
		_tick_fx()
		_redibujar()
		return
	ticks += 1
	if estado != "cartas":
		tiempo_jugado += 1
	match estado:
		"jugando":
			_leer_pausa()
			if estado != "pausa":
				_tick_jugador()
				_tick_mundo(1.0)
				_tick_guion(1.0)
				_colisiones()
				_tick_cadena()
				_tick_pistas()
				_tick_botin()
				if niveles_pendientes > 0 and estado == "jugando":
					_abrir_cartas()
		"desync":
			_leer_pausa()
			if estado != "pausa":
				_tick_jugador()
				_tick_mundo(ESC_DESYNC)
				_tick_guion(ESC_DESYNC)
				_colisiones()
				if estado == "desync":
					estado_t -= 1.0
					if estado_t <= 0:
						_empezar_reconexion()
		"reconectando":
			estado_t -= 1.0
			if estado_t <= 0:
				_empezar_cascada()
		"cascada":
			_tick_cascada()
		"cartas":
			_tick_cartas()
		"ruleta":
			_leer_pausa()
			if estado != "pausa":
				_tick_jugador()
				_tick_mundo(1.0)
				_tick_ruleta()
		"muerte":
			estado_t -= 1.0
			if ticks % 10 == 0:
				explosion(jx + randf_range(-16, 16), jy + randf_range(-16, 16), "expl_media")
			if estado_t <= 0:
				_fin(false)
		"victoria":
			_tick_victoria()
	_tick_fx()
	_redibujar()


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not Pruebas.activo and estado in ["jugando", "desync", "ruleta"]:
		abrir_pausa()
	elif que == NOTIFICATION_EXIT_TREE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _cursor() -> void:
	var modo := Input.MOUSE_MODE_VISIBLE if estado in ["cartas", "pausa", "fin"] else Input.MOUSE_MODE_HIDDEN
	if Input.mouse_mode != modo:
		Input.mouse_mode = modo


func _redibujar() -> void:
	_cursor()
	capa_fondo.queue_redraw()
	capa_mundo.queue_redraw()
	capa_frente.queue_redraw()
	capa_hud.queue_redraw()
	capa_cartas.queue_redraw()
	var s := sacudida * (Ajustes.sacudida / 100.0)
	campo.position = Vector2(PX + round(randf_range(-s, s)), round(randf_range(-s, s)))
	nave.position = Vector2(round(jx), round(jy) + (1 if fogonazo > 1 else 0))
	var ib: int = clampi(int(round((banco + 1.0) * 2.0)), 0, 4)
	nave.region_rect = Rect2((ib * 2 + (ticks / 6) % 2) * 48, 0, 48, 48)
	nave.visible = vivo and (congelado > 0 or iframes <= 0 or dash_t > 0 or (ticks / 3) % 2 == 0)
	mat_nave.set_shader_parameter("blanco", 0.75 if hp_flash > 0 else 0.0)
	filtro.visible = estado in ["desync", "reconectando", "cascada"]
	if filtro.visible:
		tiempo_shader += 1.0 / 60.0
		mat_filtro.set_shader_parameter("tiempo", tiempo_shader)
		var f := 1.0
		if estado == "cascada":
			f = clampf(1.0 - float(cola_i) / maxf(float(cola.size()), 1.0), 0.0, 1.0)
		mat_filtro.set_shader_parameter("fuerza", f)
		mat_filtro.set_shader_parameter("glitch", 2.2 if estado == "reconectando" else 1.0)


func _leer_pausa() -> void:
	if Input.is_action_just_pressed("pausa") and Engine.get_physics_frames() > sin_pausa_hasta:
		abrir_pausa()


func _tick_pistas() -> void:
	# Solo la primera vez que juegas el nivel
	if Partida.nivel_completado(nivel_id):
		return
	var lista: Array = nivel.pistas
	if pista_i < lista.size() and guion_t >= lista[pista_i][0]:
		_pista(Datos.con_teclas(lista[pista_i][1]))
		pista_i += 1
	if nivel.has("desync_regalo") and not regalo_dado and guion_t >= nivel.desync_regalo:
		regalo_dado = true
		barra = 100.0
		_pista(Datos.con_teclas("¡Barra llena! Pulsa {desync} y sigue disparando."), 420)
		Sonido.tocar("carta", 0.75)


func _pista(s: String, dur := 300) -> void:
	pista_txt = s
	pista_t = dur
	Sonido.tocar("aviso", 1.3, -6.0)


# =========================================================================================
# JUGADOR
# =========================================================================================
## Todo lo que cambia tu daño según cómo vas jugando. Lo usan las armas.
func mult_dano_jugador() -> float:
	var m := 1.0
	if quieto_t >= 60:
		m += stats.quieto_dano
	elif not quieto:
		m += stats.mov_dano
	if hp < stats.hp * 0.4:
		m += stats.clutch_dano
	return m + roce_bono


func hitbox() -> float:
	return HITBOX * maxf(stats.hitbox_mult, 0.4)


func _tick_jugador() -> void:
	if not vivo:
		return
	var v := Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo", 0.3)
	quieto = v.length() < 0.1 and dash_t <= 0
	quieto_t = quieto_t + 1 if quieto else 0
	if Ajustes.foco_alternar:
		if Input.is_action_just_pressed("foco"):
			foco_alternado = not foco_alternado
		foco = foco_alternado
	else:
		foco = Input.is_action_pressed("foco")
	var vel: float = 2.75 * stats.vel
	if foco:
		vel *= 0.45
	if dash_cd > 0:
		dash_cd -= 1.0
	if Input.is_action_just_pressed("esquivar") and dash_cd <= 0 and dash_t <= 0:
		dash_t = 9
		dash_cd = 110.0 * stats.dash_cd
		iframes = maxi(iframes, int(stats.dash_iframes))
		dvx = v.x if v.length() > 0.1 else 0.0
		dvy = v.y if v.length() > 0.1 else -1.0
		esquivas += 1
		arsenal.al_esquivar()
		Sonido.tocar("dash")
		for k in 8:
			particula(jx, jy, randf_range(-1, 1), randf_range(-1, 1), UI.C_CIAN, 14)
	var antes_x := jx
	var antes_y := jy
	if dash_t > 0:
		dash_t -= 1
		jx += dvx * 7.5
		jy += dvy * 7.5
		particula(jx, jy, 0, 0, UI.C_CIAN, 10)
	else:
		jx += v.x * vel
		jy += v.y * vel
	jx = clampf(jx, 8.0, ANCHO - 8.0)
	jy = clampf(jy, 14.0, ALTO - 14.0)
	# promedio suave: lo usan los enemigos que apuntan adelantado
	jvx = lerpf(jvx, jx - antes_x, 0.2)
	jvy = lerpf(jvy, jy - antes_y, 0.2)
	banco = move_toward(banco, clampf(v.x, -1, 1), 0.12)
	if iframes > 0:
		iframes -= 1
	if desync_esc_flash > 0:
		desync_esc_flash -= 1
	arsenal.tick()
	if stats.regen > 0 and hp < stats.hp:
		curar(stats.regen / 60.0)
	if roce_t > 0:
		roce_t -= 1
		if roce_t <= 0:
			roce_bono = 0.0
	if tiene_desync and estado == "jugando" and barra >= 100.0 and Input.is_action_just_pressed("desync"):
		_empezar_desync()
	if habs.has("tank") and not escudo:
		escudo_cd -= 1.0
		if escudo_cd <= 0:
			escudo = true
			Sonido.tocar("racha", 1.4)
	_tick_afk()
	if tiene_mascota:
		_tick_mascota()
	if hp < stats.hp * 0.3 and vivo:
		latido_t -= 1
		if latido_t <= 0:
			latido_t = 46
			Sonido.tocar("latido", 1.0, 2.0)


## Si te quedas en el mismo lugar, te llega una bomba. Se repite mientras sigas ahí.
func _tick_afk() -> void:
	if estado != "jugando":
		return
	if dist2(jx, jy, afk_x, afk_y) > AFK_MARGEN * AFK_MARGEN:
		afk_x = jx
		afk_y = jy
		afk_t = 0
	elif not enemigos.is_empty():
		afk_t += 1
	if afk_mira >= 0.0:
		afk_mira -= 1.0
		if afk_mira < 0.0:
			_caer_bomba()
	elif afk_t >= AFK_DEMORA:
		afk_mira = AFK_CAIDA
		afk_mx = jx
		afk_my = jy
		afk_t = AFK_DEMORA - AFK_REPITE
		Sonido.tocar("aviso", 0.7, 0.0)
		if afk_bombas == 0:
			_pista("Calypso: " + Datos.texto_azar("afk"), 240)
		afk_bombas += 1


func _caer_bomba() -> void:
	afk_mira = -1.0
	explosion(afk_mx, afk_my, "expl_grande")
	sacudir(10.0)
	Sonido.tocar("kill_grande", 0.7, 3.0)
	ondas.append({"x": afk_mx, "y": afk_my, "r": 10.0, "c": UI.C_ROJO})
	if vivo and dist2(jx, jy, afk_mx, afk_my) < AFK_RADIO * AFK_RADIO and dash_t <= 0:
		iframes = 0
		_recibir_dano(AFK_DANO, "afk")


func curar(v: float) -> void:
	hp = minf(hp + v, stats.hp)


func crear_tiro(x: float, y: float, ang: float, vel: float, dmg: float, tx: Texture2D, cuadros: int, crit_seguro: bool) -> Tiro:
	var t := Tiro.new()
	var v: float = vel * stats.vel_tiro
	t.x = x
	t.y = y
	t.vx = cos(ang) * v
	t.vy = sin(ang) * v
	t.crit = crit_seguro or randf() < stats.crit
	t.dmg = dmg * (stats.crit_dmg if t.crit else 1.0)
	t.tex = tx
	t.cuadros = cuadros
	t.rot = ang + PI / 2.0
	t.rotar = absf(ang + PI / 2.0) > 0.02 or stats.homing > 0
	# con la pantalla llena no sale: quien la pidió igual recibe el objeto, pero no vuela
	if tiros.size() < MAX_TIROS:
		tiros.append(t)
	return t


func enemigo_cercano(x: float, y: float, excluir := {}) -> Enemigo:
	var mejor: Enemigo = null
	var md := INF
	for e in enemigos:
		if e.muerto or e.y < -10 or excluir.has(e.id):
			continue
		var ddx := e.x - x
		var ddy := e.y - y
		var d := ddx * ddx + ddy * ddy
		if d < md:
			md = d
			mejor = e
	return mejor


## Frena a un enemigo un rato. A los jefes no.
func frenar_enemigo(e: Enemigo, factor: float, cuadros: float) -> void:
	if e.jefe or e.muerto:
		return
	e.lento = factor
	e.lento_t = maxf(e.lento_t, cuadros)


## Empuja a un enemigo; también a los que van por ruta. A los jefes no.
func empujar(e: Enemigo, ddx: float, ddy: float) -> void:
	if e.jefe or e.muerto:
		return
	if e.modo == "ruta":
		e.desv_x += ddx
		e.desv_y += ddy
	elif e.modo == "entrar":
		e.ox += ddx
		e.oy += ddy
		e.ax += ddx
		e.ay += ddy
	else:
		e.x += ddx
		e.y += ddy
		e.ax += ddx
		e.ay += ddy


func _tick_mascota() -> void:
	# se mueve suave y se queda a un lado, para no tapar la acción
	var ox := jx + 28.0
	var oy := jy + 20.0
	if pet_boca > 0:
		pet_boca -= 1
		ox = pet_ox
		oy = pet_oy
	px = lerpf(px, ox, 0.09)
	py = lerpf(py, oy, 0.09)
	pet_cd -= 1.0
	if pet_cd > 0:
		return
	match pet_ia:
		"come":
			_mascota_come()
		"chispa":
			_mascota_chispa()
		"iman":
			_mascota_iman()
		"escudo":
			_mascota_escudo()
		_:
			pet_cd = 60.0


func _mascota_come() -> void:
	var radio := Partida.pet_radio()
	var mejor := -1
	var md := radio * radio
	for i in bn:
		var d := dist2(bx[i], by[i], px, py)
		if d < md:
			md = d
			mejor = i
	if mejor < 0:
		pet_cd = 12.0
		return
	chispa(bx[mejor], by[mejor], Color("dccfe6"), 6)
	pet_ox = lerpf(px, bx[mejor], 0.7)
	pet_oy = lerpf(py, by[mejor], 0.7)
	quitar_bala(mejor)
	pet_boca = 18
	pet_cd = Partida.pet_recarga()
	nams += 1
	_sumar_barra(3.0)
	Sonido.tocar("nam", randf_range(0.95, 1.15), -1.0)
	texto(px, py - 18, "¡ÑAM!", Color("ffd0f0"), 1)


func _mascota_chispa() -> void:
	var ob := enemigo_cercano(px, py)
	var radio := Partida.pet_radio()
	if ob == null or dist2(ob.x, ob.y, px, py) > radio * radio:
		pet_cd = 12.0
		return
	rayos.append({"a": Vector2(px, py), "b": Vector2(ob.x, ob.y), "t": 8})
	golpear(ob, Partida.pet_dano() * stats.atk * stats.dano, false, ob.x, ob.y)
	pet_ox = lerpf(px, ob.x, 0.15)
	pet_oy = lerpf(py, ob.y, 0.15)
	pet_boca = 14
	pet_cd = Partida.pet_recarga()
	nams += 1
	Sonido.tocar("impacto", 1.7, -4.0)


func _mascota_iman() -> void:
	var hubo := false
	for g in gemas:
		if not g.imantada:
			g.imantada = true
			hubo = true
	if not hubo:
		pet_cd = 30.0
		return
	pet_ox = px
	pet_oy = py
	pet_boca = 14
	pet_cd = Partida.pet_recarga()
	ondas.append({"x": px, "y": py, "r": 6.0, "c": UI.C_ORO})
	Sonido.tocar("racha", 1.2, -6.0)


func _mascota_escudo() -> void:
	if escudo:
		pet_cd = 30.0
		return
	escudo = true
	pet_ox = px
	pet_oy = py
	pet_boca = 14
	pet_cd = Partida.pet_recarga()
	texto(jx, jy - 26, "¡ESCUDO!", UI.C_CIAN, 1)
	Sonido.tocar("racha", 1.4)


func _recibir_dano(cantidad: float, fuente := "") -> void:
	if iframes > 0 or not vivo or estado in ["reconectando", "cascada", "ruleta"]:
		return
	if arsenal.absorber_golpe():
		iframes = maxi(iframes, 40)
		return
	if estado == "desync" and desync_esc > 0:
		_quebrar_escudo_desync()
		return
	if escudo:
		escudo = false
		escudo_cd = 1200.0 - habs.get("tank", 1) * 180.0
		iframes = 60
		_limpiar_cerca(jx, jy, 46.0)
		sacudir(5.0)
		congelado = 4
		ondas.append({"x": jx, "y": jy, "r": 10.0, "c": UI.C_CIAN})
		texto(jx, jy - 24, "¡ESCUDO!", UI.C_CIAN, 1)
		Sonido.tocar("impacto", 0.6, 4.0)
		return
	var d: float = cantidad * mult_dano * _mult_dano_tiempo() * (1.0 + idx_nivel * 0.06) * (1.0 - stats.armadura)
	hp -= d
	golpes += 1
	golpes_por[fuente] = golpes_por.get(fuente, 0) + 1
	iframes = IFRAMES_GOLPE
	hp_flash = 8
	congelado = 7
	vineta = 1.0
	sacudir(9.0)
	flash(UI.C_ROJO, 0.5)
	ondas.append({"x": jx, "y": jy, "r": 6.0, "c": UI.C_ROJO})
	texto(jx, jy - 26, "-%d" % int(ceil(d)), UI.C_ROJO, 2)
	Sonido.tocar("dano", 1.0, 4.0)
	_limpiar_cerca(jx, jy, 34.0)
	if stats.thorns > 0.0:
		_onda_karma()
	if cadena >= 10:
		texto(jx, jy - 44, "¡CADENA A LA MITAD!", UI.C_ROSA, 1)
	cadena = cadena / 2
	_actualizar_tier(false)
	if hp <= 0:
		if stats.revives > 0:
			stats.revives -= 1
			hp = stats.hp * 0.5
			iframes = 180
			_limpiar_todo()
			_grande("¡REVIVES!", UI.C_VERDE, 2, 100)
			Sonido.tocar("nivel")
			return
		_morir()
		return
	if hp < stats.hp * 0.3:
		Sonido.tocar("corazon_roto", 1.0, 3.0)
		if not vida_baja_dicha:
			vida_baja_dicha = true
			_pista("Calypso: " + Datos.texto_azar("vida_baja"), 200)


## Karma: cuando te golpean, una onda daña a los que están cerca.
func _onda_karma() -> void:
	var dmg: float = stats.thorns * stats.atk * stats.dano * 3.0
	ondas.append({"x": jx, "y": jy, "r": 12.0, "c": UI.C_ROSA})
	for e in enemigos:
		if e.muerto:
			continue
		var r: float = 70.0 + e.radio
		if dist2(e.x, e.y, jx, jy) < r * r:
			golpear(e, dmg, false, e.x, e.y)


func _morir() -> void:
	vivo = false
	estado = "muerte"
	estado_t = 110.0
	Sonido.tocar("muerte")
	Sonido.silencio(true)
	sacudir(14.0)
	flash(Color.WHITE, 0.7)
	for k in 26:
		particula(jx, jy, randf_range(-3, 3), randf_range(-3, 3), UI.C_ORO, randi_range(20, 50))


func _limpiar_cerca(x: float, y: float, r: float) -> void:
	var i := bn - 1
	while i >= 0:
		if dist2(bx[i], by[i], x, y) < r * r:
			chispa(bx[i], by[i], Color("ff9ac0"), 3)
			quitar_bala(i)
		i -= 1


## Borra todas las balas. Una de cada tres deja un Bit: limpiar la pantalla no debe regalar niveles.
func _limpiar_todo() -> void:
	var i := bn - 1
	while i >= 0:
		if i % 3 == 0:
			_gema(bx[i], by[i], "bit", 1)
		else:
			chispa(bx[i], by[i], Color("ff9ac0"), 1)
		quitar_bala(i)
		i -= 1


# =========================================================================================
# DESYNC
# =========================================================================================
func _sumar_barra(v: float) -> void:
	if estado != "jugando" or not tiene_desync:
		return
	var antes := barra
	barra = minf(barra + v * stats.desync_carga, 100.0)
	if antes < 100.0 and barra >= 100.0:
		Sonido.tocar("carta", 0.75)


func _empezar_desync() -> void:
	estado = "desync"
	estado_t = stats.desync_dur * 60.0
	desyncs += 1
	cola.clear()
	cola_total = 0
	barra = 100.0
	desync_esc_max = int(stats.desync_escudo)
	desync_esc = desync_esc_max
	desync_esc_flash = 10
	afk_mira = -1.0
	Sonido.tocar("desync_entra")
	Sonido.desync(true)
	flash(UI.C_CIAN, 0.5)


## El escudo del Desync: cada golpe lo quiebra un poco y da un instante de invulnerabilidad.
func _quebrar_escudo_desync() -> void:
	desync_esc -= 1
	iframes = IFRAMES_ESCUDO_DESYNC
	desync_esc_flash = 14
	sacudir(6.0)
	congelado = 3
	vineta = 0.5
	flash(UI.C_CIAN, 0.25)
	ondas.append({"x": jx, "y": jy, "r": 14.0, "c": UI.C_CIAN})
	for k in 16:
		var a := randf() * TAU
		particula(jx + cos(a) * 21.0, jy + sin(a) * 21.0, cos(a) * randf_range(0.6, 2.2), sin(a) * randf_range(0.6, 2.2), UI.C_CIAN, randi_range(14, 30))
	Sonido.tocar("impacto", 0.75, 4.0)
	Sonido.tocar("corazon_roto", 1.5, -2.0)
	if desync_esc > 0:
		texto(jx, jy - 28, "ESCUDO %d/%d" % [desync_esc, desync_esc_max], UI.C_CIAN, 1)
	else:
		texto(jx, jy - 28, "¡SIN ESCUDO!", UI.C_ROSA, 1)


func _empezar_reconexion() -> void:
	estado = "reconectando"
	estado_t = 21.0
	Sonido.silencio(true)
	Sonido.tocar("reconectar")
	barra = 0.0


func _empezar_cascada() -> void:
	estado = "cascada"
	cola_i = 0
	cascada_t = 0.0
	cascada_kills = 0
	cascada_nota = 0
	cascada_paso = clampf(90.0 / maxf(cola.size(), 1), 3.0, 11.0)


func _bono_cascada() -> float:
	return minf(3.0, 1.5 + 0.03 * cola_total) * (1.0 + stats.cascada)


func _tick_cascada() -> void:
	cascada_t -= 1.0
	if cascada_t > 0:
		return
	if cola_i >= cola.size():
		_terminar_cascada()
		return
	var e := cola[cola_i]
	cola_i += 1
	cascada_t = cascada_paso
	if e.muerto:
		return
	var dmg := e.cola_dano * _bono_cascada()
	if e.jefe:
		dmg = minf(dmg, e.hpmax * 0.35)
	var hits := e.cola_hits
	e.cola_hits = 0
	e.cola_vis = 0
	e.cola_dano = 0.0
	var nota: int = ESCALA[mini(cascada_nota, ESCALA.size() - 1)]
	cascada_nota += 1
	Sonido.tocar("cascada", pow(2.0, nota / 12.0) * 0.75, 0.0, 0)
	num(e.x, e.y - 8, dmg, UI.C_ORO, 2)
	sacudir(2.0 + minf(hits * 0.3, 5.0))
	var estaba_vivo := not e.muerto
	e.por_cascada = true
	_aplicar(e, dmg, true, e.x, e.y, true)
	if estaba_vivo and e.muerto:
		cascada_kills += 1


func _terminar_cascada() -> void:
	Sonido.silencio(false)
	Sonido.desync(false)
	_limpiar_todo()
	for g in gemas:
		g.imantada = true
	if stats.cura_cascada > 0:
		curar(stats.cura_cascada)
		texto(jx, jy - 26, "+%d" % int(stats.cura_cascada), UI.C_VERDE, 1)
	var vivos := 0
	for e in enemigos:
		if not e.muerto and e.y > -10:
			vivos += 1
	if cascada_kills > 0:
		_grande("+%d" % cascada_kills, UI.C_ORO, 5, 110, -14)
		_grande("KILLS REGISTRADAS", UI.C_TEXTO, 2, 110, 56)
	if cola_total > 0:
		_grande("%d GOLPES EN CASCADA" % cola_total, UI.C_TEXTO, 1, 110, 84)
	if cascada_kills >= 6 or (vivos == 0 and cascada_kills >= 3):
		aces += 1
		_pista("Calypso: " + Datos.texto_azar("ace"), 200)
		_grande("¡ACE!", UI.C_ROSA, 3, 110, 100)
		Sonido.tocar("ace")
		flash(Color.WHITE, 0.5)
		sacudir(9.0)
	elif cascada_kills > 0:
		Sonido.tocar("kill_grande", 1.1)
	cascadas.append([cola_total, cascada_kills])
	cola.clear()
	cola_total = 0
	estado = "victoria" if victoria_pendiente else "jugando"
	if victoria_pendiente:
		estado_t = 170.0


# =========================================================================================
# MUNDO
# =========================================================================================
func _tick_mundo(esc: float) -> void:
	scroll += 0.5 * esc
	var i := bn - 1
	while i >= 0:
		bx[i] += bvx[i] * esc
		by[i] += bvy[i] * esc
		if bx[i] < -24.0 or bx[i] > ANCHO + 24.0 or by[i] < -30.0 or by[i] > ALTO + 24.0:
			quitar_bala(i)
		i -= 1
	for e in enemigos:
		if not e.muerto:
			_tick_enemigo(e, esc)
	_tick_tiros()
	_tick_gemas()
	var j := enemigos.size() - 1
	while j >= 0:
		if enemigos[j].muerto:
			enemigos.remove_at(j)
		j -= 1
	if estado == "jugando" and modo_nivel != "infinito" and guion_i >= guion.size() and enemigos.is_empty() and pendientes.is_empty() and not victoria_pendiente:
		_nivel_completado()


func _nivel_completado() -> void:
	if estado == "victoria":
		return
	estado = "victoria"
	estado_t = 100.0
	ex_jefe = Vector2(-999, -999)
	for g in gemas:
		g.imantada = true
	_grande("¡NIVEL COMPLETADO!", UI.C_ORO, 2, 100)
	Sonido.tocar("nivel")


func _tick_tiros() -> void:
	var i := tiros.size() - 1
	while i >= 0:
		var t := tiros[i]
		t.vida -= 1
		if t.giro > 0.0:
			if t.vida > VIDA_GIRO:
				t.vida = VIDA_GIRO
			# el blanco se busca cada pocos cuadros: con muchas balas, esto pesa
			if t.obj == null or t.obj.muerto or (ticks + i) % 8 == 0:
				t.obj = enemigo_cercano(t.x, t.y)
			if t.obj != null:
				var ang_act := atan2(t.vy, t.vx)
				var ang_obj := atan2(t.obj.y - t.y, t.obj.x - t.x)
				var ang := ang_act + clampf(wrapf(ang_obj - ang_act, -PI, PI), -t.giro, t.giro)
				var rapidez := sqrt(t.vx * t.vx + t.vy * t.vy)
				t.vx = cos(ang) * rapidez
				t.vy = sin(ang) * rapidez
				t.rot = ang + PI / 2.0
				t.rotar = true
		t.x += t.vx
		t.y += t.vy
		var fuera := t.y < -20 or t.y > ALTO + 20 or t.x < -20 or t.x > ANCHO + 20 or t.vida <= 0
		if t.rebote > 0 and not fuera:
			var reboto := false
			if t.x < 4 or t.x > ANCHO - 4:
				t.vx = -t.vx
				t.x = clampf(t.x, 4, ANCHO - 4)
				reboto = true
			if t.y < 4 or t.y > ALTO - 4:
				t.vy = -t.vy
				t.y = clampf(t.y, 4, ALTO - 4)
				reboto = true
			if reboto:
				t.rebote -= 1
				t.dmg *= t.decae
				t.golpeados.clear()
				t.rot = atan2(t.vy, t.vx) + PI / 2.0
				t.rotar = true
				if t.divide and tiros.size() < TOPE_DIVIDE:
					var a := atan2(t.vy, t.vx) + 0.5
					var v: float = Vector2(t.vx, t.vy).length() / stats.vel_tiro
					var n := crear_tiro(t.x, t.y, a, v, t.dmg, t.tex, t.cuadros, t.crit)
					n.rebote = t.rebote
					n.vida = t.vida
					n.decae = t.decae
					n.escala = t.escala
		if fuera:
			tiros.remove_at(i)
		i -= 1


func _tick_gemas() -> void:
	var r: float = stats.iman
	var i := gemas.size() - 1
	while i >= 0:
		var g := gemas[i]
		g.t += 1
		if not g.imantada and (g.t > 420 or dist2(g.x, g.y, jx, jy) < r * r):
			g.imantada = true
		if g.imantada:
			var dir := Vector2(jx - g.x, jy - g.y)
			var dist := dir.length()
			if dist < 12.0 and vivo:
				_recoger(g)
				gemas.remove_at(i)
				i -= 1
				continue
			var v := minf(3.0 + g.t * 0.05, 9.0)
			g.x += dir.x / maxf(dist, 1.0) * v
			g.y += dir.y / maxf(dist, 1.0) * v
		else:
			g.x += g.vx
			g.y += g.vy
			g.vx *= 0.94
			g.vy = g.vy * 0.94 + 0.03
			if g.y > ALTO - 8:
				g.imantada = true
		i -= 1


func _recoger(g: Gema) -> void:
	match g.tipo:
		"pizza":
			curar(CURA_PIZZA)
			_cartel("¡PIZZA! +%d VIDA" % int(CURA_PIZZA), UI.C_VERDE)
			Sonido.tocar("pizza", 1.0, 3.0)
		"iman":
			for o in gemas:
				o.imantada = true
			_cartel("¡IMÁN!", UI.C_CIAN)
			Sonido.tocar("racha", 1.2, 3.0)
		"bomba":
			_limpiar_todo()
			for e in enemigos:
				if not e.muerto and not e.jefe and e.y > 0:
					golpear(e, stats.atk * stats.dano * 4.0, true, e.x, e.y)
			ondas.append({"x": jx, "y": jy, "r": 12.0, "c": Color.WHITE})
			sacudir(9.0)
			flash(Color.WHITE, 0.4)
			_cartel("¡BOMBA!", UI.C_ORO)
			Sonido.tocar("kill_grande", 0.9, 3.0)
		"cofre":
			niveles_pendientes += 1
			_cartel("¡COFRE: CARTA GRATIS!", UI.C_ORO)
			Sonido.tocar("botin_2")
		"tuerca":
			chatarra += int(ceil(g.valor * stats.chatarra))
			Sonido.tocar("impacto", 1.6, -8.0, 3)
		_:
			bit_racha = mini(bit_racha + 1, ESCALA.size() - 1)
			bit_t = 26
			Sonido.tocar("bit", pow(2.0, ESCALA[bit_racha / 2] / 12.0) * 0.8, -5.0, 3)
			xp += g.valor * stats.xp * MULT_CADENA[tier_cadena]
			while xp >= xp_sig:
				xp -= xp_sig
				nivel_carta += 1
				xp_sig = XP_BASE + nivel_carta * XP_PASO
				niveles_pendientes += 1


func _cartel(s: String, c: Color) -> void:
	texto(jx, jy - 30, s, c, 1)


func _gema(x: float, y: float, tipo: String, valor := 1) -> void:
	if gemas.size() > 170 and (tipo == "bit" or tipo == "tuerca"):
		for o in gemas:
			if o.tipo == tipo:
				o.valor += valor
				return
	var g := Gema.new()
	g.x = x
	g.y = y
	var a := randf() * TAU
	var v := randf_range(0.4, 1.8)
	g.vx = cos(a) * v
	g.vy = sin(a) * v
	g.valor = valor
	g.tipo = tipo
	gemas.append(g)


func _tick_guion(esc: float) -> void:
	_tick_salva(esc)
	var j := pendientes.size() - 1
	while j >= 0:
		pendientes[j].t -= esc / 60.0
		if pendientes[j].t <= 0:
			_crear_enemigo(pendientes[j])
			pendientes.remove_at(j)
		j -= 1
	if modo_nivel == "infinito":
		_tick_infinito()
	if guion_i >= guion.size():
		return
	var ev: Dictionary = guion[guion_i]
	if ev.has("espera"):
		# espera a que no quede nadie antes de seguir
		guion_t = maxf(guion_t, ev.t)
		if enemigos.is_empty() and pendientes.is_empty():
			guion_i += 1
		return
	guion_t += esc / 60.0
	while guion_i < guion.size() and guion[guion_i].t <= guion_t:
		ev = guion[guion_i]
		if ev.has("espera"):
			return
		guion_i += 1
		if ev.has("ruleta"):
			_empezar_ruleta()
			return
		if ev.has("aviso"):
			_avisar(ev.aviso, ev.has("jefe"))
			continue
		_encolar(ev)


func _encolar(ev: Dictionary) -> void:
	for k in int(ev.n):
		var p := {"t": k * float(ev.sep), "tipo": ev.tipo}
		if ev.has("ruta"):
			p["ruta"] = ev.ruta
		if ev.has("xs"):
			p["x"] = ev.xs[k % ev.xs.size()]
		if ev.has("anclas"):
			p["ancla"] = ev.anclas[k % ev.anclas.size()]
		if ev.has("enjambre"):
			p["enjambre"] = ev.enjambre
		pendientes.append(p)


## El Modo Infinito no tiene guion fijo: el director va armando de a poco, y cada tanto llega un jefe.
func _tick_infinito() -> void:
	var minuto: int = tiempo_jugado / 3600
	if minuto > inf_minuto:
		inf_minuto = minuto
		_pista("Don Tuerca: " + FRASES_INFINITO[mini(minuto - 1, FRASES_INFINITO.size() - 1)], 240)
	if guion_i >= guion.size():
		var hay_jefe := jefe_actual != null or inf_esperando_jefe
		guion = director.tramo(inf_hasta, inf_hasta + 12.0, 0.55 if hay_jefe else 1.0)
		guion_i = 0
		inf_hasta += 12.0
	if guion_t >= inf_sig_jefe and jefe_actual == null and not inf_esperando_jefe:
		inf_esperando_jefe = true
		inf_jefes += 1
		inf_sig_jefe += 120.0
		var tipo := "compactador" if inf_jefes % 2 == 0 else "grua"
		_avisar("¡EL COMPACTADOR!" if tipo == "compactador" else "¡LA GRÚA!", true)
		pendientes.append({"t": 2.5, "tipo": tipo, "ancla": [200, 86], "mult_jefe": 0.5 + guion_t / 480.0})


## La vida enemiga según el avance del nivel. El jugador crece dentro del nivel, así que ellos también.
func _dureza_ahora() -> float:
	if modo_nivel == "infinito":
		return float(nivel.dureza) * (1.0 + guion_t / 110.0)
	return lerpf(nivel.dureza, nivel.get("dureza_fin", nivel.dureza), clampf(guion_t / maxf(float(nivel.duracion), 1.0), 0.0, 1.0))


func _mult_dano_tiempo() -> float:
	if modo_nivel == "infinito":
		return 1.0 + guion_t / 300.0
	return 1.0


func _mult_vel_tiempo() -> float:
	if modo_nivel == "infinito":
		return minf(1.0 + guion_t / 900.0, 1.4)
	return 1.0


## Cada tantos segundos, los bots en pantalla disparan a la vez: hay que moverse.
func _tick_salva(esc: float) -> void:
	var s: float = nivel.salva
	if s <= 0.0:
		return
	salva_t -= esc / 60.0
	if salva_t > 0.0:
		return
	salva_t = s
	var tiradores := 0
	var tope := 3 + idx_nivel / 2
	for e in enemigos:
		if e.def.ia == "ruta" and not e.muerto and e.y > 0 and e.y < 240 and e.lento_t <= 0.0:
			_apuntado(e.x, e.y + 8, 2.1, 1, 0.0, B_ORBE, 0)
			e.flash = 6
			tiradores += 1
			if tiradores >= tope:
				break
	if tiradores > 0:
		Sonido.tocar("disparo_riel", 0.8, -7.0)


func _avisar(txt: String, jefe: bool) -> void:
	aviso_txt = txt
	aviso_t = 150
	Sonido.tocar("aviso_jefe" if jefe else "aviso")


func _crear_enemigo(p: Dictionary) -> Enemigo:
	var e := Enemigo.new()
	e.id = sig_id
	sig_id += 1
	e.tipo = p.tipo
	e.def = Datos.ENEMIGOS[p.tipo]
	e.radio = e.def.radio
	e.nombre = e.def.nombre
	e.jefe = e.def.get("jefe", false)
	e.final = nivel.get("jefe", "") == p.tipo
	e.nacio = ticks
	var vida: float = float(e.def.hp) * mult_hp * (1.0 + stats.hardcore)
	vida *= float(p.get("mult_jefe", 1.0)) if e.jefe else _dureza_ahora()
	e.hpmax = vida
	e.hp = vida
	e.cd = randf_range(40.0, 110.0)
	if e.def.has("disparo"):
		e.cd = randf_range(30.0, float(e.def.disparo)) * nivel.agresion * mult_disparo
	if p.has("enjambre"):
		_nacer_en_enjambre(e, p.enjambre)
	elif p.has("ruta"):
		var r: Dictionary = Datos.RUTAS[p.ruta]
		e.ruta = r.pts
		if p.has("x"):
			var xx: float = p.x
			e.ruta = [[xx, -30.0], [xx, 130.0], [xx, 260.0], [xx, 400.0]]
		e.dur = r.dur
		e.modo = "ruta"
		var pos := _catmull(e.ruta, 0.0)
		e.x = pos.x
		e.y = pos.y
	else:
		var a: Array = p.get("ancla", [200, 60])
		e.ax = a[0]
		e.ay = a[1]
		e.x = a[0]
		e.y = -40.0
		e.ox = e.x
		e.oy = e.y
		e.modo = "entrar"
		e.dur = 1.3
		if e.jefe:
			e.dur = 2.6
			jefe_actual = e
			inf_esperando_jefe = false
			Sonido.musica_jefe(true)
			if p.has("amp"):
				e.amp = p.amp
			if p.get("super", false):
				e.super_jefe = true
				e.mult_cd = 0.72
				e.tinte = Color(1.0, 0.55, 0.95)
				e.nombre = "SÚPER GRÚA"
	enemigos.append(e)
	return e


func _nacer_en_enjambre(e: Enemigo, origen: String) -> void:
	e.modo = "libre"
	match origen:
		"izq":
			e.x = -16.0 - randf() * 30.0
			e.y = randf_range(40.0, 210.0)
			e.vx = 1.2
		"der":
			e.x = ANCHO + 16.0 + randf() * 30.0
			e.y = randf_range(40.0, 210.0)
			e.vx = -1.2
		"arriba_izq":
			e.x = randf_range(0.0, 110.0)
			e.y = -16.0 - randf() * 30.0
			e.vy = 1.2
		"arriba_der":
			e.x = randf_range(290.0, 400.0)
			e.y = -16.0 - randf() * 30.0
			e.vy = 1.2
		_:
			e.x = randf_range(60.0, 340.0)
			e.y = -16.0 - randf() * 30.0
			e.vy = 1.2


func _catmull(pts: Array, u: float) -> Vector2:
	var n := pts.size() - 1
	var f := clampf(u, 0.0, 0.9999) * n
	var i := int(f)
	var t := f - i
	var p0: Array = pts[maxi(i - 1, 0)]
	var p1: Array = pts[i]
	var p2: Array = pts[mini(i + 1, n)]
	var p3: Array = pts[mini(i + 2, n)]
	var t2 := t * t
	var t3 := t2 * t
	return Vector2(
		0.5 * (2.0 * p1[0] + (p2[0] - p0[0]) * t + (2.0 * p0[0] - 5.0 * p1[0] + 4.0 * p2[0] - p3[0]) * t2 + (3.0 * p1[0] - p0[0] - 3.0 * p2[0] + p3[0]) * t3),
		0.5 * (2.0 * p1[1] + (p2[1] - p0[1]) * t + (2.0 * p0[1] - 5.0 * p1[1] + 4.0 * p2[1] - p3[1]) * t2 + (3.0 * p1[1] - p0[1] - 3.0 * p2[1] + p3[1]) * t3))


func _tick_enemigo(e: Enemigo, esc0: float) -> void:
	var esc := esc0
	if e.lento_t > 0.0:
		e.lento_t -= esc0
		esc *= e.lento
	e.t += esc / 60.0
	e.anim += esc * 0.12
	if e.flash > 0:
		e.flash -= 1
	if e.inv > 0:
		e.inv -= esc
	if e.enlace > 0:
		e.enlace -= esc
	match e.modo:
		"ruta":
			var u := e.t / e.dur
			if u >= 1.0:
				e.muerto = true
				return
			var pos := _catmull(e.ruta, u)
			e.desv_x *= 0.97
			e.desv_y *= 0.97
			e.x = pos.x + e.desv_x
			e.y = pos.y + e.desv_y
		"entrar":
			var u := minf(e.t / e.dur, 1.0)
			var s := u * u * (3.0 - 2.0 * u)
			e.x = lerpf(e.ox, e.ax, s)
			e.y = lerpf(e.oy, e.ay, s)
			if u >= 1.0:
				e.modo = "actuar"
				e.t = 0.0
		"salir":
			e.y -= 1.6 * esc
			if e.y < -50:
				e.muerto = true
			return
	_ia(e, esc)
	if vivo and estado != "cascada":
		var r: float = e.radio * 0.75
		if dist2(e.x, e.y, jx, jy) < r * r:
			var podia_doler := iframes <= 0
			_recibir_dano(float(e.def.get("toque", 22.0)), e.tipo)
			# la mosca se revienta contra ti: no vale como kill
			if podia_doler and e.def.ia == "enjambre":
				e.muerto = true
				explosion(e.x, e.y, "expl_chica")


func _ia(e: Enemigo, esc: float) -> void:
	match e.def.ia:
		"ruta":
			e.cd -= esc
			if e.cd <= 0:
				e.cd = float(e.def.disparo) * randf_range(0.85, 1.25) * nivel.agresion * mult_disparo
				# al empezar el nivel aún no tienes con qué responder: disparan menos
				var ganas: float = clampf(0.35 + guion_t / 60.0, 0.35, 1.0)
				if e.y > 0 and e.y < 250 and e.disparos < (1 if idx_nivel < 2 else 2) and randf() < ganas:
					e.disparos += 1
					# a partir de la Grúa, algunos apuntan adonde vas: seguir derecho ya no salva
					var adelanto := 0.0
					if idx_nivel >= 3 and randf() < (0.25 if idx_nivel < 5 else 0.35):
						adelanto = 0.4 if idx_nivel < 5 else 0.6
					_apuntado(e.x, e.y + 8, 1.9, 1, 0.0, B_ORBE, 0, adelanto)
					Sonido.tocar("disparo_grueso", 1.8, -14.0, 6)
		"enjambre":
			_ia_mosca(e, esc)
		"kamikaze":
			if e.modo == "actuar":
				e.mt += esc
				e.linea = minf(e.mt / 45.0, 1.0)
				if e.mt < 30.0:
					e.dx = jx
					e.dy = jy
				if e.mt >= 45.0:
					e.modo = "lanzado"
					e.linea = 0.0
					var v := Vector2(e.dx - e.x, e.dy - e.y).normalized() * 4.4 * mult_vel
					e.ex = v.x
					e.ey = v.y
					Sonido.tocar("dash", 0.7, -4.0)
			elif e.modo == "lanzado":
				e.x += e.ex * esc
				e.y += e.ey * esc
				if e.x < -30 or e.x > ANCHO + 30 or e.y < -30 or e.y > ALTO + 30:
					e.muerto = true
		"sniper":
			if e.modo != "actuar":
				return
			e.mt += esc
			if e.t > e.def.permanece:
				e.modo = "salir"
				e.linea = 0.0
				e.frame_extra = -1
				return
			if e.mt >= 60.0 and e.mt < 130.0:
				e.linea = 1.0
				if e.mt < 105.0:
					e.dx = jx
					e.dy = jy
				e.frame_extra = 5 if e.mt > 105.0 else 4
			elif e.mt >= 130.0:
				var v := Vector2(e.dx - e.x, e.dy - e.y).normalized() * 6.0
				_bala(e.x, e.y + 18, v.x, v.y, B_PUNTA, 0, e.id)
				e.linea = 0.0
				e.mt = 0.0
				e.frame_extra = -1
				Sonido.tocar("disparo_grueso", 1.5, -3.0)
		"spammer":
			if e.modo != "actuar":
				return
			if e.t > e.def.permanece:
				e.modo = "salir"
				return
			e.cd -= esc
			e.frame_extra = 5 if e.cd <= 14.0 else -1
			if e.cd <= 0:
				e.cd = 110.0 * mult_disparo
				var n := 5 + mini(ciclo / 2, 2)
				_apuntado(e.x, e.y + 14, 1.55, n, 44.0, B_BURBUJA, e.id)
				Sonido.tocar("disparo_cohete", 1.3, -5.0)
		"tanque":
			if e.modo != "actuar":
				return
			if e.t > e.def.permanece:
				e.modo = "salir"
				return
			e.cd -= esc
			if e.cd <= 0:
				e.cd = 130.0 * mult_disparo
				_anillo(e.x, e.y, 1.45, 18, randf() * 0.4, _hueco_cerca(e.x, e.y), 0.75, B_ORBE, e.id)
				Sonido.tocar("disparo_riel", 0.6, -6.0)
		"apoyo":
			if e.modo != "actuar":
				return
			if e.t > e.def.permanece:
				e.modo = "salir"
				return
			e.cd -= esc
			if e.cd <= 0:
				e.cd = 60.0
				var mejor: Enemigo = null
				var md := 170.0 * 170.0
				for o in enemigos:
					if o != e and not o.muerto and o.hp < o.hpmax and not o.jefe:
						var d := dist2(o.x, o.y, e.x, e.y)
						if d < md:
							md = d
							mejor = o
				if mejor:
					mejor.hp = minf(mejor.hp + mejor.hpmax * 0.1, mejor.hpmax)
					e.dx = mejor.x
					e.dy = mejor.y
					e.enlace = 22.0
		"grua":
			_ia_grua(e, esc)
		"compactador":
			_ia_compactador(e, esc)


## Te persigue suave, con vaivén para que no se vean en fila. Si no la matas, se aburre y se va.
func _ia_mosca(e: Enemigo, esc: float) -> void:
	if e.t > float(e.def.dura):
		e.vy = lerpf(e.vy, -2.6, 0.04 * esc)
		e.x += e.vx * esc
		e.y += e.vy * esc
		if e.y < -30.0:
			e.muerto = true
		return
	var hacia := Vector2(jx - e.x, jy - e.y)
	var dist := hacia.length()
	if dist > 1.0:
		hacia /= dist
	var deseo := hacia.rotated(sin(e.id * 1.7 + e.t * 3.2) * 0.7) * 1.1 * mult_vel
	e.vx = lerpf(e.vx, deseo.x, 0.025 * esc)
	e.vy = lerpf(e.vy, deseo.y, 0.025 * esc)
	e.x += e.vx * esc
	e.y += e.vy * esc


## Por dónde deja pasar un anillo: cerca de ti, pero no justo encima. Quedarse en el mismo lugar no salva.
func _hueco_cerca(x: float, y: float) -> float:
	return atan2(jy - y, jx - x) + randf_range(0.35, 0.8) * (1.0 if randf() < 0.5 else -1.0)


func _ia_grua(e: Enemigo, esc: float) -> void:
	if e.modo != "actuar":
		return
	e.x = e.ax + sin(e.t * (0.55 + 0.25 * e.fase)) * e.amp
	e.y = e.ay + sin(e.t * 1.1) * 12.0
	var boca_y := e.y + 38.0
	e.cd -= esc
	if e.cd <= 0:
		e.cd = (70.0 - e.fase * 14.0) * e.mult_cd
		_apuntado(e.x, boca_y, 1.9, 5 - e.fase, 44.0 - e.fase * 8.0, B_ORBE, e.id, 0.3 if e.fase > 0 else 0.0)
		Sonido.tocar("disparo_grueso", 0.9, -5.0)
	e.cd2 -= esc
	if e.cd2 <= 0:
		e.cd2 = (200.0 - e.fase * 40.0) * e.mult_cd
		_anillo(e.x, boca_y, 1.4, 16 + e.fase * 6, randf() * TAU, _hueco_cerca(e.x, boca_y), 0.7, B_GRANDE if e.fase > 0 else B_ORBE, e.id)
		Sonido.tocar("disparo_riel", 0.55, -4.0)
	if e.fase >= 1:
		e.cd3 -= esc
		if e.cd3 <= 0:
			e.cd3 = 300.0 * e.mult_cd
			pendientes.append({"t": 0.0, "tipo": "bot", "ruta": "arco_izq"})
			pendientes.append({"t": 0.3, "tipo": "bot", "ruta": "arco_der"})
	_refuerzos_jefe(e, esc, 420.0, 7)


## Los jefes piden ayuda: moscas que dan algo que matar, cadena y carga de Desync.
func _refuerzos_jefe(e: Enemigo, esc: float, cada: float, n: int) -> void:
	e.ex += esc
	if e.ex < cada:
		return
	e.ex = 0.0
	var lado := "izq" if randf() < 0.5 else "der"
	for k in n:
		pendientes.append({"t": k * 0.1, "tipo": "mosca", "enjambre": lado})


func _ia_compactador(e: Enemigo, esc: float) -> void:
	if e.modo != "actuar":
		return
	e.x = e.ax + sin(e.t * 0.5) * (46.0 + e.fase * 26.0)
	e.mt += esc
	var ciclo_boca := fposmod(e.mt, 420.0)
	var objetivo := 1.0 if ciclo_boca > 130.0 and ciclo_boca < 380.0 else 0.0
	e.apertura = move_toward(e.apertura, objetivo, 0.03 * esc)
	e.mult_dano = lerpf(0.55, 1.5, e.apertura)
	var quij := e.y + 34.0
	match e.fase:
		0:
			e.cd -= esc
			if e.cd <= 0:
				e.cd = 70.0 * e.mult_cd
				if e.apertura > 0.5:
					_apuntado(e.x - 52.0, quij, 1.7, 3, 26.0, B_ORBE, e.id, 0.3)
					_apuntado(e.x + 52.0, quij, 1.7, 3, 26.0, B_ORBE, e.id, 0.3)
				else:
					_anillo(e.x, quij, 1.45, 16, randf() * TAU, _hueco_cerca(e.x, quij), 0.8, B_ORBE, e.id)
				Sonido.tocar("disparo_grueso", 0.8, -5.0)
		1:
			e.cd2 -= esc
			if e.cd2 <= 0:
				e.cd2 = 100.0 * e.mult_cd
				# dos murallas con el hueco a la misma altura: hay que ir a buscarlo
				var hueco := randi_range(1, 4)
				for k in 6:
					if k == hueco:
						continue
					var yy := 120.0 + k * 40.0
					_bala(0.0, yy, 1.05 * mult_vel, 0.0, B_GRANDE if k % 3 == 0 else B_ORBE, 0, e.id, true)
					_bala(ANCHO, yy + 20.0, -1.05 * mult_vel, 0.0, B_GRANDE if k % 3 == 1 else B_ORBE, 0, e.id, true)
				Sonido.tocar("disparo_riel", 0.5, -5.0)
			e.cd -= esc
			if e.cd <= 0:
				e.cd = 70.0 * e.mult_cd
				_apuntado(e.x, quij, 1.9, 3, 22.0, B_ORBE, e.id, 0.4)
		2:
			e.giro += 0.055 * esc
			e.cd -= esc
			if e.cd <= 0:
				e.cd = 11.0
				for k in 2:
					var a := e.giro + k * PI
					_bala(e.x, quij, cos(a) * 1.25 * mult_vel, sin(a) * 1.25 * mult_vel, B_ORBE, 0, e.id, true)
			e.cd2 -= esc
			if e.cd2 <= 0:
				e.cd2 = 240.0
				pendientes.append({"t": 0.0, "tipo": "rabioso", "ancla": [60, 120]})
				pendientes.append({"t": 0.4, "tipo": "rabioso", "ancla": [340, 120]})
				_apuntado(e.x, quij, 1.6, 5, 40.0, B_GRANDE, e.id, 0.5)
	_refuerzos_jefe(e, esc, 480.0, 9)


# --- balas -----------------------------------------------------------------------------------
func _bala(x: float, y: float, vx: float, vy: float, tipo: int, sprite := 0, dueno := 0, forzar := false) -> void:
	if bn >= MAX_BALAS or (bn >= presupuesto and not forzar):
		return
	bx[bn] = x
	by[bn] = y
	bvx[bn] = vx
	bvy[bn] = vy
	bt[bn] = tipo
	bs[bn] = sprite
	bd[bn] = dueno
	br[bn] = 0
	bn += 1


func quitar_bala(i: int) -> void:
	bn -= 1
	bx[i] = bx[bn]
	by[i] = by[bn]
	bvx[i] = bvx[bn]
	bvy[i] = bvy[bn]
	bt[i] = bt[bn]
	bs[i] = bs[bn]
	bd[i] = bd[bn]
	br[i] = br[bn]


## "adelanto": cuánto apunta adonde vas. 0 es adonde estás; 1, justo adonde llegarías.
func _apuntado(x: float, y: float, vel: float, n: int, abanico: float, tipo: int, dueno: int, adelanto := 0.0) -> void:
	vel *= mult_vel * _mult_vel_tiempo()
	var ox := jx
	var oy := jy
	if adelanto > 0.0:
		var demora: float = sqrt(dist2(x, y, jx, jy)) / maxf(vel, 0.1)
		ox = clampf(jx + jvx * demora * adelanto, 8.0, ANCHO - 8.0)
		oy = clampf(jy + jvy * demora * adelanto, 14.0, ALTO - 14.0)
	var base := atan2(oy - y, ox - x)
	for k in n:
		var f := 0.0 if n == 1 else float(k) / float(n - 1) - 0.5
		var a := base + deg_to_rad(abanico) * f
		var s := randi() % BURBUJAS.size() if tipo == B_BURBUJA else 0
		_bala(x, y, cos(a) * vel, sin(a) * vel, tipo, s, dueno)


func _anillo(x: float, y: float, vel: float, n: int, rot: float, hueco_ang: float, hueco_ancho: float, tipo: int, dueno: int) -> void:
	vel *= mult_vel * _mult_vel_tiempo()
	for k in n:
		var a := rot + TAU * k / n
		if absf(wrapf(a - hueco_ang, -PI, PI)) < hueco_ancho / 2.0:
			continue
		_bala(x, y, cos(a) * vel, sin(a) * vel, tipo, 0, dueno)


# =========================================================================================
# COLISIONES
# =========================================================================================
func _colisiones() -> void:
	var en_desync := estado == "desync"
	# las burbujas se buscan una sola vez por cuadro: con muchas balas, esto pesa
	var burbujas := PackedInt32Array()
	if not en_desync:
		for b in bn:
			if bt[b] == B_BURBUJA:
				burbujas.append(b)
	var hubo_burbuja := false
	var bono := _bono_cascada() if en_desync else 1.0
	var i := tiros.size() - 1
	while i >= 0:
		var t := tiros[i]
		var quitado := false
		for e in enemigos:
			if e.muerto or e.y < -12:
				continue
			var ddx := t.x - e.x
			var ddy := t.y - e.y
			var r: float = e.radio + 3.0 * t.escala
			if ddx * ddx + ddy * ddy >= r * r:
				continue
			if t.golpeados.get(e.id, 0) > ticks:
				continue
			# en Desync, el que ya está sentenciado no ataja más balas: pasan al siguiente
			if en_desync and not e.jefe and e.cola_dano * bono >= e.hp:
				# igual se cuenta en el número que se ve, para que suba entero (no cambia el daño)
				if not t.vistos.has(e.id):
					t.vistos[e.id] = true
					e.cola_vis += 1
					e.flash = 2
				continue
			t.golpeados[e.id] = ticks + t.rehit if t.rehit > 0 else 2147483647
			golpear(e, t.dmg, t.crit, t.x, t.y)
			if t.expl > 0:
				_explotar(t.x, t.y, t.expl, t.dmg * 0.7, e.id)
			if t.perfora > 0:
				t.perfora -= 1
			else:
				tiros.remove_at(i)
				quitado = true
				break
		if not quitado and not burbujas.is_empty():
			for b in burbujas:
				if bt[b] != B_BURBUJA:
					continue
				var ddx := t.x - bx[b]
				var ddy := t.y - by[b]
				if ddx * ddx + ddy * ddy < 64.0:
					chispa(bx[b], by[b], UI.C_ROSA, 5)
					_gema(bx[b], by[b], "bit", 1)
					bt[b] = -1
					hubo_burbuja = true
					Sonido.tocar("impacto", 1.5, -4.0)
					if t.perfora > 0:
						t.perfora -= 1
					else:
						tiros.remove_at(i)
					break
		i -= 1
	if hubo_burbuja:
		var k := burbujas.size() - 1
		while k >= 0:
			if bt[burbujas[k]] == -1:
				quitar_bala(burbujas[k])
			k -= 1
	if not vivo:
		return
	var roce2: float = stats.roce_rad * stats.roce_rad
	var hb := hitbox()
	var b := bn - 1
	while b >= 0:
		var dx := bx[b] - jx
		var dy := by[b] - jy
		var d2 := dx * dx + dy * dy
		if d2 < roce2:
			var rb := _radio_bala(bt[b])
			if d2 < (hb + rb) * (hb + rb):
				if iframes <= 0 and br[b] != 2:
					# Lag Switch: a veces la bala te atraviesa
					if stats.esquiva_pct > 0.0 and randf() < stats.esquiva_pct:
						br[b] = 2
						texto(jx, jy - 22, "¡LAG!", UI.C_CIAN, 1)
						Sonido.tocar("roce", 0.7, -2.0, 4)
					else:
						var dmg_bala := 22.0
						match bt[b]:
							B_PELLET:
								dmg_bala = 16.0
							B_GRANDE:
								dmg_bala = 28.0
							B_PUNTA:
								dmg_bala = 32.0
						var de_quien: String = _nombre_bala(bt[b])
						quitar_bala(b)
						_recibir_dano(dmg_bala, de_quien)
						if not vivo:
							return
			elif br[b] == 0:
				br[b] = 1
				_rozar(bx[b], by[b])
		b -= 1


func _nombre_bala(tipo: int) -> String:
	match tipo:
		B_GRANDE:
			return "bala_grande"
		B_PUNTA:
			return "bala_sniper"
		B_BURBUJA:
			return "burbuja"
	return "bala"


func _radio_bala(tipo: int) -> float:
	match tipo:
		B_GRANDE:
			return 6.0
		B_PELLET:
			return 2.0
		B_PUNTA:
			return 2.5
		B_BURBUJA:
			return 4.5
	return 3.5


func _rozar(x: float, y: float) -> void:
	roces += 1
	_sumar_barra(1.6)
	if not cadena_bajando and cadena > 0:
		cadena_t = minf(cadena_t + 20.0, _ventana_cadena())
	if stats.roce_dano > 0.0:
		roce_bono = minf(roce_bono + stats.roce_dano, TOPE_ROCE)
		roce_t = TIEMPO_ROCE
	Sonido.tocar("roce", randf_range(0.95, 1.1), -6.0, 2)
	chispa(lerpf(x, jx, 0.5), lerpf(y, jy, 0.5), Color.WHITE, 3)


func golpear(e: Enemigo, dmg: float, crit: bool, x: float, y: float) -> void:
	if e.muerto:
		return
	if estado == "desync":
		if e.cola_hits == 0:
			cola.append(e)
		e.cola_hits += 1
		e.cola_vis += 1
		e.cola_dano += dmg * e.mult_dano
		cola_total += 1
		e.flash = 2
		Sonido.tocar("desync_tick", 1.0 + minf(cola_total * 0.004, 0.6), 0.0, 2)
		return
	_aplicar(e, dmg, crit, x, y)


func _aplicar(e: Enemigo, dmg: float, crit: bool, x: float, y: float, cascada := false) -> void:
	if e.inv > 0 and not cascada:
		return
	if e.primer_golpe < 0:
		e.primer_golpe = ticks
	# cuánto dura de verdad bajo fuego: los ratos en que no le estás apuntando no cuentan
	if e.ult_golpe >= 0 and ticks - e.ult_golpe <= 20:
		e.bajo_fuego += ticks - e.ult_golpe
	e.ult_golpe = ticks
	var d := dmg if cascada else dmg * e.mult_dano
	if e.jefe and not cascada:
		d = _limitar_jefe(e, d)
	e.hp -= d
	e.flash = 3
	if not cascada:
		num(x, y, d, UI.C_ORO if crit else UI.C_TEXTO, 1)
		Sonido.tocar("impacto", randf_range(0.95, 1.1), -9.0, 3)
	if e.jefe:
		_revisar_fase(e)
	if e.hp <= 0:
		_matar(e)


## Retorno decreciente: dentro de cada ventana de 60 cuadros, lo que le puedes sacar a un jefe tiende a un tope.
## Así ninguna build lo baja en menos del tiempo pensado, pero a una build normal casi no se le nota.
func _limitar_jefe(e: Enemigo, d: float) -> float:
	if ticks - e.v_inicio >= 60:
		e.v_inicio = ticks
		e.v_raw = 0.0
		e.v_ef = 0.0
	var tope: float = e.hpmax / float(e.def.get("tope_seg", 60.0))
	e.v_raw += d
	var ef: float = tope * (1.0 - exp(-e.v_raw / tope))
	var real := maxf(ef - e.v_ef, 0.0)
	e.v_ef = ef
	return real


func _revisar_fase(e: Enemigo) -> void:
	var fases: Array = e.def.get("fases", [])
	if e.fase < fases.size() and e.hp <= e.hpmax * fases[e.fase] and e.hp > 0:
		e.fase += 1
		e.inv = 80.0
		e.cd = 100.0
		e.cd2 = 60.0
		e.cd3 = 120.0
		_limpiar_todo()
		sacudir(9.0)
		congelado = 8
		flash(Color.WHITE, 0.35)
		_grande("¡SE ENOJÓ!", UI.C_ROJO, 2, 70)
		# un respiro entre fases: en una pelea larga, sin kills, casi no caerían pizzas
		if not Partida.dif().get("sin_pizza", false):
			_gema(e.x, e.y + 30.0, "pizza")
		Sonido.tocar("fase_jefe")


func _explotar(x: float, y: float, radio: float, dmg: float, excluir: int) -> void:
	explosion(x, y, "expl_chica" if radio < 40.0 else "expl_media")
	Sonido.tocar("kill", 1.3, -6.0, 3)
	for e in enemigos:
		if e.muerto or e.id == excluir:
			continue
		var r: float = radio + e.radio
		if dist2(x, y, e.x, e.y) < r * r:
			golpear(e, dmg, false, e.x, e.y)


func _anotar_ttk(e: Enemigo) -> void:
	if e.primer_golpe < 0 or e.por_cascada or e.jefe:
		return
	var dura: float = e.bajo_fuego
	var f: Array = ttk.get(e.tipo, [0, 0.0])
	f[0] += 1
	f[1] += dura
	ttk[e.tipo] = f
	if guion_t >= float(nivel.duracion) * 0.85:
		var g: Array = ttk_tarde.get(e.tipo, [0, 0.0])
		g[0] += 1
		g[1] += dura
		ttk_tarde[e.tipo] = g


func _matar(e: Enemigo) -> void:
	e.muerto = true
	kills += 1
	kills_tipo[e.tipo] = kills_tipo.get(e.tipo, 0) + 1
	_anotar_ttk(e)
	var grande: bool = e.radio > 16.0
	cadena += 1
	max_cadena = maxi(max_cadena, cadena)
	cadena_t = _ventana_cadena()
	cadena_bajando = false
	_actualizar_tier(true)
	_sumar_barra(7.0 if grande else (0.8 if e.tipo == "mosca" else 1.4))
	if stats.leech > 0.0:
		curar(stats.leech)
	var i := bn - 1
	while i >= 0:
		if bd[i] == e.id:
			chispa(bx[i], by[i], UI.C_ORO, 3)
			if i % 3 == 0:
				_gema(bx[i], by[i], "bit", 1)
			quitar_bala(i)
		i -= 1
	var val: int = int(e.def.xp)
	var trozos := mini(ceili(val / 3.0), 5)
	for k in trozos:
		_gema(e.x + randf_range(-6, 6), e.y + randf_range(-6, 6), "bit", val / trozos + (1 if k < val % trozos else 0))
	# la chatarra la sueltan los enemigos: asi se entiende de donde sale
	if grande:
		_gema(e.x, e.y, "tuerca", 3)
	elif randf() < (0.06 if e.tipo == "mosca" else 0.22):
		_gema(e.x, e.y, "tuerca", 1)
	_soltar_objeto(e, grande)
	if stats.reaccion > 0.0 and randf() < stats.reaccion:
		_explotar(e.x, e.y, 28.0 * stats.area, stats.atk * stats.dano * 1.5, e.id)
	if e.jefe:
		_matar_jefe(e)
		return
	explosion(e.x, e.y, "expl_media" if grande else "expl_chica")
	Sonido.tocar("kill_grande" if grande else "kill", randf_range(0.92, 1.1), -2.0 if grande else -4.0, 2)
	sacudir(5.0 if grande else 1.5)
	if grande:
		congelado = 4
	for k in (10 if grande else 4):
		particula(e.x, e.y, randf_range(-2, 2), randf_range(-2, 2), Color("ffb04a"), randi_range(10, 24))


## Pizzas, imanes y bombas: con tantos enemigos, van con plazo mínimo; así no depende de cuántos mates.
func _soltar_objeto(e: Enemigo, grande: bool) -> void:
	var q := randf()
	var bajo: bool = hp < stats.hp * 0.4
	if pizza_cd <= 0 and q < (0.08 if bajo else 0.03) and not Partida.dif().get("sin_pizza", false):
		_gema(e.x, e.y, "pizza")
		pizza_cd = 720 if bajo else 1440
	elif q >= 0.9 and q < 0.91:
		_gema(e.x, e.y, "iman")
	elif bomba_cd <= 0 and q >= 0.91 and q < 0.92:
		_gema(e.x, e.y, "bomba")
		bomba_cd = 2400
	elif grande and q >= 0.75 and q < 0.9:
		_gema(e.x, e.y, "cofre")


func _tick_botin() -> void:
	if pizza_cd > 0:
		pizza_cd -= 1
	if bomba_cd > 0:
		bomba_cd -= 1


func _matar_jefe(e: Enemigo) -> void:
	jefes_muertos += 1
	t_jefes.append({"tipo": e.tipo, "seg": (ticks - e.nacio) / 60.0})
	jefe_actual = null
	for o in enemigos:
		if o != e and o.jefe and not o.muerto:
			jefe_actual = o
	if jefe_actual == null:
		Sonido.musica_jefe(false)
	_limpiar_todo()
	var tuercas := 18 if e.final or e.tipo == "compactador" else 8
	if e.super_jefe:
		tuercas = 30
		_gema(e.x - 20.0, e.y, "cofre")
		_gema(e.x + 20.0, e.y, "cofre")
	for k in tuercas:
		_gema(e.x + randf_range(-30, 30), e.y + randf_range(-30, 30), "tuerca", 5)
	for g in gemas:
		g.imantada = true
	if e.final:
		victoria_pendiente = true
		ex_jefe = Vector2(e.x, e.y)
		for o in enemigos:
			if o != e and not o.muerto:
				o.muerto = true
				explosion(o.x, o.y, "expl_media")
		pendientes.clear()
		if estado == "jugando":
			estado = "victoria"
			estado_t = 170.0
		Sonido.silencio(true)
	else:
		explosion(e.x, e.y, "expl_grande")
		Sonido.tocar("kill_jefe")
		congelado = 10
		sacudir(14.0)
		flash(Color.WHITE, 0.6)
		_grande("¡JEFE ABAJO!", UI.C_ORO, 3, 100)
	for k in 40:
		particula(e.x, e.y, randf_range(-4, 4), randf_range(-4, 4), UI.C_ORO, randi_range(20, 60))


func _tick_victoria() -> void:
	estado_t -= 1.0
	_tick_gemas()
	if ex_jefe.x > -900:
		if int(estado_t) % 7 == 0 and estado_t > 40:
			explosion(ex_jefe.x + randf_range(-58, 58), ex_jefe.y + randf_range(-52, 52), "expl_media")
			Sonido.tocar("kill", randf_range(0.7, 1.1), -2.0, 1)
			sacudir(5.0)
		if int(estado_t) == 40:
			explosion(ex_jefe.x, ex_jefe.y, "expl_grande")
			explosion(ex_jefe.x - 40, ex_jefe.y + 10, "expl_grande")
			explosion(ex_jefe.x + 40, ex_jefe.y - 10, "expl_grande")
			Sonido.tocar("kill_jefe")
			Sonido.tocar("ace")
			sacudir(18.0)
			flash(Color.WHITE, 0.9)
			_grande("¡%s CAYÓ!" % Datos.ENEMIGOS[nivel.jefe].nombre.to_upper(), UI.C_ORO, 2, 80)
	if estado_t <= 0:
		_fin(true)


func _fin(ganado: bool) -> void:
	estado = "fin"
	set_physics_process(false)
	Sonido.silencio(false)
	Sonido.desync(false)
	Sonido.musica_jefe(false)
	terminado.emit({
		"ganado": ganado, "kills": kills, "jefes": jefes_muertos, "jefe": nivel.has("jefe") or jefes_muertos > 0, "tiempo": tiempo_jugado / 60, "nivel": nivel_carta,
		"max_cadena": max_cadena, "desyncs": desyncs, "aces": aces, "roces": roces, "nams": nams, "golpes": golpes,
		"chatarra": chatarra, "evoluciones": evoluciones, "nivel_id": nivel_id, "abandono": abandono, "hp": int(maxf(hp, 0.0)), "hp_max": int(stats.hp), "build": _build(),
		"modo": modo_nivel, "kills_tipo": kills_tipo, "esquivas": esquivas, "cambios": cambios_usados, "giros": giros, "jackpots": jackpots, "nave": nave_id,
		"ttk": ttk, "ttk_tarde": ttk_tarde, "t_jefes": t_jefes, "golpes_por": golpes_por, "cascadas": cascadas, "jefe_hp": (jefe_actual.hp / jefe_actual.hpmax) if jefe_actual != null else -1.0,
	})


func _build() -> String:
	var r := PackedStringArray()
	for a in arsenal.armas:
		r.append("%s%d%s" % [a.id, a.nivel, "*" if a.evo else ""])
	for h in habs:
		r.append("%s%d" % [h, habs[h]])
	return ",".join(r)


## Mientras más larga la cadena, menos tiempo tienes para seguirla.
func _ventana_cadena() -> float:
	return lerpf(VENTANA_MAX, VENTANA_MIN, clampf(float(cadena) / CADENA_LARGA, 0.0, 1.0))


func _tick_cadena() -> void:
	if cadena <= 0:
		return
	cadena_t -= 1.0
	if cadena_t <= 0.0:
		# no se pierde de golpe: baja de a poco, y una kill la rescata
		cadena = maxi(cadena - BAJADA_CADENA, 0)
		cadena_bajando = true
		cadena_t = PLAZO_BAJADA
		_actualizar_tier(false)


func _actualizar_tier(sube: bool) -> void:
	var nuevo := 0
	for k in TIERS_CADENA.size():
		if cadena >= TIERS_CADENA[k]:
			nuevo = k + 1
	if sube and nuevo > tier_cadena:
		Sonido.tocar("racha", pow(2.0, nuevo / 12.0 * 2.0))
		texto(jx, jy - 30, "CADENA X%d" % cadena, UI.C_ORO, 1)
	tier_cadena = nuevo


# =========================================================================================
# RULETA: la tragamonedas de Don Tuerca
# =========================================================================================
func _empezar_ruleta() -> void:
	estado = "ruleta"
	afk_mira = -1.0
	Sonido.tocar("aviso_jefe", 1.3)
	flash(UI.C_ORO, 0.4)
	# se limpia el campo: lo que quedaba revienta, y cuenta
	_limpiar_todo()
	for e in enemigos:
		if not e.muerto and not e.jefe and e.y > -10:
			_matar(e)
		elif not e.muerto and not e.jefe:
			e.muerto = true
	pendientes.clear()
	_girar_ruleta()


func _simbolo() -> int:
	var total := 0.0
	for p in PESOS_RULETA:
		total += p
	var x: float = director.rng.randf() * total
	for i in PESOS_RULETA.size():
		x -= PESOS_RULETA[i]
		if x <= 0.0:
			return i
	return 0


func _girar_ruleta() -> void:
	giros += 1
	ruleta_t = 0
	ruleta_fase = "gira"
	ruleta_jackpot = false
	ruleta_txt = FRASES_GIRO[director.rng.randi() % FRASES_GIRO.size()]
	ruleta_txt2 = ""
	ruleta_col = UI.C_TEXTO
	ruleta_cara = 1
	for k in 3:
		ruleta_parado[k] = false
		ruleta_reb[k] = 0
		ruleta_pos[k] = randf() * SIMBOLOS.size()
		ruleta_res[k] = _simbolo()
	# la casa ayuda un poco: si dos ya calzan, el tercero tiende a calzar
	if ruleta_res[0] == ruleta_res[1] and director.rng.randf() < 0.42:
		ruleta_res[2] = ruleta_res[0]
	if ruleta_forzada.size() == 3:
		for k in 3:
			ruleta_res[k] = SIMBOLOS.find(ruleta_forzada[k])
	Sonido.tocar("carta", 1.2)
	Sonido.voz("tuerca")


func _tick_ruleta() -> void:
	ruleta_t += 1
	for k in 3:
		if ruleta_reb[k] > 0:
			ruleta_reb[k] -= 1
	if ruleta_fase == "gira":
		var todos := true
		for k in 3:
			if ruleta_parado[k]:
				continue
			todos = false
			ruleta_pos[k] += 0.34
			if ruleta_t >= T_RODILLO[k]:
				ruleta_parado[k] = true
				ruleta_pos[k] = float(ruleta_res[k])
				ruleta_reb[k] = 12
				Sonido.tocar("carta", 0.8 + k * 0.2, 2.0)
				Sonido.tocar("impacto", 0.7, 0.0)
				sacudir(2.0 + k)
		if not todos and ruleta_t % 5 == 0:
			Sonido.tocar("ui_mover", randf_range(1.0, 1.3), -4.0, 1)
		if not todos and ruleta_t % 22 == 0:
			Sonido.voz("tuerca")
			ruleta_cara = 0 if ruleta_cara == 1 else 1
		if todos and ruleta_t >= T_RODILLO[2] + 26:
			_pagar_ruleta()
	elif ruleta_t >= T_PAGO:
		if ruleta_jackpot:
			_girar_ruleta()
		else:
			_cerrar_ruleta()


func _cerrar_ruleta() -> void:
	ruleta_fase = ""
	estado = "jugando"
	iframes = maxi(iframes, 40)


func _pagar_ruleta() -> void:
	ruleta_fase = "paga"
	ruleta_t = 0
	ruleta_cara = 2
	var cuenta := {}
	for k in 3:
		var s: String = SIMBOLOS[ruleta_res[k]]
		cuenta[s] = cuenta.get(s, 0) + 1
	var tres := cuenta.size() == 1
	var lineas := PackedStringArray()
	for s: String in cuenta:
		lineas.append(_premio_ruleta(s, int(cuenta[s])))
	ruleta_txt = _frase_ruleta(cuenta, tres)
	ruleta_txt2 = "  ·  ".join(lineas)
	Sonido.voz("tuerca")
	if tres:
		flash(UI.C_ORO, 0.6)
		sacudir(9.0)
		Sonido.tocar("ace")
	else:
		Sonido.tocar("botin_2")


## Lo que da cada símbolo según cuántas veces salió. Devuelve el texto del premio.
func _premio_ruleta(s: String, n: int) -> String:
	match s:
		"jefe":
			Sonido.tocar("aviso_jefe")
			if n == 3:
				pendientes.append({"t": 0.5, "tipo": "grua", "ancla": [200, 80], "mult_jefe": 1.9, "super": true})
				ruleta_col = UI.C_ROSA
				return "¡SÚPER GRÚA!"
			if n == 2:
				pendientes.append({"t": 0.5, "tipo": "grua", "ancla": [120, 70], "mult_jefe": 0.55, "amp": 70.0})
				pendientes.append({"t": 0.9, "tipo": "grua", "ancla": [280, 70], "mult_jefe": 0.55, "amp": 70.0})
				ruleta_col = UI.C_ROJO
				return "¡Dos Grúas!"
			pendientes.append({"t": 0.5, "tipo": "grua", "ancla": [200, 80], "mult_jefe": 0.75})
			ruleta_col = UI.C_ROJO
			return "¡La Grúa!"
		"compacto":
			var c: int = 2 * n
			for k in c:
				pendientes.append({"t": 0.5 + k * 0.4, "tipo": "compacto", "ancla": [40.0 + (k + 0.5) * 320.0 / c, 70.0]})
			return "%d Compactos" % c
		"horda":
			if n == 3:
				_horda(44, 12, 14)
				ruleta_col = UI.C_ROSA
				return "¡MEGA HORDA!"
			_horda(16 * n, 3 * n, 0)
			return "Horda" if n == 1 else "Horda doble"
		"moneda", "bolsa", "diamante":
			var plata: int = int(PLATA_RULETA[s]) * n
			if n == 3:
				plata *= 10
				ruleta_jackpot = true
				jackpots += 1
				ruleta_col = UI.C_ORO
			_lluvia_chatarra(plata)
			if n == 3:
				return "¡JACKPOT! +%d chatarra. ¡Gira otra vez!" % plata
			return "+%d chatarra" % plata
		"pizza":
			if n == 3:
				curar(stats.hp)
				ruleta_col = UI.C_VERDE
				return "¡Cura total!"
			curar(CURA_PIZZA * n)
			Sonido.tocar("pizza")
			return "+%d de vida" % int(CURA_PIZZA * n)
		"cofre":
			niveles_pendientes += 3 if n == 3 else n
			if n == 3:
				ruleta_col = UI.C_ORO
				return "¡3 cartas gratis!"
			return "1 carta gratis" if n == 1 else "%d cartas gratis" % n
	return ""


func _horda(moscas: int, rabiosos: int, bots: int) -> void:
	var lados := ["izq", "der", "arriba", "arriba_izq", "arriba_der"]
	for k in moscas:
		pendientes.append({"t": 0.4 + k * 0.05, "tipo": "mosca", "enjambre": lados[k % lados.size()]})
	for k in rabiosos:
		pendientes.append({"t": 1.5 + k * 0.45, "tipo": "rabioso", "ancla": [50.0 + (k % 6) * 60.0, 60.0 + (k % 3) * 28.0]})
	var rutas_h := ["arco_izq", "arco_der", "rulo_izq", "rulo_der", "barrido_izq", "barrido_der"]
	for k in bots:
		pendientes.append({"t": 2.0 + k * 0.25, "tipo": "bot", "ruta": rutas_h[k % rutas_h.size()]})


func _lluvia_chatarra(total: int) -> void:
	var trozos: int = clampi(total / 4, 1, 16)
	for k in trozos:
		var g_x := 200.0 + randf_range(-90.0, 90.0)
		_gema(g_x, randf_range(120.0, 240.0), "tuerca", total / trozos + (1 if k < total % trozos else 0))


func _frase_ruleta(cuenta: Dictionary, tres: bool) -> String:
	if tres:
		if cuenta.has("jefe"):
			return "¡Ahora sí te fuiste, cabro!"
		if cuenta.has("horda"):
			return "¡Se me abrió la jaula entera!"
		if cuenta.has("pizza"):
			return "¡Pizza para el regalón!"
		if cuenta.has("cofre"):
			return "¡Eso no estaba en el plan!"
		return "¡ME ARRUINASTE, CABRO!"
	if cuenta.has("jefe"):
		return "¡La casa siempre gana!"
	if cuenta.has("horda") or cuenta.has("compacto"):
		return "¡Te mandé a los amigos!"
	if cuenta.has("cofre"):
		return "Algo bueno tenía que salir."
	return "Ya, toma. No te acostumbres."


# =========================================================================================
# CARTAS: ranuras limitadas y sinergias
# =========================================================================================
func _abrir_cartas() -> void:
	niveles_pendientes -= 1
	cartas = _generar_cartas()
	carta_sel = 1
	carta_t = 0
	estado = "cartas"
	Sonido.tocar("nivel")


func _generar_cartas() -> Array:
	var mundo: int = Datos.mundo_de(nivel_id)
	var opciones := []
	# una evolucion lista siempre aparece primero
	for a in arsenal.armas:
		if a.nivel >= Datos.NIVEL_MAX_CARTA and not a.evo and habs.has(a.def.sinergia):
			opciones.append({"tipo": "evo", "id": a.id, "nombre": a.def.evo.nombre, "desc": a.def.evo.desc, "icono": "icono_" + a.id})
	var pool := []
	var en_mano := []
	for a in arsenal.armas:
		en_mano.append(a.id)
		if a.nivel < Datos.NIVEL_MAX_CARTA:
			var c := _carta_arma(a.id, a.nivel)
			pool.append(c)
			pool.append(c)
	if arsenal.armas.size() < Partida.max_armas():
		for id: String in Partida.armas_disponibles(mundo):
			if arsenal.buscar(id) == null:
				pool.append(_carta_arma(id, 0))
	for id: String in habs:
		if habs[id] < Datos.max_hab(id):
			var c := _carta_hab(id, habs[id])
			pool.append(c)
			pool.append(c)
	if habs.size() < Partida.max_habs():
		for id: String in Partida.habs_disponibles(mundo, en_mano):
			if not habs.has(id):
				var c := _carta_hab(id, 0)
				pool.append(c)
				# si es la sinergia de un arma que ya tienes, sale mas seguido
				var ar: String = Datos.arma_con_sinergia(id)
				if ar != "" and arsenal.buscar(ar) != null:
					pool.append(c)
					pool.append(c)
	pool.shuffle()
	var vistos := {}
	for o in opciones:
		vistos[o.id] = true
	for p in pool:
		if opciones.size() >= 3:
			break
		if vistos.has(p.id):
			continue
		vistos[p.id] = true
		opciones.append(p)
	# con todo lleno, subir de nivel igual sirve de algo
	for r in _cartas_relleno():
		if opciones.size() >= 3:
			break
		opciones.append(r)
	return opciones.slice(0, 3)


func _cartas_relleno() -> Array:
	var r := [
		{"tipo": "cura", "id": "cura", "nombre": "Pizza Caliente", "desc": "Te cura 25 de vida.", "icono": "icono_pizza"},
		{"tipo": "chatarra", "id": "chat", "nombre": "Bolsa de Chatarra", "desc": "+20 de chatarra.", "icono": "obj_tuerca_grande"},
	]
	if tiene_desync:
		r.append({"tipo": "cura2", "id": "cura2", "nombre": "Sopaipilla", "desc": "Te cura 12 de vida y carga un poco el Desync.", "icono": "icono_copium"})
	else:
		r.append({"tipo": "dano", "id": "cafe", "nombre": "Café Recalentado", "desc": "+2 % de daño en esta partida.", "icono": "icono_p2w"})
	return r


func _carta_arma(id: String, nv: int) -> Dictionary:
	var d: Dictionary = Datos.ARMAS[id]
	var desc: String = d.desc if nv == 0 else d.mejoras[nv - 1].txt
	var sin: String = d.sinergia
	return {"tipo": "arma", "id": id, "nombre": d.nombre, "desc": desc, "nv": nv, "max": Datos.NIVEL_MAX_CARTA, "icono": "icono_" + id,
		"sinergia": Datos.nombre_hab(sin), "sin_ok": habs.has(sin), "sin_icono": "icono_" + sin, "sin_txt": "Evoluciona con:"}


func _carta_hab(id: String, nv: int) -> Dictionary:
	var d: Dictionary = Datos.HABILIDADES[id]
	var desc: String = d.desc if nv == 0 else d.por_nivel
	var c := {"tipo": "hab", "id": id, "nombre": d.nombre, "desc": desc, "nv": nv, "max": Datos.max_hab(id), "icono": "icono_" + id}
	var ar: String = Datos.arma_con_sinergia(id)
	if ar != "":
		c["sinergia"] = Datos.ARMAS[ar].nombre
		c["sin_ok"] = arsenal.buscar(ar) != null
		c["sin_icono"] = "icono_" + ar
		c["sin_txt"] = "Hace evolucionar:"
	return c


func elegir_carta(i: int) -> void:
	if estado != "cartas":
		return
	var c: Dictionary = cartas[clampi(i, 0, cartas.size() - 1)]
	Sonido.tocar("carta")
	match c.tipo:
		"arma":
			var a := arsenal.buscar(c.id)
			if a:
				arsenal.subir(a)
			else:
				arsenal.agregar(c.id)
		"hab":
			var id: String = c.id
			habs[id] = habs.get(id, 0) + 1
			var h: Dictionary = Datos.HABILIDADES[id]
			if h.has("mods"):
				Partida._sumar(stats, h.mods)
			if h.has("cura"):
				curar(h.cura)
			if h.get("especial", "") == "escudo" and habs[id] == 1:
				escudo = true
		"evo":
			arsenal.evolucionar(arsenal.buscar(c.id))
			evoluciones += 1
			Sonido.tocar("botin_4")
			flash(UI.C_ORO, 0.4)
			_grande("¡%s!" % c.nombre.to_upper(), UI.C_ORO, 2, 90)
		"cura":
			curar(25.0)
		"cura2":
			curar(12.0)
			barra = minf(barra + 20.0, 100.0)
		"chatarra":
			chatarra += 20
		"dano":
			stats.dano += 0.02
	if niveles_pendientes > 0:
		_abrir_cartas()
	else:
		estado = "jugando"
		iframes = maxi(iframes, 30)


func cambiar_cartas() -> void:
	if cambios_restantes <= 0 or estado != "cartas":
		Sonido.tocar("ui_no")
		return
	cambios_restantes -= 1
	cambios_usados += 1
	cartas = _generar_cartas()
	carta_t = 10
	Sonido.tocar("ui_ok")


func _tick_cartas() -> void:
	carta_t += 1
	if carta_t < 18:
		return
	if Input.is_action_just_pressed("mover_izquierda") or Input.is_action_just_pressed("ui_left"):
		carta_sel = posmod(carta_sel - 1, cartas.size())
		Sonido.tocar("ui_mover")
	if Input.is_action_just_pressed("mover_derecha") or Input.is_action_just_pressed("ui_right"):
		carta_sel = posmod(carta_sel + 1, cartas.size())
		Sonido.tocar("ui_mover")
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("disparar") or Input.is_action_just_pressed("esquivar"):
		elegir_carta(carta_sel)
	elif Input.is_action_just_pressed("desync"):
		cambiar_cartas()


func _rect_carta(i: int) -> Rect2:
	var an := 126.0
	var al := 208.0
	var x0: float = PX + (ANCHO - an * 3 - 6 * 2) / 2.0
	return Rect2(x0 + i * (an + 6), 66, an, al)


func _input(ev: InputEvent) -> void:
	if estado != "cartas" or carta_t < 18:
		return
	if ev is InputEventMouseMotion or ev is InputEventMouseButton:
		var pos: Vector2 = get_viewport().get_mouse_position()
		for i in cartas.size():
			if _rect_carta(i).has_point(pos):
				if carta_sel != i and ev is InputEventMouseMotion:
					carta_sel = i
					Sonido.tocar("ui_mover")
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					get_viewport().set_input_as_handled()
					elegir_carta(i)
					return


# =========================================================================================
# PAUSA
# =========================================================================================
func abrir_pausa() -> void:
	estado_previo = estado
	estado = "pausa"
	Sonido.pausa(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var panel := preload("res://pantallas/pausa.gd").new()
	panel.combate = self
	capa_pausa.add_child(panel)


func cerrar_pausa() -> void:
	estado = estado_previo
	sin_pausa_hasta = Engine.get_physics_frames() + 3
	Sonido.pausa(false)
	if estado == "desync":
		Sonido.desync(true)


func abandonar() -> void:
	Sonido.pausa(false)
	abandono = true
	_fin(false)


func volver_a_empezar() -> void:
	Sonido.pausa(false)
	Sonido.desync(false)
	Sonido.silencio(false)
	Sonido.musica_jefe(false)
	reiniciar.emit()


# =========================================================================================
# EFECTOS
# =========================================================================================
func explosion(x: float, y: float, tipo: String) -> void:
	if explos.size() > 40:
		return
	explos.append({"x": x, "y": y, "tipo": tipo, "t": 0})


func particula(x: float, y: float, vx: float, vy: float, c: Color, vida: int) -> void:
	if parts.size() > 260:
		return
	parts.append({"x": x, "y": y, "vx": vx, "vy": vy, "c": c, "v": vida})


func chispa(x: float, y: float, c: Color, n: int) -> void:
	for k in n:
		particula(x, y, randf_range(-1.4, 1.4), randf_range(-1.4, 1.4), c, randi_range(6, 14))


func texto(x: float, y: float, s: String, c: Color, esc := 1) -> void:
	if textos.size() > 60:
		return
	textos.append({"x": x, "y": y, "s": s, "c": c, "esc": esc, "v": 40})


func num(x: float, y: float, v: float, c: Color, esc: int) -> void:
	if not Ajustes.ver_numeros:
		return
	texto(x + randf_range(-5, 5), y - 6, str(int(ceil(v))), c, esc)


func _grande(s: String, c: Color, esc: int, vida: int, y_rel := 0) -> void:
	grandes.append({"s": s, "c": c, "esc": esc, "v": vida, "y": 150 + y_rel})


func sacudir(v: float) -> void:
	sacudida = minf(maxf(sacudida, v), 18.0)


func flash(c: Color, a: float) -> void:
	color_destello = c
	destello = maxf(destello, a * (0.25 if Ajustes.reducir_destellos else 1.0))


func _tick_fx() -> void:
	sacudida = maxf(sacudida - 0.6, 0.0)
	destello = maxf(destello - 0.04, 0.0)
	vineta = maxf(vineta - 0.03, 0.0)
	hp_visto = move_toward(hp_visto, hp, maxf(absf(hp_visto - hp) * 0.04, 0.4))
	if hp_flash > 0:
		hp_flash -= 1
	if fogonazo > 0:
		fogonazo -= 1
	if bit_t > 0:
		bit_t -= 1
		if bit_t == 0:
			bit_racha = 0
	if aviso_t > 0:
		aviso_t -= 1
	if pista_t > 0:
		pista_t -= 1
	var i := explos.size() - 1
	while i >= 0:
		explos[i].t += 1
		if explos[i].t >= 24:
			explos.remove_at(i)
		i -= 1
	i = parts.size() - 1
	while i >= 0:
		var p: Dictionary = parts[i]
		p.x += p.vx
		p.y += p.vy
		p.v -= 1
		if p.v <= 0:
			parts.remove_at(i)
		i -= 1
	i = textos.size() - 1
	while i >= 0:
		var t: Dictionary = textos[i]
		t.y -= 0.5
		t.v -= 1
		if t.v <= 0:
			textos.remove_at(i)
		i -= 1
	i = grandes.size() - 1
	while i >= 0:
		grandes[i].v -= 1
		if grandes[i].v <= 0:
			grandes.remove_at(i)
		i -= 1
	i = rayos.size() - 1
	while i >= 0:
		rayos[i].t -= 1
		if rayos[i].t <= 0:
			rayos.remove_at(i)
		i -= 1
	i = ondas.size() - 1
	while i >= 0:
		ondas[i].r += 4.0
		if ondas[i].r > 70.0:
			ondas.remove_at(i)
		i -= 1


func dist2(ax: float, ay: float, b_x: float, b_y: float) -> float:
	return (ax - b_x) * (ax - b_x) + (ay - b_y) * (ay - b_y)


# =========================================================================================
# DIBUJO
# =========================================================================================
func dibujar_fondo(c: CanvasItem) -> void:
	var lej: Texture2D = Datos.tex("fondo_chatarra_lejos")
	var cer: Texture2D = Datos.tex("fondo_chatarra_cerca")
	var h: float = lej.get_height()
	var y1 := fposmod(scroll * 0.5, h)
	c.draw_texture(lej, Vector2(0, y1 - h))
	c.draw_texture(lej, Vector2(0, y1))
	var y2 := fposmod(scroll * 1.15, h)
	c.draw_texture(cer, Vector2(0, y2 - h))
	c.draw_texture(cer, Vector2(0, y2))
	if Ajustes.atenuar_fondo > 0:
		c.draw_rect(Rect2(-30, -30, ANCHO + 60, ALTO + 60), Color(0, 0, 0, Ajustes.atenuar_fondo / 100.0))


func dibujar_mundo(c: CanvasItem) -> void:
	for e in enemigos:
		if e.linea > 0:
			var col := Color(1, 0.25, 0.3, 0.35 + 0.5 * e.linea)
			if e.def.ia == "sniper" and e.mt >= 105.0 and int(e.mt) % 6 < 3:
				col = Color(1, 1, 1, 0.95)
			c.draw_line(Vector2(e.x, e.y + 8), Vector2(e.dx, e.dy), col, 1.0)
		if e.enlace > 0:
			c.draw_line(Vector2(e.x, e.y), Vector2(e.dx, e.dy), Color(0.4, 1, 0.5, 0.8), 1.0)
	arsenal.dibujar_detras(c)
	for g in gemas:
		_dibujar_gema(c, g)
	for e in enemigos:
		if not e.muerto:
			_dibujar_enemigo(c, e)
	var orbe: Texture2D = Datos.tex("bala_orbe")
	var grande: Texture2D = Datos.tex("bala_grande")
	var pellet: Texture2D = Datos.tex("bala_pellet")
	var punta: Texture2D = Datos.tex("bala_punta")
	var fb := (ticks / 8) % 2
	for i in bn:
		var x := roundf(bx[i])
		var y := roundf(by[i])
		match bt[i]:
			B_ORBE:
				c.draw_texture_rect_region(orbe, Rect2(x - 5, y - 5, 11, 11), Rect2(fb * 11, 0, 11, 11))
			B_GRANDE:
				c.draw_texture_rect_region(grande, Rect2(x - 8, y - 8, 17, 17), Rect2(fb * 17, 0, 17, 17))
			B_PELLET:
				c.draw_texture_rect_region(pellet, Rect2(x - 3, y - 3, 7, 7), Rect2(fb * 7, 0, 7, 7))
			B_PUNTA:
				c.draw_set_transform(Vector2(x, y), atan2(bvy[i], bvx[i]) + PI / 2.0, Vector2.ONE)
				c.draw_texture(punta, Vector2(-3, -6))
				c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			B_BURBUJA:
				var b: Texture2D = Datos.tex(BURBUJAS[bs[i]])
				c.draw_texture(b, Vector2(x - b.get_width() / 2, y - 6))
	for t in tiros:
		_dibujar_tiro(c, t)
	for ex in explos:
		var t2: Texture2D = Datos.tex(ex.tipo)
		var tam: int = t2.get_height()
		var f: int = mini(ex.t / 4, 5)
		c.draw_texture_rect_region(t2, Rect2(round(ex.x - tam / 2.0), round(ex.y - tam / 2.0), tam, tam), Rect2(f * tam, 0, tam, tam))
	for p in parts:
		c.draw_rect(Rect2(round(p.x), round(p.y), 1, 1), p.c)
	for r in rayos:
		_dibujar_rayo(c, r.a, r.b)


func _dibujar_gema(c: CanvasItem, g: Gema) -> void:
	var nombre := "bit2"
	match g.tipo:
		"pizza":
			nombre = "obj_pizza"
		"iman":
			nombre = "obj_iman"
		"bomba":
			nombre = "obj_bomba"
		"cofre":
			nombre = "obj_cofre"
		"tuerca":
			nombre = "obj_tuerca"
		_:
			if g.valor > 2:
				nombre = "bit_grande2"
	var tx: Texture2D = Datos.tex(nombre)
	var w := tx.get_width()
	var pos := Vector2(round(g.x) - w / 2, round(g.y) - tx.get_height() / 2)
	if g.tipo in ["pizza", "iman", "bomba", "cofre"]:
		# los objetos especiales laten para que se vean
		var fase := (ticks / 10) % 2
		var r := Rect2(pos - Vector2(2, 2), Vector2(w + 4, tx.get_height() + 4))
		c.draw_rect(r, Color(1, 1, 1, 0.22 + 0.2 * fase))
		c.draw_rect(r, Color.WHITE if fase == 0 else UI.C_ORO, false)
		UI.tc(c, round(g.x), r.position.y - 14, g.tipo.capitalize().replace("Iman", "Imán"), Color.WHITE, 1, true)
	c.draw_texture(tx, pos)


func _dibujar_tiro(c: CanvasItem, t: Tiro) -> void:
	var h: float = t.tex.get_height()
	var w: float = float(t.tex.get_width()) / t.cuadros
	var f: int = (ticks / 4) % t.cuadros
	if t.rotar or t.escala != 1.0:
		c.draw_set_transform(Vector2(round(t.x), round(t.y)), t.rot if t.rotar else 0.0, Vector2.ONE * t.escala)
		c.draw_texture_rect_region(t.tex, Rect2(-w / 2.0, -h / 2.0, w, h), Rect2(f * w, 0, w, h))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		c.draw_texture_rect_region(t.tex, Rect2(round(t.x - w / 2.0), round(t.y - h / 2.0), w, h), Rect2(f * w, 0, w, h))


func _dibujar_rayo(c: CanvasItem, a: Vector2, b: Vector2) -> void:
	var pts := PackedVector2Array([a])
	var n := 5
	for k in range(1, n):
		var q := a.lerp(b, float(k) / n)
		q += Vector2(randf_range(-6, 6), randf_range(-6, 6))
		pts.append(q)
	pts.append(b)
	c.draw_polyline(pts, Color("fff070"), 2.0)
	c.draw_polyline(pts, Color.WHITE, 1.0)


func _frame_enemigo(e: Enemigo) -> int:
	var d := e.def
	if d.ia == "compactador":
		var a: int = clampi(int(round(e.apertura * 3.0)), 0, 3)
		return a + (4 if e.fase >= 2 else 0)
	if e.frame_extra >= 0:
		return e.frame_extra
	return int(e.anim) % int(d.frames)


func _dibujar_enemigo(c: CanvasItem, e: Enemigo) -> void:
	var t: Texture2D = Datos.tex(e.def.sprite)
	var w: float = e.def.w
	var h: float = e.def.h
	var f := _frame_enemigo(e)
	var mod := e.tinte
	if e.flash > 0:
		mod = Color(3.2, 3.2, 3.2, 1.0)
	if e.inv > 0 and int(e.inv) % 8 < 4:
		mod = Color(0.6, 0.6, 0.8, 1.0)
	if e.def.ia == "kamikaze" and e.modo == "actuar" and int(e.mt) % 8 < 4:
		mod = Color(2.4, 0.9, 0.9, 1.0)
	c.draw_texture_rect_region(t, Rect2(round(e.x - w / 2.0), round(e.y - h / 2.0), w, h), Rect2(f * w, 0, w, h), mod)


func dibujar_frente(c: CanvasItem) -> void:
	arsenal.dibujar_frente(c)
	if afk_mira >= 0.0:
		_dibujar_mira_afk(c)
	if escudo and vivo:
		var n := 26
		for k in n:
			var a := TAU * k / n - ticks * 0.02
			c.draw_rect(Rect2(round(jx + cos(a) * 22.0), round(jy + sin(a) * 22.0), 2, 2), UI.C_CIAN)
	if vivo and estado == "desync":
		_dibujar_escudo_desync(c)
	if vivo and tiene_mascota:
		var tp: Texture2D = Datos.tex_mascota(pet_id, pet_forma)
		var fp: int = (ticks / 8) % 4
		if pet_boca > 0:
			fp = 5 if pet_boca > 6 else 4
		c.draw_texture_rect_region(tp, Rect2(round(px - pet_tam / 2.0), round(py - pet_tam / 2.0), pet_tam, pet_tam), Rect2(fp * pet_tam, 0, pet_tam, pet_tam))
	if vivo and fogonazo > 1:
		c.draw_rect(Rect2(round(jx) - 2, round(jy) - 20, 4, 4), Color(1, 1, 0.8))
	if vivo:
		# el punto debil siempre se ve, y es del tamaño real de lo que te puede pegar
		var pos := Vector2(round(jx), round(jy))
		var hb := hitbox()
		c.draw_circle(pos, hb + 1.0, Color("0d0a18"))
		c.draw_circle(pos, hb, Color("ff6fb5"))
		c.draw_circle(pos, maxf(hb * 0.4, 1.0), Color.WHITE)
		if foco:
			var n := 16
			for k in n:
				var a := TAU * k / n
				c.draw_rect(Rect2(round(jx + cos(a) * 11.0), round(jy + sin(a) * 11.0), 1, 1), Color("ff9ac0"))
		# la vida va debajo de la nave: donde estas mirando
		var bw := 30.0
		var by0: float = round(jy) + 22.0
		var frac: float = clampf(hp / stats.hp, 0.0, 1.0)
		var col_hp: Color = UI.C_VERDE if frac > 0.5 else (UI.C_ORO if frac > 0.3 else UI.C_ROJO)
		c.draw_rect(Rect2(round(jx) - bw / 2.0 - 1, by0 - 1, bw + 2, 5), Color("0d0a18"))
		c.draw_rect(Rect2(round(jx) - bw / 2.0, by0, bw * clampf(hp_visto / stats.hp, 0.0, 1.0), 3), Color.WHITE)
		c.draw_rect(Rect2(round(jx) - bw / 2.0, by0, bw * frac, 3), col_hp)
		if tiene_desync and barra >= 100.0 and estado == "jugando" and (ticks / 12) % 2 == 0:
			UI.tc(c, round(jx), by0 + 5, "¡%s: DESYNC!" % Controles.texto("desync"), UI.C_CIAN, 1, true)
	for o in ondas:
		var n := 30
		var col: Color = o.c
		col.a = clampf(1.0 - o.r / 70.0, 0.0, 1.0)
		for k in n:
			var a := TAU * k / n
			c.draw_rect(Rect2(round(o.x + cos(a) * o.r), round(o.y + sin(a) * o.r), 2, 2), col)
	if estado in ["desync", "reconectando", "cascada"]:
		var bono := _bono_cascada()
		for e in cola:
			if e.muerto or e.cola_hits <= 0:
				continue
			var lbl := "X%d" % maxi(e.cola_vis, e.cola_hits)
			var an := UI.ancho(lbl)
			var yy: float = e.y - e.def.h / 2.0 - 12.0
			# en dorado, los que ya están sentenciados
			var sentenciado: bool = not e.jefe and e.cola_dano * bono >= e.hp
			c.draw_rect(Rect2(round(e.x - an / 2.0) - 2, round(yy), an + 4, 13), Color("a8780f") if sentenciado else Color("7a0a2a"))
			UI.t(c, round(e.x - an / 2.0), round(yy) - 1, lbl, Color.WHITE)
	for t in textos:
		UI.tc(c, round(t.x), round(t.y), t.s, t.c, t.esc, true)
	match estado:
		"desync":
			UI.tc(c, 200, 140, "PING 9999", UI.C_ROJO, 3, true)
			UI.tc(c, 200, 190, "Tus disparos no se registran...", UI.C_TEXTO, 1, true)
			UI.tc(c, 200, 204, "...todavía", UI.C_CIAN, 1, true)
			UI.tc(c, 200, 332, "GOLPES EN COLA: %d" % cola_total, UI.C_ORO, 1, true)
		"reconectando":
			if (ticks / 4) % 2 == 0:
				UI.tc(c, 200, 150, "RECONECTANDO...", UI.C_CIAN, 2, true)
		"ruleta":
			_dibujar_ruleta(c)
	for g in grandes:
		UI.tc(c, 200, g.y, g.s, g.c, g.esc, true)
	if aviso_t > 0 and (aviso_t / 10) % 2 == 0:
		c.draw_rect(Rect2(0, 118, ANCHO, 36), Color(0.5, 0.05, 0.1, 0.8))
		UI.tc(c, 200, 120, aviso_txt, Color.WHITE, 2, true)
	if pista_t > 0:
		var an := UI.ancho(pista_txt) + 16.0
		c.draw_rect(Rect2(200 - an / 2.0, 34, an, 17), Color(0.05, 0.03, 0.12, 0.88))
		c.draw_rect(Rect2(200 - an / 2.0, 34, an, 17), UI.C_ORO, false, 1.0)
		UI.tc(c, 200, 34, pista_txt, UI.C_ORO)
	# golpe y vida baja: el borde de la pantalla se pone rojo
	var v := vineta
	if hp < stats.hp * 0.3 and vivo:
		v = maxf(v, 0.35 + 0.25 * sin(ticks * 0.2))
	if v > 0.01 and not Ajustes.reducir_destellos:
		var rojo := Color(0.9, 0.05, 0.1, 0.55 * v)
		for g in [18.0, 10.0, 4.0]:
			c.draw_rect(Rect2(0, 0, ANCHO, g), rojo)
			c.draw_rect(Rect2(0, ALTO - g, ANCHO, g), rojo)
			c.draw_rect(Rect2(0, 0, g, ALTO), rojo)
			c.draw_rect(Rect2(ANCHO - g, 0, g, ALTO), rojo)
	if destello > 0:
		var col := color_destello
		col.a = destello
		c.draw_rect(Rect2(-30, -30, ANCHO + 60, ALTO + 60), col)


## La mira del AFK: se cierra sobre ti y, al final, cae la bomba.
func _dibujar_mira_afk(c: CanvasItem) -> void:
	var f: float = 1.0 - afk_mira / AFK_CAIDA
	var col := Color(1.0, 0.2, 0.25, 0.75)
	if int(afk_mira) % 8 < 4:
		col = Color(1.0, 0.9, 0.5, 0.95)
	var r: float = lerpf(AFK_RADIO + 26.0, AFK_RADIO, f)
	var n := 28
	for k in n:
		if k % 7 < 2:
			continue
		var a := TAU * k / n + f * 2.5
		c.draw_rect(Rect2(round(afk_mx + cos(a) * r), round(afk_my + sin(a) * r), 2, 2), col)
	# la zona que va a explotar
	c.draw_circle(Vector2(afk_mx, afk_my), AFK_RADIO, Color(1.0, 0.1, 0.1, 0.08 + 0.16 * f))
	# la cruz
	c.draw_rect(Rect2(round(afk_mx) - r - 6, round(afk_my), 12, 1), col)
	c.draw_rect(Rect2(round(afk_mx) + r - 6, round(afk_my), 12, 1), col)
	c.draw_rect(Rect2(round(afk_mx), round(afk_my) - r - 6, 1, 12), col)
	c.draw_rect(Rect2(round(afk_mx), round(afk_my) + r - 6, 1, 12), col)
	UI.tc(c, afk_mx, afk_my - r - 20, "AFK", col, 1, true)
	# la bomba cae en el último tercio
	if f > 0.66:
		var tx: Texture2D = Datos.tex("obj_bomba")
		var y0: float = lerpf(-20.0, afk_my, (f - 0.66) / 0.34)
		c.draw_texture(tx, Vector2(round(afk_mx) - tx.get_width() / 2.0, round(y0) - tx.get_height() / 2.0))


## El escudo del Desync: arcos que giran alrededor de la nave. Cada golpe quiebra uno.
func _dibujar_escudo_desync(c: CanvasItem) -> void:
	if desync_esc_max <= 0:
		return
	var total := 42
	var por_arco: int = total / desync_esc_max
	var r := 21.0
	var col := UI.C_CIAN
	if desync_esc == 1:
		col = UI.C_ROSA if (ticks / 6) % 2 == 0 else Color.WHITE
	elif desync_esc_flash > 0 and (ticks / 2) % 2 == 0:
		col = Color.WHITE
	for k in total:
		var arco: int = k / por_arco
		if arco >= desync_esc_max:
			continue
		var a := TAU * k / total - ticks * 0.03
		if k % por_arco < 2:
			continue  # el espacio entre arcos
		if arco >= desync_esc:
			# los arcos quebrados dejan algunas esquirlas
			if k % 4 == 0 and desync_esc_flash > 0:
				c.draw_rect(Rect2(round(jx + cos(a) * (r + 3.0)), round(jy + sin(a) * (r + 3.0)), 1, 1), UI.C_CIAN)
			continue
		var rr := r + (randf_range(-1.0, 1.0) if desync_esc_flash > 0 else 0.0)
		c.draw_rect(Rect2(round(jx + cos(a) * rr), round(jy + sin(a) * rr), 2, 2), col)


## La tragamonedas de Don Tuerca, sobre el campo. El juego sigue por detrás, pero no hay nada que te pueda pegar.
func _dibujar_ruleta(c: CanvasItem) -> void:
	c.draw_rect(Rect2(0, 13, ANCHO, ALTO - 13), Color(0.03, 0.02, 0.07, 0.45))
	var r := Rect2(64, 46, 272, 236)
	c.draw_rect(r.grow(3), Color("3a2a08"))
	UI.marco(c, r, Color("1d1736"), UI.C_ORO)
	# luces alrededor
	var n := 28
	var perim: float = (r.size.x + r.size.y) * 2.0
	for k in n:
		var d: float = perim * k / n
		var q := Vector2.ZERO
		if d < r.size.x:
			q = r.position + Vector2(d, 0)
		elif d < r.size.x + r.size.y:
			q = r.position + Vector2(r.size.x, d - r.size.x)
		elif d < r.size.x * 2.0 + r.size.y:
			q = r.position + Vector2(r.size.x * 2.0 + r.size.y - d, r.size.y)
		else:
			q = r.position + Vector2(0, perim - d)
		var prendida: bool = (k + ticks / 6) % 3 == 0
		c.draw_rect(Rect2(q.x - 2, q.y - 2, 4, 4), UI.C_ORO if prendida else Color("6a4a10"))
	UI.tc(c, 200, 52, "LA RULETA DE DON TUERCA", UI.C_ORO, 1, true)
	# la cara de Don Tuerca
	var tx: Texture2D = Datos.tex("retrato_tuerca")
	var f: int = ruleta_cara
	c.draw_texture_rect_region(tx, Rect2(168, 68, 64, 64), Rect2(f * 128, 0, 128, 128))
	# los tres rodillos
	for k in 3:
		_dibujar_rodillo(c, 200.0 - 80.0 + k * 80.0, 138.0, k)
	# la palanca
	var baja: bool = ruleta_fase == "gira" and ruleta_t < 30
	c.draw_rect(Rect2(326, 140 + (24 if baja else 0), 4, 28 - (24 if baja else 0)), Color("a8a2c8"))
	c.draw_circle(Vector2(328, 138 + (24 if baja else 0)), 5.0, UI.C_ROJO)
	if ruleta_txt != "":
		UI.tc(c, 200, 198, ruleta_txt, UI.C_TEXTO, 1, true)
	if ruleta_txt2 != "":
		if ruleta_fase == "paga" and UI.ancho(ruleta_txt2) > 250.0:
			var y := 216.0
			for lin in UI.partir(ruleta_txt2, 250.0):
				UI.tc(c, 200, y, lin, ruleta_col, 1, true)
				y += 14.0
		else:
			UI.tc(c, 200, 216, ruleta_txt2, ruleta_col, 2 if UI.ancho(ruleta_txt2, 2) < 250.0 else 1, true)
	UI.tc(c, 200, 262, "Giro %d" % giros, UI.C_GRIS)


func _dibujar_rodillo(c: CanvasItem, cx: float, y0: float, k: int) -> void:
	var alto := ALTO_SIMBOLO
	var marco := Rect2(cx - 24.0, y0, 48.0, alto + 8.0)
	c.draw_rect(marco.grow(2), UI.C_ORO if ruleta_parado[k] else Color("6a4a10"))
	c.draw_rect(marco, Color("f4f0ff") if ruleta_parado[k] else Color("c8c0dc"))
	var p: float = ruleta_pos[k]
	var rebote := 0.0
	if ruleta_reb[k] > 0:
		rebote = sin(ruleta_reb[k] * 0.9) * ruleta_reb[k] * 0.5
	var i0: int = int(floor(p))
	var frac: float = p - i0
	# el símbolo actual baja y entra el siguiente desde arriba: se recorta a la ventana del rodillo
	for d in [0, 1]:
		var idx: int = posmod(i0 + d, SIMBOLOS.size())
		var tx: Texture2D = Datos.tex("rueda_" + SIMBOLOS[idx])
		var yy: float = y0 + 4.0 + (alto - 32.0) / 2.0 + (frac - d) * alto + rebote
		var arriba: float = maxf(y0 + 2.0, yy)
		var abajo: float = minf(y0 + alto + 6.0, yy + 32.0)
		if abajo <= arriba:
			continue
		var escala_fuente: float = tx.get_height() / 32.0
		var src := Rect2(0, (arriba - yy) * escala_fuente, tx.get_width(), (abajo - arriba) * escala_fuente)
		c.draw_texture_rect_region(tx, Rect2(cx - 16.0, arriba, 32.0, abajo - arriba), src)


func _ranura_arma(c: CanvasItem, x: float, y: float, id: String, nv: int, maxi_nv: int, evo: bool) -> void:
	var r := Rect2(x, y, 34, 34)
	if id == "":
		UI.marco(c, r, Color("15112a"), Color("2a2448"))
		return
	UI.marco(c, r, UI.C_PANEL2, UI.C_ORO if evo else UI.C_LINEA)
	c.draw_texture(Datos.tex("icono_" + id), Vector2(x + 1, y + 1))
	for k in maxi_nv:
		c.draw_rect(Rect2(x + 1 + k * 7, y + 36, 5, 3), UI.C_ORO if k < nv else Color("2a2448"))


func _ranura_cerrada(c: CanvasItem, x: float, y: float) -> void:
	UI.marco(c, Rect2(x, y, 34, 34), Color("0d0a18"), Color("1d1736"))
	var t: Texture2D = Datos.tex("ui_candado")
	c.draw_texture(t, Vector2(x + 17 - t.get_width() / 2.0, y + 17 - t.get_height() / 2.0), Color(1, 1, 1, 0.5))


func dibujar_hud(c: CanvasItem) -> void:
	# ---- izquierda: vida y lo que llevas puesto
	c.draw_rect(Rect2(0, 0, PX, ALTO), UI.C_FONDO)
	c.draw_line(Vector2(PX - 0.5, 0), Vector2(PX - 0.5, ALTO), UI.C_LINEA, 1.0)
	c.draw_texture(Datos.tex("ui_corazon"), Vector2(5, 5))
	UI.t(c, 19, 0, "%d / %d" % [int(ceil(maxf(hp, 0))), int(stats.hp)], UI.C_ROJO if hp < stats.hp * 0.3 else UI.C_TEXTO)
	var frac := clampf(hp / stats.hp, 0.0, 1.0)
	var col_hp: Color = UI.C_VERDE if frac > 0.5 else (UI.C_ORO if frac > 0.3 else UI.C_ROJO)
	var rv := Rect2(5, 16, 110, 12)
	if hp_flash > 0:
		rv = rv.grow(1)
	c.draw_rect(rv, Color("0d0a18"))
	c.draw_rect(Rect2(rv.position + Vector2.ONE, Vector2((rv.size.x - 2) * clampf(hp_visto / stats.hp, 0.0, 1.0), rv.size.y - 2)), Color.WHITE)
	c.draw_rect(Rect2(rv.position + Vector2.ONE, Vector2((rv.size.x - 2) * frac, rv.size.y - 2)), col_hp if hp_flash % 2 == 0 else UI.C_ROJO)
	UI.t(c, 5, 30, "ARMAS %d/%d" % [arsenal.armas.size(), Partida.max_armas()], UI.C_CIAN)
	for i in Datos.TOPE_ARMAS:
		var x := 8.0 + (i % 2) * 54.0
		var y := 44.0 + (i / 2) * 42.0
		if i < arsenal.armas.size():
			var a = arsenal.armas[i]
			_ranura_arma(c, x, y, a.id, a.nivel, Datos.NIVEL_MAX_CARTA, a.evo)
		elif i < Partida.max_armas():
			_ranura_arma(c, x, y, "", 0, 0, false)
		else:
			_ranura_cerrada(c, x, y)
	UI.t(c, 5, 128, "HABILIDADES %d/%d" % [habs.size(), Partida.max_habs()], UI.C_VERDE)
	var ids: Array = habs.keys()
	for i in Datos.TOPE_HABS:
		var x := 8.0 + (i % 2) * 54.0
		var y := 142.0 + (i / 2) * 42.0
		if i < ids.size():
			_ranura_arma(c, x, y, ids[i], habs[ids[i]], Datos.max_hab(ids[i]), false)
		elif i < Partida.max_habs():
			_ranura_arma(c, x, y, "", 0, 0, false)
		else:
			_ranura_cerrada(c, x, y)
	# desync y esquiva, abajo
	var y0 := 230
	if tiene_desync:
		var listo := barra >= 100.0 and estado == "jugando"
		var en_uso := estado == "desync"
		c.draw_texture_rect(Datos.tex("icono_desync"), Rect2(5, y0, 16, 16), false)
		UI.t(c, 24, y0, "DESYNC", UI.C_CIAN if listo or en_uso else UI.C_GRIS)
		if listo and (ticks / 15) % 2 == 0:
			c.draw_rect(Rect2(3, y0 + 16, 114, 18), UI.C_CIAN, false, 1.0)
		var valor := barra / 100.0
		if en_uso:
			valor = estado_t / (stats.desync_dur * 60.0)
		UI.barra(c, Rect2(5, y0 + 18, 110, 14), valor, UI.C_CIAN)
		if listo:
			UI.tc(c, 60, y0 + 17, "PULSA " + Controles.texto("desync"), Color("0d0a18"))
		if en_uso:
			UI.t(c, 5, y0 + 33, "Escudo %d/%d" % [desync_esc, desync_esc_max], UI.C_CIAN if desync_esc > 0 else UI.C_ROSA)
		y0 += 48
	else:
		UI.t(c, 5, y0, "DESYNC", Color("3a3458"))
		c.draw_texture(Datos.tex("ui_candado"), Vector2(48, y0 + 2))
		y0 += 24
	var listo_d := dash_cd <= 0
	UI.t(c, 5, y0, "ESQUIVA  " + Controles.texto("esquivar"), UI.C_TEXTO if listo_d else UI.C_GRIS)
	UI.barra(c, Rect2(5, y0 + 15, 110, 6), 1.0 - dash_cd / maxf(110.0 * stats.dash_cd, 1.0), UI.C_TEXTO if listo_d else UI.C_GRIS)
	# ---- derecha: objetivo del nivel, cadena y mascota
	var d := PX + int(ANCHO)
	c.draw_rect(Rect2(d, 0, PX, ALTO), UI.C_FONDO)
	c.draw_line(Vector2(d + 0.5, 0), Vector2(d + 0.5, ALTO), UI.C_LINEA, 1.0)
	var seg_t := tiempo_jugado / 60
	if modo_nivel == "infinito":
		UI.t(c, d + 5, 0, "INFINITO", UI.C_ORO)
		var rec: int = int(Partida.d.records.get(nivel_id, {}).get("seg", 0))
		UI.t(c, d + 5, 14, "%d:%02d" % [seg_t / 60, seg_t % 60], UI.C_TEXTO, 2)
		UI.t(c, d + 5, 44, "Récord %d:%02d" % [rec / 60, rec % 60], UI.C_ORO if seg_t >= rec and rec > 0 else UI.C_GRIS)
	else:
		UI.t(c, d + 5, 0, "NIVEL " + nivel_id, UI.C_ORO)
		var prog := clampf(guion_t / maxf(float(nivel.duracion), 1.0), 0.0, 1.0)
		UI.barra(c, Rect2(d + 5, 15, 92, 8), prog, UI.C_ORO)
		c.draw_texture(Datos.tex("ui_calavera" if nivel.has("jefe") else "ui_estrella"), Vector2(d + 100, 11))
		if modo_nivel == "ruleta":
			for f in [0.45, 0.9]:
				c.draw_rect(Rect2(d + 5 + 92.0 * f, 13, 2, 12), UI.C_CIAN)
		# estrellas por conseguir
		var ok_golpes: bool = golpes <= nivel.golpes
		var ok_cadena: bool = max_cadena >= nivel.cadena
		c.draw_texture(Datos.tex("ui_estrella" if ok_golpes else "ui_estrella_vacia"), Vector2(d + 4, 28))
		UI.t(c, d + 20, 27, "Golpes %d/%d" % [golpes, nivel.golpes], UI.C_TEXTO if ok_golpes else UI.C_ROJO)
		c.draw_texture(Datos.tex("ui_estrella" if ok_cadena else "ui_estrella_vacia"), Vector2(d + 4, 44))
		UI.t(c, d + 20, 43, "Cadena %d/%d" % [mini(max_cadena, nivel.cadena), nivel.cadena], UI.C_TEXTO if ok_cadena else UI.C_GRIS)
	if ciclo > 0:
		UI.t(c, d + 76, 0, "NG+%d" % ciclo, UI.C_ROJO)
	# cadena
	UI.t(c, d + 5, 64, "CADENA", UI.C_GRIS)
	UI.t(c, d + 5, 74, "X%d" % cadena, UI.C_ORO if tier_cadena > 0 else UI.C_TEXTO, 2)
	var val_cadena := 0.0
	if cadena > 0:
		val_cadena = cadena_t / PLAZO_BAJADA if cadena_bajando else cadena_t / _ventana_cadena()
	UI.barra(c, Rect2(d + 5, 104, 110, 4), val_cadena, UI.C_ROSA if cadena_bajando else UI.C_ORO)
	# chatarra y kills
	c.draw_texture(Datos.tex("obj_tuerca"), Vector2(d + 5, 117))
	UI.t(c, d + 20, 112, "%d chatarra" % chatarra, UI.C_TEXTO)
	UI.t(c, d + 5, 126, "%d kills" % kills, UI.C_GRIS)
	UI.t(c, d + 5, 140, "Tiempo %d:%02d" % [seg_t / 60, seg_t % 60], UI.C_GRIS)
	# mascota
	if tiene_mascota:
		UI.marco(c, Rect2(d + 4, 160, 112, 74), UI.C_PANEL, UI.C_LINEA)
		var tp: Texture2D = Datos.tex_mascota(pet_id, pet_forma)
		var fp: int = (ticks / 8) % 4
		if pet_boca > 0:
			fp = 5
		var tam := pet_tam
		c.draw_texture_rect_region(tp, Rect2(d + 8, 164, tam, tam), Rect2(fp * tam, 0, tam, tam))
		UI.t(c, d + 46, 162, Partida.nombre_mascota(), UI.C_TEXTO)
		UI.t(c, d + 46, 176, "Niv. %d" % pet_nivel, UI.C_ORO)
		var txt_pet := ""
		match pet_ia:
			"come":
				txt_pet = "Come balas: %d" % nams
			"chispa":
				txt_pet = "Chispazos: %d" % nams
			"iman":
				txt_pet = "Te trae los Bits"
			"escudo":
				txt_pet = "Te da un escudo"
		UI.t(c, d + 8, 198, txt_pet, UI.C_GRIS)
		var listo_pet: float = 1.0 - clampf(pet_cd / Partida.pet_recarga(), 0.0, 1.0)
		UI.barra(c, Rect2(d + 8, 215, 104, 6), listo_pet, Color("dccfe6"))
	# ---- arriba del campo: experiencia, bien visible
	c.draw_rect(Rect2(PX, 0, ANCHO, 13), Color("0d0a18"))
	c.draw_rect(Rect2(PX + 1, 1, (ANCHO - 2) * clampf(xp / xp_sig, 0.0, 1.0), 11), Color("c49a20"))
	c.draw_rect(Rect2(PX + 1, 1, (ANCHO - 2) * clampf(xp / xp_sig, 0.0, 1.0), 4), UI.C_ORO)
	UI.t(c, PX + 4, -2, "Nivel %d" % nivel_carta, Color.WHITE, 1, true)
	# barra de jefe
	if jefe_actual and not jefe_actual.muerto:
		var e := jefe_actual
		var bx0 := PX + 30
		var ban := int(ANCHO) - 60
		c.draw_rect(Rect2(bx0, 16, ban, 10), Color("0d0a18"))
		c.draw_rect(Rect2(bx0 + 1, 17, (ban - 2) * clampf(e.hp / e.hpmax, 0.0, 1.0), 8), UI.C_ROSA if e.super_jefe else UI.C_ROJO)
		for f in e.def.get("fases", []):
			c.draw_rect(Rect2(bx0 + ban * f, 16, 1, 10), Color.WHITE)
		UI.tc(c, PX + ANCHO / 2.0, 12, e.nombre, Color.WHITE, 1, true)


func dibujar_cartas(c: CanvasItem) -> void:
	if estado != "cartas":
		return
	c.draw_rect(Rect2(PX, 13, ANCHO, ALTO - 13), Color(0.03, 0.02, 0.07, 0.8))
	UI.tc(c, PX + ANCHO / 2.0, 18, "¡SUBISTE DE NIVEL!", UI.C_ORO, 2, true)
	UI.tc(c, PX + ANCHO / 2.0, 46, "Armas %d/%d  ·  Habilidades %d/%d" % [arsenal.armas.size(), Partida.max_armas(), habs.size(), Partida.max_habs()], UI.C_GRIS)
	for i in cartas.size():
		_dibujar_carta(c, i)
	var ty := 278.0
	if arsenal.armas.size() >= Partida.max_armas() and habs.size() >= Partida.max_habs():
		UI.tc(c, PX + ANCHO / 2.0, ty, "Ranuras llenas: ahora solo salen mejoras", UI.C_GRIS)
		ty += 14
	UI.tc(c, PX + ANCHO / 2.0, ty, "%s: cambiar cartas (te quedan %d)" % [Controles.texto("desync"), cambios_restantes], UI.C_TEXTO if cambios_restantes > 0 else Color("6a6488"))


func _dibujar_carta(c: CanvasItem, i: int) -> void:
	var r := _rect_carta(i)
	var ca: Dictionary = cartas[i]
	var sel := i == carta_sel
	var tipo: String = ca.tipo
	var col := UI.C_GRIS
	var etiqueta := "BONO"
	match tipo:
		"arma":
			col = UI.C_CIAN
			etiqueta = "ARMA NUEVA" if ca.nv == 0 else "ARMA: NIVEL %d" % (ca.nv + 1)
		"hab":
			col = UI.C_VERDE
			etiqueta = "HABILIDAD NUEVA" if ca.nv == 0 else "HABILIDAD: NIVEL %d" % (ca.nv + 1)
		"evo":
			col = UI.C_ORO
			etiqueta = "¡EVOLUCIÓN!"
	if sel:
		r.position.y -= 2.0
		c.draw_rect(r.grow(2), Color.WHITE, false, 1.0)
	UI.marco(c, r, UI.C_PANEL, col)
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 15)), col.darkened(0.55))
	var cx := r.position.x + r.size.x / 2.0
	UI.tc(c, cx, r.position.y, etiqueta, Color.WHITE)
	# icono grande
	var tx: Texture2D = Datos.tex(ca.icono)
	var esc := 2.0
	var tam := tx.get_width() * esc
	c.draw_texture_rect(tx, Rect2(cx - tam / 2.0, r.position.y + 18, tam, tam), false)
	var y := r.position.y + 84
	for lin in UI.partir(ca.nombre, r.size.x - 8.0):
		UI.tc(c, cx, y, lin, UI.C_ORO if tipo == "evo" else UI.C_TEXTO)
		y += 13
	y += 2
	for lin in UI.partir(ca.desc, r.size.x - 10.0):
		UI.tc(c, cx, y, lin, UI.C_GRIS)
		y += 13
	if ca.has("max"):
		var mx: int = ca.max
		var w := mx * 8
		for k in mx:
			var xx := cx - w / 2.0 + k * 8
			var pip := UI.C_ORO if k < ca.nv else (UI.C_TEXTO if k == ca.nv and (ticks / 15) % 2 == 0 else Color("3a3458"))
			c.draw_rect(Rect2(xx, r.position.y + r.size.y - 41, 6, 5), pip)
	# sinergia: que se necesita para evolucionar
	if ca.has("sinergia"):
		var yy := r.position.y + r.size.y - 34
		c.draw_line(Vector2(r.position.x + 3, yy), Vector2(r.end.x - 3, yy), UI.C_LINEA, 1.0)
		UI.t(c, r.position.x + 4, yy, ca.sin_txt, UI.C_GRIS)
		c.draw_texture_rect(Datos.tex(ca.sin_icono), Rect2(r.position.x + 4, yy + 15, 16, 16), false)
		UI.t(c, r.position.x + 22, yy + 14, ca.sinergia, UI.C_VERDE if ca.sin_ok else UI.C_TEXTO)
		if ca.sin_ok:
			UI.t(c, r.end.x - 19, yy, "¡OK!", UI.C_VERDE)
