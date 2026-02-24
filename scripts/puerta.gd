extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_open = false
var can_interact = true

func action_use():
	if !is_open and can_interact:
		open_door()
	elif is_open and can_interact:
		close_door()

func open_door():
	can_interact = false
	animation_player.play("abrir")
	is_open = true
	
func close_door():
	can_interact = false
	animation_player.play("cerrar")
	is_open = false

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	can_interact = true
