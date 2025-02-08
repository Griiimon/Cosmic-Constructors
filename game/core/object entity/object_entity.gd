class_name ObjectEntity
extends RigidBody3D

static var NEXT_ID: int= 0

var id: int



func _ready() -> void:
	if not NetworkManager.is_client:
		id= NEXT_ID
		NEXT_ID+= 1
	
	collision_layer= CollisionLayers.PHYSICAL_OBJECTS
	collision_mask= CollisionLayers.PLAYER + CollisionLayers.GRID + CollisionLayers.TERRAIN


func destroy():
	# TODO network sync
	if NetworkManager.is_server:
		ServerManager.broadcast_sync_event(EventSyncState.Type.DESTROY_OBJECT, [id])
	queue_free()


#func serialize()-> Dictionary:
	#return { "id": id, "pos": global_position, "rot": global_rotation }
#
#
#func deserialize(data: Dictionary):
	#id= data["id"]
	#position= data["pos"]
	#rotation= data["rot"]


func get_world()-> World:
	return get_parent().get_parent()
