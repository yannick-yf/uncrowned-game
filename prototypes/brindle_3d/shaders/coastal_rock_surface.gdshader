shader_type spatial;

#include "res://shaders/coastal_granite.gdshaderinc"

uniform sampler2D painted_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float painted_scale : hint_range(0.02, 0.30, 0.005) = 0.035;
uniform float facet_strength : hint_range(0.0, 1.0) = 0.45;
uniform bool wet_base_enabled = false;
uniform float wet_height_m : hint_range(0.05, 3.0, 0.05) = 0.65;
uniform float wet_darkening : hint_range(0.0, 0.5) = 0.24;

varying vec3 world;
varying vec3 world_normal;
varying float local_height;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	local_height = VERTEX.y;
}

void fragment() {
	vec3 normal = normalize(world_normal);
	vec3 weights = abs(normal);
	weights *= weights;
	weights *= weights;
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	// Match the terrain's yz/xz/xy axis order so overlapping pieces share paint.
	vec3 painted = texture(painted_texture, world.yz * painted_scale).rgb * weights.x;
	painted += texture(painted_texture, world.xz * painted_scale).rgb * weights.y;
	painted += texture(painted_texture, world.xy * painted_scale).rgb * weights.z;
	vec3 stone = coastal_granite(world, normal, painted);
	stone *= mix(vec3(1.0), COLOR.rgb, facet_strength);
	float wet = wet_base_enabled ? 1.0 - smoothstep(0.0, wet_height_m, local_height) : 0.0;
	ALBEDO = stone * (1.0 - wet * wet_darkening);
	NORMAL = coastal_relief_normal(VERTEX,NORMAL,dot(painted,vec3(.2126,.7152,.0722))*.4);
	ROUGHNESS = mix(0.94, 0.76, wet);
	SPECULAR = 0.25;
}
