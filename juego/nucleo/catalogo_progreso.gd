class_name CatalogoProgreso
extends RefCounted
## Lo que se gana y se lleva entre partidas: rarezas, naves, piezas, mascotas, dificultades y desafíos.


static func rarezas() -> Array:
	return [
		{"id": "gris", "nombre": "Común", "color": Color("a7aeb8"), "mult": 1.0, "prob": 0.78},
		{"id": "verde", "nombre": "Poco común", "color": Color("5ccb6c"), "mult": 1.25, "prob": 0.185},
		{"id": "azul", "nombre": "Raro", "color": Color("4aa8ff"), "mult": 1.6, "prob": 0.03},
		{"id": "morado", "nombre": "Épico", "color": Color("b46cff"), "mult": 2.0, "prob": 0.005},
		{"id": "dorado", "nombre": "Legendario", "color": Color("ffc83d"), "mult": 2.5, "prob": 0.0},
		{"id": "rojo", "nombre": "Mítico", "color": Color("ff4a5a"), "mult": 3.2, "prob": 0.0},
	]


## En Nueva Partida + también caen legendarios (ciclo 1) y míticos (ciclo 2).
const PROB_CICLO := {4: 0.0015, 5: 0.0003}


## hp y dano multiplican la vida y el daño enemigo; vel, la velocidad de sus balas; disparo, el tiempo entre tiros.
## La presión (M10): ritmo multiplica los puntos por segundo del director (más enemigos a la vez), inicio sube
## además el ritmo del comienzo, ganas es cuántas ganas de disparar tienen los Bots al empezar el nivel (sube
## hasta 1 en el primer minuto), salva multiplica el tiempo entre salvas de los Bots y jefe_cd, el tiempo entre
## ataques de los jefes (menos es más seguido).
## Difícil se nota en cuántos enemigos y balas hay, no en morir de tres golpes: por eso su vida y su daño suben poco.
static func dificultades() -> Dictionary:
	return {
		"facil": {"nombre": "Fácil", "desc": "Para conocer el juego con calma. Te perdona más.", "icono": "dif_facil", "color": Color("7ee07a"),
			"hp": 0.8, "dano": 0.7, "vel": 0.9, "disparo": 1.25, "botin": 0.85, "chatarra": 1.0,
			"ritmo": 1.0, "inicio": 1.0, "ganas": 0.35, "salva": 1.0, "jefe_cd": 1.0},
		"normal": {"nombre": "Normal", "desc": "Como está pensado. Hay que esquivar y armarse bien.", "icono": "dif_normal", "color": Color("f5c84c"),
			"hp": 1.0, "dano": 1.0, "vel": 1.0, "disparo": 1.0, "botin": 1.0, "chatarra": 1.0,
			"ritmo": 1.0, "inicio": 1.0, "ganas": 0.35, "salva": 1.0, "jefe_cd": 1.0},
		"dificil": {"nombre": "Difícil", "desc": "Muchos más enemigos y balas desde el inicio. Mejor botín.", "icono": "dif_dificil", "color": Color("ff8a4a"),
			"hp": 1.15, "dano": 1.2, "vel": 1.1, "disparo": 0.9, "botin": 1.2, "chatarra": 1.2,
			"ritmo": 1.4, "inicio": 1.3, "ganas": 0.7, "salva": 0.75, "jefe_cd": 0.85},
		"extremo": {"nombre": "Extremo", "desc": "Se abre al terminar el juego. Sin pizzas. Mucho mejor botín.", "icono": "dif_extremo", "color": Color("ff4a5a"),
			"hp": 1.45, "dano": 1.5, "vel": 1.2, "disparo": 0.8, "botin": 1.5, "chatarra": 1.5, "sin_pizza": true, "requiere": "terminar",
			"ritmo": 1.6, "inicio": 1.4, "ganas": 0.85, "salva": 0.65, "jefe_cd": 0.75},
	}


## Cuánto sube cada nivel de mejora de una pieza, sobre su base, según la dificultad (#61). Con 4 % la Mira subía
## 0,08 de ataque por nivel y no se notaba (M13). Con 8 % en todas, fuera de Difícil se notaba poco: en Difícil
## está bien que cueste, porque esa es la idea del modo. Depende de la dificultad de la partida, así que vale
## para las piezas que ya tienes (es retroactivo).
const MEJORA_POR_NIVEL := {"facil": 0.12, "normal": 0.10, "dificil": 0.08, "extremo": 0.08}


# ===============================================================================================
# NAVES: cada una trae su arma principal. Casi todas se ganan con desafíos, no por pasar niveles.
# ===============================================================================================
static func naves() -> Dictionary:
	return {
		"tryhard": {"nombre": "Tryhard", "desc": "Equilibrada. Hace de todo un poco.", "arma": "pistola", "pintura": 0,
			"pasiva": "+1 cambio de cartas por partida", "mods": {"cambios": 1}, "numeros": ["Vida 70", "Velocidad normal"],
			"desbloqueo": {"tipo": "inicial"}},
		"camper": {"nombre": "Camper", "desc": "Lenta. Pega fuerte, pero estar quieto es peligroso.", "arma": "railgun", "pintura": 2,
			"pasiva": "+15 % de daño tras 1 s sin moverte", "mods": {"hp": -10.0, "vel": -0.12, "quieto_dano": 0.15}, "numeros": ["Vida 60", "Lenta"],
			"desbloqueo": {"tipo": "nivel", "nivel": "1-8", "txt": "Vence a El Compactador (1-8)"}},
		"support": {"nombre": "Main Support", "desc": "Mucha vida y drones. Cura al reconectar.", "arma": "drones", "pintura": 1,
			"pasiva": "Se cura con cada Desync y con el tiempo", "mods": {"hp": 30.0, "vel": -0.05, "regen": 0.25, "cura_cascada": 12.0}, "numeros": ["Vida 100", "Algo lenta"],
			"desbloqueo": {"tipo": "desafio", "id": "n_support", "txt": "Usa el Desync 40 veces"}},
		"ballena": {"nombre": "La Ballena", "desc": "Un tanque enorme con escopeta.", "arma": "escopeta", "pintura": 5,
			"pasiva": "+8 % de armadura", "mods": {"hp": 50.0, "vel": -0.18, "armadura": 0.08}, "numeros": ["Vida 120", "Muy lenta"],
			"desbloqueo": {"tipo": "desafio", "id": "n_ballena", "txt": "Recibe 150 golpes"}},
		"speedrunner": {"nombre": "Speedrunner", "desc": "Rapidísima, pero frágil.", "arma": "macro", "pintura": 4,
			"pasiva": "Esquiva 35 % más seguido", "mods": {"hp": -15.0, "vel": 0.22, "dash_cd": -0.35}, "numeros": ["Vida 55", "Muy rápida"],
			"desbloqueo": {"tipo": "desafio", "id": "n_speedrunner", "txt": "Evoluciona 2 armas"}},
		"smurf": {"nombre": "Smurf", "desc": "Chiquitita y letal. Si te pegan, duele.", "arma": "ping_pong", "pintura": 3,
			"pasiva": "+25 % de daño y carga Desync más rápido", "mods": {"hp": -25.0, "dano": 0.25, "desync_carga": 0.25}, "numeros": ["Vida 45", "Rápida"],
			"desbloqueo": {"tipo": "desafio", "id": "n_smurf", "txt": "Haz una cadena de 200"}},
	}


static func pinturas() -> Array:
	return [
		{"nombre": "Rojo", "rampa": ["3a0c1e", "7a1630", "c42b3e", "f0584a", "ffc0a0"]},
		{"nombre": "Azul", "rampa": ["0c1f3a", "16407a", "2b6fc4", "4aa8f0", "b8e4ff"]},
		{"nombre": "Verde", "rampa": ["14280f", "2a5018", "4a8428", "7ab63c", "d0f08a"]},
		{"nombre": "Morado", "rampa": ["2a0c3a", "54187a", "8c2bc4", "c45cf0", "f0c0ff"]},
		{"nombre": "Amarillo", "rampa": ["3a2a08", "7a5a10", "c49a20", "f5d040", "fff6a8"]},
		{"nombre": "Gris", "rampa": ["14141c", "2c2c38", "4a4a5a", "7c7c90", "c0c0d0"]},
	]


# ===============================================================================================
# MASCOTAS: una a la vez. Cada mundo trae las suyas. Tamaños chicos: no deben tapar la acción.
# ===============================================================================================
static func mascotas() -> Dictionary:
	return {
		"mordisco": {"nombre": "Mordisco", "mundo": 1, "sprite": "mascota", "ia": "come", "desc": "Se come las balas que pasan cerca.",
			"radio": [44.0, 1.0], "recarga": [260.0, -4.0, 130.0], "mods_nivel": {"dano": 0.005},
			"desbloqueo": {"tipo": "nivel", "nivel": "1-3", "txt": "Completa el nivel 1-3"}},
		"chispita": {"nombre": "Chispita", "mundo": 1, "sprite": "mascota_chispita", "ia": "chispa", "desc": "Le da chispazos al enemigo más cercano.",
			"radio": [110.0, 2.0], "recarga": [150.0, -2.0, 70.0], "dmg": [1.2, 0.05], "mods_nivel": {"cadencia": 0.003},
			"desbloqueo": {"tipo": "desafio", "id": "m_chispita", "txt": "Tu mascota come 150 balas"}},
		"imancito": {"nombre": "Imancito", "mundo": 1, "sprite": "mascota_imancito", "ia": "iman", "desc": "Te trae los Bits y la chatarra de todo el campo cada cierto rato.",
			"radio": [0.0, 0.0], "recarga": [420.0, -6.0, 200.0], "mods_nivel": {"iman": 2.0, "chatarra": 0.004},
			"desbloqueo": {"tipo": "nivel", "nivel": "1-R", "txt": "Gana la Ruleta de Don Tuerca"}},
		"caparazon": {"nombre": "Caparazón", "mundo": 1, "sprite": "mascota_caparazon", "ia": "escudo", "desc": "Cada cierto rato te da un escudo que frena un golpe.",
			"radio": [0.0, 0.0], "recarga": [1500.0, -15.0, 900.0], "mods_nivel": {"hp": 0.5},
			"desbloqueo": {"tipo": "desafio", "id": "m_caparazon", "txt": "Vence al Compactador en Difícil"}},
		# Llegan con sus mundos: por ahora se ven en silueta.
		"brote": {"nombre": "Brote", "mundo": 2, "sprite": "", "ia": "", "desc": "Algo verde. Habla demasiado.", "desbloqueo": {"tipo": "mundo", "txt": "Mundo 2: Verdor"}},
		"ficha": {"nombre": "Ficha", "mundo": 3, "sprite": "", "ia": "", "desc": "Apuesta tu suerte.", "desbloqueo": {"tipo": "mundo", "txt": "Mundo 3: Jackpot"}},
		"burbujin": {"nombre": "Burbujín", "mundo": 4, "sprite": "", "ia": "", "desc": "Tímido. Muy tímido.", "desbloqueo": {"tipo": "mundo", "txt": "Mundo 4: Abismo"}},
		"tetrin": {"nombre": "Tetrín", "mundo": 5, "sprite": "", "ia": "", "desc": "Odia el desorden.", "desbloqueo": {"tipo": "mundo", "txt": "Mundo 5: Tetra"}},
		"ascua": {"nombre": "Ascua", "mundo": 6, "sprite": "", "ia": "", "desc": "Ama pelear.", "desbloqueo": {"tipo": "mundo", "txt": "Mundo 6: Forja"}},
		"tomito": {"nombre": "Tomito", "mundo": 7, "sprite": "", "ia": "", "desc": "Se acuerda de todo.", "desbloqueo": {"tipo": "mundo", "txt": "Mundo 7: Archivo"}},
	}


# ===============================================================================================
# PIEZAS: se llevan a todas las partidas. "mundo" y "desde" dicen cuándo empiezan a caer.
# ===============================================================================================
static func items() -> Dictionary:
	return {
		# Desde el principio
		"mira_laser": {"ranura": "mira", "mundo": 1, "desde": "", "nombre": "Mira Láser", "desc": "Más ataque y más críticos.", "base": {"atk": 2.0, "crit": 0.005},
			"pasivas": [{"r": 2, "txt": "+3 % de crítico", "mods": {"crit": 0.03}}, {"r": 3, "txt": "+15 % de daño crítico", "mods": {"crit_dmg": 0.15}}, {"r": 4, "txt": "+6 % de crítico", "mods": {"crit": 0.06}}, {"r": 5, "txt": "+35 % de daño crítico", "mods": {"crit_dmg": 0.35}}]},
		"casco_lata": {"ranura": "casco", "mundo": 1, "desde": "", "nombre": "Casco de Lata", "desc": "Vida extra, con algo de cariño.", "base": {"hp": 12.0},
			"pasivas": [{"r": 2, "txt": "Recupera 0,15 de vida por segundo", "mods": {"regen": 0.15}}, {"r": 3, "txt": "+3 % de armadura", "mods": {"armadura": 0.03}}, {"r": 4, "txt": "+5 % de armadura", "mods": {"armadura": 0.05}}, {"r": 5, "txt": "Revive una vez por partida", "mods": {"revives": 1}}]},
		"alas_ligeras": {"ranura": "alas", "mundo": 1, "desde": "", "nombre": "Alas Ligeras", "desc": "Más velocidad.", "base": {"vel": 0.03},
			"pasivas": [{"r": 2, "txt": "Roce más amplio", "mods": {"roce_rad": 3.0}}, {"r": 3, "txt": "+4 % de velocidad", "mods": {"vel": 0.04}}, {"r": 4, "txt": "+25 de imán", "mods": {"iman": 25.0}}, {"r": 5, "txt": "Roce mucho más amplio", "mods": {"roce_rad": 6.0}}]},
		"motor_turbo": {"ranura": "motor", "mundo": 1, "desde": "", "nombre": "Motor Turbo", "desc": "La esquiva se recarga antes.", "base": {"dash_cd": -0.03},
			"pasivas": [{"r": 2, "txt": "+3 % de velocidad", "mods": {"vel": 0.03}}, {"r": 3, "txt": "Esquiva 10 % más seguido", "mods": {"dash_cd": -0.10}}, {"r": 4, "txt": "Esquiva protege más tiempo", "mods": {"dash_iframes": 3.0}}, {"r": 5, "txt": "Esquiva 15 % más seguido", "mods": {"dash_cd": -0.15}}]},
		"chip_suerte": {"ranura": "chip", "mundo": 1, "desde": "", "nombre": "Chip de Suerte", "desc": "Mejor botín y más chatarra.", "base": {"suerte": 0.04, "chatarra": 0.04},
			"pasivas": [{"r": 2, "txt": "+6 % de experiencia", "mods": {"xp": 0.06}}, {"r": 3, "txt": "+12 % de suerte", "mods": {"suerte": 0.12}}, {"r": 4, "txt": "+15 % de chatarra", "mods": {"chatarra": 0.15}}, {"r": 5, "txt": "+30 % de suerte", "mods": {"suerte": 0.30}}]},
		"reactor_lag": {"ranura": "reactor", "mundo": 1, "desde": "1-2", "nombre": "Reactor de Lag", "desc": "La barra de Desync se llena más rápido.", "base": {"desync_carga": 0.05},
			"pasivas": [{"r": 2, "txt": "+0,3 s de Desync", "mods": {"desync_dur": 0.3}}, {"r": 3, "txt": "+10 % de carga", "mods": {"desync_carga": 0.10}}, {"r": 4, "txt": "+0,6 s de Desync", "mods": {"desync_dur": 0.6}}, {"r": 5, "txt": "+20 % de carga", "mods": {"desync_carga": 0.20}}]},
		# Empiezan a caer a medida que avanzas en el mundo
		"cargador": {"ranura": "mira", "mundo": 1, "desde": "1-3", "nombre": "Cargador Rápido", "desc": "Más ataque, y todo dispara más rápido.", "base": {"atk": 1.5, "cadencia": 0.015},
			"pasivas": [{"r": 2, "txt": "+5 % de cadencia", "mods": {"cadencia": 0.05}}, {"r": 3, "txt": "+6 % de daño", "mods": {"dano": 0.06}}, {"r": 4, "txt": "+10 % de cadencia", "mods": {"cadencia": 0.10}}, {"r": 5, "txt": "+15 % de daño", "mods": {"dano": 0.15}}]},
		"casco_blindado": {"ranura": "casco", "mundo": 1, "desde": "1-3", "nombre": "Casco Blindado", "desc": "Menos vida, pero reduce todo el daño.", "base": {"hp": 7.0, "armadura": 0.02},
			"pasivas": [{"r": 2, "txt": "+3 % de armadura", "mods": {"armadura": 0.03}}, {"r": 3, "txt": "+3 % de armadura", "mods": {"armadura": 0.03}}, {"r": 4, "txt": "+0,3 de vida por segundo", "mods": {"regen": 0.3}}, {"r": 5, "txt": "Revive una vez por partida", "mods": {"revives": 1}}]},
		"alas_iman": {"ranura": "alas", "mundo": 1, "desde": "1-3", "nombre": "Alas Imán", "desc": "Atrae Bits y chatarra desde más lejos.", "base": {"iman": 12.0, "vel": 0.01},
			"pasivas": [{"r": 2, "txt": "+6 % de experiencia", "mods": {"xp": 0.06}}, {"r": 3, "txt": "+25 de imán", "mods": {"iman": 25.0}}, {"r": 4, "txt": "+10 % de experiencia", "mods": {"xp": 0.10}}, {"r": 5, "txt": "+15 % de chatarra", "mods": {"chatarra": 0.15}}]},
		"reactor_cascada": {"ranura": "reactor", "mundo": 1, "desde": "1-4", "nombre": "Reactor de Cascada", "desc": "La cascada del Desync pega más fuerte.", "base": {"cascada": 0.06},
			"pasivas": [{"r": 2, "txt": "+6 % de carga de Desync", "mods": {"desync_carga": 0.06}}, {"r": 3, "txt": "+15 % de cascada", "mods": {"cascada": 0.15}}, {"r": 4, "txt": "+0,3 s de Desync", "mods": {"desync_dur": 0.3}}, {"r": 5, "txt": "+35 % de cascada", "mods": {"cascada": 0.35}}]},
		"mun_perforante": {"ranura": "mira", "mundo": 1, "desde": "1-5", "nombre": "Munición Perforante", "desc": "Mucho ataque. Tus balas atraviesan.", "base": {"atk": 2.5},
			"pasivas": [{"r": 2, "txt": "Atraviesa +1", "mods": {"perfora": 1}}, {"r": 3, "txt": "+6 % de daño", "mods": {"dano": 0.06}}, {"r": 4, "txt": "Atraviesa +1", "mods": {"perfora": 1}}, {"r": 5, "txt": "+1 bala en armas frontales", "mods": {"balas": 1}}]},
		"motor_fantasma": {"ranura": "motor", "mundo": 1, "desde": "1-5", "nombre": "Motor Fantasma", "desc": "La esquiva te protege más tiempo.", "base": {"dash_iframes": 1.5},
			"pasivas": [{"r": 2, "txt": "Esquiva 6 % más seguido", "mods": {"dash_cd": -0.06}}, {"r": 3, "txt": "+6 % de carga de Desync", "mods": {"desync_carga": 0.06}}, {"r": 4, "txt": "Esquiva protege mucho más", "mods": {"dash_iframes": 4.0}}, {"r": 5, "txt": "+15 % de carga de Desync", "mods": {"desync_carga": 0.15}}]},
		"chip_critico": {"ranura": "chip", "mundo": 1, "desde": "1-5", "nombre": "Chip Crítico", "desc": "Más probabilidad de golpe crítico.", "base": {"crit": 0.015},
			"pasivas": [{"r": 2, "txt": "+15 % de daño crítico", "mods": {"crit_dmg": 0.15}}, {"r": 3, "txt": "+3 % de crítico", "mods": {"crit": 0.03}}, {"r": 4, "txt": "+30 % de daño crítico", "mods": {"crit_dmg": 0.30}}, {"r": 5, "txt": "+6 % de crítico", "mods": {"crit": 0.06}}]},
		"mun_explosiva": {"ranura": "mira", "mundo": 1, "desde": "1-6", "nombre": "Munición Explosiva", "desc": "Más ataque y áreas más grandes.", "base": {"atk": 1.75, "area": 0.015},
			"pasivas": [{"r": 2, "txt": "+6 % de tamaño", "mods": {"area": 0.06}}, {"r": 3, "txt": "+6 % de daño", "mods": {"dano": 0.06}}, {"r": 4, "txt": "+10 % de tamaño", "mods": {"area": 0.10}}, {"r": 5, "txt": "+20 % de tamaño", "mods": {"area": 0.20}}]},
		"reactor_estable": {"ranura": "reactor", "mundo": 1, "desde": "1-6", "nombre": "Reactor Estable", "desc": "El escudo del Desync aguanta más.", "base": {"desync_carga": 0.02},
			"pasivas": [{"r": 2, "txt": "+1 golpe de escudo en Desync", "mods": {"desync_escudo": 1}}, {"r": 3, "txt": "+6 % de carga", "mods": {"desync_carga": 0.06}}, {"r": 4, "txt": "+1 golpe de escudo en Desync", "mods": {"desync_escudo": 1}}, {"r": 5, "txt": "+0,5 s de Desync", "mods": {"desync_dur": 0.5}}]},
		"chip_xp": {"ranura": "chip", "mundo": 1, "desde": "1-6", "nombre": "Chip de Experiencia", "desc": "Subes de nivel más rápido en cada partida.", "base": {"xp": 0.03},
			"pasivas": [{"r": 2, "txt": "+25 de imán", "mods": {"iman": 25.0}}, {"r": 3, "txt": "+6 % de experiencia", "mods": {"xp": 0.06}}, {"r": 4, "txt": "+1 cambio de cartas", "mods": {"cambios": 1}}, {"r": 5, "txt": "+15 % de experiencia", "mods": {"xp": 0.15}}]},
		# Llegan con el Mundo 2
		"mira_termica": {"ranura": "mira", "mundo": 2, "desde": "", "nombre": "Mira Térmica", "desc": "Más daño a los enemigos con mucha vida.", "base": {"atk": 2.5, "crit": 0.005},
			"pasivas": [{"r": 2, "txt": "+4 % de crítico", "mods": {"crit": 0.04}}, {"r": 3, "txt": "+8 % de daño", "mods": {"dano": 0.08}}, {"r": 4, "txt": "+25 % de daño crítico", "mods": {"crit_dmg": 0.25}}, {"r": 5, "txt": "+15 % de daño", "mods": {"dano": 0.15}}]},
		"casco_espinas": {"ranura": "casco", "mundo": 2, "desde": "", "nombre": "Casco de Espinas", "desc": "Al recibir un golpe, devuelve una onda.", "base": {"hp": 10.0, "thorns": 0.3},
			"pasivas": [{"r": 2, "txt": "Onda más fuerte", "mods": {"thorns": 0.5}}, {"r": 3, "txt": "+3 % de armadura", "mods": {"armadura": 0.03}}, {"r": 4, "txt": "Onda mucho más fuerte", "mods": {"thorns": 1.0}}, {"r": 5, "txt": "Revive una vez por partida", "mods": {"revives": 1}}]},
		"alas_cuchilla": {"ranura": "alas", "mundo": 2, "desde": "", "nombre": "Alas Cuchilla", "desc": "Más velocidad y daño al moverte.", "base": {"vel": 0.025, "mov_dano": 0.02},
			"pasivas": [{"r": 2, "txt": "+3 % de daño en movimiento", "mods": {"mov_dano": 0.03}}, {"r": 3, "txt": "+4 % de velocidad", "mods": {"vel": 0.04}}, {"r": 4, "txt": "+6 % de daño en movimiento", "mods": {"mov_dano": 0.06}}, {"r": 5, "txt": "+6 % de velocidad", "mods": {"vel": 0.06}}]},
		"motor_nitro": {"ranura": "motor", "mundo": 2, "desde": "", "nombre": "Motor Nitro", "desc": "Esquivas más lejos y más seguido.", "base": {"dash_cd": -0.04},
			"pasivas": [{"r": 2, "txt": "Esquiva 8 % más seguido", "mods": {"dash_cd": -0.08}}, {"r": 3, "txt": "+4 % de velocidad", "mods": {"vel": 0.04}}, {"r": 4, "txt": "Esquiva protege más tiempo", "mods": {"dash_iframes": 4.0}}, {"r": 5, "txt": "Esquiva 15 % más seguido", "mods": {"dash_cd": -0.15}}]},
		"reactor_fuga": {"ranura": "reactor", "mundo": 2, "desde": "", "nombre": "Reactor con Fuga", "desc": "Mucha carga de Desync, pero menos vida.", "base": {"desync_carga": 0.08, "hp": -3.0},
			"pasivas": [{"r": 2, "txt": "+10 % de cascada", "mods": {"cascada": 0.10}}, {"r": 3, "txt": "+10 % de carga", "mods": {"desync_carga": 0.10}}, {"r": 4, "txt": "+25 % de cascada", "mods": {"cascada": 0.25}}, {"r": 5, "txt": "+20 % de carga", "mods": {"desync_carga": 0.20}}]},
		"chip_botin": {"ranura": "chip", "mundo": 2, "desde": "", "nombre": "Chip de Botín", "desc": "Mucha más chatarra.", "base": {"chatarra": 0.08},
			"pasivas": [{"r": 2, "txt": "+6 % de suerte", "mods": {"suerte": 0.06}}, {"r": 3, "txt": "+15 % de chatarra", "mods": {"chatarra": 0.15}}, {"r": 4, "txt": "+12 % de suerte", "mods": {"suerte": 0.12}}, {"r": 5, "txt": "+30 % de chatarra", "mods": {"chatarra": 0.30}}]},
	}


# ===============================================================================================
# LA BASE: siempre puede salir y no se apaga. Cada mundo le agrega 2 armas y 2 habilidades fijas.
# ===============================================================================================
static func base_por_mundo() -> Array:
	return [
		{"armas": ["pistola", "escopeta", "macro", "misiles", "rayo", "sierras"], "habs": ["doble", "spray", "p2w", "fatfinger", "pizza", "stonks"]},
		{"armas": ["railgun", "cohetes"], "habs": ["headshot", "goblin"]},
		{"armas": ["drones", "ping_pong"], "habs": ["wallbang", "copium"]},
		{"armas": ["aura", "rollback"], "habs": ["lagcomp", "tank"]},
		{"armas": ["minas", "laser"], "habs": ["aimbot", "clutch"]},
		{"armas": ["molotov", "quickscope"], "habs": ["reaccion", "bunnyhop"]},
		{"armas": ["firewall", "tornado"], "habs": ["thorns", "leech"]},
	]


# ===============================================================================================
# DESAFÍOS: cumplirlos desbloquea armas, habilidades, naves, mascotas y ranuras.
# stat: una clave de las estadísticas de la partida, o "estrellas" / "desafios".
# ===============================================================================================
static func _d(id: String, txt: String, stat: String, meta: int, tipo: String, cosa := "", requiere := "") -> Dictionary:
	var de := {"id": id, "mundo": 1, "txt": txt, "stat": stat, "meta": meta, "premio": {"tipo": tipo, "id": cosa}}
	if requiere != "":
		de["requiere"] = requiere
	return de


static func desafios() -> Array:
	return [
		# ---- armas
		_d("a_cohetes", "Mata a 25 Rabiosos", "k_rabioso", 25, "arma", "cohetes"),
		_d("a_ping_pong", "Roza 80 balas", "roces", 80, "arma", "ping_pong"),
		_d("a_railgun", "Mata a 15 Snipers", "k_sniper", 15, "arma", "railgun"),
		_d("a_firewall", "Gana un nivel sin recibir golpes", "sin_golpes", 1, "arma", "firewall"),
		_d("a_drones", "Usa el Desync 5 veces", "desyncs", 5, "arma", "drones", "desync"),
		_d("a_aura", "Gana 8 niveles", "victorias", 8, "arma", "aura"),
		_d("a_rollback", "Haz una cadena de 60", "max_cadena", 60, "arma", "rollback"),
		_d("a_minas", "Mata a 15 Spammers", "k_spammer", 15, "arma", "minas"),
		_d("a_laser", "Haz 3 ACE", "aces", 3, "arma", "laser", "desync"),
		_d("a_molotov", "Mata a 10 Compactos", "k_compacto", 10, "arma", "molotov"),
		_d("a_rush_b", "Mata a 60 Moscas", "k_mosca", 60, "arma", "rush_b"),
		_d("a_quickscope", "Vence a La Grúa 3 veces", "k_grua", 3, "arma", "quickscope"),
		_d("a_tornado", "Recoge 1.500 de chatarra", "chatarra_total", 1500, "arma", "tornado"),
		_d("a_taladro", "Mata a 1.000 enemigos", "kills", 1000, "arma", "taladro"),
		_d("a_gacha", "Gira la ruleta 4 veces", "giros", 4, "arma", "gacha"),
		_d("a_ragequit", "Pierde 10 veces", "muertes", 10, "arma", "ragequit"),
		_d("a_sumidero", "Vence a El Compactador", "k_compactador", 1, "arma", "sumidero"),
		_d("a_frame_drop", "Aguanta 3 minutos en el Modo Infinito", "inf_seg", 180, "arma", "frame_drop"),
		_d("a_afk_farmer", "Aguanta 5 minutos en el Modo Infinito", "inf_seg", 300, "arma", "afk_farmer"),
		_d("a_speedhack", "Consigue 15 estrellas", "estrellas", 15, "arma", "speedhack"),
		# ---- habilidades
		_d("h_goblin", "Recoge 300 de chatarra", "chatarra_total", 300, "hab", "goblin"),
		_d("h_copium", "Gana 3 niveles", "victorias", 3, "hab", "copium"),
		_d("h_headshot", "Haz una cadena de 40", "max_cadena", 40, "hab", "headshot"),
		_d("h_ping0", "Esquiva 50 veces", "esquivas", 50, "hab", "ping0"),
		_d("h_aimbot", "Mata a 500 enemigos", "kills", 500, "hab", "aimbot"),
		_d("h_wallbang", "Mata a 30 Snipers", "k_sniper", 30, "hab", "wallbang"),
		_d("h_lagcomp", "Roza 250 balas", "roces", 250, "hab", "lagcomp"),
		_d("h_buffer", "Usa el Desync 10 veces", "desyncs", 10, "hab", "buffer", "desync"),
		_d("h_combo", "Usa el Desync 25 veces", "desyncs", 25, "hab", "combo", "desync"),
		_d("h_tank", "Recibe 50 golpes", "golpes_total", 50, "hab", "tank"),
		_d("h_thorns", "Mata a 30 Moscas", "k_mosca", 30, "hab", "thorns"),
		_d("h_lagswitch", "Esquiva 150 veces", "esquivas", 150, "hab", "lagswitch"),
		_d("h_macrokeys", "Esquiva 300 veces", "esquivas", 300, "hab", "macrokeys"),
		_d("h_bunnyhop", "Gana 20 niveles", "victorias", 20, "hab", "bunnyhop"),
		_d("h_clutch", "Gana un nivel con menos de 15 % de vida", "clutch", 1, "hab", "clutch"),
		_d("h_leech", "Mata a 2.500 enemigos", "kills", 2500, "hab", "leech"),
		_d("h_reaccion", "Evoluciona 3 armas", "evoluciones", 3, "hab", "reaccion"),
		_d("h_rng", "Cambia cartas 15 veces", "cambios", 15, "hab", "rng"),
		_d("h_hardcore", "Gana un nivel en Difícil", "v_dif_dificil", 1, "hab", "hardcore"),
		_d("h_battlepass", "Mejora piezas 20 veces", "mejoras", 20, "hab", "battlepass"),
		_d("h_hitboxchica", "Gana 3 niveles sin recibir golpes", "sin_golpes", 3, "hab", "hitboxchica"),
		_d("h_overclock", "Saca 3 estrellas en 5 niveles", "tres_estrellas", 5, "hab", "overclock"),
		_d("h_buffstack", "Fusiona piezas 10 veces", "fusiones", 10, "hab", "buffstack", "fusion"),
		_d("h_framerate", "Roza 600 balas", "roces", 600, "hab", "framerate"),
		# ---- naves
		_d("n_speedrunner", "Evoluciona 2 armas", "evoluciones", 2, "nave", "speedrunner"),
		_d("n_support", "Usa el Desync 40 veces", "desyncs", 40, "nave", "support", "desync"),
		_d("n_ballena", "Recibe 150 golpes", "golpes_total", 150, "nave", "ballena"),
		_d("n_smurf", "Haz una cadena de 200", "max_cadena", 200, "nave", "smurf"),
		# ---- mascotas
		_d("m_chispita", "Tu mascota come 150 balas", "nams", 150, "mascota", "chispita", "mascota"),
		_d("m_caparazon", "Vence a El Compactador en Difícil", "v_1-8_dificil", 1, "mascota", "caparazon"),
		# ---- ranuras: como en Megabonk, se empieza con pocas y se ganan con desafíos
		_d("r_hab4", "Completa 8 desafíos", "desafios", 8, "ranura_hab"),
		_d("r_arma3", "Completa 15 desafíos", "desafios", 15, "ranura_arma"),
		_d("r_arma4", "Completa 35 desafíos", "desafios", 35, "ranura_arma"),
	]
