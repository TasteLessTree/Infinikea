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
	if item_data and item_data.mesh_scene:
		current_item_instance = item_data.mesh_scene.instantiate()
		current_item_instance.position = Vector3.ZERO
		current_item_instance.rotation = Vector3.ZERO
		add_child(current_item_instance)
		"if current_item_instance = linterna:
			linterna"
		

func _update_held_item(slot_index: int):
	var item = Inventario.hotbar[slot_index]
	show_item(item)

func _input(_event: InputEvent):
	# Encender apagar la linterna
	if Input.is_action_just_pressed("spotlight_on_off") and !spotlight_on:
		sfx_flashlight.play()
		spotlight_on = true
		linterna.light_energy = 1.5
	elif Input.is_action_just_pressed("spotlight_on_off") and spotlight_on:
		sfx_flashlight.play()
		spotlight_on = false
		linterna.light_energy = 0
