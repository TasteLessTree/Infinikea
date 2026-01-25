extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var armature: Node3D = $Armature

@export var player_path: NodePath

var player = null
var state_machine

const SPEED: float = 7.5
const SCREAM_RANGE: float = 4.0
const ATTACK_RANGE: float = 2.0

func _ready() -> void:
	player = get_node(player_path)
	state_machine = animation_tree.get("parameters/playback")

func _physics_process(_delta: float) -> void:
	match state_machine.get_current_node():
		"idle":
			animation_tree.set("parameters/conditions/walking", true)

		"walk":
			walk_or_run(0.0)

		"run":
			walk_or_run(0.5)
		
		"scream":
			look_towards(player.global_position)

		"attack":
			animation_tree.set("parameters/conditions/run", !target_in_range())
			look_towards(player.global_position)

		"hit":
			pass

func walk_or_run(running_speed: float) -> void:
	velocity = Vector3.ZERO
	nav_agent.set_target_position(player.global_position)
	var next_nav_point  = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * (SPEED + running_speed)

	# Atacar si el jugador está cerca
	animation_tree.set("parameters/conditions/scream", scream_in_range())
	animation_tree.set("parameters/conditions/attack", target_in_range())

	# Mientras está andando
	look_towards(next_nav_point)

	move_and_slide()

func target_in_range() -> bool:
	return global_position.distance_to(player.global_position) <= ATTACK_RANGE

func scream_in_range() -> bool:
	return global_position.distance_to(player.global_position) < SCREAM_RANGE

func look_towards(target: Vector3) -> void:
	var look_pos = Vector3(target.x, global_position.y, target.z)
	armature.look_at(look_pos, Vector3.UP)
