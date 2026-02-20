extends WorldEnvironment

@onready var env: Environment = environment
@onready var ambient_lightbulb: AudioStreamPlayer = $ambient_lightbulb
@onready var ambient_store_music: AudioStreamPlayer = $ambient_store_music
@onready var sfx_lights_off: AudioStreamPlayer = $sfx_lights_off
@onready var sfx_lights_on: AudioStreamPlayer = $sfx_lights_on
@onready var animation_player: AnimationPlayer = $"AnimationPlayer"
@onready var directional_light_3d: DirectionalLight3D = $"../DirectionalLight3D"

func _ready() -> void:
	ambient_lightbulb.play()
	CicloDiaNoche.cambio_estado.connect(_on_ciclo_cambiado)
	animation_player.pause()

func _process(_delta: float) -> void:
	var progreso = CicloDiaNoche.tiempo_transcurrido / CicloDiaNoche.duracion_total
	animation_player.play("ciclo_dia_noche")
	animation_player.seek(progreso * animation_player.current_animation_length, true)

# Ciclo de día y noche
func _on_ciclo_cambiado(noche: bool) -> void:
	var twin = create_tween()

	if noche:
		# Efectos visuales
		twin.tween_property(env, "ambient_light_color", Color(0.35, 0.45, 0.5), 1.5)
		twin.parallel().tween_property(env, "ambient_light_energy", 0.04, 1.5)
		twin.parallel().tween_property(env, "background_energy_multiplier", 0.25, 1.5)

		var sky_material = env.sky.sky_material as ProceduralSkyMaterial
		if sky_material:
			twin.tween_property(sky_material, "sky_top_color", Color(0.02, 0.02, 0.05), 1.5)
			twin.tween_property(sky_material, "sky_horizon_color", Color(0.1, 0.1, 0.15), 1.5)
		twin.parallel().tween_property(env, "background_energy_multiplier", 0.25, 1.0)

		# Música y ambiente
		ambient_store_music.stop()
		sfx_lights_off.play()
		ambient_lightbulb.play()
	else:
		# Efectos visuales
		twin.tween_property(env, "ambient_light_color", Color(1.0, 0.9, 0.8), 1.5)
		twin.parallel().tween_property(env, "ambient_light_energy", 1.0, 1.5)
		twin.parallel().tween_property(env, "background_energy_multiplier", 1.0, 1.0)

		var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
		if sky_mat:
			twin.tween_property(sky_mat, "sky_top_color", Color(0.4, 0.6, 0.9), 1.5)
			twin.tween_property(sky_mat, "sky_horizon_color", Color(0.8, 0.8, 0.7), 1.5)

		# Música y ambiente
		ambient_lightbulb.stop()
		sfx_lights_on.play()
		ambient_store_music.play()

func _set_sun():
	animation_player.play("ciclo_dia_noche")
