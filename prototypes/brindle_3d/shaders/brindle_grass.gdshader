shader_type spatial;

// Grass component extracted from Brindle's village_ground.gdshader.
// The original noise, palette and world-space sampling are retained.
uniform vec4 grass_dark : source_color = vec4(0.20, 0.29, 0.15, 1.0);
uniform vec4 grass_light : source_color = vec4(0.36, 0.43, 0.21, 1.0);
uniform sampler2D ground_noise : filter_linear_mipmap, repeat_enable;
varying vec3 world;

float noise(vec2 p) {
	return texture(ground_noise, p * 0.021).r;
}

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world.xz;
	float grain = noise(p * 18.0);
	float patches = noise(p * 0.65) * 0.58 + noise(p * 2.9) * 0.27 + noise(p * 8.0) * 0.15;
	vec3 grass = mix(grass_dark.rgb, grass_light.rgb, smoothstep(0.22, 0.80, patches));
	grass *= 0.94 + grain * 0.12;
	ALBEDO = grass;
	ROUGHNESS = 0.96;
}
