extends Node

signal inventory_changed
signal slot_selected(slot_index: int)
# signal item_drop(item)

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
