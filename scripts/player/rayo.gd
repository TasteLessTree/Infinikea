extends RayCast3D

@onready var prompt: Label = $Prompt

# Called when the node enters the scene tree for the first time.
func _physics_process(_delta):
	prompt.text = ""

	if is_colliding():
		var collider = get_collider()
		
		if collider is Interactuable:
			prompt.text = collider.item_data.item_name + "\n [E]" 
		
		elif collider.has_method("action_use"):
			prompt.text = "Puerta \n [E]" 
		
		if collider.has_method("action_use") and Input.is_action_just_pressed("interactuar"):
			collider.action_use()


	
