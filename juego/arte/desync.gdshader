shader_type canvas_item;
// El mundo durante el Desync: pierde el color y las filas se corren, como una conexion mala.
uniform sampler2D pantalla : hint_screen_texture, filter_nearest;
uniform float tiempo = 0.0;
uniform float fuerza = 1.0;
uniform float glitch = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float fila = floor(uv.y * 120.0);
	float r = fract(sin(fila * 12.9898 + floor(tiempo * 14.0) * 78.233) * 43758.5453);
	if (r > 0.94) {
		uv.x += (r - 0.97) * 0.22 * glitch;
	}
	vec3 c = texture(pantalla, uv).rgb;
	float lum = dot(c, vec3(0.3, 0.59, 0.11));
	vec3 o = vec3(0.024, 0.07, 0.12);
	vec3 m = vec3(0.08, 0.31, 0.435);
	vec3 cl = vec3(0.72, 0.957, 1.0);
	vec3 d = lum < 0.45 ? mix(o, m, lum / 0.45) : mix(m, cl, (lum - 0.45) / 0.55);
	d = floor(d * 18.0) / 18.0;
	COLOR = vec4(mix(c, d, fuerza), 1.0);
}
