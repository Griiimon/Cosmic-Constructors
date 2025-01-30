class_name PlayerActionStateMachineState
extends PlayerStateMachineState

@export var input_mappings: Dictionary

var ghost: Node3D



func interaction_logic():
	if Input.is_action_just_pressed("block_interact"):
		var shapecast: ShapeCast3D= player.interact_shapecast
		if shapecast.is_colliding():
			var grid: BlockGrid= shapecast.get_collider(0)
			assert(grid)
			var collision_pos: Vector3= shapecast.get_collision_point(0)
			collision_pos-= shapecast.global_basis.z * 0.01
			
			var grid_block: BaseGridBlock= grid.get_block_from_global_pos(collision_pos)
			if grid_block:
				if grid_block.get_block_definition().can_interact() and grid_block.get_block_instance().can_interact(grid, grid_block, player):
					grid_block.get_block_instance().interact(grid, grid_block, player)
					return
	
	if Input.is_action_just_pressed("item_interact"):
		var shapecast: ShapeCast3D= player.item_interact_shapecast
		if shapecast.is_colliding():
			var collider: PhysicsBody3D= shapecast.get_collider(0)
			if collider is WorldItemInstance:
				var item: WorldItemInstance= collider
				(get_state_machine() as PlayerActionStateMachine).pick_up_item(item)
			else:
				var ore_pile: OrePile= collider.get_parent()
				assert(ore_pile)
				var item_instance: WorldItemInstance= ore_pile.drop_item(player.world)
				player.action_state_machine.pick_up_item(item_instance)
			return

	if Input.is_action_just_pressed("pull"):
		var shapecast: ShapeCast3D= player.pull_shapecast
		if shapecast.is_colliding():
			var collider: PhysicsBody3D= shapecast.get_collider(0)
			player.action_state_machine.pull(BaseComponent.get_from_node(collider, PullableComponent.NODE_NAME))
		return


func init_ghost(model: Node3D):
	
	if ghost:
		remove_ghost()

	ghost= model
	ghost.set_script(null)
	
	var mesh_instances: Array= ghost.find_children("*")
	if ghost is MeshInstance3D:
		mesh_instances.append(ghost)
	
	for child: Node in mesh_instances:
		child.set_script(null)
		if child is not MeshInstance3D and not child.is_in_group(Groups.KEEP_GHOST_GROUP):
			child.queue_free()
		else:
			if child is not MeshInstance3D: continue
			
			var mesh_instance: MeshInstance3D= child
			var old_material: Material= mesh_instance.mesh.surface_get_material(0)
			var new_material: StandardMaterial3D
			if not old_material or old_material is ShaderMaterial or child.is_in_group(Groups.OVERWRITE_MATERIAL_GROUP):
				new_material= StandardMaterial3D.new()
			else:
				new_material= old_material.duplicate()
				
			new_material.albedo_color= Color.SKY_BLUE
			new_material.albedo_color.a= 0.7
			
			new_material.metallic= 0
			new_material.roughness= 1
			
			mesh_instance.mesh= mesh_instance.mesh.duplicate()
			mesh_instance.mesh.surface_set_material(0, new_material)
			
			#material.transparency= BaseMaterial3D.TRANSPARENCY_ALPHA
			#material.albedo_color.a= 0.8

	add_child(ghost)
	ghost.top_level= true

	ghost.hide()


func remove_ghost():
	if not ghost: return
	remove_child(ghost)
	ghost.queue_free()
	ghost= null
