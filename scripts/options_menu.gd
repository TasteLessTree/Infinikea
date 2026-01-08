class_name OptionsMenu
extends Control

@onready var atras: Button = $MarginContainer/VBoxContainer/Atras

signal exit_option_menu

func _ready() -> void:
	atras.button_down.connect(on_exit_pressed)
	set_process(false)

func on_exit_pressed() -> void:
	exit_option_menu.emit()
	set_process(false)
