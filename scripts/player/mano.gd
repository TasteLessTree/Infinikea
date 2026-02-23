extends Node3D

@onready var linterna = $SpotLight3D
@onready var sfx_flashlight = $"../../../Sonidos/sfx_flashlight"
@onready var sfx_eating = $"../../../Sonidos/sfx_eating"
@onready var raycast = $"../Vision"

const INTERACTUABLE_SCENE = preload("res://scenes/player/interactuables.tscn")

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
	
	if item_data.mesh_scene:
		current_item_instance = item_data.mesh_scene.instantiate()
		if current_item_instance is RigidBody3D:
			current_item_instance.freeze = true # Congela el cuerpo
			current_item_instance.process_mode = Node.PROCESS_MODE_DISABLED # Opcional:
			_remover_colisiones(current_item_instance)
		current_item_instance.position = Vector3.ZERO
		current_item_instance.rotation = Vector3.ZERO
		add_child(current_item_instance)
		
		# --- LÓGICA PARA EL MATERIAL OVERLAY ---
		# Buscamos el nodo 'brillo' que es un MeshInstance3D
		var mesh_node = current_item_instance.get_node_or_null("flashlight_low") as MeshInstance3D
		
		if mesh_node:
			# Si quieres quitarlo completamente al estar en la mano:
			mesh_node.material_overlay = null 
			
			# O si quieres que dependa de si la linterna está encendida:
			# _actualizar_brillo_overlay(mesh_node)
		
	if (item_data.item_name == "Linterna"):
		# No alteramos 'spotlight_on' aquí para que mantenga su estado al cambiar de slot
		linterna.light_energy = 2 if spotlight_on else 0
	
	else:
		_desactivar_linterna_visual()
	
func _update_held_item(slot_index: int):
	var item = Inventario.hotbar[slot_index]
	show_item(item)

func _input(_event: InputEvent):
	# 1. Obtener qué item tenemos en la mano actualmente
	var item_actual = Inventario.hotbar[Inventario.selected_slot] 
	
	if item_actual == null:
		return
	
	# 2. Solo permitir el input si el item actual es la linterna
	if Input.is_action_just_pressed("use_item"):
		if item_actual.item_name == "Linterna":
			usar_linterna()
		
		# 3. Poner en el suelo un maniquí
		elif item_actual.item_name == "Maniquí":
			colocar_maniqui(item_actual)
		
		# 4. Comer un perrito caliente
		elif item_actual.item_name == "Hot Dog":
			comer_hot_dog()
		
func usar_linterna():
	#Inventario.slot_selected.connect(_update_held_item)
	sfx_flashlight.play() 
	spotlight_on = !spotlight_on
	linterna.light_energy = 2 if spotlight_on else 0
	
func colocar_maniqui(item_data: ItemData):
	if raycast.is_colliding():
		var punto_colision = raycast.get_collision_point()
		
		# Escena madre de los interactuables
		var nuevo_interactuable = INTERACTUABLE_SCENE.instantiate()
		
		if "item_data" in nuevo_interactuable:
			nuevo_interactuable.item_data = item_data
		
		# Nuevo maniquí
		get_tree().root.add_child(nuevo_interactuable)
		
		# Posicionarlo
		nuevo_interactuable.global_position = punto_colision
		
		var player_pos = global_position
		player_pos.y = nuevo_interactuable.global_position.y # Nivelamos la altura
		nuevo_interactuable.look_at(player_pos, Vector3.UP)
		nuevo_interactuable.rotate_y(PI) # A veces look_at lo deja de espaldas, esto lo gira 180°
		
		Inventario.remove_item(Inventario.selected_slot) # Lo elimina del inventario físico
		clear_item() # Lo elimina de la mano del jugador

func comer_hot_dog():
	Inventario.remove_item(Inventario.selected_slot) # Lo elimina del inventario físico
	clear_item() # Lo elimina de la mano del jugador
	
	if sfx_eating:
		sfx_eating.play()
	
	# Buscar al jugador
	var player = owner as Player
	
	if player:
		player.aplicar_buff_hot_dog()

func _desactivar_linterna_visual():
	linterna.light_energy = 0
	
func _remover_colisiones(nodo: Node):
	for child in nodo.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D or child is StaticBody3D or child is RigidBody3D:
			child.queue_free() # Elimina la colisión solo de la instancia en la mano
		_remover_colisiones(child) # Recursivo para sub-nodos

func _actualizar_brillo_overlay(mesh_node: MeshInstance3D):
	if mesh_node:
		# Si la linterna está ON, mantenemos el overlay (o lo reasignamos)
		# Si está OFF, lo ponemos en null para que no brille
		if spotlight_on:
			# Aquí podrías guardar el material en una variable si necesitas reasignarlo
			pass 
		else:
			mesh_node.material_overlay = null
