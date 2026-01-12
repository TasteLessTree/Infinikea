extends Control

@onready var player_camera: Camera3D = $"/root/Main/Player/Head/Camera3D"
@onready var h_slider: HSlider = $HBoxContainer/HSlider
@onready var fov_value: Label = $HBoxContainer/Fov_value

func _on_h_slider_value_changed(value: float) -> void:
	player_camera.fov = h_slider.value
	fov_value.text = str(h_slider.value)
