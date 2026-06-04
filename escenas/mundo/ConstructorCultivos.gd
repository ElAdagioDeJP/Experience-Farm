extends Node3D

const ESCALA_MODELO := Vector3(0.05, 0.05, 0.05)
const TAM_CUADRANTE := 12.0
const ESPACIADO_PLANTAS := 3.5

var datos_cultivos: Array[Dictionary] = [
	{
		"mesh": "res://assets/models/maiz_blanco_v3.obj",
		"scale": 2.0,
		"crop_icon_path": "res://export/PhotosofPlants/MaizBlanco.jpg",
		"crop_name": "Maíz Blanco",
		"crop_subtitle": "Zea mays · Carlos Arvelo, Carabobo",
		"crop_description": "El maíz blanco es el alma de la cocina venezolana. De sus granos molidos nace la harina precocida que da vida a la arepa, plato nacional consumido en cada hogar del país cada día. En Carabobo, los llanos de Carlos Arvelo producen miles de hectáreas de este grano bajo el Sistema de Riego Río Pao, convirtiéndolo en el granero más importante de la región central.",
		"crop_history": "Desde tiempos precolombinos los pueblos indígenas de estas tierras ya cultivaban el maíz en sus conucos. Con la llegada de la Reforma Agraria de 1960, miles de parceleros se asentaron en los llanos de Güigüe, transformando la sabana en un mar verde de milpas que hoy abastece a las plantas procesadoras de Valencia, a menos de 60 kilómetros de aquí.",
		"crop_region": "Municipio Carlos Arvelo · Sistema de Riego Río Pao"
	},
	{
		"mesh": "res://assets/models/maiz_v3.obj",
		"scale": 2.0,
		"crop_icon_path": "res://export/PhotosofPlants/MaizAmarillo.png",
		"crop_name": "Maíz Amarillo",
		"crop_subtitle": "Zea mays (var. amarillo) · Carlos Arvelo, Carabobo",
		"crop_description": "El maíz amarillo es el complemento industrial del blanco: su destino principal son los alimentos balanceados para aves y cerdos, la industria más potente de Carabobo. También se usa en almidones, aceites y productos de confitería. Su color dorado intenso lo distingue visualmente en el campo, y su ciclo de cosecha coincide exactamente con el del maíz blanco en la misma llanura.",
		"crop_history": "La demanda explosiva de las granjas avícolas y porcinas de Tocuyito, que comenzó a crecer en los años 70, impulsó la siembra masiva de maíz amarillo en los llanos de Carabobo. Las plantas de alimentos balanceados de Valencia —Protinal, Purina— necesitaban grano cerca, y los productores de Carlos Arvelo respondieron. Hoy ese vínculo campo-industria sigue siendo el corazón económico del estado.",
		"crop_region": "Municipio Carlos Arvelo · Sistema de Riego Río Pao"
	},
	{
		"mesh": "res://assets/models/sorgo_v3.obj",
		"scale": 1.1,
		"crop_icon_path": "res://export/PhotosofPlants/Sorga.jpg",
		"crop_name": "Sorgo",
		"crop_subtitle": "Sorghum bicolor · Carlos Arvelo, Carabobo",
		"crop_description": "El sorgo es el cultivo de rotación por excelencia en los llanos de Carabobo. Más resistente a la sequía que el maíz, ocupa los mismos campos entre cosechas, evitando el agotamiento del suelo. Su enorme panoja roja oscura en la cima es inconfundible. Se usa principalmente para alimentar animales de granja, pero también en la producción artesanal de chicha y guarapo en las comunidades rurales.",
		"crop_history": "Los productores carabobeños adoptaron el sorgo como cultivo de rescate durante las sequías de los años 80, cuando el maíz fallaba por falta de agua. La rotación maíz-sorgo-caraota se convirtió en el sistema de producción estándar del municipio Carlos Arvelo, aprovechando la estacionalidad del sistema de riego y manteniendo la tierra productiva todo el año.",
		"crop_region": "Municipio Carlos Arvelo · Rotación con maíz"
	},
	{
		"mesh": "res://assets/models/cana_v3.obj",
		"scale": 1.15,
		"crop_icon_path": "res://export/PhotosofPlants/CañadeAzucar.jpg",
		"crop_name": "Caña de Azúcar",
		"crop_subtitle": "Saccharum officinarum · Diego Ibarra, Carabobo",
		"crop_description": "La caña de azúcar define el paisaje de Mariara y San Joaquín desde hace siglos. De sus tallos azucarados se extrae el guarapo fresco, el papelón, el ron y el azúcar refinada. El Central El Palmar, uno de los pocos centrales azucareros activos del país, sigue procesando la cosecha de miles de cañicultores de la zona. La zafra —época de corte— es una fiesta comunitaria en estos municipios.",
		"crop_history": "Las primeras haciendas cañeras del valle se establecieron en el siglo XVII, aprovechando los suelos arcillosos del antiguo lecho del Lago de Valencia, ricos en materia orgánica. Los trapiches de madera tirados por bueyes fueron reemplazados por el Central El Palmar en el siglo XIX, modernizando toda la economía local. Hoy la caña resiste la presión urbana de Mariara y San Joaquín, conservando una tradición de más de 300 años.",
		"crop_region": "Municipio Diego Ibarra · San Joaquín · Ribera del Lago de Valencia"
	},
	{
		"mesh": "res://assets/models/caraota_v3.obj",
		"scale": 1.25,
		"crop_icon_path": "res://export/PhotosofPlants/Caraotas.jpg",
		"crop_name": "Caraotas Negras",
		"crop_subtitle": "Phaseolus vulgaris · Carlos Arvelo, Carabobo",
		"crop_description": "Las caraotas negras son inseparables de la mesa venezolana. Junto al arroz, la carne y la tajada, forman el 'pabellón criollo', el plato más representativo del país. En Carabobo se cultivan en rotación con el maíz, aprovechando la fertilidad residual del suelo y las últimas lluvias de la temporada. El tipo 'Tacarigua' —bautizado por el lago cercano— es la variedad local más apreciada por su sabor.",
		"crop_history": "La caraota negra tipo Tacarigua lleva el nombre del Lago de Valencia, llamado así por los pueblos indígenas. Su cultivo en los llanos de Güigüe se intensificó tras la Reforma Agraria, cuando los parceleros asentados combinaron maíz y caraotas como estrategia de seguridad alimentaria familiar. Hoy sigue siendo el cultivo de subsistencia más importante de las comunidades rurales de Carlos Arvelo.",
		"crop_region": "Municipio Carlos Arvelo · Variedad Tacarigua"
	},
	{
		"mesh": "res://assets/models/tabaco_v3.obj",
		"scale": 1.2,
		"crop_icon_path": "res://export/PhotosofPlants/TabacodeCapa.jpg",
		"crop_name": "Tabaco de Capa",
		"crop_subtitle": "Nicotiana tabacum · Borburata, Puerto Cabello",
		"crop_description": "El tabaco de Borburata es uno de los secretos mejor guardados de Carabobo. Sus hojas anchas y suaves, curadas en galeras tradicionales con ventilación natural, producen una capa de cigarro de calidad reconocida por las principales tabacaleras del mundo. El microclima de brumas matinales y suelos francos bien drenados de la costa crean condiciones únicas que ningún otro lugar del estado puede replicar.",
		"crop_history": "Desde el siglo XVII, las costas de Borburata exportaban tabaco fino por el puerto de Puerto Cabello hacia España y las Antillas. Fue el segundo gran producto de exportación de la región, después del cacao. Con la llegada del petróleo, el cultivo decayó, pero un grupo de familias de Borburata mantuvo viva la tradición. Hoy pequeños productores intentan revivir el tabaco de capa como producto gourmet de exportación.",
		"crop_region": "Municipio Puerto Cabello · Borburata · Costa del Litoral"
	},
	{
		"mesh": "res://assets/models/cacao_v3.obj",
		"scale": 4.05,
		"crop_icon_path": "res://export/PhotosofPlants/CacaoDeAroma.jpg",
		"crop_name": "Cacao Fino de Aroma",
		"crop_subtitle": "Theobroma cacao · Patanemo, Puerto Cabello",
		"crop_description": "El cacao de Borburata y Patanemo es considerado uno de los cacaos finos de aroma más apreciados del mundo. De tipo criollo y trinitario, su perfil sensorial combina notas de frutas rojas, nuez y flores. Las chocolaterías artesanales de Europa y Japón pagan precios premium por este grano. Se cultiva bajo sombra de bucare y jobo en pequeñas parcelas familiares que rara vez superan las dos hectáreas.",
		"crop_history": "Desde el siglo XVII, el puerto de Puerto Cabello era el principal embarcadero del cacao venezolano hacia Europa. Los esclavos y luego los aparceros de Patanemo cultivaron y fermentaron el cacao bajo la sombra de los grandes árboles de la serranía. Hoy ese saber ancestral de fermentar y secar el cacao al sol en bateas de madera sigue vivo, y el 'cacao de Carabobo' comienza a aparecer en tablillas de chocolate gourmet en París y Tokio.",
		"crop_region": "Municipio Puerto Cabello · Patanemo y Borburata"
	},
	{
		"mesh": "res://assets/models/cafe_v3.obj",
		"scale": 1.45,
		"crop_icon_path": "res://export/PhotosofPlants/CafedeAltura.jpg",
		"crop_name": "Café de Altura",
		"crop_subtitle": "Coffea arabica · Bejuma y Miranda, Carabobo",
		"crop_description": "En los municipios occidentales de Carabobo, a más de 800 metros de altura, el café arábigo encuentra su hábitat ideal: temperaturas frescas de 19-23°C, lluvias orográficas abundantes y suelos bien drenados desarrollados sobre esquistos metamórficos. El café de Bejuma es un café de especialidad con acidez brillante y notas florales, aún poco conocido pero de altísimo potencial en mercados gourmet.",
		"crop_history": "Fueron los inmigrantes europeos —italianos y portugueses— llegados a Bejuma y Miranda en los años 40 y 50 quienes popularizaron el cultivo del café bajo sombra en terrazas construidas en las laderas de la montaña. Trajeron técnicas de manejo intensivo y horticultura que transformaron los piedemontes occidentales. Hoy, décadas después, sus descendientes mantienen pequeños cafetales que producen un grano que empieza a ganar reconocimiento regional.",
		"crop_region": "Municipios Bejuma y Miranda · Cordillera Occidental · 800-1200 msnm"
	},
	{
		"mesh": "res://assets/models/aguacate_v3.obj",
		"scale": 2.2,
		"crop_icon_path": "res://export/PhotosofPlants/Aguacate.jpg",
		"crop_name": "Aguacate",
		"crop_subtitle": "Persea americana · Bejuma, Carabobo",
		"crop_description": "El aguacate, llamado 'la mantequilla de los pobres' en Venezuela, es uno de los frutales más cultivados en los valles montañosos del occidente de Carabobo. Su pulpa cremosa y nutritiva es fundamental en la dieta venezolana: en ensaladas, como guarnición de carnes, o simplemente con sal y limón. Las variedades locales tienen cáscaras rugosas de color verde oscuro a púrpura y pueden pesar hasta 500 gramos.",
		"crop_history": "Cuando la plaga del Dragón Amarillo devastó los huertos de cítricos de Bejuma y Miranda a partir del 2013, muchos productores que habían perdido sus naranjos y mandarinos buscaron alternativas. El aguacate fue la respuesta natural: resistente, productivo y con mercado creciente. Así, en menos de una década, los mismos valles que antes olían a flor de azahar se llenaron de grandes árboles de aguacate de copa extendida.",
		"crop_region": "Municipio Bejuma · Miranda · Piedemonte occidental"
	},
	{
		"mesh": "res://assets/models/tomate_v3.obj",
		"scale": 1.4,
		"crop_icon_path": "res://export/PhotosofPlants/Tomates.jpg",
		"crop_name": "Tomate",
		"crop_subtitle": "Solanum lycopersicum · Guacara, Carabobo",
		"crop_description": "El tomate es el rey de la horticultura periurbana de Carabobo. Cultivado en pequeñas parcelas de los municipios Guacara y Los Guayos, a veces bajo ambientes protegidos con riego por goteo, el tomate abastece el Mercado Mayorista de Valencia con producción de ciclo corto de 90 días. La cercanía al mercado es su mayor ventaja: el tomate cosechado hoy puede estar en una mesa de Valencia esta misma tarde.",
		"crop_history": "La producción de tomate periurbano explotó en los años 90, cuando pequeños productores comenzaron a alquilar parcelas en los intersticios urbanos de Guacara y Los Guayos para cultivar hortalizas de ciclo corto. La extrema cercanía a La Quizanda —el gran mercado mayorista de Valencia— eliminaba los costos de transporte y permitía vender directamente a los bodegueros. Ese modelo informal sigue funcionando hoy, adaptándose a la especulación inmobiliaria que amenaza con devorar las últimas tierras cultivables.",
		"crop_region": "Municipio Guacara · Los Guayos · Zona periurbana"
	},
	{
		"mesh": "res://assets/models/pimenton_v3.obj",
		"scale": 1.35,
		"crop_icon_path": "res://export/PhotosofPlants/Pimenton.jpg",
		"crop_name": "Pimentón Rojo",
		"crop_subtitle": "Capsicum annuum · Guacara, Carabobo",
		"crop_description": "El pimentón rojo es el colorido compañero del tomate en los huertos periurbanos de Carabobo. Su intenso color rojo brillante al madurar, su dulzura característica y su versatilidad culinaria lo hacen indispensable en guisos, sofritos y encurtidos venezolanos. Se cultiva en las mismas parcelas que el tomate, con sistemas de riego por goteo alimentados por pozos subterráneos, aprovechando los acuíferos de la zona.",
		"crop_history": "El pimentón llegó a los mercados carabobeños gracias a los productores horticultores de origen portugués e italiano que se establecieron en Guacara en la posguerra. Eran expertos en horticultura intensiva y transformaron pequeñas parcelas de suelo aluvial del río Guacara en jardines productivos de alta eficiencia. Su legado todavía se siente: muchos de los horticultores actuales son segunda y tercera generación de aquellas familias inmigrantes.",
		"crop_region": "Municipio Guacara · Margen del Río Guacara"
	},
	{
		"mesh": "res://assets/models/yuca_v3.obj",
		"scale": 0.93,
		"crop_icon_path": "res://export/PhotosofPlants/Yuca.jpg",
		"crop_name": "Yuca",
		"crop_subtitle": "Manihot esculenta · Puerto Cabello, Carabobo",
		"crop_description": "La yuca es uno de los cultivos más antiguos y versátiles de Venezuela. Su tubérculo blanco y almidonado se hierve, se fríe, se ralla para hacer casabe —el pan indígena venezolano— o se fermenta para producir chicha. Resistente a la sequía y a suelos pobres, la yuca crece con poco cuidado en las tierras cálidas de la franja costera de Carabobo, siendo un cultivo de seguridad alimentaria fundamental para las comunidades rurales.",
		"crop_history": "El casabe de yuca era ya el alimento base de los pueblos indígenas carib y arawak que habitaban las costas de lo que hoy es Puerto Cabello antes de la llegada de los españoles. Los colonizadores adoptaron rápidamente el casabe como alimento de viaje y subsistencia, y los barcos que salían de Puerto Cabello lo llevaban como provisión. Ese legado prehispánico sobrevive hoy en los conucos costeros donde las familias siguen rallando yuca y horneando casabe en budares de barro.",
		"crop_region": "Municipio Puerto Cabello · Juan José Mora · Franja costera"
	}
]


func _ready() -> void:
	_crear_caminos_entre_filas()
	_crear_cercas()
	_crear_cuadrantes()


func _crear_cuadrantes() -> void:
	for i in datos_cultivos.size():
		var fila := i / 3
		var columna := i % 3
		var centro := Vector3((float(columna) - 1.0) * TAM_CUADRANTE, 0.0, (float(fila) - 1.5) * TAM_CUADRANTE)
		_crear_cuadrante(i + 1, centro, datos_cultivos[i])


func _crear_cuadrante(numero: int, centro: Vector3, data: Dictionary) -> void:
	var nodo_cuadrante := Node3D.new()
	nodo_cuadrante.name = "Quadrant%d" % numero
	nodo_cuadrante.position = centro
	add_child(nodo_cuadrante)

	var mesh_cultivo := load(data["mesh"]) as Mesh
	if mesh_cultivo == null:
		push_warning("No se pudo cargar malla de cultivo: %s" % data["mesh"])
		return

	for z in range(3):
		for x in range(3):
			var local_pos := Vector3((x - 1) * ESPACIADO_PLANTAS, 0.0, (z - 1) * ESPACIADO_PLANTAS)
			_crear_planta(nodo_cuadrante, mesh_cultivo, local_pos, data)

	_crear_letrero(nodo_cuadrante, data["crop_name"])


func _crear_planta(parent_node: Node3D, mesh_cultivo: Mesh, local_pos: Vector3, data: Dictionary) -> void:
	var planta := StaticBody3D.new()
	planta.name = "Planta"
	planta.position = local_pos
	parent_node.add_child(planta)

	var visual := MeshInstance3D.new()
	visual.name = "MeshInstance3D"
	visual.mesh = mesh_cultivo
	var factor_escala := float(data.get("scale", 1.0))
	visual.scale = ESCALA_MODELO * factor_escala
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	planta.add_child(visual)

	var area := Area3D.new()
	area.name = "Area3D"
	area.collision_layer = 1
	area.collision_mask = 1
	area.input_ray_pickable = true
	area.monitorable = true
	area.monitoring = true
	area.script = load("res://escenas/mundo/CropInteractable.gd")
	planta.add_child(area)

	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	var aabb := mesh_cultivo.get_aabb()
	box.size = Vector3(
		maxf(0.6, aabb.size.x * ESCALA_MODELO.x * factor_escala),
		maxf(0.6, aabb.size.y * ESCALA_MODELO.y * factor_escala),
		maxf(0.6, aabb.size.z * ESCALA_MODELO.z * factor_escala)
	)
	shape.shape = box
	shape.position.y = box.size.y * 0.5
	area.add_child(shape)

	area.set("crop_name", data["crop_name"])
	area.set("crop_subtitle", data["crop_subtitle"])
	area.set("crop_description", data["crop_description"])
	area.set("crop_history", data["crop_history"])
	area.set("crop_region", data["crop_region"])
	area.set("crop_icon_path", data.get("crop_icon_path", ""))


func _crear_letrero(parent_node: Node3D, nombre: String) -> void:
	var mesh_letrero := load("res://assets/models/letrero_cultivo.obj") as Mesh
	if mesh_letrero == null:
		return
	var letrero := MeshInstance3D.new()
	letrero.name = "Letrero"
	letrero.mesh = mesh_letrero
	letrero.scale = ESCALA_MODELO
	letrero.position = Vector3(0, 0, 0)
	letrero.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent_node.add_child(letrero)

	var label := Label3D.new()
	label.name = "Texto"
	label.text = nombre.to_upper()
	label.position = Vector3(2.4, 1.25, -1.8)
	label.modulate = Color("3D2510")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 30
	parent_node.add_child(label)


func _crear_caminos_entre_filas() -> void:
	for z in [-12.0, 0.0, 12.0]:
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "Camino"
		add_child(cuerpo)
		var colision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(36.0, 0.1, 1.5)
		colision.shape = shape
		cuerpo.add_child(colision)

		var mesh := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(36.0, 0.06, 1.5)
		mesh.mesh = box_mesh
		mesh.position = Vector3(0.0, 0.03, z)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("A0724A")
		mat.roughness = 1.0
		mesh.material_override = mat
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mesh)


func _crear_cercas() -> void:
	var mesh_cerca := load("res://assets/models/cerco_cultivo.obj") as Mesh
	if mesh_cerca == null:
		return
	for x in [-6.0, 6.0]:
		_crear_linea_cerca(mesh_cerca, Vector3(x, 0.0, 0.0), true)
	for z in [-12.0, 0.0, 12.0]:
		_crear_linea_cerca(mesh_cerca, Vector3(0.0, 0.0, z), false)


func _crear_linea_cerca(mesh_cerca: Mesh, centro: Vector3, vertical: bool) -> void:
	for i in range(-40, 41):
		if i % 4 != 0:
			continue
		var cerca := MeshInstance3D.new()
		cerca.mesh = mesh_cerca
		cerca.scale = ESCALA_MODELO
		cerca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if vertical:
			cerca.position = centro + Vector3(0.0, 0.0, float(i) * 0.6)
		else:
			cerca.position = centro + Vector3(float(i) * 0.45, 0.0, 0.0)
			cerca.rotation.y = deg_to_rad(90.0)
		add_child(cerca)
