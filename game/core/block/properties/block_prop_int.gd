class_name BlockPropInt
extends BlockProperty

enum ToggleBehavior { FLIP, INCREASE, DECREASE }

var i: int= 0
var toggle_behavior: ToggleBehavior
var step_size: float= 1
var value_range= null
var can_toggle: bool= true



func _init(_name: String, _i: int= 0, _callback= null, instant_callback: bool= true, _owner: BlockInstance= null):
	super(_name, _callback, instant_callback, _owner)
	i= _i


func get_value_f()-> float:
	return i


func get_value_i()-> int:
	return i


func toggle(grid: BaseBlockGrid, grid_block: GridBlock, sync: bool= true):
	if is_locked: return
	if not can_toggle: return
	
	match toggle_behavior:
		ToggleBehavior.FLIP:
			i= -i
			super(grid, grid_block, sync)
			return
		ToggleBehavior.INCREASE:
			increase(grid, grid_block, 1, sync)
		ToggleBehavior.DECREASE:
			decrease(grid, grid_block, 1, sync)


func set_variant(grid: BaseBlockGrid, grid_block: GridBlock, val: Variant, sync: bool= true):
	i= val
	do_clamp()
	super(grid, grid_block, val, sync)


func increase(grid: BaseBlockGrid, grid_block: GridBlock, modifier: int, sync: bool= true):
	if is_locked: return
	change_value(grid, grid_block, modifier, 1, sync)


func decrease(grid: BaseBlockGrid, grid_block: GridBlock, modifier: int, sync: bool= true):
	if is_locked: return
	change_value(grid, grid_block, modifier, -1, sync)


func change_value(grid: BaseBlockGrid, grid_block: GridBlock, modifier: int, delta: int, sync: bool= true):
	if is_locked: return
	i+= step_size * modifier * delta
	do_clamp()
	super(grid, grid_block, modifier, delta, sync)


func do_clamp():
	if value_range:
		clampi(i, (value_range as Vector2i).x, (value_range as Vector2i).y)

func get_variant()-> Variant:
	return i


func is_true()-> bool:
	return i > 0


func set_toggle_behavior(behavior: ToggleBehavior):
	toggle_behavior= behavior
	return self


func set_step_size(step: float):
	step_size= step
	return self


func set_range(min_range: float, max_range: float):
	value_range= Vector2i(min_range, max_range)
	return self


func disable_toggle():
	can_toggle= false
	return self


func get_value_as_text()-> String:
	return str(i)
