extends Control

@onready var option_button: OptionButton = $HBoxContainer/OptionButton

const RESULUTION_DICTIONARY: Dictionary = {
	"1152 x 648": Vector2i(1152, 648),
	"1280 x 720": Vector2i(1280, 720),
	"1920 x 1080": Vector2i(1920, 1080)
}

func _ready() -> void:
	option_button.item_selected.connect(on_resolution_selected)

func add_resolution() -> void:
	pass
	
func on_resolution_selected(idx: int) -> void:
	pass
