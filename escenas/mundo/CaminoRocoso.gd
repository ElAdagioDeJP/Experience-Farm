extends Node3D
## Genera el camino de piedra organico muestreando el Curve3D.
## Coloca losas de piedra irregulares (piedra_losa.vox) con rotacion y escala
## variables para imitar un empedrado natural de tierra, no una cuadricula.

@export var camino: NodePath
@export var malla_tile: Mesh
@export var paso: float = 1.4            # distancia base entre losas (metros)
@export var filas: int = 2               # losas a cada lado del eje
@export var escala_xy: float = 0.09      # escala horizontal
@export var escala_y: float = 0.055      # escala vertical (losa plana)
@export var probabilidad: float = 0.72   # prob de colocar cada losa (saltos naturales)


func _ready() -> void:
	if malla_tile == null:
		push_warning("CaminoRocoso: malla_tile sin asignar")
		return
	var np: Node = get_node_or_null(camino)
	if not (np is Path3D) or (np as Path3D).curve == null:
		push_warning("CaminoRocoso: Path3D no encontrado")
		return

	var curve: Curve3D = (np as Path3D).curve
	var largo: float = curve.get_baked_length()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4471

	var transforms: Array[Transform3D] = []
	var t: float = 0.0

	while t <= largo:
		var pa: Vector3 = curve.sample_baked(t)
		var pb: Vector3 = curve.sample_baked(minf(t + 0.5, largo))
		var tang: Vector3 = pb - pa
		if tang.length_squared() > 0.0001:
			tang = tang.normalized()
		else:
			tang = Vector3(0.0, 0.0, -1.0)
		var perp: Vector3 = tang.cross(Vector3.UP)
		if perp.length_squared() < 0.0001:
			perp = Vector3.RIGHT
		else:
			perp = perp.normalized()

		for f in range(-filas, filas + 1):
			# Omitir aleatoriamente para huecos naturales en el empedrado
			if rng.randf() > probabilidad:
				continue

			# Offset perpendicular con jitter para aspecto organico
			var jitter_perp: float = rng.randf_range(-0.5, 0.5)
			var jitter_tang: float = rng.randf_range(-0.4, 0.4)
			var offset: Vector3 = perp * (f * paso + jitter_perp) + tang * jitter_tang
			var pos := Vector3(pa.x + offset.x, -0.04, pa.z + offset.z)

			# Rotacion libre: stepping stones giran cualquier angulo
			var rot_y: float = rng.randf_range(0.0, TAU)
			# Escala variable: mezcla de losas grandes y chicas
			var sc_factor: float = rng.randf_range(0.65, 1.35)
			var sx: float = escala_xy * sc_factor
			var sy: float = escala_y

			var b := Basis().rotated(Vector3.UP, rot_y)
			b = b.scaled(Vector3(sx, sy, sx))
			transforms.append(Transform3D(b, pos))

		t += paso + rng.randf_range(-0.2, 0.3)  # paso variable: empedrado irregular

	var mm := MultiMesh.new()
	mm.mesh = malla_tile
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
