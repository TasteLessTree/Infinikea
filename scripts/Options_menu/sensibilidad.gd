extends Control

@onready var player: CharacterBody3D = $"/root/Main/Player"
@onready var h_slider: HSlider = $HBoxContainer/HSlider
@onready var sensibildad_value: Label = $HBoxContainer/Sensibildad_value

func _on_h_slider_value_changed(value: float) -> void:
	player.camera_acc = h_slider.value
	sensibildad_value.text = str(h_slider.value)
