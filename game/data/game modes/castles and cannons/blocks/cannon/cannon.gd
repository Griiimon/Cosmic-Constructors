extends BlockInstance

@export var cannonball_scene: PackedScene

@onready var hor_rotation: BlockPropFloat= BlockPropFloat.new("Hor. Rotation", 0.0, on_horizontal_rotation).set_range(-45, 45).client_side_callback()
@onready var ver_rotation: BlockPropFloat= BlockPropFloat.new("Ver. Rotation", 30.0, on_vertical_rotation).set_range(-10, 85).client_side_callback()
@onready var power: BlockPropFloat= BlockPropFloat.new("Power", 50.0).set_range(10, 100).set_step_size(0.5)

@onready var projectiles: BlockPropInt= BlockPropInt.new("Projectiles", 5).read_only()
@onready var powder: BlockPropInt= BlockPropInt.new("Powder", 1000).read_only()

@onready var rotor: MeshInstance3D = %Rotor
@onready var barrel: MeshInstance3D = %Barrel
@onready var muzzle: Node3D = %Muzzle



func interact(grid: BlockGrid, grid_block: GridBlock, _player: Player):
	run_server_method(shoot, grid, grid_block, [ (grid_block.block_definition as CannonBlock).recoil_impulse ])


func shoot(grid: BlockGrid, grid_block: GridBlock, recoil: float):
	assert(not NetworkManager.is_client)
	if not projectiles.is_true() or powder.get_value_f() < power.get_value_f():
		return

	grid.world.spawn_object(cannonball_scene, muzzle.global_position, Vector3.ZERO, -power.get_value_f() * muzzle.global_basis.z)
	grid.apply_impulse(global_basis.z * recoil, global_position - get_grid().global_position)
	projectiles.set_variant(grid, grid_block, projectiles.get_value_i() - 1)
	powder.set_variant(grid, grid_block, powder.get_value_f() - power.get_value_f())


func on_horizontal_rotation():
	rotor.rotation_degrees.y= hor_rotation.get_value_f()


func on_vertical_rotation():
	barrel.rotation_degrees.x= ver_rotation.get_value_f() - 90
	
