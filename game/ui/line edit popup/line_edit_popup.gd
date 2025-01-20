class_name LineEditPopup
extends PopupPanel

@onready var line_edit: LineEdit = %LineEdit

var callback: Callable
var previous_mouse_mode: Input.MouseMode



func open(_title: String, _callback: Callable):
	title= _title
	callback= _callback
	show()
	line_edit.grab_click_focus()
	previous_mouse_mode= Input.mouse_mode
	Input.mouse_mode= Input.MOUSE_MODE_VISIBLE


func _on_button_ok_pressed(new_text: String= "") -> void:
	hide()
	Input.mouse_mode= previous_mouse_mode
	callback.call(line_edit.text)
