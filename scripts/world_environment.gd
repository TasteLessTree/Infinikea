extends WorldEnvironment

@onready var ambient_lightbulb: AudioStreamPlayer = $ambient_lightbulb

func _ready() -> void:
	ambient_lightbulb.play()
