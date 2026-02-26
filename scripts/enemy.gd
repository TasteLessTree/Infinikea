extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var sfx_scream: AudioStreamPlayer = $sfx_scream
@onready var sfx_attack: AudioStreamPlayer = $sfx_attack
@onready var sfx_pluh: AudioStreamPlayer3D = $sfx_pluh
@onready var raycast_origin: RayCast3D = $RayCast3D
@onready var timer: Timer = $Timer

@export var player_path: NodePath
@export var turn_speed: float = 6.0
@export var facing_correction_deg: float = 180.0

# Golpear al jugador
signal player_hit

# Estados del enemigo
enum EnemyState { IDLE, NEUTRAL, SEARCHING, SCREAMING, CHASING, ATTACKING_MANNEQUIN }
var state: int = EnemyState.IDLE

# Configurables
@export_range(0.1, 20.0, 0.1) var walking_speed: float = 2.0
@export_range(0.1, 40.0, 0.1) var running_speed: float = 7.5
@export_range(0.1, 30.0, 0.1) var detection_range: float = 12.0
@export_range(0.1, 20.0, 0.1) var scream_range: float = 12.0
@export_range(0.1, 6.0, 0.1) var attack_range: float = 1.8

# Elegir un punto aleatorio (en un radio) para moverse
@export_range(1.0, 50.0, 0.5) var wander_radius: float = 8.0

# Temporizadores
@export var wander_retarget_time: float = 2.0
@export var scream_cooldown: float = 3.0
@export var lost_interest_timeout: float = 7.83
@export var attack_cooldown_time: float = 1.0

# Gravedad
@export var gravity: float = 24.0

var player: Node3D = null

var current_target: Vector3 = Vector3.ZERO

var lost_interest_timer: float = 0.0
var scream_start_time: float = 0.0
var next_wander_time: float = 0.0
var scream_timer: float = 0.0
var attack_cooldown: float = 0.0

var has_triggered_scream: bool = false
var is_screaming: bool = false
var is_attacking: bool = false

func _ready() -> void:
	# Detectar el jugador
	if player_path and has_node(player_path):
		player = get_node(player_path) as Node3D
	else:
		if get_tree().root.has_node("root"):
			pass # Si no lo detecta lo dejamos cómo null

	if not animation_player.animation_finished.is_connected(_on_animation_player_animation_finished):
		animation_player.animation_finished.connect(_on_animation_player_animation_finished, CONNECT_REFERENCE_COUNTED)

	# Estado inicial
	_set_state(EnemyState.NEUTRAL)

	# Conectar con la señal del ciclo de día y noche
	CicloDiaNoche.cambio_estado.connect(_on_ciclo_cambiado)

func _physics_process(delta: float) -> void:
	# Actualizar temporizador del grito
	scream_timer = max(0.0, scream_timer - delta)
	attack_cooldown = max(0.0, attack_cooldown - delta)

	# Gravedad
	velocity.y -= gravity * delta

	# Comportamiento
	match state:
		EnemyState.IDLE:
			_process_idle(delta)

		EnemyState.NEUTRAL:
			_process_neutral(delta)

		EnemyState.SEARCHING:
			_process_searching(delta)

		EnemyState.SCREAMING:
			_process_screaming(delta)

		EnemyState.CHASING:
			_process_chasing(delta)

		EnemyState.ATTACKING_MANNEQUIN:
			_process_attack_mannequin(delta)

	move_and_slide()

# Cambiar estado
func _set_state(new_state: int) -> void:
	if new_state == state:
		return

	state = new_state
	is_screaming = false

	match state:
		EnemyState.IDLE:
			_play_animation("idle")
			velocity = Vector3.ZERO
			nav_agent.set_avoidance_enabled(false)
			timer.start()

		EnemyState.NEUTRAL:
			_play_animation("walk")
			nav_agent.set_avoidance_enabled(true)
			_pick_new_wander_target()
			timer.start()

		EnemyState.SEARCHING:
			_play_animation("walk")
			nav_agent.set_avoidance_enabled(true)
			_pick_new_wander_target()
			timer.stop()

		EnemyState.SCREAMING:
			is_screaming = true
			scream_start_time = Time.get_ticks_msec() / 1000.0
			_play_animation("scream")
			if sfx_scream:
				sfx_scream.play()
			velocity = Vector3.ZERO
			nav_agent.set_avoidance_enabled(false)
			timer.start()

		EnemyState.CHASING:
			_play_animation("run")
			nav_agent.set_avoidance_enabled(true)
			timer.start()

		EnemyState.ATTACKING_MANNEQUIN:
			nav_agent.set_avoidance_enabled(false)
			timer.start()

""" --- Estados --- """
# Idle
func _process_idle(_delta: float) -> void:
	var tiempo = randf_range(1.0, 5.0)
	if Time.get_ticks_msec() / (1000.0 * tiempo) >= next_wander_time:
		if CicloDiaNoche.get_es_de_noche():
			_set_state(EnemyState.SEARCHING)
		else:
			_set_state(EnemyState.NEUTRAL)

# Neutral
func _process_neutral(delta: float) -> void:
	_wander_tick(delta, walking_speed)

	if CicloDiaNoche.get_es_de_noche():
		_set_state(EnemyState.SEARCHING)
	else:
		_on_timer_timeout()

# Searching
func _process_searching(delta: float) -> void:
	# Si no es de noche, neutral
	if not CicloDiaNoche.get_es_de_noche():
		_set_state(EnemyState.NEUTRAL)
		return

	# Detectar al maniquí
	var targer_mannequin = _get_visible_mannequin()
	if targer_mannequin:
		_move_to_and_attack(targer_mannequin, delta)
		return

	_wander_tick(delta, walking_speed)

	# Gritar si está cerca
	if _can_see_player() and _distance_to_player() <= detection_range:
		_check_detection_reactio()
		return
	else:
		has_triggered_scream = false

# Screaming
func _process_screaming(delta: float) -> void:
	_look_towards(player.global_position, delta)
	velocity = Vector3.ZERO

# Chasing
func _process_chasing(delta: float) -> void:
	# Si no es de noche, neutral
	if not CicloDiaNoche.get_es_de_noche():
		_set_state(EnemyState.NEUTRAL)
		return

	# Detectar al maniquí
	var targer_mannequin = _get_visible_mannequin()
	if targer_mannequin:
		_move_to_and_attack(targer_mannequin, delta)
		return

	var can_see = _can_see_player()

	if can_see:
		nav_agent.target_position = player.global_position
		lost_interest_timer = 0.0
	else:
		lost_interest_timer += delta
		if lost_interest_timer >= lost_interest_timeout:
			_set_state(EnemyState.SEARCHING)
			return
	
	# Continuar con la ruta
	if nav_agent.is_navigation_finished():
		_move_towards(player.global_position, running_speed, delta)
	else:
		var next_point = nav_agent.get_next_path_position()
		_move_towards(next_point, running_speed, delta)

	# Comprobar si puede atacar
	if _player_in_range():
		_start_attack()

func _process_attack_mannequin(delta: float) -> void:
	var mannequin = _get_visible_mannequin()
	if mannequin:
		_move_to_and_attack(mannequin, delta)
		return
	_set_state(EnemyState.SEARCHING)

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
		return INF

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
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos, 3, exclude)
	var result = space.intersect_ray(query)

	if not result:
		return true
	
	if result.has("collider"):
		var collider = result.collider
		return collider == player

	return false

# Animaciones
func _play_animation(animation_name: String) -> void:
	if animation_player and animation_player.has_animation(animation_name):
		if animation_player.is_playing() and animation_player.current_animation == animation_name:
			return
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

# Atacar (enviar señal)
func hit_player() -> void:
	if _player_in_range():
		emit_signal("player_hit")

# Atacar (animación y sonidos)
func _start_attack() -> void:
	is_attacking = true
	velocity = Vector3.ZERO
	if sfx_attack:
			sfx_attack.play()
	_play_animation("attack")
	attack_cooldown = attack_cooldown_time

# El jugador está en rango
func _player_in_range() -> bool:
	if _can_see_player() and _distance_to_player() <= attack_range:
		return true
	return false

# Ciclo de día y noche
func _on_ciclo_cambiado(noche: bool) -> void:
	if noche:
		_set_state(EnemyState.SEARCHING)
	else:
		_set_state(EnemyState.NEUTRAL)

# Pequeña probabilidad de quedarse IDLE
func _on_timer_timeout() -> void:
	if CicloDiaNoche.get_es_de_noche():
		return
	if state != EnemyState.NEUTRAL and state != EnemyState.IDLE:
		return

	if randi() % 100 == 0:
		_set_state(EnemyState.IDLE)
	else:
		_set_state(EnemyState.NEUTRAL)

# Detectar maniquíes
func _get_visible_mannequin() -> Node3D:
	var interactuables = get_tree().get_nodes_in_group("interactuable")

	for obj in interactuables:
		if obj.get("item_data") and obj.item_data.get("item_name") == "Maniqui":
			var distance = global_position.distance_to(obj.global_position)

			if distance <= detection_range:
				var from_pos = global_position + Vector3(0, 1.4, 0)
				var to_pos = obj.global_position + Vector3(0, 1.3, 0)
				var space = get_world_3d().direct_space_state
				var exclude = [self.get_rid()]
				var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos, 3, exclude)
				var result = space.intersect_ray(query)

				if not result or result.collider == obj:
					return obj
	return null

# Atacar al maniquí
func _attack_mannequin(target: Node3D) -> void:
	velocity = Vector3.ZERO
	_look_towards(target.global_position, get_physics_process_delta_time())
	if sfx_attack:
		sfx_attack.play()
	_play_animation("attack")

	target.queue_free()
	# Se queda quieto un momento después de romper el maniquí
	velocity = Vector3.ZERO
	_set_state(EnemyState.IDLE)

# Moverse hacia el maniquí
func _move_to_and_attack(target: Node3D, delta: float) -> void:
	var distance = global_position.distance_to(target.global_position)

	if distance <= attack_range:
		_attack_mannequin(target)
	else:
		nav_agent.target_position = target.global_position
		var next_point = nav_agent.get_next_path_position()
		_move_towards(next_point, running_speed, delta)

# Animación del grito
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "scream" and state == EnemyState.SCREAMING:
		scream_timer = scream_cooldown
		has_triggered_scream = false
		_set_state(EnemyState.CHASING)
		return

	if anim_name == "attack":
		is_attacking = false
		if CicloDiaNoche.get_es_de_noche():
			_play_animation("run")

# Garantizar que el grito ocurra
func _check_detection_reactio() -> void:
	# No volver a detectar
	if has_triggered_scream or is_screaming or scream_timer > 0.0:
		return

	has_triggered_scream = true
	_set_state(EnemyState.SCREAMING)

""" --- Guardar y cargar --- """
# Guardar
func save() -> Dictionary:
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"current_target_x" : current_target.x,
		"current_target_y" : current_target.y,
		"current_target_z" : current_target.z,
		"state" : state,
		"scream_timer": scream_timer,
		"attack_cooldown" : attack_cooldown,
		"next_wander_time" : next_wander_time,
		"has_triggered_scream" : has_triggered_scream,
		"lost_interest_timer" : lost_interest_timer,
		"player_path": player_path
	}

	return save_dict

# Cargar
func load_data(data: Dictionary) -> void:
	position = Vector3(data["pos_x"], data["pos_y"], data["pos_z"])
	current_target = Vector3(data["current_target_x"], data["current_target_y"], data["current_target_z"])
	state = int(data["state"])
	scream_timer = data["scream_timer"]
	attack_cooldown = data["attack_cooldown"]
	next_wander_time = data["next_wander_time"]
	has_triggered_scream = data["has_triggered_scream"]
	lost_interest_timer = data["lost_interest_timer"]
	player_path = data["player_path"]
	_set_state(state)

# Easter egg
func easter_egg() -> void:
	if sfx_pluh:
		sfx_pluh.play()
