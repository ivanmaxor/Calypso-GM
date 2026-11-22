class_name Asignaciones
extends RefCounted
## Reglas de las teclas: dos espacios de teclado/mouse y dos de mando por accion.
## No toca el motor, asi se puede probar sola (ver pruebas/correr_pruebas.gd).
##
## Una tecla se guarda como texto simple, por ejemplo "key:W", "mouse:2", "btn:0" o "axis:5:1".
## Guardar los eventos del motor directo no sirve: al cargarlos vuelven vacios.

const GRUPOS := ["teclado", "mando"]
const RANURAS := 2

## accion -> {"teclado": [a, b], "mando": [a, b]}
var mapa := {}


func _init(defecto := {}) -> void:
	mapa = defecto.duplicate(true)


func obtener(accion: String, grupo: String, ranura: int) -> String:
	return mapa[accion][grupo][ranura]


## Quien usa esta tecla. Devuelve {} si esta libre.
func buscar(grupo: String, tecla: String) -> Dictionary:
	if tecla == "":
		return {}
	for accion in mapa:
		for r in RANURAS:
			if mapa[accion][grupo][r] == tecla:
				return {"accion": accion, "ranura": r}
	return {}


## Intenta asignar. Si la tecla esta ocupada devuelve {"conflicto": {...}} y no cambia nada.
## Con modo "intercambiar" o "quitar" resuelve el conflicto.
func asignar(accion: String, grupo: String, ranura: int, tecla: String, modo := "") -> Dictionary:
	var otro := buscar(grupo, tecla)
	if otro.is_empty():
		mapa[accion][grupo][ranura] = tecla
		return {"ok": true}
	if otro.accion == accion and otro.ranura == ranura:
		return {"ok": true}
	if modo == "":
		return {"conflicto": otro}
	var mia: String = mapa[accion][grupo][ranura]
	if modo == "intercambiar":
		mapa[otro.accion][grupo][otro.ranura] = mia
		mapa[accion][grupo][ranura] = tecla
		return {"ok": true}
	if modo == "quitar":
		if otro.accion != accion and _cuantas(otro.accion, grupo) <= 1:
			return {"error": "sin_tecla", "accion": otro.accion}
		mapa[otro.accion][grupo][otro.ranura] = ""
		mapa[accion][grupo][ranura] = tecla
		return {"ok": true}
	return {"error": "modo"}


## Borra un espacio. Una accion nunca puede quedar sin ninguna tecla.
func borrar(accion: String, grupo: String, ranura: int) -> bool:
	if mapa[accion][grupo][ranura] == "":
		return true
	if _cuantas(accion, grupo) <= 1:
		return false
	mapa[accion][grupo][ranura] = ""
	return true


func _cuantas(accion: String, grupo: String) -> int:
	var n := 0
	for r in RANURAS:
		if mapa[accion][grupo][r] != "":
			n += 1
	return n


## Mezcla lo leido del archivo con los valores por defecto. Ignora lo que no entienda.
func cargar_desde(datos: Dictionary, defecto: Dictionary) -> void:
	mapa = defecto.duplicate(true)
	for accion in defecto:
		for grupo in GRUPOS:
			var clave: String = accion + "/" + grupo
			if not datos.has(clave):
				continue
			var v = datos[clave]
			if typeof(v) != TYPE_ARRAY and typeof(v) != TYPE_PACKED_STRING_ARRAY:
				continue
			if v.size() != RANURAS:
				continue
			var a := str(v[0])
			var b := str(v[1])
			if not (es_valida(a, grupo) and es_valida(b, grupo)):
				continue
			if a == "" and b == "":
				continue
			mapa[accion][grupo] = [a, b]
	_limpiar_duplicados(defecto)


func exportar() -> Dictionary:
	var d := {}
	for accion in mapa:
		for grupo in GRUPOS:
			d[accion + "/" + grupo] = mapa[accion][grupo].duplicate()
	return d


static func es_valida(tecla: String, grupo: String) -> bool:
	if tecla == "":
		return true
	if grupo == "teclado":
		return tecla.begins_with("key:") or tecla.begins_with("mouse:")
	return tecla.begins_with("btn:") or tecla.begins_with("axis:")


## Si un archivo editado a mano repite una tecla, gana la primera accion.
func _limpiar_duplicados(defecto: Dictionary) -> void:
	for grupo in GRUPOS:
		var vistas := {}
		for accion in mapa:
			for r in RANURAS:
				var t: String = mapa[accion][grupo][r]
				if t == "":
					continue
				if vistas.has(t):
					mapa[accion][grupo][r] = ""
				else:
					vistas[t] = true
		for accion in mapa:
			if _cuantas(accion, grupo) == 0:
				mapa[accion][grupo] = defecto[accion][grupo].duplicate()
