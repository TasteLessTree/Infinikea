extends Control

@onready var options_menu: OptionsMenu = $OptionsMenu
@onready var sfx_main_menu_music = $sfx_main_menu

var is_main_menu: bool = true

func mostrar_menu_principal() -> void:
	is_main_menu = true
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	sfx_main_menu_music.play()

func iniciar_juego() -> void:
	is_main_menu = false
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	sfx_main_menu_music.stop()

func _ready() -> void:
	handle_signals()
	mostrar_menu_principal()
	
func _process(_delta: float) -> void:
	if is_main_menu:
		get_tree().paused = true
		visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_salir_pressed() -> void:
	get_tree().quit()

func _on_opciones_pressed() -> void:
	$PanelContainer/VBoxContainer.visible = false
	$PanelContainer.self_modulate = 0
	options_menu.set_process(true)
	options_menu.visible = true
	
func on_exit_options_menu() -> void:
	$PanelContainer/VBoxContainer.visible = true
	$PanelContainer.self_modulate = 100
	options_menu.visible = false

func _on_continuar_pressed() -> void:
	pass

func _on_nueva_partida_pressed() -> void:
	iniciar_juego()

func handle_signals() -> void:
	options_menu.exit_option_menu.connect(on_exit_options_menu)
