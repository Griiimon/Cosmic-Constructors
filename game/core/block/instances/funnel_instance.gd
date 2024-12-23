extends BlockInstance

@onready var gather_area: Area3D = $"Gather Area"
@onready var fluid_container: FluidContainer = $"Fluid Container"


func _on_gather_area_body_entered(body: Node3D) -> void:
	fluid_container.fill(1)
