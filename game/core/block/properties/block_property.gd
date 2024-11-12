class_name BlockProperty

var callback: Callable


func _init(_callback= null) -> void:
	if _callback:
		callback= _callback
	do_callback.call_deferred()


func do_callback():
	if callback:
		callback.call()


func get_value_f()-> float:
	return 0.0


func toggle():
	do_callback()


func increase():
	do_callback()


func decrease():
	do_callback()


func set_variant(val: Variant):
	pass


func change_step_size():
	pass


func is_true()-> bool:
	return false


func get_as_text()-> String:
	return ""
