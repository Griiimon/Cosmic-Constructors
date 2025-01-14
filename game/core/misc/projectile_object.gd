class_name ProjectileObject
extends Node3D

@export var shape: Shape3D

var world: World
var projectile_definition: Projectile
var velocity: Vector3
var shapecast: ShapeCast3D



func _ready() -> void:
	shapecast= ShapeCast3D.new()
	shapecast.shape= shape
	shapecast.collision_mask= Global.PLAYER_COLLISION_LAYER + Global.GRID_COLLISION_LAYER + Global.TERRAIN_COLLISION_LAYER
	shapecast.top_level= true
	add_child(shapecast)


func _physics_process(delta: float) -> void:
	var old_pos: Vector3= global_position
	global_position+= velocity * delta
	
	shapecast.position= old_pos
	shapecast.target_position= shapecast.to_local(global_position)
	shapecast.force_shapecast_update()
	if shapecast.is_colliding():
		var collider: Node3D= shapecast.get_collider(0)
		#if collider.is_in_group(DamageComponent.GROUP_NAME):
			#var damage_component: DamageComponent= DamageComponent.get_component(collider)
#
			#var dmg: Damage= Damage.create_instance(projectile_definition.damage, velocity.normalized(), Damage.SourceType.PROJECTILE)
			#dmg.shape_index= shapecast.get_collider_shape(0)
#
			#damage_component.take_damage(dmg)
	
		var damage: Damage= Damage.create_instance(projectile_definition.damage, shapecast.get_collision_point(0), velocity.normalized(), Damage.SourceType.PROJECTILE)
		damage.shape_index= shapecast.get_collider_shape(0)
		#world.damage_object(collider, damage)
		world.damage_point(damage, collider)
		
		queue_free()
