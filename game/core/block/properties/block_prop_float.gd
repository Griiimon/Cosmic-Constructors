class_name BlockPropFloat
extends BlockProperty

var f: float= 0.0



func _init(_f: float= 0.0, _callback= null):
	super(_callback)
	f= _f


func get_value_f()-> float:
	return f


func toggle():
	f= -f
	super()


func is_true()-> bool:
	return not is_zero_approx(f)