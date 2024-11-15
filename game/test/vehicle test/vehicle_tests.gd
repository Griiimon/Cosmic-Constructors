extends Node

@export var world_name= "vehicle test"
@export var load_world: bool= false
@export var remove_asteroid:= false

@onready var game: Game= get_parent()

var player: Player

var collected_resources: Dictionary



func _ready() -> void:
	await game.ready

	player= game.player

	if load_world:
		Global.game.world.load_world(world_name)
	else:

		var default_block= load("res://game/data/blocks/light structure/light_structure_block.tres")

		var grid: BlockGrid= Global.game.world.add_grid(Vector3(0, 5, 0))

		for x in range(-4, 5):
			for z in 11:
				grid.add_block(default_block, Vector3i(x, 0, -z))
		
		
	#player.action_state_machine.idle_state.equip_hand_item(load("res://game/data/hand items/tools/hand drill/hand_drill.tres"))
	#player.action_state_machine.idle_state.equip_hand_item(load("res://game/data/hand items/weapons/rocket launcher/rocket_launcher.tres"))

	player.world.freeze_grids(true)
	

func _physics_process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed: 
			if event.keycode == KEY_F2:
				player.world.freeze_grids(false)
			elif event.keycode == KEY_F5:
				player.world.save_world(world_name)

			else:
				var switch_block: int= Input.get_axis("next_block", "previous_block")
				
				if switch_block:
					var build_state: PlayerBuildState= player.action_state_machine.build_state
					var blocks: Array[Block]= GameData.block_library.blocks
					var block_index= blocks.find(build_state.current_block)

					block_index= wrapi(block_index + switch_block, 0, blocks.size())
					build_state.current_block= blocks[block_index]

					while not build_state.current_block.can_be_built:
						block_index= wrapi(block_index + switch_block, 0, blocks.size())
						build_state.current_block= blocks[block_index]
					
					SignalManager.build_block_changed.emit(build_state.current_block)
					
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var query:= PhysicsRayQueryParameters3D.create(player.head.global_position, player.build_raycast.to_global(player.build_raycast.target_position))#, Global.GRID_COLLISION_LAYER)
			prints("Remove query", query.from, query.to)
			query.hit_back_faces= false
			query.hit_from_inside= false
			var result= player.get_world_3d().direct_space_state.intersect_ray(query)
			if result:
				var grid: BlockGrid= result.collider
				var collision_point: Vector3= result.position
				collision_point+= -player.build_raycast.global_basis.z * 0.05
				grid.get_block_from_global_pos(collision_point).destroy(grid)
