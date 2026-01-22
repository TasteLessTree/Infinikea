extends Node3D

@onready var linterna = $SpotLight3D
@onready var sfx_flashlight = $"../../../Sonidos/sfx_flashlight"
@onready var linterna_modelo = $linterna_modelo

var spotlight_on: bool = false
var current_item_instance: Node3D = null

func _ready():
	Inventario.slot_selected.connect(_update_held_item)

func clear_item():
	if current_item_instance:
		current_item_instance.queue_free()
		current_item_instance = null



func show_item(item_data: ItemData):
	clear_item()
	
	if item_data == null:
		_desactivar_linterna_visual()
		return
	
	if item_data and item_data.mesh_scene:
		current_item_instance = item_data.mesh_scene.instantiate()
		current_item_instance.position = Vector3.ZERO
		current_item_instance.rotation = Vector3.ZERO
		add_child(current_item_instance)
	if (item_data.item_name == "Linterna"):
		linterna_modelo.visible = true
		# No alteramos 'spotlight_on' aquí para que mantenga su estado al cambiar de slot
		linterna.light_energy = 1.5 if spotlight_on else 0
	else:
		_desactivar_linterna_visual()
		

func _update_held_item(slot_index: int):
	var item = Inventario.hotbar[slot_index]
	show_item(item)
		

func _input(_event: InputEvent):
	# 1. Obtener qué item tenemos en la mano actualmente
	var item_actual = Inventario.hotbar[Inventario.selected_slot] 
	
	# 2. Solo permitir el input si el item actual es la linterna
	if item_actual != null and item_actual.item_name == "Linterna":
		if Input.is_action_just_pressed("spotlight_on_off"):
			Inventario.slot_selected.connect(_update_held_item)
			sfx_flashlight.play() 
			spotlight_on = !spotlight_on
			linterna.light_energy = 1.5 if spotlight_on else 0
		
		
func _desactivar_linterna_visual():
	linterna_modelo.visible = false
	linterna.light_energy = 0
