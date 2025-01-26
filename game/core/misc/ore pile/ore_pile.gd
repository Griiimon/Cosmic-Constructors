class_name OrePile
extends Node3D

signal updated

@export var mesh_size: Vector2
@export var volume_factor: float
@export var max_height: float= 1.0
@export var flip_dot: float= -0.1

@export var orig_shader_material: ShaderMaterial
@export var base_noise: FastNoiseLite
@export var texture_size: int= 128

@export var materials: Array[RawItem]
@export var amounts: Array[float]

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

@onready var area_collision_shape: CollisionShape3D = $"Catch Area/Area CollisionShape"

@onready var gravity_gauge: CollisionObject3D = $"Gravity Gauge"
@onready var static_box_collision_shape: CollisionShape3D = $"StaticBody3D/Static Box CollisionShape"
@onready var static_capsule_collision_shape: CollisionShape3D = $"StaticBody3D/Static Capsule CollisionShape"

@onready var drop_cooldown: Timer = $"Drop Cooldown"


var noises: Array[FastNoiseLite]
var ratios: Array[float]
var total_amount: int= 0

var shader_material: ShaderMaterial



func _ready() -> void:
	shader_material= orig_shader_material.duplicate()
	mesh_instance.mesh.surface_set_material(0, shader_material)
	update()

	(area_collision_shape.shape as BoxShape3D).size= Vector3(mesh_size.x, max_height, mesh_size.y)
	area_collision_shape.position.y= max_height / 2.0

	(static_box_collision_shape.shape as BoxShape3D).size= Vector3(mesh_size.x, 0.01, mesh_size.y)
	(static_capsule_collision_shape.shape as CapsuleShape3D).radius= min(mesh_size.x, mesh_size.y)
	(static_capsule_collision_shape.shape as CapsuleShape3D).height= 0.01


func _physics_process(delta: float) -> void:
	if is_empty(): return
	
	if is_flipped() and drop_cooldown.is_stopped():
		drop_item(Global.game.world)
		drop_cooldown.start()

func update():
	update_ratios()
	update_mesh()
	update_texture()
	update_collision()
	
	updated.emit()


func update_ratios():
	ratios.clear()
	
	for amount in amounts:
		ratios.append(amount / float(total_amount))


func update_mesh():
	(mesh_instance.mesh as BoxMesh).size= Vector3(mesh_size.x, get_mesh_height(), mesh_size.y)
	mesh_instance.position.y= get_mesh_height() / 2.0
	mesh_instance.visible= total_amount > 0


func update_texture():
	if materials.is_empty(): return
	
	var albedo_texture_images: Array[Image]
	var normal_texture_images: Array[Image]
	
	var metallic_arr: PackedFloat32Array
	var specular_arr: PackedFloat32Array
	var roughness_arr: PackedFloat32Array
	var normal_scale_arr: PackedFloat32Array

	metallic_arr.resize(16)
	specular_arr.resize(16)
	roughness_arr.resize(16)
	normal_scale_arr.resize(16)
	
	var img: Image
	
	for i in materials.size():
		img= materials[i].material.albedo_texture.get_image()
		albedo_texture_images.append(img)
		img= materials[i].material.normal_texture.get_image()
		normal_texture_images.append(img)

		metallic_arr[i]= materials[i].material.metallic
		specular_arr[i]= materials[i].material.metallic_specular
		roughness_arr[i]= materials[i].material.roughness
		normal_scale_arr[i]= materials[i].material.normal_scale
		
	var texture_array:= Texture2DArray.new()
	texture_array.create_from_images(albedo_texture_images)
	shader_material.set_shader_parameter("albedoTextures", texture_array) 

	texture_array= Texture2DArray.new()
	texture_array.create_from_images(normal_texture_images)
	shader_material.set_shader_parameter("normalTextures", texture_array) 

	shader_material.set_shader_parameter("metallicArr", metallic_arr) 
	shader_material.set_shader_parameter("specularArr", specular_arr) 
	shader_material.set_shader_parameter("roughnessArr", roughness_arr) 
	shader_material.set_shader_parameter("normalScaleArr", normal_scale_arr) 


	img= Image.create(texture_size, texture_size, false, Image.FORMAT_R8)

	
	for x in texture_size:
		for y in texture_size:
			var highest_material_weight: float= -1.0
			var highest_material_index: int

			for i in ratios.size():
				var noise: float= noises[i].get_noise_2d(x, y)
				var val: float= noise + ratios[i]
				if val > highest_material_weight:
					highest_material_weight= val
					highest_material_index= i
			
			#print(highest_material_index)
			var color:= Color.BLACK
			color.r8= highest_material_index
			img.set_pixel(x, y, color)

	var weight_texture: ImageTexture= ImageTexture.create_from_image(img)
	shader_material.set_shader_parameter("weightTexture", weight_texture) 


func update_collision():
	if total_amount == 0:
		static_box_collision_shape.set_deferred("disabled", true)
		static_capsule_collision_shape.set_deferred("disabled", true)
	else:
		static_box_collision_shape.set_deferred("disabled", false)
		static_capsule_collision_shape.set_deferred("disabled", false)
		
	(static_box_collision_shape.shape as BoxShape3D).size.y= get_mesh_height()
	static_box_collision_shape.position.y= get_mesh_height() / 2.0

	(static_capsule_collision_shape.shape as CapsuleShape3D).height= get_mesh_height() * 1.1
	static_capsule_collision_shape.position.y= get_mesh_height() * 0.55


func add_raw_item(item: RawItem, amount: int):
	if item in materials:
		amounts[materials.find(item)]+= amount
	else:
		materials.append(item)
		amounts.append(amount)

		var material_noise: FastNoiseLite= base_noise.duplicate()
		material_noise.seed= noises.size() + 1
		noises.append(material_noise)


	total_amount+= amount
	
	update()


func add_inv_item(inv_item: InventoryItem):
	add_raw_item(inv_item.item, inv_item.count)


func sub_raw_item(material: RawItem)-> int:
	var count: int= min(get_amount(material), material.get_max_unit_size())
	var idx: int= materials.find(material)
	amounts[idx]-= count
	total_amount-= count
	
	assert(amounts[idx] >= 0)
	
	if amounts[idx] == 0:
		materials.remove_at(idx)
		amounts.remove_at(idx)

	update()

	return count


func drop_item(world: World)-> WorldItemInstance:
	var pile_material: RawItem= get_dominant_material()
	var inv_item:= InventoryItem.new(pile_material, sub_raw_item(pile_material))
	var spawn_pos: Vector3= global_position + global_basis.y * (get_mesh_height() + 0.5)
	return world.spawn_inventory_item(inv_item, spawn_pos)
	

func _on_catch_area_body_entered(body: Node3D) -> void:
	assert(body is WorldItemInstance)
	var item_inst: WorldItemInstance= body
	if item_inst.inv_item.item as RawItem and not is_flipped():
		add_inv_item(item_inst.inv_item)
		item_inst.queue_free()


func get_mesh_height()-> float:
	return max(total_amount * 0.001 * volume_factor, 0.01)


func get_dominant_material()-> RawItem:
	var dominant_material: RawItem= null
	for material in materials:
		if dominant_material == null or get_amount(dominant_material) < get_amount(material):
			dominant_material= material
	return dominant_material


func get_amount(material: RawItem)-> int:
	return int(amounts[materials.find(material)])


func get_mass()-> int:
	return round(total_amount / 1000)


func is_full()-> bool:
	return get_mesh_height() >= max_height


func is_empty()-> bool:
	return materials.is_empty()


func is_flipped()-> bool:
	var grav_dir: Vector3= gravity_gauge.get_gravity().normalized()
	return grav_dir.dot(global_basis.y) > flip_dot
