class_name OrePile
extends Node3D

@export var mesh_size: Vector2
@export var volume_factor: float

@export var base_noise: FastNoiseLite
@export var texture_size: int= 128

@export var materials: Array[RawItem]
@export var amounts: Array[float]

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var shader_material: ShaderMaterial= mesh_instance.mesh.surface_get_material(0)

var noises: Array[FastNoiseLite]
var ratios: Array[float]
var total_amount: int= 0



func _ready() -> void:
	update()


func update():
	update_ratios()
	update_mesh()
	update_texture()


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
	
	var texture_images: Array[Image]

	for i in materials.size():
		var img: Image= materials[i].material.albedo_texture.get_image()
		#img.save_png("res://temp/%d.png" % i)
		texture_images.append(img)
		
	var texture_array:= Texture2DArray.new()

	texture_array.create_from_images(texture_images)
	#texture_array.create_from_images(materials.map(func(x: RawItem): return x.material.albedo_texture.get_image()))
	shader_material.set_shader_parameter("albedoTextures", texture_array) 


	var img: Image= Image.create(texture_size, texture_size, false, Image.FORMAT_R8)

	
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
	DebugHud.send("Total Amount", total_amount)
	DebugHud.send("Mesh Height", get_mesh_height())
	
	update()


func _on_catch_area_body_entered(body: Node3D) -> void:
	assert(body is WorldItemInstance)
	var item_inst: WorldItemInstance= body
	if item_inst.inv_item.item as RawItem:
		add_raw_item(item_inst.inv_item.item, item_inst.inv_item.count)
		item_inst.queue_free()


func get_mesh_height()-> float:
	#return total_amount * 0.001
	return total_amount * 0.001 * volume_factor
