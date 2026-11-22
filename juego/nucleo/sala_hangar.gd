class_name SalaHangar
extends RefCounted
## Dónde está cada objeto en la habitación del Hangar (pantalla de 640x360).
## r: el rectángulo del sprite hangar_obj_<id>. nombre y frase: lo que se muestra al enfocarlo.
## La franja superior de 26 px es para la barra de estaciones.
## Los rectángulos y POS_NAVE/POS_MASCOTA los escribe herramientas/arte/generar_v3_escenas.py: r mide justo lo que mide el sprite.

const OBJETOS := {
	"naves": {"r": Rect2(244, 238, 152, 82), "nombre": "NAVES", "frase": "Elige con qué nave sales y píntala."},
	"equipo": {"r": Rect2(12, 50, 109, 249), "nombre": "EQUIPO", "frase": "Ponle piezas a tu nave y mejóralas con chatarra."},
	"fusionar": {"r": Rect2(126, 98, 126, 173), "nombre": "FUSIONAR", "frase": "Tres piezas iguales entran, una mejor sale. No preguntes."},
	"mascota": {"r": Rect2(401, 214, 153, 103), "nombre": "MASCOTA", "frase": "Conoce a tus mascotas y elige con cuál sales."},
	"arsenal": {"r": Rect2(398, 56, 136, 144), "nombre": "ARSENAL", "frase": "Encargos de Don Tuerca, y qué armas pueden salir."},
	"salida": {"r": Rect2(526, 45, 111, 255), "nombre": "SALIR", "frase": "De vuelta al mapa."},
}
const ORDEN := ["naves", "equipo", "fusionar", "mascota", "arsenal", "salida"]
## Centro de la nave real (48x48 al doble), flotando sobre el plato, y de la mascota activa (al doble), sobre la frazada de su tina.
const POS_NAVE := Vector2(320, 224)
const POS_MASCOTA := Vector2(475, 225)
## Lo del fondo que en la habitación queda delante de una estación (la lámpara, los rollos, el letrero de piso mojado
## y la caja de herramientas). Se dibuja después de las estaciones, con la misma luz que el fondo.
## Cada id es el sprite hangar_delante_<id> y su rectángulo. Lo escribe el generador junto con hangar_fondo.
const DELANTE := {
	"lampara": Rect2(368, 26, 40, 47),
	"herramientas": Rect2(564, 286, 70, 38),
	"piso_mojado": Rect2(194, 242, 46, 65),
	"rollos": Rect2(107, 249, 33, 59),
}
