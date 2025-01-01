@tool
class_name OrePile
extends Node3D

@export var base_noise: FastNoiseLite
@export var texture_size: int= 128

@export var materials: Array[RawItem]
@export var amounts: Array[float]

@export var do_update: bool: 
	set(b):
		update()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var shader_material: ShaderMaterial= mesh_instance.mesh.surface_get_material(0)

var noises: Array[FastNoiseLite]
var ratios: Array[float]



func _ready() -> void:
	for i in materials.size():
		var material_noise: FastNoiseLite= base_noise.duplicate()
		material_noise.seed= i
		noises.append(material_noise)

	if not Engine.is_editor_hint():
		update.call_deferred()


func update_ratios():
	ratios.clear()
	for amount in amounts:
		ratios.append(amount)


func update():
	update_ratios()
	
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
			
			print(highest_material_index)
			var color:= Color.BLACK
			color.r8= highest_material_index
			img.set_pixel(x, y, color)

	var weight_texture: ImageTexture= ImageTexture.create_from_image(img)
	shader_material.set_shader_parameter("weightTexture", weight_texture) 
