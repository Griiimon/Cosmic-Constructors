class_name ExplosionEffect
extends BaseEffect

var radius: float



func _init(_position: Vector3, _radius: float) -> void:
	super(Type.EXPLOSION, _position)
	radius= _radius


func create()-> Node3D:
	var explosion: ExplosionEffectInstance= GameData.scene_library.explosion_scene.instantiate()
	explosion.position= position
	explosion.set_radius(radius)
	return explosion


func get_args()-> Array:
	return super() + [radius]
