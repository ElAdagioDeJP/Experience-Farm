extends Area3D

@export var music_stream: AudioStream
@export var ambient_stream: AudioStream
@export var inicio_radio_distancia: float = 72.0
@export var radio_pleno_distancia: float = 8.0
@export var volumen_lejano_db: float = -40.0
@export var volumen_cercano_db: float = -6.0
@export var radio_rot_z_base: float = 0.0
@export var atenuacion_musica_ambiente_db: float = 14.0
@export var playlist_paths: PackedStringArray = [
	"res://music/radio/CABALLO VIEJO - SIMON DIAZ.mp3",
	"res://music/radio/Compadre Gerardo Brito (Remastered).mp3",
	"res://music/radio/De Oriente Al Llano.mp3",
	"res://music/radio/El Gran Varon.mp3",
	"res://music/radio/Juanito Alimaña - Héctor Lavoe.mp3",
	"res://music/radio/La Muerte del Rucio Moro   Reynaldo Armas letra.mp3",
	"res://music/radio/Llanerísimas.mp3",
	"res://music/radio/Lucerito.mp3",
	"res://music/radio/Mujer déjate querer.mp3",
	"res://music/radio/No Me Corra Cantinero - Vitico Castillo (Letra).mp3",
	"res://music/radio/Santiago Rojas  - La Viuda Millonaria  Video Lyric.mp3"
]

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var musica_ambiente: AudioStreamPlayer = get_node_or_null("../../../Atmosfera/MusicaAmbiente") as AudioStreamPlayer

var player_node: Node3D
var radio_encendida: bool = false
var antenna_tween: Tween
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _playlist: Array[AudioStream] = []
var _idx_actual: int = -1
var _volumen_ambiente_base_db: float = -9.5


func _ready() -> void:
	_rng.randomize()
	_cargar_playlist()
	audio_player.volume_db = -80.0
	audio_player.max_distance = maxf(inicio_radio_distancia + 8.0, 20.0)
	audio_player.unit_size = 3.0
	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	audio_player.bus = "Music"
	audio_player.max_polyphony = 1
	audio_player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	audio_player.finished.connect(_on_track_finished)
	if musica_ambiente != null:
		_volumen_ambiente_base_db = musica_ambiente.volume_db
	player_node = _buscar_jugador()


func _process(_delta: float) -> void:
	if player_node == null:
		player_node = _buscar_jugador()
		return

	var dist: float = global_position.distance_to(player_node.global_position)
	if dist > inicio_radio_distancia:
		if radio_encendida:
			apagar_radio()
		_actualizar_musica_ambiente(0.0)
		return

	if not radio_encendida:
		encender_radio()

	audio_player.volume_db = _volumen_por_distancia(dist)
	var t_radio: float = clampf(inverse_lerp(inicio_radio_distancia, radio_pleno_distancia, dist), 0.0, 1.0)
	_actualizar_musica_ambiente(t_radio)


func encender_radio() -> void:
	radio_encendida = true
	if audio_player.stream == null:
		_seleccionar_track_aleatorio(true)
	if not audio_player.playing:
		audio_player.play()
	_iniciar_animacion_antena()


func apagar_radio() -> void:
	radio_encendida = false
	audio_player.stop()
	audio_player.volume_db = -80.0
	_detener_animacion_antena()


func _volumen_por_distancia(dist: float) -> float:
	var t: float = inverse_lerp(inicio_radio_distancia, radio_pleno_distancia, dist)
	t = clampf(t, 0.0, 1.0)
	return lerpf(volumen_lejano_db, volumen_cercano_db, t)


func _cargar_playlist() -> void:
	_playlist.clear()
	for path in playlist_paths:
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path) as AudioStream
			if stream != null:
				_playlist.append(stream)
	if _playlist.is_empty() and music_stream != null:
		_playlist.append(music_stream)
	_seleccionar_track_aleatorio(true)


func _seleccionar_track_aleatorio(forzar: bool = false) -> void:
	if _playlist.is_empty():
		return
	if _playlist.size() == 1:
		_idx_actual = 0
		audio_player.stream = _playlist[0]
		return

	var idx_nuevo: int = _idx_actual
	while idx_nuevo == _idx_actual or forzar:
		idx_nuevo = _rng.randi_range(0, _playlist.size() - 1)
		if forzar and idx_nuevo != _idx_actual:
			break

	_idx_actual = idx_nuevo
	audio_player.stream = _playlist[_idx_actual]


func _on_track_finished() -> void:
	_seleccionar_track_aleatorio()
	if radio_encendida:
		audio_player.play()


func _iniciar_animacion_antena() -> void:
	var mesh_radio: Node3D = get_parent().get_node_or_null("RadioMesh") as Node3D
	if mesh_radio == null:
		return
	mesh_radio.rotation_degrees.z = radio_rot_z_base
	if antenna_tween:
		antenna_tween.kill()
	antenna_tween = create_tween().set_loops()
	antenna_tween.tween_property(mesh_radio, "rotation_degrees:z", radio_rot_z_base + 3.0, 0.8)
	antenna_tween.tween_property(mesh_radio, "rotation_degrees:z", radio_rot_z_base - 3.0, 0.8)


func _detener_animacion_antena() -> void:
	if antenna_tween:
		antenna_tween.kill()
		antenna_tween = null
	var mesh_radio: Node3D = get_parent().get_node_or_null("RadioMesh") as Node3D
	if mesh_radio != null:
		mesh_radio.rotation_degrees.z = radio_rot_z_base


func _actualizar_musica_ambiente(t_radio: float) -> void:
	if musica_ambiente == null:
		return
	var objetivo: float = lerpf(_volumen_ambiente_base_db, _volumen_ambiente_base_db - atenuacion_musica_ambiente_db, t_radio)
	musica_ambiente.volume_db = objetivo


func _buscar_jugador() -> Node3D:
	var candidato: Node = get_tree().get_first_node_in_group("player")
	if candidato == null:
		candidato = get_tree().get_first_node_in_group("jugador")
	return candidato as Node3D
