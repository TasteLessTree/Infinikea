extends Control

func _ready() -> void:
	visible = false

func pausar() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_salir_pressed() -> void:
	get_tree().quit()

func _on_main_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
