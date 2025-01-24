class_name PropertyViewerPanel
extends ScrollSelectionPanel

#class ExtraProperty:
	#var text: String
	#var value: Variant
#
	#func _init(_text: String, _value):
		#text= _text
		#value= _value
#
	#func get_value_as_text()-> String:
		#return ("%.4f" % value) if value is float else value


var grid: BlockGrid
var block: GridBlock
var block_instance: BlockInstance
var initial_player_look: Vector3



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
	var stored_row: int= selected_row
	var stored_value_selected: bool= is_value_selected
	selected_row= -1
	is_value_selected= false
	rows.clear()

	add_row("Name", block.get_name(grid))
	
	#for property: ExtraProperty in block_instance.get_extra_properties():
		#var row: PropertyViewerRow= add_row(property.text, property.get_value_as_text())
		#row.label_type.modulate= Color.WHITE_SMOKE
		#row.label_value.modulate= Color.WHITE_SMOKE
		#if update_interval.is_stopped():
			#update_interval.start()

	for property in block_instance.get_properties():
		var row: PropertyViewerRow= add_row()
		row.property= property
		if property.is_read_only:
			row.property= null
		else:
			row.grid= grid
			row.grid_block= block
			if selected_row == -1:
				selected_row= rows.size() - 1

	if stored_row > -1:
		selected_row= stored_row
		is_value_selected= stored_value_selected

	if block_instance.requires_property_viewer_updates():
		if update_interval.is_stopped():
			update_interval.start()


func open(_block: GridBlock= null, _grid: BlockGrid= null):
	assert(_grid and _block)
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
		open(_block, _grid)
		initial_player_look= player.get_look_vec()


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	super(event)
	
	if event is InputEventKey:
		if event.pressed:
			if event.keycode >= KEY_1 and event.keycode <= KEY_9:
				var row: PropertyViewerRow= get_current_row()
				if can_assign_hotkey_to(row):
					var key: int= event.keycode - KEY_0
					var assignment: BaseHotkeyAssignment= HotkeyAssignmentBlockProperty.new(key, block, row.property, grid)
					grid.assign_hotkey(assignment, block.local_pos) 
					SignalManager.hotkey_assigned.emit(assignment, grid)


		get_viewport().set_input_as_handled()


func change_row(delta: int):
	super(delta)
	if not get_current_row().property:
		if not has_any_property_row():
			return
		change_row(delta)


func has_any_property_row()-> bool:
	for row in rows:
		if (row as PropertyViewerRow).property:
			return true
	return false


func can_assign_hotkey_to(row: PropertyViewerRow)-> bool:
	return row.property != null
