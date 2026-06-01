extends Node3D
## Sistema de nubes dinamicas: mueve N instancias de MeshInstance3D (nubes voxel)
## lentamente por el cielo. Cuando una nube sale del borde visible, reaparece
## en el lado opuesto (loop continuo). GL Compatibility compatible.

@export var velocidad: Vector2 = Vector2(3.0, 0.5)   # m/s en X y Z
@export var altura_min: float = 55.0
@export var altura_max: float = 80.0
@export var radio_area: float = 200.0      # nubes distribuidas en circulo de este radio
@export var malla_nube: Mesh               # asignar nube.obj como ArrayMesh
@export var cantidad: int = 18
@export var escala_min: float = 1.2
@export var escala_max: float = 3.0

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
		# Material propio sin sombras (nubes no castean sombra en GL Compatibility)
		nube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var ang := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(radio_area * 0.2, radio_area)
		var x := cos(ang) * dist
		var z := sin(ang) * dist
		var y := rng.randf_range(altura_min, altura_max)
		var sc := rng.randf_range(escala_min, escala_max)

		nube.position = Vector3(x, y, z)
		nube.scale = Vector3(sc, sc * 0.6, sc)
		add_child(nube)
		_nubes.append(nube)


func _process(delta: float) -> void:
	for nube in _nubes:
		nube.position.x += velocidad.x * delta
		nube.position.z += velocidad.y * delta
		# Loop: si sale del area, vuelve por el lado opuesto
		if nube.position.x > radio_area:
			nube.position.x = -radio_area
		if nube.position.z > radio_area:
			nube.position.z = -radio_area
