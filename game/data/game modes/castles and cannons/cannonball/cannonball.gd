extends ObjectEntity

@export var damage: Damage



func _physics_process(delta: float) -> void:
	if global_position.y < -1000:
		destroy()


func _on_body_entered(body: Node) -> void:
	get_world().explosion(damage, body)
	destroy()
