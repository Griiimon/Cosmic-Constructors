extends HandObject

@export var muzzle: Node3D



func use():
	var weapon_definition: ProjectileWeapon= item_definition
	var projectile: ProjectileObject= weapon_definition.projectile.scene.instantiate()
	projectile.projectile_definition= weapon_definition.projectile
	projectile.position= player.to_global(muzzle.global_position)
	projectile.rotation= player.pivot.global_rotation
	player.world.add_projectile(projectile)
	projectile.velocity= -projectile.global_basis.z * weapon_definition.muzzle_velocity