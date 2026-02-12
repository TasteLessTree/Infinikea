class_name Player
extends CharacterBody3D

@onready var camara = $Head/Camera3D
@onready var head = $Head
@onready var linterna = $Head/Camera3D/Mano/SpotLight3D
@onready var body_pivot = $Player
@onready var stamina_bar = $UI/ProgressBar
@onready var sfx_footsteps = $Sonidos/sfx_footsteps
@onready var sfx_jump = $Sonidos/sfx_jump
@onready var sfx_gasping = $Sonidos/sfx_gasping
@onready var ray = $Head/Camera3D/Vision
@onready var label = $Head/Camera3D/Vision/Prompt


@export var playerSpeed: float = 8.0
@export var friction: float = 20.0
@export var player_acc: float = 5.0
@export var move_speed: float = 6.0
@export var gravity: float = 24.0
@export var jump_velocity: float = 6.0
@export var camera_sens: float = 0.05
@export var jumpForce: float = 8.0
@export var camera_acc: float = 1.5
@export var sprintSpeed: float = 12.0 
@export var staminaMax: float = 100.0
@export var staminaDrainRate: float = 20.0
@export var staminaRegenRate: float = 15.0
@export var regenCooldown: float = 0.5
@export var flashlight_pitch_up = 35.0 # grados
@export var flashlight_pitch_down = 10  # grados hacia abajo

var direction: Vector3 = Vector3.ZERO
var y_velocity: float = 6.0
var head_y_axis: float = 0.0
var camera_x_axis: float = 0.0
var crouch_height: float = 0.5
var stand_height: float = 2.0
var crouching = false
var crouch_speed: float = 3.5

var stamina: float = staminaMax
var is_sprinting: bool = false
var regen_cooldown_timer: float = 0.0
var step_distance_accum: float = 0.0

# Distancia entre pasos
const STEP_DISTANCE: float = 2.75

func _input(event):
	if event is InputEventMouseMotion:
		head_y_axis += event.relative.x * camera_sens
		camera_x_axis += event.relative.y * camera_sens
		camera_x_axis = clamp(camera_x_axis, -90.0, 90)

func _ready() -> void:	
	stamina_bar.show_percentage = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func crouch():
	if Input.is_action_just_pressed("crouch"):
		crouching = !crouching
		if crouching:
			$CollisionShape3D.shape.height = crouch_height
		else:
			$CollisionShape3D.shape.height = stand_height

func _physics_process(delta):
	crouch()
	
	ray_scanning(delta)
	var input_x = Input.get_axis("move_left", "move_right")
	var input_z = Input.get_axis("move_forward", "move_back")
	
	# Dirección basada en la rotación del cuerpo [cite: 7]
	direction = input_x * body_pivot.basis.x + input_z * body_pivot.basis.z
	direction.y = 0.0
	direction = direction.normalized()
	
	# Lógica de Sprint y Stamina [cite: 5, 6]
	var want_sprint = Input.is_action_pressed("sprint")
	if want_sprint and stamina > 0.0 and is_on_floor() and not crouching:
		is_sprinting = true
		regen_cooldown_timer = 0.0
	else:
		is_sprinting = false
		
	if is_sprinting:
		stamina = max(stamina - staminaDrainRate * delta, 0.0)
		if stamina <= 25.0:
			sfx_gasping.play()
		if stamina <= 0.0:
			is_sprinting = false # No puedes correr si no hay estamina
			regen_cooldown_timer = regenCooldown
	else:
		if regen_cooldown_timer > 0.0:
			regen_cooldown_timer -= delta
		else:
			stamina = min(stamina + staminaRegenRate * delta, staminaMax)
			
	var target_speed = _get_walk_speed()
	var target_velocity = direction * target_speed

	# 2. SISTEMA DE MOVIMIENTO MEJORADO:
	if direction.length() > 0:
		# Aplicamos aceleración si hay input
		velocity.x = lerp(velocity.x, target_velocity.x, player_acc * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, player_acc * delta)
	else:
		# Aplicamos fricción fuerte si NO hay input para frenar en seco
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)
	
	# Actualizar la barra de progreso
	if stamina_bar:
		stamina_bar.value = stamina
	
	body_pivot.rotation.y = -deg_to_rad(head_y_axis)
	camara.rotation.x = lerp(camara.rotation.x, -deg_to_rad(camera_x_axis), camera_acc * delta)
	
	head.rotation.y= -deg_to_rad(head_y_axis)
	
	# Sonido de andar
	var moving = direction.length() > 0.1
	if is_on_floor() and moving:
		step_distance_accum += (velocity * delta).length()
		if step_distance_accum >= STEP_DISTANCE:
				if sfx_footsteps:
					sfx_footsteps.play()
				step_distance_accum = 0.0
	else:
		step_distance_accum = 0.0
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jumpForce
		if sfx_jump:
			sfx_jump.play(0.25)
	else:
		velocity.y -= gravity * delta

	move_and_slide()

func ray_scanning(_delta):
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider == null:
			return
		
		if Input.is_action_just_pressed("interactuar"):
			print(collider.name)
			
			if collider.is_in_group("interactuable"):
				collider.interact()

func _process(_delta):
	var cam_pitch = rad_to_deg(camara.rotation.x)
	var clamped_pitch = clamp(cam_pitch,-flashlight_pitch_down, flashlight_pitch_up)
	
	$Head/Camera3D/Mano.rotation.x = -deg_to_rad(clamped_pitch)

func _get_walk_speed():
	if crouching:
		return crouch_speed
	if is_sprinting:
		return sprintSpeed
	else:
		return playerSpeed
