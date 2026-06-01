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
		var ai_base: AnimalIA = b as AnimalIA
		var orden_variantes: Array[int] = _orden_variantes_para_animal(rng, ai_base)
		if b.has_method("set"):
			b.set("variante", orden_variantes[0])
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
			var idx_variante: int = (i + 1) % 4
			copia.set("variante", orden_variantes[idx_variante])
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


func _orden_variantes(rng: RandomNumberGenerator) -> Array[int]:
	var orden: Array[int] = [0, 1, 2, 3]
	for i in range(orden.size() - 1, 0, -1):
		var j: int = int(rng.randi() % (i + 1))
		var tmp: int = orden[i]
		orden[i] = orden[j]
		orden[j] = tmp
	return orden


func _orden_variantes_para_animal(rng: RandomNumberGenerator, animal: AnimalIA) -> Array[int]:
	var orden: Array[int] = _orden_variantes(rng)
	if animal == null:
		return orden

	match animal.tipo_animal:
		AnimalIA.TipoAnimal.CABALLO:
			return _priorizar_variante(orden, 2)
		AnimalIA.TipoAnimal.POLLITO:
			return _orden_variantes_pollito(rng)

	return orden


func _priorizar_variante(orden: Array[int], objetivo: int) -> Array[int]:
	var idx: int = orden.find(objetivo)
	if idx <= 0:
		return orden
	var primero: int = orden[0]
	orden[0] = objetivo
	orden[idx] = primero
	return orden


func _orden_variantes_pollito(rng: RandomNumberGenerator) -> Array[int]:
	var opciones: Array[int] = [1, 2]
	for i in range(opciones.size() - 1, 0, -1):
		var j: int = int(rng.randi() % (i + 1))
		var tmp: int = opciones[i]
		opciones[i] = opciones[j]
		opciones[j] = tmp
	return [0, opciones[0], opciones[1], opciones[0]]
