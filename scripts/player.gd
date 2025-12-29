extends CharacterBody3D

@onready var camara = $Head/Camera3D
@onready var head = $Head 
@onready var mano = $Hand
@onready var linterna = $Hand/SpotLight3D


@export var playerSpeed = 8.0
@export var player_acc = 5.0
@export var move_speed: float = 6.0
@export var gravity: float = 24.0
@export var jump_velocity: float = 6.0
@export var camera_sens: float = 0.05
@export var jumpForce = 8.0
@export var camera_acc = 1.5


var direction = Vector3.ZERO
var y_velocity: float = 6.0
var head_y_axis = 0.0
var camera_x_axis = 0.0

func _input(event):
	if event is InputEventMouseMotion:
		head_y_axis +=event.relative.x * camera_sens
		camera_x_axis += event.relative.y * camera_sens
		camera_x_axis = clamp(camera_x_axis, -90.0, 90)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func _physics_process(delta):
	# Gravedad
	direction = Input.get_axis("move_left", "move_right")* head.basis.x + Input.get_axis("move_forward", "move_back") * head.basis.z
	velocity = velocity.lerp(direction * playerSpeed + velocity.y * Vector3.UP, player_acc * delta)
	
	mano.rotation.y = -deg_to_rad(head_y_axis)
	linterna.rotation.x = -deg_to_rad(camera_x_axis)
	
	head.rotation.y = lerp(head.rotation.y, -deg_to_rad(head_y_axis), camera_acc * delta)
	camara.rotation.x = lerp(camara.rotation.x, -deg_to_rad(camera_x_axis), camera_acc * delta)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jumpForce
	else:
		velocity.y -= gravity * delta
	
	move_and_slide()
	
	
"""var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
	y_velocity -= gravity * delta
	
	
	if is_starting_jump:
		$Player/AnimationPlayer.play("Jump_Start")
	elif not is_on_floor() and velocity.y <0:
		$Player/AnimationPlayer.play("Jump_Land")
	elif is_on_floor():
		var ground_speed := velocity.length()
		if ground_speed > 0.0:
			$Player/AnimationPlayer.play("Walk")
		else:
			$Player/AnimationPlayer.play("Idle")
	
	if not is_on_floor():
		y_velocity -= gravity * delta
	else :
		if Input.is_action_just_pressed("jump"):
			y_velocity = jump_velocity
		else:
			y_velocity = 0.0
			

	# Input con WASD pero es un vector 2D
	var input_dir: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)
	
	var velocity_3d: Vector3 = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		# Mirar en la dirección del jugador
		var forward: Vector3 = global_transform.basis.z
		var right: Vector3 = global_transform.basis.x
		
		# Combinar para el movimiento en 3D
		var move_dir: Vector3 = (forward * input_dir.y) + (right * input_dir.x)
		move_dir = move_dir.normalized()
		
		velocity_3d.x = move_dir.x * move_speed
		velocity_3d.z = move_dir.z * move_speed
		
	else:
		velocity_3d.x = move_toward(velocity.x, 0.0, move_speed)
		velocity_3d.z = move_toward(velocity.z, 0.0, move_speed)
		
	# Aplicar velocidad vertical
	velocity_3d.y = y_velocity
	
	
	velocity = velocity_3d"""
