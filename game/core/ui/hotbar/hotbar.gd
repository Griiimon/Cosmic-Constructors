class_name Hotbar
extends Control

@onready var hbox_slots: HBoxContainer = %HBoxContainer
@onready var mouse_control: Control = %"Mouse Control"
@onready var mouse_texture: TextureRect = %"Mouse Texture"

var slots: Array[HotbarSlot]
var current_layout: HotbarLayout

var mouse_mode: bool= false:
	set(b):
		mouse_mode= b
		if not is_inside_tree(): return
		mouse_control.visible= b

var mouse_control_assignment: HotkeyAssignmentBlockProperty



func _ready() -> void:
	for child in hbox_slots.get_children():
		slots.append(child)

	#SignalManager.player_seated.connect(populate_slots_from_seat)
	#SignalManager.player_left_seat.connect(populate_slots_from_player)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("hotbar_mouse_mode"):
			mouse_mode= not mouse_mode
		elif event.pressed:
			if event.keycode >= KEY_1 and event.keycode <= KEY_9:
				select_slot(event.keycode - KEY_1)

	elif mouse_mode and mouse_control_assignment:
		if event is InputEventMouseMotion:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				var mouse_pos_x: float= mouse_texture.anchor_left
				mouse_pos_x= clampf(mouse_pos_x + event.relative.x * 0.005 * GameData.get_mouse_sensitivity(), 0.0, 1.0)
				mouse_texture.anchor_left= mouse_pos_x
				mouse_texture.anchor_right= mouse_pos_x
				
				var grid: BlockGrid= mouse_control_assignment.get_grid(Global.world)
				var grid_block: GridBlock= grid.get_block_local(mouse_control_assignment.block_pos)
				mouse_control_assignment.property.set_variant(grid, grid_block, pow((mouse_pos_x * 2 - 1) * 3, 3))
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton:
			if event.pressed:
				if event.button_index == MOUSE_BUTTON_RIGHT:
					var grid: BlockGrid= mouse_control_assignment.get_grid(Global.world)
					var grid_block: GridBlock= grid.get_block_local(mouse_control_assignment.block_pos)
					mouse_control_assignment.property.set_variant(grid, grid_block, 0.0)

					mouse_texture.anchor_left= 0.5
					mouse_texture.anchor_right= 0.5
					get_viewport().set_input_as_handled()
		#get_viewport().set_input_as_handled()


func select_slot(idx: int):
	var slot: HotbarSlot= slots[idx]
	slot.select(self)


#func populate_slots_from_seat(grid: BlockGrid, grid_block: GridBlock):
	#var seat: SeatInstance= grid_block.get_block_instance()
	#
	#for i in 9:
		#populate_slot(i, seat.hotkeys[i + 1] if seat.hotkeys.has(i + 1) else null, grid)
#
#
#func populate_slots_from_player(player: Player):
	#clear()


func populate_slot(idx: int, assignment: BaseHotkeyAssignment, grid: BlockGrid):
	slots[idx].assign(assignment, null, grid)


func switch_layout(layout: HotbarLayout):
	current_layout= layout
	update_layout()


func update_layout():
	for i in slots.size():
		var slot: HotbarSlot= slots[i]
		slot.assign(current_layout.slots[i], null, current_layout.grid)


func start_mouse_control(assignment: HotkeyAssignmentBlockProperty):
	mouse_control_assignment= assignment


func cancel_mouse_control():
	mouse_control_assignment= null


func clear():
	for slot in slots:
		slot.label.text= ""
