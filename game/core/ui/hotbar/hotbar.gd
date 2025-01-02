class_name Hotbar
extends Control

@onready var hbox_slots: HBoxContainer = %HBoxContainer
@onready var mouse_control: Control = %"Mouse Control"
@onready var mouse_texture: TextureRect = %"Mouse Texture"

var slots: Array[HotbarSlot]

var mouse_mode: bool= false:
	set(b):
		mouse_mode= b
		if not is_inside_tree(): return
		mouse_control.visible= b

var mouse_control_property: BlockProperty



func _ready() -> void:
	for child in hbox_slots.get_children():
		slots.append(child)

	SignalManager.player_seated.connect(populate_slots_from_seat)
	SignalManager.player_left_seat.connect(populate_slots_from_player)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("hotbar_mouse_mode"):
			mouse_mode= not mouse_mode
		elif event.pressed:
			if event.keycode >= KEY_1 and event.keycode <= KEY_9:
				select_slot(event.keycode - KEY_1)

	elif event is InputEventMouseMotion:
		if mouse_mode and mouse_control_property:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				var mouse_pos_x: float= mouse_texture.anchor_left
				mouse_pos_x= clampf(mouse_pos_x + event.relative.x * 0.005, 0.0, 1.0)
				mouse_texture.anchor_left= mouse_pos_x
				mouse_texture.anchor_right= mouse_pos_x
				mouse_control_property.set_variant(pow((mouse_pos_x * 2 - 1) * 3, 3))
				get_viewport().set_input_as_handled()
		

func select_slot(idx: int):
	var slot: HotbarSlot= slots[idx]
	slot.select(self)


func populate_slots_from_seat(grid: BlockGrid, grid_block: GridBlock):
	var seat: SeatInstance= grid_block.get_block_instance()
	
	for i in 9:
		populate_slot(i, seat.hotkeys[i + 1] if seat.hotkeys.has(i + 1) else null, grid)


func populate_slots_from_player(player: Player):
	clear()


func populate_slot(idx: int, assignment: BaseHotkeyAssignment, grid: BlockGrid):
	slots[idx].assign(assignment, grid)


func start_mouse_control(property: BlockProperty):
	mouse_control_property= property


func cancel_mouse_control():
	mouse_control_property= null


func clear():
	for slot in slots:
		slot.label.text= ""
