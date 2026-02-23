extends Control

@onready var options_menu: OptionsMenu = $OptionsMenu
@onready var music_main_menu = $music_main_menu
@onready var continuar: Button = $PanelContainer/VBoxContainer/Continuar

var is_main_menu: bool = true

func mostrar_menu_principal() -> void:
	is_main_menu = true
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	music_main_menu.play()

func iniciar_juego() -> void:
	Inventario.clear_inventory()
	CicloDiaNoche.set_es_de_noche(false)
	desactivar_menu()

func desactivar_menu() -> void:
	is_main_menu = false
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	music_main_menu.stop()

func _ready() -> void:
	handle_signals()
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		continuar.disabled = false
	else:
		continuar.disabled = true
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
	SaveManager.load_game()
	desactivar_menu()

func _on_nueva_partida_pressed() -> void:
	# Sobre-escribir el archivo de guardado
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)
	desactivar_menu()
	mostrar_cinematica()

func mostrar_cinematica() -> void:
	visible = false
	music_main_menu.stop()
	get_tree().paused = false

	var cutscene = preload("res://scenes/cutscene/intro.tscn").instantiate()
	get_tree().root.add_child(cutscene)

	cutscene.cutscene_finished.connect(_on_cutscene_finished)

func handle_signals() -> void:
	options_menu.exit_option_menu.connect(on_exit_options_menu)

func _on_cutscene_finished() -> void:
	iniciar_juego()
