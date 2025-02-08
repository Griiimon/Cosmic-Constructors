class_name FluidSplashEffect
extends BaseEffect

var eject_vector: Vector3
var fluid: Fluid



func _init(_position: Vector3, _eject_vector: Vector3, _fluid: Fluid):
	super(Type.FLUID_SPLASH, _position)
	eject_vector= _eject_vector
	fluid= _fluid


func create()-> Node3D:
	if not GameData.game_settings.video_settings.enable_fluid_particles:
		return

	var splash: FluidSplashEffectInstance= GameData.scene_library.fluid_splash_scene.instantiate()
	splash.position= position
	splash.eject_vector= eject_vector
	splash.fluid= fluid
	splash.start()
	return splash


func get_args()-> Array:
	return super() + [ eject_vector, GameData.get_fluid_id(fluid) ]


static func parse_args(args: Array)-> Array:
	var fluid_id: int= args[4]
	return args.slice(0, 3) + [ GameData.get_fluid(fluid_id) ]

	
