class_name ProjectileInstance
extends RigidBody3D

var projectile: Projectile



func _ready() -> void:
	collision_layer= Global.PROJECTILE_COLLISION_LAYER
	continuous_cd= true
	contact_monitor= true
	max_contacts_reported= 1
	
	body_shape_entered.connect(on_body_shape_entered)


func on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int):
	if body is BlockGrid:
		var grid: BlockGrid= body
		grid.take_damage_at_shape(projectile.max_damage, body_shape_index)
