extends Node

signal test_finished

@export var scenes: Array[PackedScene]



func _ready() -> void:
	late_ready.call_deferred()


func late_ready():
	reparent(get_tree().root)
	
	for scene in scenes:
		finish_test()
		get_tree().change_scene_to_packed.call_deferred(scene)
		
		await test_finished


func finish_test():
	await Global.get_tree().process_frame
	#while not Global.game or not Global.game.world:
		#await Global.get_tree().process_frame
	await Global.game.ready
		
	if Global.game.world.is_loading:
		await Global.game.world.finished_loading
	
	#await get_tree().create_timer(1).timeout
	test_finished.emit()
