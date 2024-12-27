class_name Hotbar
extends PanelContainer

@onready var hbox_slots: HBoxContainer = %HBoxContainer

var slots: Array[HotbarSlot]



func _ready() -> void:
	for child in hbox_slots.get_children():
		slots.append(child)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.keycode >= KEY_1 and event.keycode <= KEY_9:
				select_slot(event.keycode - KEY_1)


func select_slot(idx: int):
	slots[idx].select()
