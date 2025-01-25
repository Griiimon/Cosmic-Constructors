shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2DArray albedoTextures: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2DArray normalTextures: hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D weightTexture: source_color;

uniform float[16] metallicArr;
uniform float[16] specularArr;
uniform float[16] roughnessArr;
uniform float[16] normalScaleArr;


void fragment() {
	int index = int(floor(texture(weightTexture, UV).r * 255.0));

	vec4 albedoColor = texture(albedoTextures, vec3(UV * 2.0, float(index)));
	vec4 normalColor = texture(normalTextures, vec3(UV * 2.0, float(index)));
	ALBEDO = albedoColor.rgb;
	NORMAL_MAP= normalColor.rgb;
	//NORMAL_MAP_DEPTH= 10.0;
	NORMAL_MAP_DEPTH= normalScaleArr[index];

/*	METALLIC= 0.5;
	SPECULAR= 0.5;
	ROUGHNESS= 0.5; */
	METALLIC= metallicArr[index];
	SPECULAR= specularArr[index];
	ROUGHNESS= roughnessArr[index];
}