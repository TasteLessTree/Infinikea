extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D

@export var player_path: NodePath
@export_enum("Idle", "Neutral", "Searching", "Spotted", "Chasing", "Attack") var states: String

var player = null
var state: String = "Idle"

const SPEED: float = 7.5
const SCREAM_RANGE: float = 4.0
const ATTACK_RANGE: float = 2.0

func _ready() -> void:
	player = get_node(player_path)

func _physics_process(_delta: float) -> void:
	match state:
		"Idle":
			animation_tree.set("parameters/conditions/walking", true)
			ray_scanning()

		"Neutral":
			walk_or_run(0.0)

		"Searching":
			animation_player.play("scream")

		_:
			print("Unexpected token: " + state + ". Check spelling or add state")

func ray_scanning() -> void:
	if ray_cast_3d.is_colliding():
		var collider = ray_cast_3d.get_collider()
		
		if collider == null:
			return
		
		if collider == player:
			print("Jugador detectado")
			print("Cambiando estado")
			state = "Neutral"

func walk_or_run(running_speed: float) -> void:
	velocity = Vector3.ZERO
	nav_agent.set_target_position(player.global_position)
	var next_nav_point  = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * (SPEED + running_speed)

	ray_scanning()

	# Gritar si el jugador está cerca y atacarle si está a un más cerca
	animation_tree.set("parameters/conditions/scream", scream_in_range())
	animation_tree.set("parameters/conditions/attack", target_in_range())

	look_towards(next_nav_point)

	move_and_slide()

func target_in_range() -> bool:
	return global_position.distance_to(player.global_position) <= ATTACK_RANGE

func scream_in_range() -> bool:
	return global_position.distance_to(player.global_position) < SCREAM_RANGE

func look_towards(target: Vector3) -> void:
	var look_pos = Vector3(target.x, global_position.y, target.z)
	look_at(look_pos, Vector3.UP)
