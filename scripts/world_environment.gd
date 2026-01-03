extends WorldEnvironment

@onready var sfx_fluorescent_lightbulb = $sfx_fluorescent_lightbulb

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sfx_fluorescent_lightbulb.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
