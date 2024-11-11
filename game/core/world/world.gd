class_name World
extends Node3D

const SAVE_FILE_NAME= "user://world.json"

var grids: Node
var projectiles: Node
var grid_freeze_state:= false


func _ready() -> void:
	grids= generate_sub_node("Grids")
	projectiles= generate_sub_node("Projectiles")


func generate_sub_node(node_name: String)-> Node:
	var node:= Node.new()
	node.name= node_name
	add_child(node)
	return node


func add_grid(pos: Vector3, rot: Vector3= Vector3.ZERO)-> BlockGrid:
	var grid:= BlockGrid.new()
	grid.position= pos
	grid.rotation= rot
	grid.world= self
	grids.add_child(grid)
	
	grid.freeze= grid_freeze_state
	
	return grid


func save_world():
	var save_file: FileAccess = FileAccess.open(SAVE_FILE_NAME, FileAccess.WRITE)
	for grid: BlockGrid in grids.get_children():
		var json_string = JSON.stringify(grid.serialize())
		save_file.store_line(json_string)
	save_file.close()


func load_world():
	if not FileAccess.file_exists(SAVE_FILE_NAME):
		return

	var save_file = FileAccess.open(SAVE_FILE_NAME, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		var json = JSON.new()

		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		var grid_data = json.data

		var grid: BlockGrid= BlockGrid.deserialize(grid_data, self)

		grid.update_properties()


func add_projectile(projectile: ProjectileObject):
	projectiles.add_child(projectile)


func freeze_grids(b: bool):
	grid_freeze_state= b
	for grid: BlockGrid in grids.get_children():
		grid.freeze= b
