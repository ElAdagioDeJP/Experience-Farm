extends CharacterBody3D
## Controlador en primera persona para el walking simulator.
## Nodo raíz: CharacterBody3D. Estructura esperada:
##   Jugador (CharacterBody3D)  -> este script
##     CollisionShape3D         -> CapsuleShape3D (altura ~1.8, radio ~0.3)
##     PivoteCamara (Node3D)     -> pivote de cabeceo (pitch), a la altura de los ojos (~1.6)
##       Camara (Camera3D)

# --- Parámetros ajustables desde el Inspector ---
@export var velocidad: float = 4.0            # m/s en el plano horizontal
@export var sensibilidad_mouse: float = 0.0025 # radianes por píxel de movimiento del mouse
@export var gravedad: float = 18.0            # caída; mantiene al jugador pegado al GridMap
@export var limite_pitch_grados: float = 89.0 # tope vertical de cámara (evita voltearse de cabeza)

# Pivote que rota SOLO en X (cabeceo). La rotación horizontal (yaw) se aplica al cuerpo.
@onready var pivote_camara: Node3D = $PivoteCamara


func _ready() -> void:
	# Capturar y ocultar el cursor al iniciar la escena: el mouse pasa a controlar la cámara.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# Rotación de cámara con el mouse. Solo procesa cuando el cursor está capturado.
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw (360° libre): rotar el cuerpo entero sobre su eje Y.
		rotate_y(-event.relative.x * sensibilidad_mouse)
		# Pitch (arriba/abajo): rotar el pivote sobre X.
		pivote_camara.rotate_x(-event.relative.y * sensibilidad_mouse)
		# Clamp del pitch para que la cámara no se voltee de cabeza.
		var tope: float = deg_to_rad(limite_pitch_grados)
		pivote_camara.rotation.x = clamp(pivote_camara.rotation.x, -tope, tope)

	# Liberar el cursor con Escape (útil para depurar / salir del foco).
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Re-capturar al hacer clic dentro de la ventana.
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	# Gravedad: acumula caída mientras no esté en el suelo.
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# Entrada WASD normalizada en [-1,1] por eje. Acciones definidas en Project Settings > Input Map.
	var entrada: Vector2 = Input.get_vector(
		"mover_izquierda", "mover_derecha", "mover_adelante", "mover_atras"
	)
	# Convertir la entrada local a dirección global usando la orientación del cuerpo (basis).
	# entrada.y mapea al eje Z local (adelante = -Z), entrada.x al eje X local.
	var direccion: Vector3 = (transform.basis * Vector3(entrada.x, 0.0, entrada.y)).normalized()

	if direccion:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
	else:
		# Sin entrada: frenado suave hasta 0 (sin patinar).
		velocity.x = move_toward(velocity.x, 0.0, velocidad)
		velocity.z = move_toward(velocity.z, 0.0, velocidad)

	# Mueve y resuelve colisiones contra suelo, cercas y árboles (StaticBody3D del GridMap/escenas).
	move_and_slide()
