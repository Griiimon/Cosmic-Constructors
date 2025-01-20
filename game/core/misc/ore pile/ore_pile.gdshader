shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2DArray albedoTextures: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2DArray normalTextures: hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D weightTexture: source_color;


void fragment() {
	float index = texture(weightTexture, UV).r;
	vec4 albedoColor = texture(albedoTextures, vec3(UV * 2.0, floor(index*255.0)));
	vec4 normalColor = texture(normalTextures, vec3(UV * 2.0, floor(index*255.0)));
	ALBEDO = albedoColor.rgb;
	NORMAL_MAP= normalColor.rgb;
	NORMAL_MAP_DEPTH= 10.0;
	
	METALLIC= 0.5;
	SPECULAR= 0.5;
	ROUGHNESS= 0.5;
}