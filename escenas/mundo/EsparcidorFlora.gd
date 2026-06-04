extends MultiMeshInstance3D
## Esparce instancias con Poisson Disk Sampling: garantiza distancia minima
## entre ejemplares, evita solapamiento visual de arboles/arbustos.
## Ademas respeta una zona de exclusion a lo largo de un Path3D (camino organico).
##
## Para un arbol "tronco + copa" usa DOS nodos hermanos con la MISMA semilla/
## area/distancia_min/exclusion (quedan alineados) y distinto altura_offset.

@export var cantidad: int = 80
@export var area: Vector2 = Vector2(240, 240)   # X/Z en metros
@export var escala_min: float = 0.9
@export var escala_max: float = 1.3
@export var semilla: int = 1337
@export var distancia_min: float = 4.0          # Poisson: separacion minima entre instancias
@export var radio_excluido: float = 8.0         # radio libre alrededor del origen (spawn)
## Path3D opcional: ninguna instancia se coloca a menos de radio_camino metros del camino.
@export var camino: NodePath
@export var radio_camino: float = 6.0
## Desplazamiento vertical para alinear copa sobre tronco.
@export var altura_offset: float = 0.0
## Zona rectangular opcional donde no se instancia flora (centro y tamano en XZ global).
@export var zona_exclusion_centro: Vector2 = Vector2.ZERO
@export var zona_exclusion_tamano: Vector2 = Vector2.ZERO

var _puntos_camino: PackedVector2Array = []     # XZ precalculado del camino


func _ready() -> void:
	if multimesh == null:
		push_warning("EsparcidorFlora: falta MultiMesh en %s" % name)
		return
	if multimesh.mesh == null:
		push_warning("EsparcidorFlora: MultiMesh sin malla en %s" % name)
		return

	# Precalcular puntos del camino en XZ para chequeo de proximidad.
	if camino and not camino.is_empty():
		var nodo_camino: Node = get_node_or_null(camino)
		if nodo_camino is Path3D and (nodo_camino as Path3D).curve:
			var curve: Curve3D = (nodo_camino as Path3D).curve
			var n: int = 120
			for i in range(n + 1):
				var t: float = curve.get_baked_length() * i / float(n)
				var p: Vector3 = curve.sample_baked(t)
				_puntos_camino.append(Vector2(p.x, p.z))

	_poblar_poisson()


func _cerca_del_camino(xz: Vector2) -> bool:
	for p in _puntos_camino:
		if xz.distance_to(p) < radio_camino:
			return true
	return false


func _en_rect_exclusion(xz: Vector2) -> bool:
	if zona_exclusion_tamano.x <= 0.0 or zona_exclusion_tamano.y <= 0.0:
		return false
	var mitad := zona_exclusion_tamano * 0.5
	return (
		xz.x >= zona_exclusion_centro.x - mitad.x
		and xz.x <= zona_exclusion_centro.x + mitad.x
		and xz.y >= zona_exclusion_centro.y - mitad.y
		and xz.y <= zona_exclusion_centro.y + mitad.y
	)


func _poblar_poisson() -> void:
	## Cuando distancia_min <= 0, usa scatter aleatorio puro (O(n)) — necesario
	## para cantidades altas (>5000) donde Poisson O(n²) cuelga el juego.
	## Cuando distancia_min > 0, usa Poisson dart throwing con rechazo.
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla

	var aceptados: PackedVector2Array = []

	if distancia_min <= 0.0:
		# Scatter aleatorio: sin chequeo de vecinos, solo zonas de exclusion.
		var intentos := 0
		var max_intentos := cantidad * 8
		while aceptados.size() < cantidad and intentos < max_intentos:
			intentos += 1
			var px := rng.randf_range(-area.x * 0.5, area.x * 0.5)
			var pz := rng.randf_range(-area.y * 0.5, area.y * 0.5)
			var xz := Vector2(px, pz)
			if xz.length() < radio_excluido:
				continue
			if _cerca_del_camino(xz):
				continue
			if _en_rect_exclusion(xz):
				continue
			aceptados.append(xz)
	else:
		var max_intentos := cantidad * 40
		var intentos := 0
		while aceptados.size() < cantidad and intentos < max_intentos:
			intentos += 1
			var px := rng.randf_range(-area.x * 0.5, area.x * 0.5)
			var pz := rng.randf_range(-area.y * 0.5, area.y * 0.5)
			var xz := Vector2(px, pz)
			if xz.length() < radio_excluido:
				continue
			if _cerca_del_camino(xz):
				continue
			if _en_rect_exclusion(xz):
				continue
			var valido := true
			for a in aceptados:
				if xz.distance_to(a) < distancia_min:
					valido = false
					break
			if valido:
				aceptados.append(xz)

	# Colocar instancias en el MultiMesh.
	var n_real := aceptados.size()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = n_real

	for i in n_real:
		var pos := Vector3(aceptados[i].x, altura_offset, aceptados[i].y)
		var t := Transform3D(Basis(), pos)
		t = t.rotated_local(Vector3.UP, rng.randf_range(0.0, TAU))
		t = t.scaled_local(Vector3.ONE * rng.randf_range(escala_min, escala_max))
		multimesh.set_instance_transform(i, t)
