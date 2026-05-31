extends MultiMeshInstance3D
## Esparce N instancias de una malla (tronco/copa/maleza) sobre la sabana en una
## sola draw call. Distribución procedural con semilla fija (reproducible) + jitter
## de rotación y escala. Para un árbol "tronco + copa" usa DOS nodos con la MISMA
## semilla/area/cantidad/radio_excluido (quedan alineados) y distinto altura_offset.

@export var cantidad: int = 300
@export var area: Vector2 = Vector2(120, 120)   # extensión X/Z en metros
@export var escala_min: float = 0.9
@export var escala_max: float = 1.3
@export var semilla: int = 1337
## Radio libre alrededor del origen (deja despejado el sendero/spawn).
@export var radio_excluido: float = 6.0
## Altura (Y) a la que se centra cada instancia. Sube la copa sobre el tronco.
@export var altura_offset: float = 0.0
## Opcional: extrae la malla del primer MeshInstance3D de esta escena (.glb) y la
## usa en el MultiMesh. Util para reusar assets .glb (pasto) sin .tres aparte.
@export var malla_desde_escena: PackedScene


func _ready() -> void:
	if multimesh == null:
		push_warning("EsparcidorFlora: falta el recurso MultiMesh en %s" % name)
		return
	if malla_desde_escena:
		var m := _extraer_malla(malla_desde_escena)
		if m:
			multimesh.mesh = m
	if multimesh.mesh == null:
		push_warning("EsparcidorFlora: MultiMesh sin malla en %s" % name)
		return
	_poblar()


func _extraer_malla(escena: PackedScene) -> Mesh:
	var inst := escena.instantiate()
	var malla: Mesh = null
	var pila: Array = [inst]
	while pila and malla == null:
		var n = pila.pop_back()
		if n is MeshInstance3D and n.mesh:
			malla = n.mesh
		for h in n.get_children():
			pila.append(h)
	inst.free()
	return malla


func _poblar() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla

	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = cantidad

	for i in cantidad:
		var pos := Vector3(
			rng.randf_range(-area.x * 0.5, area.x * 0.5),
			altura_offset,
			rng.randf_range(-area.y * 0.5, area.y * 0.5)
		)
		# Reintenta si cae dentro del radio despejado (sendero/spawn).
		var intentos := 0
		while Vector2(pos.x, pos.z).length() < radio_excluido and intentos < 8:
			pos.x = rng.randf_range(-area.x * 0.5, area.x * 0.5)
			pos.z = rng.randf_range(-area.y * 0.5, area.y * 0.5)
			intentos += 1

		var t := Transform3D(Basis(), pos)
		t = t.rotated_local(Vector3.UP, rng.randf_range(0.0, TAU))
		t = t.scaled_local(Vector3.ONE * rng.randf_range(escala_min, escala_max))
		multimesh.set_instance_transform(i, t)
