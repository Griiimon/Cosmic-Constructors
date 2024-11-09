class_name BlockProperty

var callback: Callable


func _init(_callback= null) -> void:
	callback= _callback


func do_callback():
	if callback:
		callback.call()


func toggle():
	do_callback()


func increase():
	do_callback()


func decrease():
	do_callback()


func change_step_size():
	pass


func is_true()-> bool:
	return false
	
