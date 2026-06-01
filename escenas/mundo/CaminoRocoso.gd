extends Node3D
## Genera visualmente el camino de tierra/piedra muestreando el Curve3D del Path3D
## y colocando instancias de tile_tierra via MultiMesh. Crea el camino "de dentro"
## sin necesidad de GridMap ni tiles manuales.

@export var camino: NodePath
@export var malla_tile: Mesh
@export var paso: float = 1.92          # separacion entre filas (= 16 vox * 0.12)
@export var filas: int = 2              # columnas a cada lado del eje (total 2*filas+1)
@export var escala_xy: float = 0.12     # escala horizontal por tile
@export var escala_y: float = 0.04     # escala vertical (tile plano, casi flush)


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
	rng.seed = 9812

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
			var offset: Vector3 = perp * (f * paso)
			var pos := Vector3(pa.x + offset.x, -0.05, pa.z + offset.z)
			var rot_y: float = rng.randf_range(-0.25, 0.25)
			var sx: float = escala_xy + rng.randf_range(-0.01, 0.02)
			var b := Basis().rotated(Vector3.UP, rot_y)
			b = b.scaled(Vector3(sx, escala_y, sx))
			transforms.append(Transform3D(b, pos))
		t += paso

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
