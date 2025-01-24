class_name BlockProperty

var callback: Callable
var display_name: String
var owner: BlockInstance
var is_locked: bool= false:
	get():
		if is_read_only: 
			return true
		return is_locked
		
var client_side: bool= false
var is_read_only: bool= false



func _init(_name: String, _callback= null, instant_callback: bool= true, _owner: BlockInstance= null) -> void:
	display_name= _name
	owner= _owner
	
	if _callback:
		callback= _callback
	if instant_callback:
		do_callback.call_deferred()


func client_side_callback():
	client_side= true
	return self


func read_only():
	is_read_only= true
	return self


func do_callback():
	if callback and (not NetworkManager.is_client or client_side):
		callback.call()


func get_value_f()-> float:
	return 0.0


func get_value_i()-> int:
	return 0


func toggle(grid: BlockGrid, grid_block: GridBlock, sync: bool= true):
	if sync: sync(grid, grid_block)
	do_callback()


func increase(grid: BlockGrid, grid_block: GridBlock, _modifier: int, sync: bool= true):
	do_callback()


func decrease(grid: BlockGrid, grid_block: GridBlock, _modifier: int, sync: bool= true):
	do_callback()


func change_value(grid: BlockGrid, grid_block: GridBlock, _modifier: int, _delta: int, sync: bool= true):
	do_callback()


func set_variant(grid: BlockGrid, grid_block: GridBlock, _val: Variant, sync: bool= true):
	do_callback()


func sync(grid: BlockGrid, grid_block: GridBlock):
	if NetworkManager.is_single_player: return
	if NetworkManager.is_client:
		ServerManager.receive_sync_event.rpc_id(1, EventSyncState.Type.CHANGE_BLOCK_PROPERTY, [grid.id, grid_block.local_pos, display_name, get_variant()])
	else:
		ServerManager.broadcast_sync_event(EventSyncState.Type.CHANGE_BLOCK_PROPERTY, [grid.id, grid_block.local_pos, display_name, get_variant()])


func change_step_size():
	pass


func get_variant()-> Variant:
	return null


func is_true()-> bool:
	return false


func get_as_text()-> String:
	return display_name + ": " + get_value_as_text()


func get_value_as_text()-> String:
	return ""
