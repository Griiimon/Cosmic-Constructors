class_name PropertyViewerPanel
extends PanelContainer

@export var ROW_SCENE: PackedScene

@onready var content_container: VBoxContainer = %"VBoxContainer Content"

var grid: BlockGrid
var block: GridBlock
var block_instance: BlockInstance

var rows: Array[PanelViewerRow]

var selected_row: int= -1:
	set(i):
		if selected_row > -1:
			rows[selected_row].deselect()
		selected_row= i
		rows[selected_row].select_type() 

var is_value_selected: bool= false:
	set(b):
		if is_value_selected and not b:
			rows[selected_row].deselect_value()
		is_value_selected= b
		if is_value_selected:
			rows[selected_row].select_value()



func populate():
	Utils.free_children(content_container)
	selected_row= -1
	is_value_selected= false
	rows.clear()
	
	for property in block_instance.get_properties():
		var row: PanelViewerRow= ROW_SCENE.instantiate()
		row.property= property
		add_child(row)
		if selected_row == -1:
			selected_row= 0


func open(_block: GridBlock, _grid: BlockGrid):
	grid= _grid
	block= _block
	
	block_instance= block.get_block_instance()
	if not block_instance: return
	
	populate()


func close():
	hide()


func update(_block: GridBlock, _grid: BlockGrid= null):
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


func _unhandled_input(event: InputEvent) -> void:
	assert(visible)
	
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				selected_row= wrapi(selected_row - 1, 0, rows.size())
			elif event.button == MOUSE_BUTTON_WHEEL_DOWN:
				selected_row= wrapi(selected_row + 1, 0, rows.size())
	
