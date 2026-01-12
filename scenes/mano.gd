extends Node3D

@onready var linterna = $SpotLight3D
@onready var sfx_flashlight = $sfx_flashlight

var spotlight_on: bool = false

func _input(_event: InputEvent):
	# Encender apagar la linterna
	if Input.is_action_just_pressed("spotlight_on_off") and !spotlight_on:
		sfx_flashlight.play()
		spotlight_on = true
		linterna.light_energy = 1.5
	elif Input.is_action_just_pressed("spotlight_on_off") and spotlight_on:
		sfx_flashlight.play()
		spotlight_on = false
		linterna.light_energy = 0
