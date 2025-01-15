class_name PropertyViewerPanel
extends PanelContainer

class ExtraProperty:
	var text: String
	var value: Variant

	func _init(_text: String, _value):
		text= _text
		value= _value

	func get_value_as_text()-> String:
		return ("%.4f" % value) if value is float else value


@export var ROW_SCENE: PackedScene

@onready var content_container: VBoxContainer = %"VBoxContainer Content"
@onready var update_interval: Timer = $"Update Interval"


var grid: BlockGrid
var block: GridBlock
var block_instance: BlockInstance
var initial_player_look: Vector3

var rows: Array[PanelViewerRow]

var selected_row: int= -1:
	set(i):
		if selected_row > -1:
			get_current_row().deselect()
		selected_row= i
		if selected_row == -1: return
		get_current_row().select_type() 

var is_value_selected: bool= false:
	set(b):
		if is_value_selected and not b:
			get_current_row().deselect_value()
		is_value_selected= b
		if is_value_selected:
			get_current_row().select_value()


func _process(_delta: float) -> void:
	if not visible: return
	
	var global_block_pos: Vector3= grid.get_global_block_pos(block.local_pos)
	if get_viewport().get_camera_3d().is_position_behind(global_block_pos):
		close()
		return
	
	if Global.player:
		if Global.player.get_look_vec().dot(initial_player_look) < 0.7:
			close()
			return

	
func populate():
	Utils.free_children(content_container)
	selected_row= -1
	is_value_selected= false
	rows.clear()

	add_row("Name", block.get_name(grid))
	
	for property: ExtraProperty in block_instance.get_extra_properties():
		var row: PanelViewerRow= add_row(property.text, property.get_value_as_text())
		row.label_type.modulate= Color.WHITE_SMOKE
		row.label_value.modulate= Color.WHITE_SMOKE
		if update_interval.is_stopped():
			update_interval.start()

	for property in block_instance.get_properties():
		var row: PanelViewerRow= add_row()
		row.property= property
		if selected_row == -1:
			selected_row= rows.size() - 1


func add_row(type: String= "", value: String= "")-> PanelViewerRow:
	var row: PanelViewerRow= ROW_SCENE.instantiate()
	content_container.add_child(row)
	row.label_type.text= type
	row.label_value.text= value

	rows.append(row)
	return row


func open(_block: GridBlock, _grid: BlockGrid):
	grid= _grid
	block= _block
	
	block_instance= block.get_block_instance()
	if not block_instance: return
	
	populate()
	show()


func close():
	hide()
	update_interval.stop()


func update(_block: GridBlock, _grid: BlockGrid, player: Player):
	if not _block: 
		close()
		return
		
	assert(_grid != null)
	
	if _block != block:
		open(_block, _grid)

	if not block_instance: 
		close()
		return

	var global_block_pos: Vector3= grid.get_global_block_pos(block.local_pos)
	var camera: Camera3D= get_viewport().get_camera_3d()

	if camera.is_position_behind(global_block_pos):
		close()
	else:
		position= camera.unproject_position(global_block_pos)
		show()
		initial_player_look= player.get_look_vec()


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	
	if event is InputEventMouseButton:
		if event.pressed:
			if is_value_selected:
				match event.button_index:
					MOUSE_BUTTON_LEFT:
						get_current_row().toggle()
						is_value_selected= false
					MOUSE_BUTTON_RIGHT:
						is_value_selected= false
					MOUSE_BUTTON_WHEEL_UP:
						get_current_row().change_value(-1)
					MOUSE_BUTTON_WHEEL_DOWN:
						get_current_row().change_value(1)
			else:
				match event.button_index:
					MOUSE_BUTTON_LEFT:
						if selected_row > -1:
							if get_current_row().property is BlockPropAction:
								get_current_row().toggle()
							else:
								is_value_selected= true
					MOUSE_BUTTON_RIGHT:
						close()
					MOUSE_BUTTON_WHEEL_UP:
						change_row(-1)
					MOUSE_BUTTON_WHEEL_DOWN:
						change_row(1)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var row: PanelViewerRow= get_current_row()
			if can_assign_hotkey_to(row):
				var key: int= event.keycode - KEY_0
				var assignment: BaseHotkeyAssignment= HotkeyAssignmentBlockProperty.new(key, block, row.property, grid)
				grid.assign_hotkey(assignment, block.local_pos) 
				SignalManager.hotkey_assigned.emit(assignment, grid)
		get_viewport().set_input_as_handled()


func change_row(delta: int):
	selected_row= wrapi(selected_row + delta, 0, rows.size())
	if not get_current_row().property:
		#TODO guard against infinte loop
		change_row(delta)
	

func get_current_row()-> PanelViewerRow:
	assert(selected_row < rows.size(), "row %d vs size %d" % [selected_row, rows.size()])
	return rows[selected_row]


func _on_update_interval_timeout() -> void:
	populate()


func can_assign_hotkey_to(row: PanelViewerRow)-> bool:
	return row.property != null
