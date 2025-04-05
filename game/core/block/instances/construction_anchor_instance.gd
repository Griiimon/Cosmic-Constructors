extends BlockInstance


@onready var release:= BlockPropAction.new("Release", drop)
@onready var horizontal_offset: BlockPropFloat= BlockPropFloat.new("Horizontal", 0.0, on_offset_changed).set_step_size(1).disable_toggle()
@onready var vertical_offset: BlockPropFloat= BlockPropFloat.new("Vertical", 0.0, on_offset_changed).set_step_size(1).disable_toggle()
@onready var depth_offset: BlockPropFloat= BlockPropFloat.new("Depth", 0.0, on_offset_changed).set_step_size(1).disable_toggle()

@onready var area: Area3D = $Area3D

var grid: BlockGrid
var original_offset: Vector3



func _ready() -> void:
	default_interaction_property= release


func on_placed_client(_grid: BlockGrid, _grid_block: GridBlock):
	area.queue_free()


func on_update(grid: BlockGrid, grid_block: GridBlock):
	assert(not NetworkManager.is_client)
	reset(grid, grid_block)


func on_offset_changed():
	assert(not NetworkManager.is_client)
	if not grid: return
	var new_offset:=  Vector3(horizontal_offset.get_value_f(), vertical_offset.get_value_f(), depth_offset.get_value_f()) * global_transform.basis
	DebugHud.send("New Offset", new_offset)
	grid.position= original_offset + new_offset


func reset(grid: BlockGrid, grid_block: GridBlock):
	horizontal_offset.set_variant(grid, grid_block, 0.0)
	vertical_offset.set_variant(grid, grid_block, 0.0)
	depth_offset.set_variant(grid, grid_block, 0.0)


func _on_area_body_entered(body: Node3D) -> void:
	assert(not NetworkManager.is_client)
	assert(body is BlockGrid)
	
	if grid: return
	
	reset(get_grid(), get_grid_block())

	grid= body
	
	if grid.is_sub_grid(): return
	if grid.is_anchored: return
	
	grid.freeze= true
	original_offset= grid.position


func _on_area_body_exited(body: Node3D) -> void:
	if body == grid:
		drop()


func drop():
	assert(not NetworkManager.is_client)
	if not grid: return
	grid.freeze= false
	grid= null
