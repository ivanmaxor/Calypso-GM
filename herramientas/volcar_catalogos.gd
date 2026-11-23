extends SceneTree
## Vuelca los catálogos del juego a un JSON, para generar memorias/inventario.md sin copiar números a mano.
## Uso (desde la carpeta juego/):
##   <godot> --headless --path . --script ../herramientas/volcar_catalogos.gd -- <salida.json> --pruebas --guardado=volcado
## OJO: --pruebas --guardado=volcado es obligatorio. Con --script Godot igual carga los autoloads, y sin esos argumentos
## Partida y Ajustes leen y REESCRIBEN las partidas reales de user:// (incluida la conversión automática de una partida antigua).
## Después: python herramientas/inventario.py <salida.json> memorias/inventario.md


func _a_json(v):
	match typeof(v):
		TYPE_DICTIONARY:
			var r := {}
			for k in v:
				r[str(k)] = _a_json(v[k])
			return r
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_INT32_ARRAY:
			var r := []
			for x in v:
				r.append(_a_json(x))
			return r
		TYPE_COLOR:
			return "#" + v.to_html(false)
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return [v.x, v.y]
		TYPE_RECT2:
			return [v.position.x, v.position.y, v.size.x, v.size.y]
		TYPE_STRING_NAME:
			return str(v)
		_:
			return v


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var salida: String = args[0] if args.size() > 0 else "catalogos.json"
	var d := {
		"armas": CatalogoArmas.armas(),
		"habilidades": CatalogoArmas.habilidades(),
		"enemigos": CatalogoNiveles.enemigos(),
		"mundos": CatalogoNiveles.mundos(),
		"niveles": CatalogoNiveles.niveles(),
		"rarezas": CatalogoProgreso.rarezas(),
		"dificultades": CatalogoProgreso.dificultades(),
		"mejora_por_nivel": CatalogoProgreso.MEJORA_POR_NIVEL,
		"naves": CatalogoProgreso.naves(),
		"mascotas": CatalogoProgreso.mascotas(),
		"items": CatalogoProgreso.items(),
		"base_por_mundo": CatalogoProgreso.base_por_mundo(),
		"desafios": CatalogoProgreso.desafios(),
	}
	var f := FileAccess.open(salida, FileAccess.WRITE)
	f.store_string(JSON.stringify(_a_json(d), "  ", false))
	f.close()
	print("catalogos volcados en ", salida)
	quit()
