class_name CatalogoNiveles
extends RefCounted
## Enemigos, rutas, mundos y niveles.


static func enemigos() -> Dictionary:
	return {
	"mosca": {"nombre": "Mosca", "sprite": "mosca", "w": 24, "h": 24, "frames": 4, "hp": 7, "xp": 1, "radio": 7.0, "ia": "enjambre", "toque": 8.0, "dura": 14.0, "ayuda": "Chica y rápida. Viene en montón y te persigue."},
	"bot": {"nombre": "Bot", "sprite": "bot", "w": 32, "h": 32, "frames": 4, "hp": 16, "xp": 3, "radio": 11.0, "ia": "ruta", "disparo": 240, "toque": 22.0, "ayuda": "Básico. Sigue una ruta y dispara a veces."},
	"rabioso": {"nombre": "Rabioso", "sprite": "rabioso", "w": 32, "h": 32, "frames": 4, "hp": 20, "xp": 3, "radio": 10.0, "ia": "kamikaze", "toque": 24.0, "ayuda": "Parpadea y se lanza hacia ti."},
	"sniper": {"nombre": "Sniper", "sprite": "sniper", "w": 40, "h": 40, "frames": 4, "hp": 50, "xp": 6, "radio": 13.0, "ia": "sniper", "permanece": 12.0, "toque": 22.0, "ayuda": "Muestra una línea roja y dispara por ahí."},
	"spammer": {"nombre": "Spammer", "sprite": "spammer", "w": 48, "h": 48, "frames": 4, "hp": 100, "xp": 10, "radio": 18.0, "ia": "spammer", "permanece": 14.0, "toque": 22.0, "ayuda": "Sus burbujas se rompen a balazos."},
	"compacto": {"nombre": "Compacto", "sprite": "compacto", "w": 48, "h": 48, "frames": 4, "hp": 240, "xp": 18, "radio": 20.0, "ia": "tanque", "permanece": 16.0, "toque": 26.0, "ayuda": "Muy resistente. Dispara anillos."},
	"reparador": {"nombre": "Reparador", "sprite": "reparador", "w": 32, "h": 32, "frames": 4, "hp": 45, "xp": 6, "radio": 11.0, "ia": "apoyo", "permanece": 16.0, "toque": 22.0, "ayuda": "Cura a los demás: mátalo primero."},
	"grua": {"nombre": "La Grúa", "sprite": "grua", "w": 96, "h": 96, "frames": 4, "hp": 1200.0, "xp": 60, "radio": 34.0, "ia": "grua", "jefe": true, "fases": [0.5], "tope_seg": 42.0, "toque": 26.0, "ayuda": "Minijefe."},
	"compactador": {"nombre": "El Compactador", "sprite": "compactador", "w": 128, "h": 128, "frames": 8, "hp": 5000.0, "xp": 200, "radio": 42.0, "ia": "compactador", "jefe": true, "fases": [0.66, 0.33], "tope_seg": 50.0, "toque": 30.0, "ayuda": "Jefe. Recibe más daño con las mandíbulas abiertas."},
}


static func rutas() -> Dictionary:
	return {
	"arco_izq": {"dur": 7.0, "pts": [[-30, 40], [110, 60], [300, 110], [270, 220], [120, 190], [-30, 110]]},
	"arco_der": {"dur": 7.0, "pts": [[430, 40], [290, 60], [100, 110], [130, 220], [280, 190], [430, 110]]},
	"s_izq": {"dur": 8.0, "pts": [[110, -30], [50, 60], [190, 120], [60, 190], [190, 260], [110, 400]]},
	"s_der": {"dur": 8.0, "pts": [[290, -30], [350, 60], [210, 120], [340, 190], [210, 260], [290, 400]]},
	"rulo_izq": {"dur": 9.0, "pts": [[-30, 110], [120, 90], [230, 170], [150, 250], [60, 170], [150, 90], [300, 70], [430, 50]]},
	"rulo_der": {"dur": 9.0, "pts": [[430, 110], [280, 90], [170, 170], [250, 250], [340, 170], [250, 90], [100, 70], [-30, 50]]},
	"caida_a": {"dur": 5.5, "pts": [[60, -30], [80, 130], [50, 260], [70, 400]]},
	"caida_b": {"dur": 5.5, "pts": [[200, -30], [190, 130], [215, 260], [200, 400]]},
	"caida_c": {"dur": 5.5, "pts": [[340, -30], [320, 130], [350, 260], [330, 400]]},
	"cruce_izq": {"dur": 6.5, "pts": [[-30, 50], [110, 110], [240, 200], [340, 300], [440, 400]]},
	"cruce_der": {"dur": 6.5, "pts": [[430, 50], [290, 110], [160, 200], [60, 300], [-40, 400]]},
	"barrido_izq": {"dur": 6.5, "pts": [[-30, 70], [110, 105], [290, 105], [430, 70]]},
	"barrido_der": {"dur": 6.5, "pts": [[430, 70], [290, 105], [110, 105], [-30, 70]]},
	"v_izq": {"dur": 7.0, "pts": [[90, -30], [130, 110], [200, 210], [270, 110], [310, -30]]},
	"v_der": {"dur": 7.0, "pts": [[310, -30], [270, 110], [200, 210], [130, 110], [90, -30]]},
	"recta": {"dur": 6.5, "pts": [[200, -30], [200, 130], [200, 260], [200, 400]]},
}


static func mundos() -> Array:
	return [
	{"nombre": "Chatarra", "desc": "Un basural con mal genio.", "abierto": true},
	{"nombre": "Verdor", "desc": "Una selva que no para de hablar.", "abierto": false},
	{"nombre": "Jackpot", "desc": "Un planeta casino.", "abierto": false},
	{"nombre": "Abismo", "desc": "Un océano tímido y oscuro.", "abierto": false},
	{"nombre": "Tetra", "desc": "Un mundo que odia el desorden. Caen bloques.", "abierto": false},
	{"nombre": "Forja", "desc": "Un volcán que ama pelear.", "abierto": false},
	{"nombre": "Archivo", "desc": "La memoria del universo.", "abierto": false},
]


## Cada nivel: "ritmo" son los puntos por segundo al empezar y al terminar (ver director.gd);
## "mezcla" son [tipo, peso, segundo desde el que sale]; "hitos" es lo fijo, para presentar enemigos y jefes.
## "dureza" y "dureza_fin" multiplican la vida enemiga al empezar y al terminar el nivel.
static func niveles() -> Dictionary:
	return {
	"1-1": {"nombre": "Despertar en el basural", "desc": "Muévete, dispara y recoge lo que caiga.", "dureza": 1.0, "dureza_fin": 1.5, "agresion": 1.25, "presupuesto": 40, "salva": 0.0, "golpes": 2, "cadena": 30, "duracion": 100.0,
		"premio": {"tipo": "hangar", "nombre": "HANGAR", "icono": "icono_hangar", "desc": "Ponle piezas a tu nave"},
		"enemigos": ["bot"],
		"pistas": [[1.0, "Muévete con {mover}. La nave dispara sola."], [5.0, "Lo rojo son balas: ¡esquívalas!"], [11.0, "Lo dorado son Bits, no balas: recógelos y subes de nivel."], [30.0, "Las tuercas son chatarra: sirve para mejorar tu nave."]],
		"ritmo": [1.7, 3.8], "mezcla": [["bot", 1.0, 0.0]],
		"hitos": [{"t": 1.5, "tipo": "bot", "n": 3, "sep": 0.5, "ruta": "arco_izq"}]},
	"1-2": {"nombre": "Algo se mueve", "desc": "Llegan los Rabiosos y las Moscas. Aprende a esquivar.", "dureza": 1.05, "dureza_fin": 1.8, "agresion": 1.1, "presupuesto": 60, "salva": 8.0, "golpes": 3, "cadena": 60, "duracion": 130.0,
		"premio": {"tipo": "desync", "nombre": "DESYNC", "icono": "icono_desync", "desc": "Tu arma secreta"},
		"enemigos": ["bot", "rabioso", "mosca"],
		"pistas": [[1.0, "{esquivar} te hace esquivar: por un momento nada te toca."], [14.0, "Los Rabiosos parpadean y se lanzan. ¡Muévete!"], [32.0, "Solo el punto del centro de tu nave recibe daño. {foco} te hace ir lento."], [55.0, "Las Moscas te persiguen. Mueren de un toque: ¡dales!"]],
		"ritmo": [1.8, 5.0], "mezcla": [["bot", 1.0, 0.0], ["rabioso", 0.3, 20.0], ["mosca", 0.35, 58.0]],
		"hitos": [{"t": 14.0, "tipo": "rabioso", "n": 2, "sep": 0.8, "anclas": [[120, 70], [280, 70]]}, {"t": 56.0, "tipo": "mosca", "n": 10, "sep": 0.08, "enjambre": "arriba"}]},
	"1-3": {"nombre": "¿Y esa barra?", "desc": "Prueba el DESYNC. Aparecen francotiradores.", "dureza": 1.1, "dureza_fin": 2.2, "agresion": 1.0, "presupuesto": 80, "salva": 8.0, "golpes": 3, "cadena": 90, "duracion": 160.0, "desync_regalo": 16.0,
		"premio": {"tipo": "mascota", "nombre": "MASCOTA Y FUSIÓN", "icono": "mascota", "desc": "Algo salió de una lata de atún"},
		"enemigos": ["bot", "rabioso", "mosca", "sniper"],
		"pistas": [[1.0, "Matar y pasar cerca de las balas llena la barra de DESYNC."], [34.0, "El Sniper muestra una línea: cuando brilla, sal de ahí."]],
		"ritmo": [1.9, 6.0], "mezcla": [["bot", 1.0, 0.0], ["mosca", 0.5, 15.0], ["rabioso", 0.35, 18.0], ["sniper", 0.2, 45.0]],
		"hitos": [{"t": 33.0, "tipo": "sniper", "n": 2, "sep": 0.5, "anclas": [[70, 40], [330, 40]]}]},
	"1-4": {"nombre": "La Grúa", "desc": "Lleva años levantando autos. Ahora te quiere a ti.", "dureza": 1.15, "dureza_fin": 2.4, "agresion": 0.95, "presupuesto": 100, "salva": 8.0, "golpes": 4, "cadena": 90, "duracion": 150.0, "jefe": "grua",
		"premio": {"tipo": "tablon", "nombre": "TABLÓN Y ARSENAL", "icono": "icono_arsenal", "desc": "Encargos que te dan armas nuevas"},
		"enemigos": ["bot", "rabioso", "mosca", "sniper", "grua"],
		"pistas": [[1.0, "Sube de nivel todo lo que puedas: viene un minijefe."], [153.0, "Apunta al núcleo rojo. Todo lo que tiene núcleo rojo se rompe."]],
		"ritmo": [2.0, 5.6], "mezcla": [["bot", 1.0, 0.0], ["mosca", 0.5, 15.0], ["rabioso", 0.4, 10.0], ["sniper", 0.22, 25.0]],
		"hitos": [{"t": 150.0, "espera": true}, {"t": 151.0, "aviso": "¡LA GRÚA!", "jefe": true}, {"t": 153.0, "tipo": "grua", "n": 1, "sep": 0.0, "anclas": [[200, 80]]}]},
	"1-5": {"nombre": "Gritones", "desc": "Spammers: lanzan burbujas de chat.", "dureza": 1.2, "dureza_fin": 2.8, "agresion": 0.95, "presupuesto": 120, "salva": 7.0, "golpes": 4, "cadena": 110, "duracion": 190.0,
		"premio": {"tipo": "pieza", "rareza": 2, "nombre": "PIEZA RARA", "icono": "icono_fusion", "desc": "Una pieza azul al azar"},
		"enemigos": ["bot", "rabioso", "mosca", "sniper", "spammer"],
		"pistas": [[8.0, "Las burbujas del Spammer se rompen a balazos."]],
		"ritmo": [2.1, 7.0], "mezcla": [["bot", 1.0, 0.0], ["mosca", 0.5, 15.0], ["rabioso", 0.4, 15.0], ["sniper", 0.2, 40.0], ["spammer", 0.25, 30.0]],
		"hitos": [{"t": 6.0, "tipo": "spammer", "n": 1, "sep": 0.0, "anclas": [[200, 55]]}]},
	"1-6": {"nombre": "Mantención", "desc": "Tanques y reparadores. Elige bien a quién matar.", "dureza": 1.25, "dureza_fin": 3.2, "agresion": 0.9, "presupuesto": 130, "salva": 7.0, "golpes": 5, "cadena": 120, "duracion": 210.0,
		"premio": {"tipo": "cambios", "nombre": "+1 CAMBIO DE CARTAS", "icono": "icono_spray", "desc": "Cambia cartas una vez más por partida"},
		"enemigos": ["bot", "rabioso", "mosca", "sniper", "spammer", "compacto", "reparador"],
		"pistas": [[9.0, "El Reparador cura a los demás: mátalo primero."]],
		"ritmo": [2.2, 7.6], "mezcla": [["bot", 1.0, 0.0], ["mosca", 0.5, 15.0], ["rabioso", 0.35, 15.0], ["sniper", 0.18, 40.0], ["spammer", 0.18, 45.0], ["compacto", 0.16, 50.0], ["reparador", 0.16, 50.0]],
		"hitos": [{"t": 7.0, "tipo": "compacto", "n": 1, "sep": 0.0, "anclas": [[200, 70]]}, {"t": 8.0, "tipo": "reparador", "n": 1, "sep": 0.0, "anclas": [[120, 40]]}]},
	"1-7": {"nombre": "Hora punta", "desc": "Todo el basural a la vez. Arma tu mejor build.", "dureza": 1.3, "dureza_fin": 3.8, "agresion": 0.85, "presupuesto": 150, "salva": 6.5, "golpes": 5, "cadena": 150, "duracion": 240.0,
		"premio": {"tipo": "chatarra", "cantidad": 150, "nombre": "BOLSA DE CHATARRA", "icono": "obj_tuerca_grande", "desc": "150 de chatarra para mejorar piezas"},
		"enemigos": ["bot", "rabioso", "mosca", "sniper", "spammer", "compacto", "reparador"], "pistas": [],
		"ritmo": [2.3, 9.0], "mezcla": [["bot", 1.0, 0.0], ["mosca", 0.5, 15.0], ["rabioso", 0.4, 15.0], ["sniper", 0.2, 35.0], ["spammer", 0.2, 40.0], ["compacto", 0.14, 60.0], ["reparador", 0.14, 60.0]],
		"hitos": []},
	"1-8": {"nombre": "El Compactador", "desc": "Se comió dos camionetas y a un cuñado.", "dureza": 1.35, "dureza_fin": 3.4, "agresion": 0.85, "presupuesto": 160, "salva": 7.0, "golpes": 5, "cadena": 130, "duracion": 180.0, "jefe": "compactador",
		"premio": {"tipo": "nave", "id": "camper", "nombre": "NAVE: CAMPER", "icono": "nave", "desc": "Y se abre el MODO INFINITO"},
		"enemigos": ["bot", "rabioso", "mosca", "sniper", "spammer", "compactador"],
		"pistas": [[184.0, "Con las mandíbulas abiertas recibe mucho más daño."]],
		"ritmo": [2.3, 6.8], "mezcla": [["bot", 1.0, 0.0], ["mosca", 0.5, 15.0], ["rabioso", 0.4, 15.0], ["sniper", 0.2, 35.0], ["spammer", 0.2, 40.0]],
		"hitos": [{"t": 180.0, "espera": true}, {"t": 181.0, "aviso": "¡EL COMPACTADOR!", "jefe": true}, {"t": 184.0, "tipo": "compactador", "n": 1, "sep": 0.0, "anclas": [[200, 86]]}]},
	"1-R": {"nombre": "La Ruleta de Don Tuerca", "desc": "Dos veces gira la ruleta: plata, hordas o jefes. Tres iguales, y agárrate.", "modo": "ruleta", "indice": 4, "dureza": 1.2, "dureza_fin": 2.6, "agresion": 0.95, "presupuesto": 110, "salva": 5.5, "golpes": 6, "cadena": 100, "duracion": 170.0,
		"premio": {"tipo": "mascota", "id": "imancito", "nombre": "MASCOTA: IMANCITO", "icono": "mascota", "desc": "Y piezas cada vez que ganes"},
		"enemigos": ["bot", "rabioso", "mosca", "sniper", "spammer", "compacto", "grua"], "pistas": [],
		"ritmo": [2.8, 6.8], "mezcla": [["bot", 1.0, 0.0], ["mosca", 0.5, 15.0], ["rabioso", 0.4, 15.0], ["sniper", 0.2, 30.0], ["spammer", 0.2, 35.0], ["compacto", 0.12, 50.0]],
		"hitos": []},
	"1-INF": {"nombre": "Chatarrera Infinita", "desc": "Todo el basural junto y cada vez más fuerte. Aguanta lo que puedas.", "modo": "infinito", "indice": 6, "dureza": 1.2, "dureza_fin": 1.2, "agresion": 0.95, "presupuesto": 140, "salva": 6.0, "golpes": 0, "cadena": 0, "duracion": 0.0,
		"premio": {"tipo": "record", "nombre": "RÉCORD", "icono": "icono_infinito", "desc": "Chatarra y piezas según cuánto aguantes"},
		"enemigos": ["bot", "rabioso", "mosca", "sniper", "spammer", "compacto", "reparador", "grua", "compactador"], "pistas": [],
		"ritmo": [3.0, 10.0], "ritmo_seg": 300.0, "mezcla": [["bot", 1.0, 0.0], ["mosca", 0.5, 15.0], ["rabioso", 0.4, 10.0], ["sniper", 0.2, 25.0], ["spammer", 0.2, 40.0], ["compacto", 0.14, 60.0], ["reparador", 0.14, 70.0]],
		"hitos": []},
}
