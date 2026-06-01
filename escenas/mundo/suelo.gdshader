shader_type spatial;
// Suelo sabana carabobena: gradiente radial verde-dorado + patron de cuadricula
// sutil para contraste de textura estilo CubeWorld. Sin franja recta de camino
// (el camino organico es visible por la ausencia de vegetacion + CaminoRocoso).
render_mode cull_back;

uniform vec3 verde_vivo : source_color = vec3(0.32, 0.52, 0.18);
uniform vec3 verde_seco : source_color = vec3(0.58, 0.58, 0.24);
uniform vec3 tierra_base : source_color = vec3(0.50, 0.40, 0.24);
uniform float radio_borde = 190.0;

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Gradiente radial verde -> seco
	float d = clamp(length(mundo.xz) / radio_borde, 0.0, 1.0);
	vec3 col = mix(verde_vivo, verde_seco, d * d);

	// Patron cuadricula 2x2m — da contraste CubeWorld sin gradientes
	float gx = floor(mundo.x * 0.5);
	float gz = floor(mundo.z * 0.5);
	float checker = mod(gx + gz, 2.0);
	col = mix(col, col * 0.84, checker * 0.28);

	// Variacion adicional en celdas 4x4m para romper monotonia
	float gx2 = floor(mundo.x * 0.25);
	float gz2 = floor(mundo.z * 0.25);
	float checker2 = mod(gx2 + gz2, 2.0);
	col = mix(col, col * 1.07, checker2 * 0.12);

	// Mezcla sutil de tierra en borde exterior muy seco
	col = mix(col, tierra_base, clamp((d - 0.75) * 2.5, 0.0, 0.4));

	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
