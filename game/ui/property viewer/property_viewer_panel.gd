class_name PropertyViewerPanel
extends PanelContainer

@export var ROW_SCENE: PackedScene

@onready var content_container: VBoxContainer = %"VBoxContainer Content"

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
	
	for property in block_instance.get_properties():
		var row: PanelViewerRow= ROW_SCENE.instantiate()
		content_container.add_child(row)
		rows.append(row)
		row.property= property
		if selected_row == -1:
			selected_row= 0


func open(_block: GridBlock, _grid: BlockGrid):
	grid= _grid
	block= _block
	
	block_instance= block.get_block_instance()
	if not block_instance: return
	
	populate()
	show()


func close():
	hide()


func update(_block: GridBlock, _grid: BlockGrid, player: Player):
	if not _block: 
		hide()
		return
		
	assert(_grid != null)
	
	if _block != block:
		open(_block, _grid)

	if not block_instance: 
		hide()
		return

	var global_block_pos: Vector3= grid.get_global_block_pos(block.local_pos)
	var camera: Camera3D= get_viewport().get_camera_3d()

	if camera.is_position_behind(global_block_pos):
		hide()
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
					MOUSE_BUTTON_RIGHT:
						is_value_selected= false
					MOUSE_BUTTON_WHEEL_UP:
						get_current_row().change_value(-1)
					MOUSE_BUTTON_WHEEL_DOWN:
						get_current_row().change_value(1)
			else:
				match event.button_index:
					MOUSE_BUTTON_LEFT:
						is_value_selected= true
					MOUSE_BUTTON_RIGHT:
						close()
					MOUSE_BUTTON_WHEEL_UP:
						selected_row= wrapi(selected_row - 1, 0, rows.size())
					MOUSE_BUTTON_WHEEL_DOWN:
						selected_row= wrapi(selected_row + 1, 0, rows.size())


func get_current_row()-> PanelViewerRow:
	assert(selected_row < rows.size(), "row %d vs size %d" % [selected_row, rows.size()])
	return rows[selected_row]
