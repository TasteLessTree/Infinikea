extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var sfx_scream: AudioStreamPlayer = $sfx_scream
@onready var sfx_attack: AudioStreamPlayer = $sfx_attack
@onready var raycast_origin: RayCast3D = $RayCast3D

@export var player_path: NodePath
@export var turn_speed: float = 6.0
@export var facing_correction_deg: float = 180.0

# Golpear al jugador
signal player_hit

# Estados del enemigo
enum EnemyState { IDLE, NEUTRAL, SEARCHING, CHASING }
var state: int = EnemyState.IDLE

# Configurables
@export_range(0.1, 20.0, 0.1) var walking_speed: float = 2.0
@export_range(0.1, 40.0, 0.1) var running_speed: float = 7.5
@export_range(0.1, 30.0, 0.1) var detection_range: float = 12.0
@export_range(0.1, 10.0, 0.1) var scream_range: float = 4.0
@export_range(0.1, 6.0, 0.1) var attack_range: float = 1.8

# Elegir un punto aleatorio (en un radio) para moverse
@export_range(1.0, 50.0, 0.5) var wander_radius: float = 8.0

# Temporizadores
@export var wander_retarget_time: float = 2.0
@export var scream_cooldown: float = 3.0
@export var lost_interest_timeout: float = 5.0

var player: Node3D = null
var next_wander_time: float = 0.0
var scream_timer: float = 0.0
var current_target: Vector3 = Vector3.ZERO
var lost_interest_timer: float = 0.0

func _ready() -> void:
	# Detectar el jugador
	if player_path and has_node(player_path):
		player = get_node(player_path) as Node3D
	else:
		if get_tree().root.has_node("root"):
			pass # Si no lo detecta lo dejamos cómo null

	# Iniciar temporizadores de caminar y gritar
	next_wander_time = Time.get_ticks_msec() / 1000.0 + randf_range(0.0, wander_retarget_time)
	scream_timer = 0.0

	# Estado inicial
	_set_state(EnemyState.NEUTRAL)

	# Conectar con la señal del ciclo de día y noche
	CicloDiaNoche.cambio_estado.connect(_on_ciclo_cambiado)

func _physics_process(delta: float) -> void:
	# Detectar el jugador
	if player_path and has_node(player_path):
		player = get_node(player_path) as Node3D
	else:
		if get_tree().root.has_node("root"):
			pass # Si no lo detecta lo dejamos cómo null

	# Actualizar temporizadores
	scream_timer = max(0.0, scream_timer - delta)

	# Si no ve al jugador, incrementar el temporizador
	if state == EnemyState.CHASING:
		if not _can_see_player():
			lost_interest_timeout += delta
			if lost_interest_timer >= lost_interest_timeout:
				_set_state(EnemyState.SEARCHING)
		else:
			lost_interest_timer = 0.0

	# Comportamiento
	match state:
		EnemyState.IDLE:
			_process_idle(delta)

		EnemyState.NEUTRAL:
			_process_neutral(delta)

		EnemyState.SEARCHING:
			_process_searching(delta)

		EnemyState.CHASING:
			_process_chasing(delta)

	# Desplazamiento
	velocity = velocity.move_toward(Vector3.ZERO, 10 * delta) if state == EnemyState.IDLE else velocity

	move_and_slide()

# Cambiar el estado
func _set_state(new_state: int) -> void:
	if new_state == state:
		return

	state = new_state

	match state:
		EnemyState.IDLE:
			_play_animation("idle")
			velocity = Vector3.ZERO
			nav_agent.set_avoidance_enabled(false)

		EnemyState.NEUTRAL:
			_play_animation("walk")
			nav_agent.set_avoidance_enabled(true)
			_pick_new_wander_target()

		EnemyState.SEARCHING:
			_play_animation("walk")
			nav_agent.set_avoidance_enabled(true)
			_pick_new_wander_target()

		EnemyState.CHASING:
			_play_animation("run")
			nav_agent.set_avoidance_enabled(true)

""" --- Estados --- """
# Idle
func _process_idle(_delta: float) -> void:
	if Time.get_ticks_msec() / 1000.0 >= next_wander_time:
		_set_state(EnemyState.NEUTRAL)
		print("ENEMIGO salió IDLE")

# Neutral
func _process_neutral(delta: float) -> void:
	_wander_tick(delta, walking_speed)

	if CicloDiaNoche.get_es_de_noche():
		if _can_see_player() and _distance_to_player() <= detection_range:
			# Neutral y noche pasamos a chasing por que hemos detectado al jugador
			_set_state(EnemyState.CHASING)
	else:
		# Generar un número aleatorio [1, 10000] si es igual a 1, no hacer nada (idle)
		if 1 == (randi() % 10000 + 1):
			print("ENEMIGO en IDLE")
			_set_state(EnemyState.IDLE)
		else:
			_set_state(EnemyState.NEUTRAL)

# Searching
func _process_searching(delta: float) -> void:
	# Si no es de noche, neutral
	if not CicloDiaNoche.get_es_de_noche():
		_set_state(EnemyState.NEUTRAL)
		return

	_wander_tick(delta, walking_speed)

	# Gritar si está cerca
	if _can_see_player() and _distance_to_player() <= scream_range and scream_timer <= 0.0:
		_play_animation("scream")
		sfx_scream.play() # TODO: Buscar un sonido
		scream_timer = scream_cooldown

		# Tras gritar, perseguimos
		_set_state(EnemyState.CHASING)

	# Detectar al jugador desde lejos, pero no grita
	if _can_see_player() and _distance_to_player() <= detection_range and _distance_to_player() > scream_range:
		_set_state(EnemyState.CHASING)

# Chasing
func _process_chasing(delta: float) -> void:
	# Si no es de noche, neutral
	if not CicloDiaNoche.get_es_de_noche():
		_set_state(EnemyState.NEUTRAL)
		return

	# El objetivo es el jugador
	if player:
		nav_agent.set_target_position(player.global_transform.origin)
	
	# Continuar con la ruta
	if nav_agent.is_navigation_finished():
		_move_towards(player.global_position, running_speed, delta)
	else:
		var next_point = nav_agent.get_next_path_position()
		_move_towards(next_point, running_speed, delta)

	# Comprobar si puede atacar
	if _can_see_player() and _distance_to_player() <= attack_range:
		_play_animation("attack")
		sfx_attack.play() # TODO: Buscar un sonido

""" --- Movimiento --- """
func _pick_new_wander_target() -> void:
	# Calcular un punto aleatorio al rededor
	var angle = randf() * TAU
	var r = randf() * wander_radius
	var local_point = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
	var world_point = global_position + local_point

	# Calcular el camino hacia ese punto
	nav_agent.target_position = world_point
	next_wander_time = Time.get_ticks_msec() / 1000.0 + randf_range(1.0, wander_retarget_time)

func _wander_tick(delta: float, speed: float) -> void:
	# Elegir un nuevo objetivo
	var now = Time.get_ticks_msec() / 1000.0

	if now >= next_wander_time or nav_agent.is_navigation_finished():
		_pick_new_wander_target()

	# Si tenemos un camino, seguirlo
	if not nav_agent.is_navigation_finished():
		var next_point = nav_agent.get_next_path_position()
		_move_towards(next_point, speed, delta)
	else:
		velocity = Vector3.ZERO

func _move_towards(target_pos: Vector3, speed: float, delta: float) -> void:
	# Movimiento horizontal
	var dir = (target_pos - global_position)
	dir.y = 0

	if dir.length() > 0.1:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed

		# Mirar hacia delante
		_look_towards(global_position + dir, delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		velocity.z = lerp(velocity.z, 0.0, 0.2)

""" --- Dirección y utilidades --- """
# Distancia al jugador
func _distance_to_player() -> float:
	if player:
		return global_position.distance_to(player.global_position)
	else:
		return 9999.0

# Puede ver al jugador
func _can_see_player() -> bool:
	if player == null:
		return false

	if _distance_to_player() > detection_range:
		return false

	# Desde el enemigo al jugador
	var from_pos = global_position + Vector3(0, 1.4, 0)
	var to_pos = player.global_position + Vector3(0, 1.3, 0)
	var space = get_world_3d().direct_space_state
	var exclude = [self.get_rid()]
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos, 0x7FFFFFFF, exclude)
	var result = space.intersect_ray(query)

	if not result:
		return true
	
	if result.has("collider"):
		var collider = result.collider
		return collider == player or player.is_a_parent_of(collider)

	return false

# Animaciones
func _play_animation(animation_name: String) -> void:
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)

# Dirección
func _look_towards(target: Vector3, delta: float) -> void:
	var look_pos = Vector3(target.x, global_position.y, target.z)
	var desired = global_transform.looking_at(look_pos, Vector3.UP)

	if facing_correction_deg != 0.0:
		desired.basis = desired.basis.rotated(Vector3.UP, deg_to_rad(facing_correction_deg))

	# Interpolación
	var t = clamp(turn_speed * delta, 0.0, 1.0)

	# Mantener escala
	var original_basis = global_transform.basis.get_scale()
	var slerped_basis = global_transform.basis.orthonormalized().slerp(desired.basis.orthonormalized(), t)

	slerped_basis = slerped_basis.scaled(original_basis)
	global_transform.basis = slerped_basis

# Atacar
func _hit_player() -> void:
	if _can_see_player() and _distance_to_player() <= attack_range:
		_play_animation("attack")
		sfx_attack.play() # TODO: Buscar un sonido
		emit_signal("player_hit")

# Ciclo de día y noche
func _on_ciclo_cambiado(noche: bool) -> void:
	if noche:
		_set_state(EnemyState.SEARCHING)
	else:
		if state == EnemyState.CHASING or state == EnemyState.SEARCHING:
			_set_state(EnemyState.NEUTRAL)
