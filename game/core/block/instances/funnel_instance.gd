extends TubeGroupMemberInstance

@onready var gather_area: Area3D = $"Gather Area"
@onready var fluid_container: FluidContainer = $"Fluid Container"



func _on_gather_area_body_entered(body: Node3D) -> void:
	var drop: FluidDrop= body
	
	if not fluid_container.fluid or fluid_container.fluid == drop.fluid:
		if not fluid_container.is_full():
			fluid_container.fill(drop.amount, drop.fluid)
			drop.queue_free()


func is_input()-> bool:
	return true
