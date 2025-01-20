class_name BlockPropEnum
extends BlockProperty

var enum_dict: Dictionary
var current_key: String



func _init(_name: String, _dict: Dictionary, _callback= null, instant_callback: bool= true, _owner: BlockInstance= null):
	super(_name, _callback, instant_callback, _owner)
	enum_dict= _dict


func get_value_i()-> int:
	return enum_dict[current_key]


func set_variant(val: Variant):
	assert(val is int)
	var index: int= enum_dict.values().find(int(val))
	assert(index != -1)
	current_key= enum_dict.keys()[index]


func toggle():
	if is_locked: return
	increase(1)
	

func increase(modifier: int):
	if is_locked: return
	change_value(modifier, 1)


func decrease(modifier: int):
	if is_locked: return
	change_value(modifier, -1)


func change_value(modifier: int, delta: int):
	current_key= enum_dict.keys()[wrapi(enum_dict.keys().find(current_key) + delta, 0, enum_dict.keys().size())]
	super(modifier, delta)


func get_value_as_text()-> String:
	return current_key
