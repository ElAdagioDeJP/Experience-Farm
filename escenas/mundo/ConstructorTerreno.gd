extends GridMap
## Pinta el terreno del nivel: un campo de grama con un sendero de tierra que
## guía visualmente desde el spawn (z+) hasta la cabaña al fondo (z-).
## Items de la MeshLibrary: 0=grama, 1=tierra, 2=camino.

const ITEM_GRAMA := 0
const ITEM_TIERRA := 1
const ITEM_CAMINO := 2

## Mitad del ancho del campo en celdas (campo = (2*ancho+1) celdas en X).
@export var ancho_campo: int = 28
@export var z_inicio: int = 12    # borde detrás del spawn (grid z)
@export var z_fin: int = -26      # borde en la cabaña (grid z)
@export var ancho_sendero: int = 1 # celdas a cada lado del centro (sendero = 2*esto+1)


func _ready() -> void:
	# Campo de grama (relleno base).
	for x in range(-ancho_campo, ancho_campo + 1):
		for z in range(z_fin, z_inicio + 1):
			set_cell_item(Vector3i(x, 0, z), ITEM_GRAMA)

	# Sendero de tierra/camino por el centro, del spawn a la cabaña.
	for z in range(z_fin, z_inicio + 1):
		for x in range(-ancho_sendero, ancho_sendero + 1):
			set_cell_item(Vector3i(x, 0, z), ITEM_CAMINO)

	# Pequeño claro de tierra batida frente a la cabaña.
	for x in range(-4, 5):
		for z in range(z_fin, z_fin + 5):
			set_cell_item(Vector3i(x, 0, z), ITEM_TIERRA)
