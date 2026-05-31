shader_type spatial;
// Suelo de sabana: gradiente radial de verde (centro/granja) a verde-dorado
// seco (bordes), con un camino de tierra integrado a lo largo de X~0.
// Lit normal (recibe sol y sombras) pero con colores planos estilo CubeWorld.
render_mode cull_back;

uniform vec3 verde_centro : source_color = vec3(0.40, 0.54, 0.22);
uniform vec3 verde_borde : source_color = vec3(0.66, 0.62, 0.30);
uniform vec3 color_camino : source_color = vec3(0.62, 0.50, 0.32);
uniform float radio_borde = 200.0;
uniform float camino_ancho = 4.5;
uniform float camino_z_min = -130.0;
uniform float camino_z_max = 125.0;

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = clamp(length(mundo.xz) / radio_borde, 0.0, 1.0);
	vec3 col = mix(verde_centro, verde_borde, d);
	// Camino de tierra batida hacia la cabaña.
	float borde = smoothstep(camino_ancho + 1.0, camino_ancho - 1.0, abs(mundo.x));
	if (mundo.z > camino_z_min && mundo.z < camino_z_max) {
		col = mix(col, color_camino, borde);
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
