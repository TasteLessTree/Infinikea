extends Node

signal cambio_estado(es_de_noche)

@export var duracion_total: float = 165.0
@export var porcion_dia: float = 0.2727

var tiempo_transcurrido: float = 0.0
var es_de_noche: bool = false

func _process(delta: float) -> void:
	tiempo_transcurrido += delta

	# Reinciar el temporizador
	if tiempo_transcurrido >= duracion_total:
		tiempo_transcurrido = 0.0

	# Determinar si es de día o de noche
	var limite_dia = duracion_total * porcion_dia
	var nuevo_estado = tiempo_transcurrido > limite_dia

	# Cambiar la energía acordemente
	if nuevo_estado != es_de_noche:
		es_de_noche = nuevo_estado
		cambiar_iluminacion(es_de_noche)
		cambio_estado.emit(es_de_noche)

func cambiar_iluminacion(noche: bool) -> void:
	# Obtener los nodos del grupo
	var luces = get_tree().get_nodes_in_group("luces_techo")

	var energia_objetivo = 0.25 if noche else 2.0

	for luz in luces:
		if luz is SpotLight3D:
			# Transición suave
			var twin = create_tween()
			twin.tween_property(luz, "light_energy", energia_objetivo, 1.0)

func get_es_de_noche() -> bool:
	return es_de_noche

func set_es_de_noche(noche: bool) -> void:
	es_de_noche = noche

	# Reiciar el ciclo
	if es_de_noche:
		tiempo_transcurrido = duracion_total * porcion_dia
	else:
		tiempo_transcurrido = 0.0

	cambiar_iluminacion(es_de_noche)
	cambio_estado.emit(es_de_noche)

# Guardar
func save() -> Dictionary:
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"is_singleton" : true,
		"tiempo_transcurrido" : tiempo_transcurrido,
		"es_de_noche" : es_de_noche
	}

	return save_dict

# Cargar
func load_data(data: Dictionary) -> void:
	tiempo_transcurrido = float(data["tiempo_transcurrido"])
	es_de_noche = bool(data["es_de_noche"])
	tiempo_transcurrido = float(data["tiempo_transcurrido"])
	cambiar_iluminacion(es_de_noche)
	cambio_estado.emit(es_de_noche)
