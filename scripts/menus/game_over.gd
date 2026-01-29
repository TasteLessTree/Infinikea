extends Control

func _ready() -> void:
	pausar()

func pausar() -> void:
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$AnimationPlayer.play("blur")

func _on_salir_pressed() -> void:
	get_tree().quit()

func _on_main_pressed() -> void:
	pass # TODO: Replace with function body.
