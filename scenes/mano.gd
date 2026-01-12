extends Node3D

@onready var linterna = $SpotLight3D

var spotlight_on: bool = false
# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(InputEvent):
	# Encender apagar la linterna
	if Input.is_action_just_pressed("spotlight_on_off") and !spotlight_on:
		spotlight_on = true
		linterna.light_energy = 1.5
	elif Input.is_action_just_pressed("spotlight_on_off") and spotlight_on:
		spotlight_on = false
		linterna.light_energy = 0
