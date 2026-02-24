extends Node3D

func terminar_partida() -> void:
	var cutscene_scene = preload("res://scenes/cutscene/ending.tscn")
	var cutscene = cutscene_scene.instantiate()
	get_tree().root.add_child(cutscene)

	cutscene.ending_cutscene_finished.connect(_on_ending_cutscene_finished)

func _on_ending_cutscene_finished() -> void:
	var main_menu = get_tree().root.find_child("MainMenu", true, false)
	if main_menu:
		main_menu.mostrar_menu_principal()
