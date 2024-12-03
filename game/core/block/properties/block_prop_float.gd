class_name BlockPropFloat
extends BlockProperty

enum ToggleBehavior { FLIP, INCREASE, DECREASE }

var f: float= 0.0
var toggle_behavior: ToggleBehavior
var step_size: float= 0.01
var range= null



func _init(_name: String, _f: float= 0.0, _callback= null):
	super(_name, _callback)
	f= _f


func get_value_f()-> float:
	return f


func toggle():
	match toggle_behavior:
		ToggleBehavior.FLIP:
			f= -f
		ToggleBehavior.INCREASE:
			f+= step_size
		ToggleBehavior.DECREASE:
			f-= step_size
	
	if range:
		f= clamp(f, (range as Vector2).x, (range as Vector2).y)
	
	super()


func set_variant(val: Variant):
	f= val


func is_true()-> bool:
	return not is_zero_approx(f)


func set_toggle_behavior(behavior: ToggleBehavior):
	toggle_behavior= behavior
	return self


func set_step_size(step: float):
	step_size= step
	return self


func set_range(min_range: float, max_range: float):
	range= Vector2(min_range, max_range)
	return self


func get_value_as_text()-> String:
	return "%.4f" % f
