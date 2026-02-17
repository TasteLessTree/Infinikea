extends WorldEnvironment

@onready var ambient_lightbulb: AudioStreamPlayer = $ambient_lightbulb
@onready var directional_light_3d: DirectionalLight3D = $"../DirectionalLight3D"
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

func _ready() -> void:
	ambient_lightbulb.play()
	_set_sun()
	
func _set_sun():
	animation_player.play("ciclo_dia_noche")
