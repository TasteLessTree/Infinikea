extends CharacterBody3D

@onready var camara = $Camera3D

@export var move_speed: float = 6.0
@export var gravity: float = 24.0
@export var jump_velocity: float = 6.0

var y_velocity: float = 6.0

const CAMERA_SENS: float = 0.003

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
		
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * CAMERA_SENS
		rotation.x -= event.relative.y * CAMERA_SENS

func _physics_process(delta: float) -> void:
	# Gravedad
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
	
	velocity = velocity_3d
	move_and_slide()
