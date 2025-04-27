extends BaseSandbox



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton: 
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				#var collider= player.terrain_raycast.get_collider()
				#if collider:
					#var terrain: BaseTerrainComponent= BaseTerrainComponent.get_terrain(collider)
					#if terrain:
						#terrain.mine(player.terrain_raycast.get_collision_point() + player.get_look_vec() * 0.1, 1)
						#DebugHud.send("Terrain ray collision", player.terrain_raycast.get_collision_point())
				var terrain: VoxelTerrain= Global.terrain.terrain_node
				var hit: VoxelRaycastResult= terrain.get_voxel_tool().raycast(player.head.global_position, player.get_look_vec(), 5)
				if hit:
					Global.terrain.mine(hit.position, 1)
