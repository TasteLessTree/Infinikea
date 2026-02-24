extends Node

signal inventory_changed
signal slot_selected(slot_index: int)
# signal item_drop(item)

@onready var ui: CanvasLayer = $UI

const HOTBAR_SIZE: int = 4
var hotbar: Array[ItemData]
var selected_slot: int = 1

func _init():
	for i in HOTBAR_SIZE:
		hotbar.append(null)

func add_item(item:  ItemData) -> bool:
	for i in HOTBAR_SIZE:
		if hotbar[i] == null:
			hotbar[i] = item
			inventory_changed.emit()
			select_slot(i)
			return true
	return false

func select_slot(index: int):
	# print(index)
	selected_slot = clamp(index, 0, HOTBAR_SIZE -1)
	slot_selected.emit(selected_slot)

func remove_item(pos: int) -> void:
	hotbar[pos] = null
	inventory_changed.emit()

func clear_inventory() -> void:
	for i in HOTBAR_SIZE:
		hotbar[i] = null
	selected_slot = 1
	inventory_changed.emit()

func save_inventory() -> Array:
	var save_path = []
	for item in hotbar:
		if item != null:
			save_path.append(item.resource_path)
		else:
			save_path.append("")
	return save_path

func load_inventory(items_data: Array) -> void:
	clear_inventory()
	for i in range(items_data.size()):
		if i >= HOTBAR_SIZE:
			break

		var item_path = items_data[i]

		if item_path is String and item_path != "":
			var resource = load(item_path)
			if resource:
				hotbar[i] = resource
			else:
				push_error("El recurso en " + item_path + " no es de tipo ItemData")
				hotbar[i] = null
		else:
			hotbar[i] = null

	inventory_changed.emit()

func hide_inventory():
	ui.visible = false

func show_inventory():
	ui.visible = true
