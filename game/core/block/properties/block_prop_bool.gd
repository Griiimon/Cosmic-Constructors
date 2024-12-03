class_name BlockPropBool
extends BlockProperty

var b: bool= false



func _init(_name: String, _b: bool= false, _callback= null):
	super(_name, _callback)
	b= _b


func toggle():
	b= not b
	super()


func set_variant(val: Variant):
	b= val


func is_true()-> bool:
	return b


func set_true():
	if not b:
		toggle()


func set_false():
	if b:
		toggle()


func get_value_as_text()-> String:
	return "On" if b else "Off"
