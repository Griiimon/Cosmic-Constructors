class_name BaseSandbox
extends Node

@export var remove_voxel_terrain:= false
@export var equip_item: HandItem
@export var load_world: bool= false
@export var project_folder_world: bool= true
@export var freeze_grids: bool= false
@export var custom_world_name: String= ""

@onready var game: Game= get_parent()

var player: Player
var default_block: Block

var collected_resources: Dictionary



func _ready() -> void:
	await game.ready
	
	if remove_voxel_terrain:
		var potential_terrains= game.find_children("*", "VoxelLodTerrain")
		var terrain: VoxelLodTerrain= potential_terrains[0]
		
		if terrain:
			terrain.queue_free()

	if NetworkManager.is_server:
		do_load_world()
	else:
		if game.player:
			on_player_spawned()
		else:
			SignalManager.player_spawned.connect(on_player_spawned)


func on_player_spawned():
	player= game.player

	default_block= load("res://game/data/blocks/light structure/light_structure_block.tres")
	
	if equip_item:
		player.equip_hand_item(equip_item)

	do_load_world()

	if freeze_grids and NetworkManager.is_single_player:
		player.world.freeze_grids(freeze_grids)

	on_start()


func do_load_world():
	if load_world and not NetworkManager.is_client: #NetworkManager.is_single_player:
		await get_tree().physics_frame
		# TODO
		#if Global.terrain:
			#while not Global.terrain.is_area_meshed(..):
				#await get_tree().physics_frame
		Global.game.world.load_world_from_file(custom_world_name, project_folder_world)
	

func on_start():
	pass


func _physics_process(_delta):
	if player:
		DebugHud.send("Gravity", "%.3f" % player.get_gravity().length())
		DebugHud.send("Velocity", "%.2f" % player.get_velocity().length())
		#DebugHud.send("Vel Vector", player.get_velocity())


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed: 
			if event.keycode == KEY_F2:
				spawn_pallet()
				#if not NetworkManager.is_client:
					#get_world().freeze_grids(false)
			elif event.keycode == KEY_F3:
				if player:
					#player.wear_equipment(load("res://game/data/equipment/back/jetpack/atmospheric_jetpack.tres"))
					#player.play_animation("wave")
					get_world().freeze_grids(false)
					#sit_in_nearest_seat()
			elif event.keycode == KEY_F4:
				DebugPanel.toggle()
			elif event.keycode == KEY_F5:
				if NetworkManager.is_client:
					ServerManager.request_save.rpc_id(1, custom_world_name, project_folder_world)
				else:
					get_world().save_world(custom_world_name, project_folder_world)
			elif event.keycode == KEY_F6:
				get_tree().debug_collisions_hint= not get_tree().debug_collisions_hint
			elif event.keycode == KEY_F7:
				player.get_parent().move_child(player, 1)
			elif event.keycode == KEY_F9:
				get_tree().reload_current_scene.call_deferred()
				return


func spawn_plain_grid(pos: Vector3, size: Vector2i, centered: bool= true):
	var grid: BlockGrid= Global.game.world.add_grid(pos)
	
	for x in size.x:
		for z in size.y:
			@warning_ignore("narrowing_conversion")
			grid.add_block(default_block, Vector3i(x, 0, z) - Vector3i(size.x / 2.0, 0, size.y / 2.0) / 2)


func sit_in_nearest_seat():
	if not player: return
	for grid: BlockGrid in player.world.grids.get_children():
		for block: BaseGridBlock in grid.get_blocks():
			if block.get_block_definition() is SeatBlock:
				player.sit(block.get_grid_block())
				return


func spawn_pallet():
	if not player: return
	var pallet: Pallet= load("res://game/data/object entities/wooden_pallet.tscn").instantiate()
	pallet.position= player.global_position + player.get_look_vec() + Vector3.UP
	player.world.add_child(pallet)


func get_world()-> World:
	return (get_parent() as Game).world
