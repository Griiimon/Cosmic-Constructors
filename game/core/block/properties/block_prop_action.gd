class_name BlockPropAction
extends BlockProperty




func _init(_name: String, _callback):
	super(_name, _callback, false)


func toggle():
	do_callback()

func increase(_modifier: int):
	toggle()


func decrease(_modifier: int):
	toggle()


func change_value(_modifier: int, _delta: int):
	toggle()


func get_value_as_text()-> String:
	return "ACTION"
