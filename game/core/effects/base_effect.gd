class_name BaseEffect

enum Type { EXPLOSION, FLUID_SPLASH }

var type: Type
var position: Vector3



func _init(_type: Type, _position: Vector3) -> void:
	type= _type
	position= _position


func create()-> Node3D:
	return null


func get_args()-> Array:
	return [int(type), position]


static func from_args(args: Array)-> BaseEffect:
	var new_type: Type= args[0]
	match new_type:
		Type.EXPLOSION:
			return ExplosionEffect.new.callv(args)
		Type.FLUID_SPLASH:
			return FluidSplashEffect.new.callv(FluidSplashEffect.parse_args(args))

	assert(false)
	return null
