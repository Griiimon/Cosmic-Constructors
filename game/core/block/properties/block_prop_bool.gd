class_name BlockPropBool
extends BlockProperty

var b: bool= false



func _init(_b: bool= false, _callback= null):
	super(_callback)
	b= _b


func toggle():
	b= not b
	super()


func is_true()-> bool:
	return b


func set_true():
	if not b:
		toggle()


func set_false():
	if b:
		toggle()


func get_as_text()-> String:
	return "On" if b else "Off"
