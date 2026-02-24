extends RayCast3D

@onready var prompt: Label = $Prompt

const INDICADOR: String = "\n[E]"

# Called when the node enters the scene tree for the first time.
func _physics_process(_delta):
	prompt.text = ""

	if is_colliding():
		var collider = get_collider()
		
		if collider is Interactuable:
			prompt.text = collider.item_data.item_name + INDICADOR
		
		elif collider.has_method("action_use"):
			prompt.text = "Puerta" + INDICADOR
		
		elif collider.has_method("terminar_partida"):
			prompt.text = "¿Salir?" + INDICADOR
		
		if collider.has_method("action_use") and Input.is_action_just_pressed("interactuar"):
			collider.action_use()

		if collider.has_method("terminar_partida") and Input.is_action_just_pressed("interactuar"):
			collider.terminar_partida()
		
		if collider.has_method("salida"):
			prompt.text = "Aún no puedo salir.\nTengo trabajo que hacer."
			