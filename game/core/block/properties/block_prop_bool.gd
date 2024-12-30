class_name BlockPropBool
extends BlockProperty

var b: bool= false



func _init(_name: String, _b: bool= false, _callback= null, instant_callback: bool= true, _owner: GridBlock= null):
	super(_name, _callback, instant_callback, _owner)
	b= _b


func get_value_i()-> int:
	return 1 if is_true() else 0


func toggle():
	b= not b
	super()


func increase(_modifier: int):
	toggle()


func decrease(_modifier: int):
	toggle()


func change_value(_modifier: int, _delta: int):
	toggle()
	

func set_variant(val: Variant):
	b= val
	super(val)


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
