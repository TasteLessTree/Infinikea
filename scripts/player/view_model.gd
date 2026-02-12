extends Camera3D

@onready var camara = $Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	camara.position.x = lerp(camara.position.x, 0.0, delta * 5.0)
	camara.position.y = lerp(camara.position.y, 0.0, delta * 5.0)
	
func sway(sway_amount):
	camara.position.x += sway_amount.x * 0.00009
	camara.position.y += sway_amount.y * 0.00009
