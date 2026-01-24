extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

@export var player_path: NodePath

var player = null

const SPEED: float = 7.5

func _ready() -> void:
	player = get_node(player_path)

func _physics_process(_delta: float) -> void:
	velocity = Vector3.ZERO
	nav_agent.set_target_position(player.global_position)
	var next_nav_point  = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * SPEED
	
	move_and_slide()
