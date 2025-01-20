class_name ScrollSelectionPanel
extends PanelContainer


@export var ROW_SCENE: PackedScene

@onready var content_container: VBoxContainer = %"VBoxContainer Content"
@onready var update_interval: Timer = $"Update Interval"


var rows: Array[ScrollSelectionRow]

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


func populate():
	clear()
	pass


func clear():
	Utils.free_children(content_container)
	selected_row= -1
	is_value_selected= false
	rows.clear()


func add_row(type: String= "", value: String= "")-> ScrollSelectionRow:
	var row: ScrollSelectionRow= ROW_SCENE.instantiate()
	content_container.add_child(row)
	row.label_type.text= type
	row.label_value.text= value

	rows.append(row)
	return row


func open(_block: GridBlock= null, _grid: BlockGrid= null):
	populate()
	show()


func close():
	hide()
	update_interval.stop()


func _gui_input(event: InputEvent) -> void:
	_unhandled_input(event)


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
						if selected_row > -1 and get_current_row().can_select():
							if get_current_row().can_toggle():
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
		if event.pressed:
			match event.keycode:
				KEY_PAGEUP:
					change_row(-1)
					get_viewport().set_input_as_handled()
				KEY_PAGEDOWN:
					change_row(1)
					get_viewport().set_input_as_handled()


func change_row(delta: int):
	selected_row= wrapi(selected_row + delta, 0, rows.size())
	

func get_current_row()-> ScrollSelectionRow:
	assert(selected_row < rows.size(), "row %d vs size %d" % [selected_row, rows.size()])
	return rows[selected_row]


func _on_update_interval_timeout() -> void:
	populate()
