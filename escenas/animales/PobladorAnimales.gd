extends Node3D
## Duplica fauna base y reparte variantes por el mapa.

@export var semilla: int = 202606
@export var duplicados_por_base: int = 3
@export var area_spawn: Vector2 = Vector2(290, 290)
@export var radio_spawn_excluido: float = 16.0
@export var distancia_minima: float = 6.5


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = semilla

	var bases: Array[Node] = []
	for child in get_children():
		if child is AnimalIA:
			bases.append(child)

	if bases.is_empty():
		return

	var ocupados: Array[Vector2] = []
	for b in bases:
		var bb: Node3D = b as Node3D
		if bb != null:
			ocupados.append(Vector2(bb.global_position.x, bb.global_position.z))

	for b in bases:
		if b.has_method("set"):
			b.set("variante", int(rng.randi() % 4))
		for i in range(duplicados_por_base):
			var copia: Node = b.duplicate(Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)
			if copia == null:
				continue
			var c3d: Node3D = copia as Node3D
			if c3d == null:
				continue

			var p: Vector2 = _buscar_posicion(rng, ocupados)
			ocupados.append(p)
			c3d.global_position = Vector3(p.x, 0.0, p.y)
			c3d.rotation.y = rng.randf_range(0.0, TAU)
			copia.set("variante", int(rng.randi() % 4))
			add_child(copia)


func _buscar_posicion(rng: RandomNumberGenerator, ocupados: Array[Vector2]) -> Vector2:
	var intentos: int = 0
	while intentos < 120:
		intentos += 1
		var p: Vector2 = Vector2(
			rng.randf_range(-area_spawn.x * 0.5, area_spawn.x * 0.5),
			rng.randf_range(-area_spawn.y * 0.5, area_spawn.y * 0.5)
		)
		if p.length() < radio_spawn_excluido:
			continue
		var valido: bool = true
		for o in ocupados:
			if p.distance_to(o) < distancia_minima:
				valido = false
				break
		if valido:
			return p

	return Vector2(
		rng.randf_range(-area_spawn.x * 0.5, area_spawn.x * 0.5),
		rng.randf_range(-area_spawn.y * 0.5, area_spawn.y * 0.5)
	)
