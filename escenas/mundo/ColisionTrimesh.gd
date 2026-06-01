extends MeshInstance3D
## Genera colision estatica trimesh (ConcavePolygonShape3D) a partir de la malla
## de este MeshInstance3D al cargar la escena. Pensado para construcciones fijas
## (granero, cercas): el jugador no atraviesa paredes ni muebles, y los huecos de
## puertas/ventanas quedan transitables porque la colision sigue la malla exacta.
##
## Trimesh solo sirve para cuerpos estaticos. create_trimesh_collision() crea un
## StaticBody3D hijo con su CollisionShape3D ya configurado.


func _ready() -> void:
	if mesh == null:
		push_warning("ColisionTrimesh: %s no tiene malla; sin colision." % name)
		return
	# Crea StaticBody3D + CollisionShape3D (ConcavePolygonShape3D) como hijos.
	# Hereda la escala del nodo, asi que la colision calza con lo que se ve.
	create_trimesh_collision()
