class_name Hotbar
extends PanelContainer

@onready var hbox_slots: HBoxContainer = %HBoxContainer

var slots: Array[HotbarSlot]



func _ready() -> void:
	for child in hbox_slots.get_children():
		slots.append(child)

	SignalManager.player_seated.connect(populate_slots_from_seat)
	SignalManager.player_left_seat.connect(populate_slots_from_player)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.keycode >= KEY_1 and event.keycode <= KEY_9:
				select_slot(event.keycode - KEY_1)


func select_slot(idx: int):
	var slot: HotbarSlot= slots[idx]
	slot.select()


func populate_slots_from_seat(grid: BlockGrid, grid_block: GridBlock):
	var seat: SeatInstance= grid_block.get_block_instance()
	
	for i in 9:
		populate_slot(i, seat.hotkeys[i + 1] if seat.hotkeys.has(i + 1) else null, grid)


func populate_slots_from_player(player: Player):
	clear()


func populate_slot(idx: int, assignment: BaseHotkeyAssignment, grid: BlockGrid):
	slots[idx].assign(assignment, grid)


func clear():
	for slot in slots:
		slot.label.text= ""
