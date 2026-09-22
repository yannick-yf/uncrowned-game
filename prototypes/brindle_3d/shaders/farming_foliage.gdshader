shader_type spatial;
render_mode cull_disabled;

// Local village foliage only. Keep the source tint/vertex colours and opaque
// shadow casting; transmission is light-dependent, never emissive or transparent.
uniform vec4 tint : source_color = vec4(0.35, 0.44, 0.27, 1.0);
uniform int style_family = 0; // 0: farming kit, 1: painted Brindle library.
uniform float roughness : hint_range(0.0, 1.0) = 0.94;
uniform float texture_strength : hint_range(0.0, 1.0) = 0.17;
uniform float facet_softness : hint_range(0.0, 1.0) = 0.12;
uniform bool vertex_srgb = false;
uniform float wind_strength : hint_range(0.0, 0.03, 0.001) = 0.01;
uniform float transmission_strength : hint_range(0.0, 0.3, 0.005) = 0.12;
uniform float scattering_strength : hint_range(0.0, 0.15, 0.005) = 0.035;
uniform float transmission_depth : hint_range(0.01, 1.0, 0.01) = 0.22;
uniform float backlight_strength : hint_range(0.0, 0.2, 0.005) = 0.08;

varying vec3 local_position;
varying vec3 world_position;

float foliage_hash(vec3 value) {
	if (style_family == 0) {
		return fract(sin(dot(value, vec3(127.1, 311.7, 74.7))) * 43758.5453);
	}
	value = fract(value * 0.1031);
	value += dot(value, value.yzx + 33.33);
	return fract((value.x + value.y) * value.z);
}

float foliage_noise(vec3 value) {
	vec3 cell = floor(value);
	vec3 part = fract(value);
	part = part * part * (3.0 - 2.0 * part);
	return mix(
		mix(mix(foliage_hash(cell), foliage_hash(cell + vec3(1, 0, 0)), part.x),
			mix(foliage_hash(cell + vec3(0, 1, 0)), foliage_hash(cell + vec3(1, 1, 0)), part.x), part.y),
		mix(mix(foliage_hash(cell + vec3(0, 0, 1)), foliage_hash(cell + vec3(1, 0, 1)), part.x),
			mix(foliage_hash(cell + vec3(0, 1, 1)), foliage_hash(cell + vec3(1, 1, 1)), part.x), part.y), part.z);
}

void vertex() {
	local_position = VERTEX;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// World-space phase also distinguishes trees inside a shared MultiMesh.
	// The trunk and fruit meshes are deliberately excluded from this material.
	float weight = smoothstep(0.45, 2.6, local_position.y);
	float phase = TIME * 0.75 + world_position.x * 0.12 + world_position.z * 0.09;
	VERTEX.x += sin(phase) * wind_strength * weight;
	VERTEX.z += cos(phase * 0.83 + 0.8) * wind_strength * 0.35 * weight;
}

void fragment() {
	vec3 base;
	if (style_family == 0) {
		// Match farming_surface.gdshader's original surface_kind == 6 albedo.
		float broad = foliage_noise(local_position * 2.1);
		float fine = foliage_noise(local_position * 25.0);
		base = tint.rgb * COLOR.rgb * (0.9 + 0.15 * broad + 0.06 * fine);
		base *= 0.86 + 0.23 * smoothstep(0.05, 4.5, local_position.y) + 0.08 * broad;
	} else {
		// Match painted_surface.gdshader's untextured leaf material, including its
		// facet softness. This avoids tinting the existing birches a new green.
		float broad = foliage_noise(world_position * 1.4);
		float fine = foliage_noise(world_position * 23.0);
		float detail = broad * 0.8 + fine * 0.2;
		vec3 vertex_tint = vertex_srgb ? pow(COLOR.rgb, vec3(2.2)) : mix(COLOR.rgb, vec3(1.0), facet_softness);
		base = tint.rgb * vertex_tint * (1.0 + (detail - 0.5) * texture_strength * 2.0);
	}
	ALBEDO = max(base, vec3(0.001));
	ROUGHNESS = roughness;
	// Subtle Forward+ SSS/transmission and a cheap shadow-aware backlight term.
	// No skin scattering mode, brightness boost, alpha, or extra texture sample.
#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
	SSS_STRENGTH = scattering_strength;
	SSS_TRANSMITTANCE_COLOR = vec4(base * transmission_strength, 1.0);
	SSS_TRANSMITTANCE_DEPTH = transmission_depth;
	SSS_TRANSMITTANCE_BOOST = 0.0;
#endif
	BACKLIGHT = base * backlight_strength;
}
