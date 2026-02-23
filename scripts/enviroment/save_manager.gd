extends Node

const SAVE_PATH = "user://savegame.save"

# Guardar la partida
func save_game() -> void:
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")

	# Ciclo de día y noche
	var cilo_dia_noche = CicloDiaNoche.save()
	save_file.store_line(JSON.stringify(cilo_dia_noche))

	for node in save_nodes:
		if node.scene_file_path.is_empty():
			print("Nodo '%s' no instanciado, saltando nodo..." % node.name)
			continue

		# Comprobar que tengan la función de guardado
		if node.has_method("save"):
			var node_data = node.call("save")
			var json_data = JSON.stringify(node_data)
			save_file.store_line(json_data)

# Cargar la partida
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return # No existe una partida guardada

	# Limpiar nodos persistentes actuales para no duplicar
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		i.queue_free()

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)

		# Asegurarse de que no haya errores al parsear el JSON
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Comprobar si es del ciclo de día y noche u otro objeto
		var node_data = json.get_data()

		if not node_data.has("filename"):
			if CicloDiaNoche.has_method("load_data"):
				CicloDiaNoche.load_data(node_data)
			continue

		var path = node_data["filename"]
		if path == null or not ResourceLoader.exists(path):
			print("Error: no se puede encontrar la escena con ruta: '%s'" % path)
			continue

		var scene_resource = load(path)
		if scene_resource:
			var new_object = scene_resource.instantiate()
			new_object.add_to_group("Persist")

			var parent_node = get_node_or_null(node_data["parent"])
			if parent_node:
				parent_node.add_child(new_object)

				# Restaurar posición y estados
				new_object.position = Vector3(node_data["pos_x"], node_data["pos_y"], node_data["pos_z"])
				if new_object.has_method("load_data"):
					new_object.load_data(node_data)
			else:
				print("Error: El nodo padre no existe: '%s'" % node_data["parent"])
