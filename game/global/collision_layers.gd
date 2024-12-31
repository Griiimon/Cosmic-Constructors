extends Node

const PLAYER= 1
const GRID= 2
const TERRAIN= 4
const PROJECTILE= 8
const PHYSICAL_OBJECTS= 16
const PERIPHERAL_GRID_ENTITIES= 32
const WORLD_ITEM= 64
const ROPE= 512



func get_all_body_layers()-> int:
	return PLAYER + GRID + PHYSICAL_OBJECTS + PERIPHERAL_GRID_ENTITIES + WORLD_ITEM + ROPE
