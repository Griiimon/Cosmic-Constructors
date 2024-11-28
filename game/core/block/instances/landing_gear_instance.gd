class_name LandingGearInstance
extends BlockInstanceOnOff

@export var enabled_material: StandardMaterial3D
@export var locked_material: StandardMaterial3D
@export var disabled_material: StandardMaterial3D

@onready var area: Area3D = $Area3D
@onready var light: MeshInstance3D = $Light



func _ready() -> void:
	default_interaction_property= active
	active.set_true()


func physics_tick(grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	if active.is_true():
		if area.has_overlapping_bodies():
			grid.freeze= true
			light.mesh.surface_set_material(0, locked_material)
	else:
		grid.freeze= false


func on_set_active():
	var material: StandardMaterial3D= enabled_material if active.is_true() else disabled_material
	light.mesh.surface_set_material(0, material)
