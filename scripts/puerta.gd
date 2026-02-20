extends Node3D
@onready var animation_player: AnimationPlayer = $StaticBody3D/AUTOMATIC_SLIDING_DOOR_MAX/AnimationPlayer

var opened = false

func interact():
	if not animation_player:
		return
	if opened:
		open_door()
	else:
		close_door()
	
	opened = !opened

func open_door():
	animation_player.play("Rectangle04|Take 001|BaseLayer")
	animation_player.play("Rectangle08|Take 001|BaseLayer")
	
func close_door():
	animation_player.play_backwards("Rectangle04|Take 001|BaseLayer")
	animation_player.play_backwards("Rectangle08|Take 001|BaseLayer")
