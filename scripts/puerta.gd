extends Node3D

@onready var animation_player: AnimationPlayer = $AUTOMATIC_SLIDING_DOOR_MAX/AnimationPlayer

var is_open = false
var player_near = false
var is_animating = false

func _on_Area_body_entered(body):
	if body.name == "player":
		player_near = true
		
func _on_Area_body_exited(body):
	if body.name == "player":
		player_near = false
		
func process():
	if player_near and Input.is_action_just_pressed("interactuar"):
		toggle_door()
		
func toggle_door():
	is_animating = true
	if is_open:
		animation_player.play_backwards("Rectangle08|Take 001|BaseLayer")
		animation_player.play_backwards("Rectangle08|Take 001|BaseLayer")
		
	else:
		animation_player.play("Rectangle04|Take 001|BaseLayer")
		animation_player.play("Rectangle08|Take 001|BaseLayer")
	is_open = !is_open	
