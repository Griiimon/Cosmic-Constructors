shader_type spatial;

uniform sampler2DArray albedoTextures: source_color;
uniform sampler2D weightTexture: source_color;


void fragment() {
	float index = texture(weightTexture, UV).r;
	vec4 albedoColor = texture(albedoTextures, vec3(UV * 2.0, floor(index*255.0)));
	ALBEDO = albedoColor.rgb;
}