extends Control

@onready var options_menu: OptionsMenu = $OptionsMenu

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
	$PanelContainer/VBoxContainer.visible = false
	$PanelContainer.self_modulate = 0
	options_menu.set_process(true)
	options_menu.visible = true

func _on_exit_options_menu() -> void:
	$PanelContainer/VBoxContainer.visible = true
	$PanelContainer.self_modulate = 100
	options_menu.visible = false

func _on_menu_principal_pressed() -> void:
	SaveManager.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_guardar_y_salir_pressed() -> void:
	SaveManager.save_game()
	get_tree().quit()

func _process(_delta: float) -> void:
	pause_menu()
	
func _ready() -> void:
	handle_signals()
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$AnimationPlayer.play("RESET")

func handle_signals() -> void:
	options_menu.exit_option_menu.connect(_on_exit_options_menu)
