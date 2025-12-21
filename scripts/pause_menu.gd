extends Control

func resume() -> void:
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$AnimationPlayer.play_backwards("blur")
	
func pausar() -> void:
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$AnimationPlayer.play("blur")

func pause_menu() -> void:
	if Input.is_action_just_pressed("pause_menu") and get_tree().paused == false:
		pausar()
	elif Input.is_action_just_pressed("pause_menu") and get_tree().paused == true:
		resume()

func _on_continuar_pressed() -> void:
	resume()

func _on_opciones_pressed() -> void:
	pass # Replace with function body.

func _on_salir_pressed() -> void:
	get_tree().quit()

func _process(_delta: float) -> void:
	pause_menu()
	
func _ready() -> void:
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$AnimationPlayer.play("RESET")
