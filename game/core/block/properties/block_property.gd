class_name BlockProperty

var callback: Callable
var display_name: String
var owner: BlockInstance
var is_locked: bool= false



func _init(_name: String, _callback= null, instant_callback: bool= true, _owner: BlockInstance= null) -> void:
	display_name= _name
	owner= _owner
	
	if _callback:
		callback= _callback
	if instant_callback:
		do_callback.call_deferred()


func do_callback():
	if callback:
		callback.call()


func get_value_f()-> float:
	return 0.0


func get_value_i()-> int:
	return 0


func toggle():
	do_callback()


func increase(_modifier: int):
	do_callback()


func decrease(_modifier: int):
	do_callback()


func change_value(_modifier: int, _delta: int):
	do_callback()


func set_variant(_val: Variant):
	do_callback()


func change_step_size():
	pass


func is_true()-> bool:
	return false


func get_as_text()-> String:
	return display_name + ": " + get_value_as_text()


func get_value_as_text()-> String:
	return ""
