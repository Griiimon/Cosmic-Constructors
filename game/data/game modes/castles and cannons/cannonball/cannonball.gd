extends ObjectEntity

@export var damage: Damage



func _physics_process(delta: float) -> void:
	if global_position.y < -1000:
		destroy()


func _on_body_entered(body: Node) -> void:
	var dmg: Damage= Damage.create_instance(damage, global_position, linear_velocity.normalized(), Damage.SourceType.PROJECTILE)
	get_world().damage_point(dmg, body)
	destroy()
