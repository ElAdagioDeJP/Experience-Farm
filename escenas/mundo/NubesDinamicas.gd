extends Node3D
## Sistema de nubes dinamicas. Nubes voxel flotan lentamente en el cielo.
## Spawn inicial fuera del frustum del jugador (radio alto) para evitar
## que el jugador vea bloques aparecer de la nada. GL Compatibility compatible.

@export var velocidad: Vector2 = Vector2(2.5, 0.4)
@export var altura_min: float = 55.0
@export var altura_max: float = 78.0
@export var radio_area: float = 200.0
@export var malla_nube: Mesh
@export var cantidad: int = 18
@export var escala_min: float = 1.5
@export var escala_max: float = 3.5

var _nubes: Array[MeshInstance3D] = []


func _ready() -> void:
	if malla_nube == null:
		push_warning("NubesDinamicas: malla_nube no asignada")
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 77331

	for i in cantidad:
		var nube := MeshInstance3D.new()
		nube.mesh = malla_nube
		nube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		# Spawn en el annulo exterior (70%-100% del radio) para evitar
		# que aparezcan dentro del campo de vision del jugador al inicio.
		var ang := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(radio_area * 0.70, radio_area)
		var x := cos(ang) * dist
		var z := sin(ang) * dist
		var y := rng.randf_range(altura_min, altura_max)
		var sc := rng.randf_range(escala_min, escala_max)

		nube.position = Vector3(x, y, z)
		nube.scale = Vector3(sc, sc * 0.55, sc)
		add_child(nube)
		_nubes.append(nube)


func _process(delta: float) -> void:
	for nube in _nubes:
		nube.position.x += velocidad.x * delta
		nube.position.z += velocidad.y * delta
		# Loop: al salir del borde, reaparecer en el lado opuesto con
		# posicion Y y Z aleatoria para variedad. Solo cambia el eje que salio.
		if nube.position.x > radio_area:
			nube.position.x = -radio_area
			nube.position.z = randf_range(-radio_area * 0.9, radio_area * 0.9)
		if nube.position.z > radio_area:
			nube.position.z = -radio_area
			nube.position.x = randf_range(-radio_area * 0.9, radio_area * 0.9)
