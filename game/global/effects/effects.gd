extends Node



func create(effect: BaseEffect):
	add_child(effect.create())
	if NetworkManager.is_server:
		ServerManager.broadcast_sync_event(EventSyncState.Type.CREATE_EFFECT, effect.get_args())


#func spawn_explosion(pos: Vector3, radius: float):
	#var explosion: ExplosionEffect= explosion_scene.instantiate()
	#explosion.position= pos
	#explosion.set_radius(radius)
	#add_child(explosion)


#func spawn_fluid_splash(pos: Vector3, vec: Vector3, fluid: Fluid):
	#if not GameData.game_settings.video_settings.enable_fluid_particles:
		#return
#
	#var splash: FluidSplashEffect= fluid_splash_scene.instantiate()
	#splash.position= pos
	#add_child(splash)
	#splash.eject_vector= vec
	#splash.fluid= fluid
	#splash.start()
	##DebugHud.send("Splash position", splash.position)
	##DebugHud.send("Splash vec", splash.eject_vector)
