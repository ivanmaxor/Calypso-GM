shader_type canvas_item;
// La nave se dibuja con colores clave: solo rojo = casco, solo verde = franja, solo azul = llama.
// Asi la pintura y las rarezas del equipo la cambian sin tener que dibujarla otra vez.
uniform vec4 casco[5];
uniform vec4 franja[5];
uniform vec4 llama[4];
uniform float blanco = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a > 0.5) {
		float r = c.r * 255.0;
		float g = c.g * 255.0;
		float b = c.b * 255.0;
		if (g < 2.0 && b < 2.0 && r >= 30.0) {
			c = casco[clamp(int(round(r / 40.0)) - 1, 0, 4)];
		} else if (r < 2.0 && b < 2.0 && g >= 30.0) {
			c = franja[clamp(int(round(g / 40.0)) - 1, 0, 4)];
		} else if (r < 2.0 && g < 2.0 && b >= 30.0) {
			c = llama[clamp(int(round(b / 40.0)) - 1, 0, 3)];
		}
		c.rgb = mix(c.rgb, vec3(1.0), blanco);
	}
	COLOR = c;
}
