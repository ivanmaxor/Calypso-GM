class_name PanelNave
extends Control
## La columna izquierda del mapa y del Hangar: tu nave siempre a la vista.

const ANCHO := 150

var nave: Sprite2D
var mat: ShaderMaterial
var t := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(ANCHO, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	nave = Sprite2D.new()
	nave.region_enabled = true
	nave.scale = Vector2(2, 2)
	mat = ShaderMaterial.new()
	mat.shader = load("res://arte/nave.gdshader")
	nave.material = mat
	nave.position = Vector2(ANCHO / 2.0, 66)
	add_child(nave)
	refrescar()


func refrescar() -> void:
	var id: String = Partida.nave_actual()
	nave.texture = Datos.tex("nave2_" + id)
	Partida.preparar_material(mat, id)
	queue_redraw()


func _process(d: float) -> void:
	t += d
	var fr := int(t * 8.0) % 2
	nave.region_rect = Rect2((4 + fr) * 48, 0, 48, 48)
	nave.position.y = round(64.0 + sin(t * 1.6) * 3.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, ANCHO, 360), UI.C_FONDO)
	draw_line(Vector2(ANCHO - 0.5, 0), Vector2(ANCHO - 0.5, 360), UI.C_LINEA, 1.0)
	UI.marco(self, Rect2(5, 5, ANCHO - 10, 112), Color("15112a"), UI.C_LINEA)
	var pet := Partida.mascota_activa()
	if pet != "":
		var tam := Partida.tam_mascota(pet)
		var f := int(t * 7.0) % 4
		var y := roundf(100.0 - tam / 2.0 + sin(t * 2.3) * 2.0)
		draw_texture_rect_region(Datos.tex_mascota(pet, Partida.forma_mascota(pet)), Rect2(ANCHO - tam - 9, y, tam, tam), Rect2(f * tam, 0, tam, tam))
	var id: String = Partida.nave_actual()
	var def: Dictionary = Datos.NAVES[id]
	UI.tc(self, ANCHO / 2.0, 118, def.nombre, UI.C_ORO)
	draw_texture_rect(Datos.tex("icono_" + def.arma), Rect2(7, 134, 16, 16), false)
	UI.t(self, 26, 133, Datos.ARMAS[def.arma].nombre, UI.C_TEXTO)
	var s := Partida.stats_nave()
	UI.t(self, 7, 150, "Ataque", UI.C_GRIS)
	var at := str(int(s.atk * s.dano))
	UI.t(self, ANCHO - 8 - UI.ancho(at), 150, at, UI.C_TEXTO)
	UI.t(self, 7, 164, "Vida", UI.C_GRIS)
	var vi := str(int(s.hp))
	UI.t(self, ANCHO - 8 - UI.ancho(vi), 164, vi, UI.C_TEXTO)
	draw_line(Vector2(6, 181), Vector2(ANCHO - 7, 181), UI.C_LINEA, 1.0)
	draw_texture(Datos.tex("obj_tuerca"), Vector2(7, 186))
	UI.t(self, 22, 182, "Chatarra", UI.C_GRIS)
	var ch := str(int(Partida.d.chatarra))
	UI.t(self, ANCHO - 8 - UI.ancho(ch), 182, ch, UI.C_TEXTO)
	draw_texture(Datos.tex("ui_estrella"), Vector2(6, 199))
	UI.t(self, 22, 196, "Estrellas", UI.C_GRIS)
	var es := "%d/%d" % [Partida.estrellas_totales(), Datos.ORDEN_NIVELES.size() * 3]
	UI.t(self, ANCHO - 8 - UI.ancho(es), 196, es, UI.C_TEXTO)
