extends Control

@onready var audio_name: Label = $HBoxContainer/Audio_Name
@onready var h_slider: HSlider = $HBoxContainer/HSlider
@onready var audio_value: Label = $HBoxContainer/Audio_Value

@export_enum("Master", "Music", "Ambient", "Sfx", "Voice") var bus_name: String

var bus_idx: int = 0

func _ready() -> void:
	h_slider.value_changed.connect(on_value_changed)
	get_bus_name_by_index()
	set_name_label_text()
	set_slider_value()
	
func set_name_label_text() -> void:
	match bus_name:
		"Master":
			audio_name.text = "Sonido maestro"
		"Music":
			audio_name.text = "Música"
		"Ambient":
			audio_name.text = "Ambiente"
		"Sfx":
			audio_name.text = "Efectos de sonido"
		"Voice":
			audio_name.text = "Voces"
		_:
			audio_name.text = "Valor desconocido"
	
func set_auido_value_label_text() -> void:
	audio_value.text = str(h_slider.value * 100) + "%"

func get_bus_name_by_index() -> void:
	bus_idx = AudioServer.get_bus_index(bus_name)
	
func set_slider_value() -> void:
	h_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	set_auido_value_label_text()
	
func on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	set_auido_value_label_text()
