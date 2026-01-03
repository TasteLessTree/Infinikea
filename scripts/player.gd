extends CharacterBody3D

@onready var camara = $Head/Camera3D
@onready var head = $Head
@onready var mano = $Hand
@onready var linterna = $Hand/SpotLight3D
@onready var body_pivot = $Player
@onready var sfx_footsteps = $sfx_footsteps
@onready var sfx_jump = $sfx_jump
@onready var stamina_bar = $Head/ProgressBar

@export var playerSpeed: float = 8.0
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

var direction: Vector3 = Vector3.ZERO
var y_velocity: float = 6.0
var head_y_axis: float = 0.0
var camera_x_axis: float = 0.0
var step_distance_accum: float = 0.0
var spotlight_on: bool = true
var stamina: float = staminaMax
var is_sprinting: bool = false
var regen_cooldown_timer: float = 0.0

# Distancia entre pasos
const STEP_DISTANCE: float = 2.75

func _input(event):
	if event is InputEventMouseMotion:
		head_y_axis +=event.relative.x * camera_sens
		camera_x_axis += event.relative.y * camera_sens
		camera_x_axis = clamp(camera_x_axis, -90.0, 90)

func _ready() -> void:
	stamina_bar.show_percentage = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:	
	# Entrada
	var input_x = Input.get_axis("move_left", "move_right")
	var input_z = Input.get_axis("move_forward", "move_back")
	
	# Dirección basaba en la rotación del cuerpo
	direction = input_x * body_pivot.basis.x + input_z * body_pivot.basis.z
	direction.y = 0.0
	direction = direction.normalized()
	
	# Esprintar
	var want_sprint = Input.is_action_pressed("sprint")
	if want_sprint and stamina > 0.0 and is_on_floor():
		is_sprinting = true
		regen_cooldown_timer = 0.0
	else:
		is_sprinting = false
		
	if is_sprinting:
		stamina = max(stamina - staminaDrainRate * delta, 0.0)
		if stamina <= 0.0:
			is_sprinting = false # No puedes correr si no hay estamina
			regen_cooldown_timer = regenCooldown
	else:
		if regen_cooldown_timer > 0.0:
			regen_cooldown_timer -= delta
		else:
			stamina = min(stamina + staminaRegenRate * delta, staminaMax)
			
	var currentSpeed = _get_walk_speed()
	velocity = velocity.lerp(direction * currentSpeed + velocity.y * Vector3.UP, player_acc * delta)
	
	# Actualizar la barra de progreso
	if stamina_bar:
		stamina_bar.value = stamina
	
	# Rotación cabeza y cámara
	mano.rotation.y = -deg_to_rad(head_y_axis)
	linterna.rotation.x = -deg_to_rad(camera_x_axis)
	
	body_pivot.rotation.y = -deg_to_rad(head_y_axis)
	head.rotation.y = lerp(head.rotation.y, -deg_to_rad(head_y_axis), camera_acc * delta)
	camara.rotation.x = lerp(camara.rotation.x, -deg_to_rad(camera_x_axis), camera_acc * delta)
	
	# Sonido de andar
	var moving = direction.length() > 0.1
	if is_on_floor() and moving:
		step_distance_accum += (velocity * delta).length()
		if step_distance_accum >= STEP_DISTANCE:
				sfx_footsteps.play()
				step_distance_accum = 0.0
	else:
		step_distance_accum = 0.0
	
	# Saltar
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jumpForce
		sfx_jump.play(0.25)
	else:
		velocity.y -= gravity * delta
	
	# Encender apagar la linterna
	if Input.is_action_just_pressed("spotlight_on_off") and spotlight_on:
		spotlight_on = false
		linterna.visible = false
	elif Input.is_action_just_pressed("spotlight_on_off") and !spotlight_on:
		spotlight_on = true
		linterna.visible = true
	
	move_and_slide()

func _get_walk_speed():
	if is_sprinting:
		return sprintSpeed
	else:
		return playerSpeed
