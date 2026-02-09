extends WorldEnvironment

@onready var ambient_lightbulb: AudioStreamPlayer = $ambient_lightbulb
@onready var env: Environment = environment

func _ready() -> void:
	ambient_lightbulb.play()
	CicloDiaNoche.cambio_estado.connect(_on_ciclo_cambiado)

# Ciclo de día y noche
func _on_ciclo_cambiado(noche: bool) -> void:
	var twin = create_tween()

	if noche:
		twin.tween_property(env, "ambient_light_color", Color(0.35, 0.45, 0.5), 1.5)
		twin.parallel().tween_property(env, "ambient_light_energy", 0.4, 1.5)
	else:
		twin.tween_property(env, "ambient_light_color", Color(1.0, 0.95, 0.85), 1.5)
		twin.parallel().tween_property(env, "ambient_light_energy", 1.2, 1.5)
