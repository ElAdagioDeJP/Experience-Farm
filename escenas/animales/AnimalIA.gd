extends CharacterBody3D
class_name AnimalIA
## IA basica estilo sandbox: deambula cerca de su origen y huye del jugador
## cuando este se acerca demasiado.

enum TipoAnimal {
	VACA,
	TORO,
	CABALLO,
	CERDO,
	GALLINA,
	GALLO,
	POLLITO,
}

@export var tipo_animal: TipoAnimal = TipoAnimal.VACA
@export var velocidad_caminar: float = 1.25
@export var aceleracion: float = 4.5
@export var gravedad: float = 18.0
@export var snap_suelo: float = 0.35
@export var radio_vagabundeo: float = 8.0
@export var radio_huida: float = 8.5
@export var distancia_objetivo: float = 0.8
@export var espera_min: float = 1.2
@export var espera_max: float = 3.4
@export var velocidad_giro: float = 7.0
@export var intensidad_animacion: float = 1.0
@export var usar_offset_yaw_manual: bool = false
@export var yaw_modelo_grados: float = 0.0
@export_range(0, 3, 1) var variante: int = 0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _origen: Vector3 = Vector3.ZERO
var _objetivo: Vector3 = Vector3.ZERO
var _espera_restante: float = 0.0
var _jugador: Node3D
var _tiempo_anim: float = 0.0
var _fase_anim: float = 0.0

var _esqueleto: Node3D
var _modelo: Node3D
var _hueso_cadera: Node3D
var _hueso_torso: Node3D
var _hueso_cabeza: Node3D
var _hueso_cola: Node3D

var _base_cadera_pos: Vector3 = Vector3.ZERO
var _base_torso_pos: Vector3 = Vector3.ZERO
var _base_cabeza_pos: Vector3 = Vector3.ZERO
var _base_cola_pos: Vector3 = Vector3.ZERO

var _base_cadera_rot: Vector3 = Vector3.ZERO
var _base_torso_rot: Vector3 = Vector3.ZERO
var _base_cabeza_rot: Vector3 = Vector3.ZERO
var _base_cola_rot: Vector3 = Vector3.ZERO
var _yaw_modelo_offset: float = 0.0


func _ready() -> void:
	_rng.seed = int(get_instance_id()) * 3571
	_origen = global_position
	floor_snap_length = snap_suelo
	_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
	_fase_anim = _rng.randf_range(0.0, TAU)
	_preparar_esqueleto()
	_seleccionar_objetivo_aleatorio()
	_espera_restante = _rng.randf_range(espera_min, espera_max)


func _physics_process(delta: float) -> void:
	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D

	if not is_on_floor():
		velocity.y -= gravedad * delta
	else:
		velocity.y = 0.0

	_actualizar_objetivo_por_jugador()
	_actualizar_movimiento(delta)
	_animar_esqueleto(delta)
	move_and_slide()


func _actualizar_objetivo_por_jugador() -> void:
	if _jugador == null:
		return
	var delta_jugador: Vector3 = global_position - _jugador.global_position
	var distancia_plana: float = Vector2(delta_jugador.x, delta_jugador.z).length()
	if distancia_plana >= radio_huida or distancia_plana <= 0.001:
		return

	var direccion_huida: Vector3 = Vector3(delta_jugador.x, 0.0, delta_jugador.z).normalized()
	var salto_huida: float = radio_vagabundeo * 0.7
	_objetivo = _limitar_en_radio(_origen + direccion_huida * salto_huida)
	_espera_restante = 0.0


func _actualizar_movimiento(delta: float) -> void:
	if _espera_restante > 0.0:
		_espera_restante -= delta
		velocity.x = move_toward(velocity.x, 0.0, aceleracion * delta)
		velocity.z = move_toward(velocity.z, 0.0, aceleracion * delta)
		if _espera_restante <= 0.0:
			_seleccionar_objetivo_aleatorio()
		return

	var hacia: Vector3 = _objetivo - global_position
	var plano: Vector3 = Vector3(hacia.x, 0.0, hacia.z)
	var distancia: float = plano.length()

	if distancia <= distancia_objetivo:
		_espera_restante = _rng.randf_range(espera_min, espera_max)
		velocity.x = move_toward(velocity.x, 0.0, aceleracion * delta)
		velocity.z = move_toward(velocity.z, 0.0, aceleracion * delta)
		return

	var direccion: Vector3 = plano / distancia
	var yaw_deseado: float = _yaw_objetivo_desde_direccion(direccion)
	rotation.y = lerp_angle(rotation.y, yaw_deseado, min(1.0, velocidad_giro * delta))
	var delta_yaw: float = abs(wrapf(yaw_deseado - rotation.y, -PI, PI))
	var factor_alineacion: float = clamp(1.0 - (delta_yaw / deg_to_rad(95.0)), 0.05, 1.0)
	var frente: Vector3 = -global_transform.basis.z
	frente.y = 0.0
	if frente.length() > 0.0001:
		frente = frente.normalized()
	else:
		frente = direccion
	var objetivo_velocidad: Vector3 = frente * velocidad_caminar * factor_alineacion
	velocity.x = move_toward(velocity.x, objetivo_velocidad.x, aceleracion * delta)
	velocity.z = move_toward(velocity.z, objetivo_velocidad.z, aceleracion * delta)


func _seleccionar_objetivo_aleatorio() -> void:
	var angulo: float = _rng.randf_range(0.0, TAU)
	var distancia: float = _rng.randf_range(radio_vagabundeo * 0.25, radio_vagabundeo)
	var desplazamiento: Vector3 = Vector3(cos(angulo) * distancia, 0.0, sin(angulo) * distancia)
	_objetivo = _limitar_en_radio(_origen + desplazamiento)


func _limitar_en_radio(punto: Vector3) -> Vector3:
	var delta_origen: Vector3 = punto - _origen
	var plano: Vector2 = Vector2(delta_origen.x, delta_origen.z)
	if plano.length() <= radio_vagabundeo:
		return punto
	var dir: Vector2 = plano.normalized() * radio_vagabundeo
	return Vector3(_origen.x + dir.x, punto.y, _origen.z + dir.y)


func _preparar_esqueleto() -> void:
	_esqueleto = get_node_or_null("Esqueleto") as Node3D
	if _esqueleto == null:
		return

	_modelo = _esqueleto.get_node_or_null("Modelo") as Node3D
	_hueso_cadera = _asegurar_hueso(_esqueleto, "Cadera")
	_hueso_torso = _asegurar_hueso(_hueso_cadera, "Torso")
	_hueso_cabeza = _asegurar_hueso(_hueso_torso, "Cabeza")
	_hueso_cola = _asegurar_hueso(_hueso_cadera, "Cola")

	_aplicar_offsets_por_tipo()

	if _modelo != null and _modelo.get_parent() != _hueso_torso:
		var base_transform: Transform3D = _modelo.transform
		var owner: Node = _modelo.owner
		var parent_actual: Node = _modelo.get_parent()
		if parent_actual != null:
			parent_actual.remove_child(_modelo)
		_hueso_torso.add_child(_modelo)
		_modelo.owner = owner
		_modelo.transform = base_transform

	_aplicar_malla_variante()

	_base_cadera_pos = _hueso_cadera.position
	_base_torso_pos = _hueso_torso.position
	_base_cabeza_pos = _hueso_cabeza.position
	_base_cola_pos = _hueso_cola.position

	_base_cadera_rot = _hueso_cadera.rotation
	_base_torso_rot = _hueso_torso.rotation
	_base_cabeza_rot = _hueso_cabeza.rotation
	_base_cola_rot = _hueso_cola.rotation
	_yaw_modelo_offset = _calcular_yaw_modelo_offset()
 


func _asegurar_hueso(parent: Node3D, nombre: String) -> Node3D:
	var nodo: Node3D = parent.get_node_or_null(nombre) as Node3D
	if nodo != null:
		return nodo
	nodo = Node3D.new()
	nodo.name = nombre
	parent.add_child(nodo)
	nodo.owner = owner
	return nodo


func _aplicar_offsets_por_tipo() -> void:
	if _hueso_cabeza == null or _hueso_cola == null:
		return

	match tipo_animal:
		TipoAnimal.VACA:
			_hueso_cabeza.position = Vector3(0.0, 0.32, -0.42)
			_hueso_cola.position = Vector3(0.0, 0.24, 0.44)
		TipoAnimal.TORO:
			_hueso_cabeza.position = Vector3(0.0, 0.36, -0.48)
			_hueso_cola.position = Vector3(0.0, 0.26, 0.46)
		TipoAnimal.CABALLO:
			_hueso_cabeza.position = Vector3(0.0, 0.44, -0.52)
			_hueso_cola.position = Vector3(0.0, 0.34, 0.50)
		TipoAnimal.CERDO:
			_hueso_cabeza.position = Vector3(0.0, 0.22, -0.30)
			_hueso_cola.position = Vector3(0.0, 0.18, 0.32)
		TipoAnimal.GALLINA:
			_hueso_cabeza.position = Vector3(0.0, 0.20, -0.24)
			_hueso_cola.position = Vector3(0.0, 0.15, 0.24)
		TipoAnimal.GALLO:
			_hueso_cabeza.position = Vector3(0.0, 0.23, -0.25)
			_hueso_cola.position = Vector3(0.0, 0.20, 0.26)
		TipoAnimal.POLLITO:
			_hueso_cabeza.position = Vector3(0.0, 0.16, -0.20)
			_hueso_cola.position = Vector3(0.0, 0.11, 0.18)


func _animar_esqueleto(delta: float) -> void:
	if _hueso_cadera == null:
		return

	var v_plana: float = Vector2(velocity.x, velocity.z).length()
	var move_ratio: float = clamp(v_plana / max(velocidad_caminar, 0.01), 0.0, 1.5)
	var freq: float = lerp(1.6, 5.2, clamp(move_ratio, 0.0, 1.0))
	_tiempo_anim += delta * freq

	var perfil: Dictionary = _perfil_animacion()
	var fase: float = _tiempo_anim + _fase_anim
	var onda: float = sin(fase)
	var onda2: float = sin(fase * 2.0)
	var idle: float = 1.0 - clamp(move_ratio, 0.0, 1.0)

	var bob: float = float(perfil["bob"]) * (0.35 + move_ratio * 0.65) * intensidad_animacion
	var inclinacion: float = float(perfil["inclinacion"]) * move_ratio * intensidad_animacion
	var cuello: float = float(perfil["cuello"]) * (0.2 + move_ratio * 0.8) * intensidad_animacion
	var cola: float = float(perfil["cola"]) * (0.4 + move_ratio * 0.6) * intensidad_animacion
	var respira: float = float(perfil["respira"]) * idle * intensidad_animacion

	_hueso_cadera.position = _base_cadera_pos + Vector3(0.0, bob * abs(onda), 0.0)
	_hueso_cadera.rotation = _base_cadera_rot + Vector3(inclinacion * onda, 0.0, 0.0)

	_hueso_torso.position = _base_torso_pos + Vector3(0.0, bob * 0.28 * abs(onda2), 0.0)
	_hueso_torso.rotation = _base_torso_rot + Vector3(-inclinacion * 0.62 * onda, 0.0, 0.0)

	_hueso_cabeza.position = _base_cabeza_pos + Vector3(0.0, respira * onda2, 0.0)
	_hueso_cabeza.rotation = _base_cabeza_rot + Vector3(cuello * onda, cuello * 0.45 * sin(fase * 0.5), 0.0)

	_hueso_cola.position = _base_cola_pos
	_hueso_cola.rotation = _base_cola_rot + Vector3(0.0, cola * sin(fase * 1.7), 0.0)


func _perfil_animacion() -> Dictionary:
	match tipo_animal:
		TipoAnimal.VACA:
			return {"bob": 0.07, "inclinacion": 0.14, "cuello": 0.11, "cola": 0.20, "respira": 0.02}
		TipoAnimal.TORO:
			return {"bob": 0.075, "inclinacion": 0.16, "cuello": 0.13, "cola": 0.22, "respira": 0.018}
		TipoAnimal.CABALLO:
			return {"bob": 0.09, "inclinacion": 0.18, "cuello": 0.17, "cola": 0.26, "respira": 0.018}
		TipoAnimal.CERDO:
			return {"bob": 0.06, "inclinacion": 0.12, "cuello": 0.08, "cola": 0.18, "respira": 0.02}
		TipoAnimal.GALLINA:
			return {"bob": 0.11, "inclinacion": 0.22, "cuello": 0.24, "cola": 0.28, "respira": 0.03}
		TipoAnimal.GALLO:
			return {"bob": 0.12, "inclinacion": 0.24, "cuello": 0.27, "cola": 0.30, "respira": 0.03}
		TipoAnimal.POLLITO:
			return {"bob": 0.14, "inclinacion": 0.29, "cuello": 0.34, "cola": 0.32, "respira": 0.04}
	return {"bob": 0.07, "inclinacion": 0.12, "cuello": 0.10, "cola": 0.20, "respira": 0.02}


func _yaw_objetivo_desde_direccion(dir: Vector3) -> float:
	var d: Vector3 = Vector3(dir.x, 0.0, dir.z)
	if d.length() <= 0.0001:
		return rotation.y
	d = d.normalized()
	return atan2(-d.x, -d.z) - _yaw_modelo_offset


func _calcular_yaw_modelo_offset() -> float:
	if usar_offset_yaw_manual:
		return deg_to_rad(yaw_modelo_grados)
	if _modelo == null:
		return 0.0
	var frente_local: Vector3 = _modelo.transform.basis * Vector3.FORWARD
	frente_local.y = 0.0
	if frente_local.length() <= 0.0001:
		return 0.0
	frente_local = frente_local.normalized()
	return atan2(-frente_local.x, -frente_local.z)


func _aplicar_malla_variante() -> void:
	if not (_modelo is MeshInstance3D):
		return
	var mi: MeshInstance3D = _modelo as MeshInstance3D
	var ruta: String = _ruta_malla_variante()
	if ruta.is_empty():
		return
	var malla: Mesh = load(ruta) as Mesh
	if malla != null:
		mi.mesh = malla


func _ruta_malla_variante() -> String:
	var idx: int = clamp(variante, 0, 3) + 1
	match tipo_animal:
		TipoAnimal.VACA:
			return "res://assets/models/variantes/vaca_v%d.obj" % idx
		TipoAnimal.TORO:
			return "res://assets/models/variantes/toro_v%d.obj" % idx
		TipoAnimal.CABALLO:
			return "res://assets/models/variantes/caballo_v%d.obj" % idx
		TipoAnimal.CERDO:
			return "res://assets/models/variantes/cerdo_v%d.obj" % idx
		TipoAnimal.GALLINA:
			return "res://assets/models/variantes/gallina_v%d.obj" % idx
		TipoAnimal.GALLO:
			return "res://assets/models/variantes/gallo_v%d.obj" % idx
		TipoAnimal.POLLITO:
			return "res://assets/models/variantes/pollito_v%d.obj" % idx
	return ""
