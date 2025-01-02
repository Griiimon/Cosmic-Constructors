class_name BlockPropFloat
extends BlockProperty

enum ToggleBehavior { FLIP, INCREASE, DECREASE }

var f: float= 0.0
var toggle_behavior: ToggleBehavior
var step_size: float= 0.01
var range= null
var can_toggle: bool= true



func _init(_name: String, _f: float= 0.0, _callback= null, instant_callback: bool= true, _owner: BlockInstance= null):
	super(_name, _callback, instant_callback, _owner)
	f= _f


func get_value_f()-> float:
	return f


func get_value_i()-> int:
	return round(f)


func toggle():
	if not can_toggle: return
	
	match toggle_behavior:
		ToggleBehavior.FLIP:
			f= -f
			super()
			return
		ToggleBehavior.INCREASE:
			increase(1)
		ToggleBehavior.DECREASE:
			decrease(1)
	
	if range:
		f= clamp(f, (range as Vector2).x, (range as Vector2).y)


func set_variant(val: Variant):
	f= val
	do_clamp()
	super(val)


func increase(modifier: int):
	change_value(modifier, 1)


func decrease(modifier: int):
	change_value(modifier, -1)


func change_value(modifier: int, delta: int):
	f+= step_size * modifier * delta
	do_clamp()
	super(modifier, delta)


func do_clamp():
	if range:
		f= clampf(f, range.x, range.y)


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


func disable_toggle():
	can_toggle= false
	return self


func get_value_as_text()-> String:
	return "%.4f" % f
